from database.db import SupabaseDB, handle_supabase_error
from models.fuel_price import FuelPrice
from datetime import datetime, timedelta, timezone


class FuelTransaction:
    """Data-access layer for the existing fuel_transactions schema.

    Supabase schema:
      id, vehicle_id, station_id, liters_pumped, amount_paid,
      pumped_at, sync_status
    """

    def __init__(self):
        self.db = SupabaseDB()
        self.client = self.db.get_client()
        self.table = 'fuel_transactions'
        self.price_model = FuelPrice()

    def _now(self):
        return datetime.now(timezone.utc)

    def _get_current_fuel_price(self, fuel_type='petrol_92'):
        try:
            price = self.price_model.get_current(fuel_type)
            if not price:
                return None
            return {
                'fuel_type': price.get('fuel_type', fuel_type),
                'price_per_liter': float(price.get('price_per_liter', 0) or 0),
                'currency': price.get('currency', 'MMK'),
            }
        except Exception as e:
            print(f"⚠️ Could not load fuel price: {e}")
            return None

    @handle_supabase_error
    def create_transaction(self, vehicle_id, station_id, liters,
                           amount_paid=None, quota_before=None,
                           quota_after=None, fuel_type='petrol_92'):
        """Create one transaction using the existing database schema.

        quota_before/quota_after are accepted for backward compatibility,
        but are not written because those columns do not exist in the table.
        """
        try:
            now = self._now()
            liters = float(liters)

            if liters <= 0:
                return {'error': 'Liters must be greater than 0'}

            # The current schema has no transaction_hash/idempotency column.
            # Use a short time-window duplicate check as a safety net.
            window_start = now - timedelta(minutes=1)
            try:
                existing = self.client.table(self.table) \
                    .select('*') \
                    .eq('vehicle_id', vehicle_id) \
                    .eq('station_id', station_id) \
                    .eq('liters_pumped', liters) \
                    .gte('pumped_at', window_start.isoformat()) \
                    .order('pumped_at', desc=True) \
                    .limit(1) \
                    .execute()

                if existing.data:
                    print(
                        "⚠️ Possible duplicate transaction detected; "
                        f"returning existing ID {existing.data[0]['id']}"
                    )
                    return existing.data[0]
            except Exception as duplicate_error:
                print(f"⚠️ Duplicate check skipped: {duplicate_error}")

            price = self._get_current_fuel_price(fuel_type)
            if not price:
                return {'error': f'No active fuel price configured for {fuel_type}'}

            unit_price = float(price['price_per_liter'])
            currency = price['currency']

            if amount_paid is None:
                amount_paid = round(liters * unit_price, 2)
            else:
                amount_paid = float(amount_paid)

            transaction_data = {
                'vehicle_id': vehicle_id,
                'station_id': station_id,
                'liters_pumped': liters,
                'amount_paid': amount_paid,
                'pumped_at': now.isoformat(),
                'sync_status': 'online',
                'fuel_type': fuel_type,
                'unit_price': unit_price,
            }

            print(f"📝 Creating transaction: {transaction_data}")

            result = self.client.table(self.table) \
                .insert(transaction_data) \
                .execute()

            if result.data:
                print(f"✅ Transaction created: {result.data[0]['id']}")
                return result.data[0]

            return {'error': 'Transaction was not created'}

        except Exception as e:
            print(f"❌ Error creating transaction: {e}")
            import traceback
            traceback.print_exc()
            return {'error': str(e)}

    @handle_supabase_error
    def get_vehicle_transactions(self, vehicle_id, limit=10):
        try:
            result = self.client.table(self.table) \
                .select('*') \
                .eq('vehicle_id', vehicle_id) \
                .order('pumped_at', desc=True) \
                .limit(limit) \
                .execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"❌ Error: {e}")
            return []

    @handle_supabase_error
    def get_station_transactions(self, station_id, date=None):
        try:
            if date is None:
                date = datetime.now(timezone.utc).date()
            else:
                date = datetime.fromisoformat(str(date)).date()

            start = datetime.combine(
                date, datetime.min.time(), tzinfo=timezone.utc
            )
            end = start + timedelta(days=1)

            result = self.client.table(self.table) \
                .select('*, vehicles(plate_number, vehicle_type)') \
                .eq('station_id', station_id) \
                .gte('pumped_at', start.isoformat()) \
                .lt('pumped_at', end.isoformat()) \
                .order('pumped_at', desc=True) \
                .execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"❌ Error: {e}")
            return []

    @handle_supabase_error
    def get_weekly_usage(self, vehicle_id, week_key=None):
        """Sum liters_pumped during the current week.

        week_key is retained for backward compatibility; the date range is
        derived from the current ISO week instead of a nonexistent DB column.
        """
        try:
            now = datetime.now(timezone.utc)
            start = (now - timedelta(days=now.weekday())).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            end = start + timedelta(days=7)

            result = self.client.table(self.table) \
                .select('liters_pumped') \
                .eq('vehicle_id', vehicle_id) \
                .gte('pumped_at', start.isoformat()) \
                .lt('pumped_at', end.isoformat()) \
                .execute()

            return round(
                sum(
                    float(item.get('liters_pumped', 0) or 0)
                    for item in (result.data or [])
                ),
                2
            )
        except Exception as e:
            print(f"❌ Error calculating weekly usage: {e}")
            return 0.0
