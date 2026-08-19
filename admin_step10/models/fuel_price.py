from datetime import datetime, timezone
from database.db import SupabaseDB, handle_supabase_error


class FuelPrice:
    def __init__(self):
        self.client = SupabaseDB().get_client()
        self.table = 'fuel_prices'

    @handle_supabase_error
    def get_current(self, fuel_type: str):
        now = datetime.now(timezone.utc).isoformat()
        result = (
            self.client.table(self.table)
            .select('*')
            .eq('fuel_type', fuel_type)
            .eq('status', 'active')
            .lte('effective_from', now)
            .order('effective_from', desc=True)
            .limit(10)
            .execute()
        )

        for row in (result.data or []):
            effective_to = row.get('effective_to')
            if not effective_to or effective_to >= now:
                return row
        return None

    @handle_supabase_error
    def list_current(self):
        result = (
            self.client.table(self.table)
            .select('*')
            .eq('status', 'active')
            .order('fuel_type')
            .order('effective_from', desc=True)
            .execute()
        )
        rows = result.data or []
        current = {}
        now = datetime.now(timezone.utc).isoformat()
        for row in rows:
            if row['fuel_type'] in current:
                continue
            if row.get('effective_from', '') > now:
                continue
            effective_to = row.get('effective_to')
            if effective_to and effective_to < now:
                continue
            current[row['fuel_type']] = row
        return list(current.values())

    @handle_supabase_error
    def create_price(self, fuel_type, price_per_liter, currency='MMK'):
        fuel_type = str(fuel_type).strip().lower()
        price = float(price_per_liter)
        if not fuel_type:
            return {'error': 'fuel_type is required'}
        if price <= 0:
            return {'error': 'price_per_liter must be greater than 0'}

        # Close the previous active price so the latest price has a clean range.
        now = datetime.now(timezone.utc)
        self.client.table(self.table).update({
            'status': 'inactive',
            'effective_to': now.isoformat(),
            'updated_at': now.isoformat(),
        }).eq('fuel_type', fuel_type).eq('status', 'active').execute()

        result = self.client.table(self.table).insert({
            'fuel_type': fuel_type,
            'price_per_liter': price,
            'currency': currency,
            'effective_from': now.isoformat(),
            'status': 'active',
            'created_at': now.isoformat(),
            'updated_at': now.isoformat(),
        }).execute()
        return result.data[0] if result.data else {'error': 'Price was not created'}
