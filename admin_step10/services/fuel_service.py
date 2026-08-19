from database.db import handle_supabase_error
from models.vehicle import Vehicle
from models.transaction import FuelTransaction
from services.quota_service import QuotaService
import json


class FuelService:
    def __init__(self):
        self.vehicle_model = Vehicle()
        self.transaction_model = FuelTransaction()
        self.quota_service = QuotaService()

    @handle_supabase_error
    def process_fuel_request(self, vehicle_id, station_id, requested_liters):
        """ဆီဖြည့်သွင်းခွင့် ပြုမပြု ဆုံးဖြတ်ခြင်း"""

        # ယာဉ်ရှိမရှိ စစ်ဆေး
        vehicle = self.vehicle_model.get_vehicle_by_id(vehicle_id)
        if not vehicle:
            return {
                'success': False,
                'message': 'ယာဉ်မတွေ့ပါ',
                'code': 'VEHICLE_NOT_FOUND'
            }

        if isinstance(vehicle, dict) and vehicle.get('error'):
            return {
                'success': False,
                'message': vehicle['error'],
                'code': 'VEHICLE_ERROR'
            }

        # ခွဲတမ်းကျန်ရှိမှု စစ်ဆေး
        quota_status = self.quota_service.check_available_quota(vehicle_id)

        if isinstance(quota_status, dict) and quota_status.get('error'):
            return {
                'success': False,
                'message': quota_status['error'],
                'code': 'QUOTA_ERROR'
            }

        if not quota_status.get('can_fuel'):
            return {
                'success': False,
                'message': f'ဤယာဉ်အတွက် ယခုအပတ် ခွဲတမ်းပြည့်သွားပါပြီ။ ကျန်ရှိခွဲတမ်း: 0 လီတာ',
                'remaining': 0,
                'used': quota_status['used_this_week'],
                'quota': quota_status['weekly_quota'],
                'code': 'QUOTA_EXHAUSTED'
            }

        if requested_liters > quota_status['remaining']:
            return {
                'success': False,
                'message': f'�ောင်းဆိုထားသော ပမာဏ ({requested_liters}L) သည် ကျန်ရှိခွဲတမ်း ({quota_status["remaining"]}L) ထက် များနေပါသည်',
                'remaining': quota_status['remaining'],
                'max_allowed': quota_status['remaining'],
                'used': quota_status['used_this_week'],
                'quota': quota_status['weekly_quota'],
                'code': 'EXCEEDS_QUOTA'
            }

        # Resolve the vehicle's fuel type. The Step 9 migration adds a
        # dedicated fuel_type column; petrol_92 is only a development fallback
        # for legacy rows.
        fuel_type = str(vehicle.get('fuel_type') or 'petrol_92').strip().lower()

        # ဆီဖြည့်သွင်းခွင့် ပြုခြင်း
        transaction = self.transaction_model.create_transaction(
            vehicle_id, station_id, requested_liters, fuel_type=fuel_type
        )

        if isinstance(transaction, dict) and transaction.get('error'):
            return {
                'success': False,
                'message': transaction['error'],
                'code': 'TRANSACTION_ERROR'
            }

        # အပ်ဒိတ်လုပ်ပြီးသော ကျန်ရှိခွဲတမ်း
        new_remaining = quota_status['remaining'] - requested_liters

        return {
            'success': True,
            'message': 'ဆီဖြည့်သွင်းခွင့် ပြုလိုက်ပါပြီ',
            'transaction': transaction,
            'liters_dispensed': requested_liters,
            'remaining_after': new_remaining,
            'fuel_type': transaction.get('fuel_type', fuel_type),
            'unit_price': float(transaction.get('unit_price', 0) or 0),
            'currency': 'MMK',
            'amount_paid': float(transaction.get('amount_paid', 0) or 0),
            'vehicle': {
                'id': vehicle['id'],
                'plate_number': vehicle['plate_number'],
                'vehicle_type': vehicle['vehicle_type']
            },
            'code': 'SUCCESS'
        }

    @handle_supabase_error
    def scan_qr_and_fuel(self, qr_data, station_id, requested_liters):
        """QR ကုဒ်ကို စကင်ဖတ်ပြီး ဆီဖြည့်ခြင်း"""
        try:
            # QR ကုဒ်ထဲက အချက်အလက်ကိ် JSON အဖြစ် ဖတ်ခြင်း
            data = json.loads(qr_data)
            vehicle_id = data.get('vehicle_id')

            if not vehicle_id:
                return {
                    'success': False,
                    'message': 'QR ကုဒ်တွင် ယာဉ်အချက်အလက် မပါဝင်ပါ',
                    'code': 'INVALID_QR'
                }

            return self.process_fuel_request(vehicle_id, station_id, requested_liters)

        except json.JSONDecodeError:
            return {
                'success': False,
                'message': 'QR ကုဒ် မှားယွင်းနေပါသည်',
                'code': 'INVALID_QR_FORMAT'
            }