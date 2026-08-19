from database.db import handle_supabase_error
from models.vehicle import Vehicle
from models.transaction import FuelTransaction
from datetime import datetime


class QuotaService:
    def __init__(self):
        self.vehicle_model = Vehicle()
        self.transaction_model = FuelTransaction()

    @handle_supabase_error
    def check_available_quota(self, vehicle_id):
        """ယာဉ်တစ်စီးအတွက် ကျန်ရှိသော ခွဲတမ်းကို စစ်ဆေးခြင်း"""
        vehicle = self.vehicle_model.get_vehicle_by_id(vehicle_id)

        if not vehicle:
            return {'error': 'ယာဉ်မတွေ့ပါ'}

        if isinstance(vehicle, dict) and vehicle.get('error'):
            return vehicle

        weekly_quota = vehicle.get('weekly_quota', 20)
        current_week = datetime.now().strftime('%Y-W%W')

        # ယခုအပတ်သုံးစွဲပြီးသော ဆီပမာဏ
        used_this_week = self.transaction_model.get_weekly_usage(vehicle_id, current_week)

        # ကျန်ရှိခွဲတမ်း တွက်ချက်
        remaining = weekly_quota - used_this_week

        # ယာဉ်အချက်အလက် ရယူ
        vehicle_info = {
            'id': vehicle['id'],
            'plate_number': vehicle['plate_number'],
            'vehicle_type': vehicle['vehicle_type']
        }

        return {
            'vehicle': vehicle_info,
            'weekly_quota': weekly_quota,
            'used_this_week': used_this_week,
            'remaining': max(0, remaining),
            'can_fuel': remaining > 0,
            'week': current_week
        }

    @handle_supabase_error
    def get_all_vehicles_quota_status(self, user_id):
        """အသုံးပြုသူတစ်ဦး၏ ယာဉ်အားလုံးအတွက် ခွဲတမ်းအခြေအနေ"""
        vehicles = self.vehicle_model.get_vehicles_by_user(user_id)
        status_list = []

        for vehicle in vehicles:
            status = self.check_available_quota(vehicle['id'])
            if status and not isinstance(status, dict) and status.get('error'):
                continue
            status_list.append(status)

        return status_list

    @handle_supabase_error
    def get_system_quota_summary(self):
        """စနစ်တစ်ခုလုံး၏ ခွဲတမ်းအကျဉ်းချုပ် (Admin အတွက်)"""
        # စုစုပေါင်း ယာဉ်အရေအတွက်
        vehicles_result = self.vehicle_model.client.table('vehicles') \
            .select('id', count='exact') \
            .eq('is_active', True) \
            .execute()

        total_vehicles = vehicles_result.count if hasattr(vehicles_result, 'count') else 0

        # ယခုအပတ် စုစုပေါင်းသုံးစွဲမှု
        weekly_summary = self.transaction_model.get_system_weekly_summary()

        return {
            'total_vehicles': total_vehicles,
            'weekly_summary': weekly_summary,
            'timestamp': datetime.now().isoformat()
        }