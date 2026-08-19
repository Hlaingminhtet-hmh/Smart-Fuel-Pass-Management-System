from database.db import SupabaseDB, handle_supabase_error
from datetime import datetime


class Vehicle:
    def __init__(self):
        self.db = SupabaseDB()
        self.client = self.db.get_client()
        self.table = 'vehicles'

    @handle_supabase_error
    def register_vehicle(self, user_id, plate_number, vehicle_type, engine_capacity=None):
        """ယာဉ်အသစ် မှတ်ပုံတင်ခြင်း"""

        # Check if plate exists
        existing = self.get_vehicle_by_plate(plate_number)
        if existing:
            return {'error': 'လိုင်စင်နံပါတ် ရှိပြီးသားဖြစ်ပါသည်'}

        # Clean engine capacity
        if engine_capacity:
            import re
            numbers = re.findall(r'\d+', str(engine_capacity))
            engine_capacity = float(numbers[0]) if numbers else None

        # Set quota based on vehicle type
        quotas = {
            'bike': 10,
            'car': 40,
            'three_wheel': 25,
            'bus': 200,
            'truck': 300
        }

        vehicle_data = {
            'user_id': user_id,
            'plate_number': plate_number.upper(),
            'vehicle_type': vehicle_type,
            'engine_capacity': engine_capacity,
            'weekly_quota': quotas.get(vehicle_type, 20),
            'qr_code_image': None,  # QR image သိမ်းမယ်
            'qr_code_data': None,  # QR data သိမ်းမယ်
            'qr_generated_at': None,
            'is_active': True,
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }

        print(f"📝 Registering vehicle: {vehicle_data}")

        result = self.client.table(self.table).insert(vehicle_data).execute()

        if result.data and len(result.data) > 0:
            print(f"✅ Vehicle registered: {result.data[0]}")
            return result.data[0]
        return {'error': 'ယာဉ်မှတ်ပုံတင်ရာတွင် အမှားရှိနေပါသည်'}

    @handle_supabase_error
    def save_qr_code(self, vehicle_id, qr_image, qr_data):
        """QR code ကို database မှာ သိမ်းမယ်"""
        try:
            update_data = {
                'qr_code_image': qr_image,
                'qr_code_data': qr_data,
                'qr_generated_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }

            result = self.client.table(self.table) \
                .update(update_data) \
                .eq('id', vehicle_id) \
                .execute()

            if result.data and len(result.data) > 0:
                print(f"✅ QR code saved for vehicle: {vehicle_id}")
                return result.data[0]
            return None
        except Exception as e:
            print(f"❌ Error saving QR code: {e}")
            return None

    @handle_supabase_error
    def get_qr_code(self, vehicle_id):
        """Database ကနေ QR code ကိုပြန်ယူမယ်"""
        try:
            result = self.client.table(self.table) \
                .select('qr_code_image, qr_code_data, plate_number, vehicle_type') \
                .eq('id', vehicle_id) \
                .execute()

            if result.data and len(result.data) > 0:
                return result.data[0]
            return None
        except Exception as e:
            print(f"❌ Error getting QR code: {e}")
            return None


    @handle_supabase_error
    def get_vehicle_by_plate(self, plate_number):
        """လိုင်စင်နံပါတ်ဖြင့် ရှာဖွေခြင်း"""
        try:
            print(f"🔍 Searching for vehicle with plate: {plate_number}")
            result = self.client.table(self.table) \
                .select('*') \
                .eq('plate_number', plate_number.upper()) \
                .execute()

            if result.data and len(result.data) > 0:
                print(f"✅ Vehicle found: {result.data[0]}")
                return result.data[0]
            print(f"❌ No vehicle found with plate: {plate_number}")
            return None
        except Exception as e:
            print(f"❌ Error in get_vehicle_by_plate: {e}")
            return None

    @handle_supabase_error
    def get_vehicle_by_id(self, vehicle_id):
        """Vehicle ID ဖြင့် ရှာဖွေခြင်း"""
        try:
            result = self.client.table(self.table) \
                .select('*') \
                .eq('id', vehicle_id) \
                .execute()

            if result.data and len(result.data) > 0:
                return result.data[0]
            return None
        except Exception as e:
            print(f"❌ Error in get_vehicle_by_id: {e}")
            return None

    @handle_supabase_error
    def get_vehicles_by_user(self, user_id):
        """အသုံးပြုသူတစ်ဦး၏ ယာဉ်များအားလုံး ရယူခြင်း"""
        try:
            result = self.client.table(self.table) \
                .select('*') \
                .eq('user_id', user_id) \
                .eq('is_active', True) \
                .execute()

            return result.data if result.data else []
        except Exception as e:
            print(f"❌ Error in get_vehicles_by_user: {e}")
            return []

    @handle_supabase_error
    def update_qr_code(self, vehicle_id, qr_image, qr_data=None):
        """QR ကုဒ် သိမ်းဆည်းခြင်း"""
        try:
            update_data = {
                'qr_code': qr_image,
                'updated_at': datetime.now().isoformat()
            }

            if qr_data:
                update_data['qr_data'] = qr_data

            result = self.client.table(self.table) \
                .update(update_data) \
                .eq('id', vehicle_id) \
                .execute()

            if result.data and len(result.data) > 0:
                print(f"✅ QR code updated for vehicle: {vehicle_id}")
                return result.data[0]
            return None
        except Exception as e:
            print(f"❌ Error in update_qr_code: {e}")
            return None

    @handle_supabase_error
    def update_weekly_quota(self, vehicle_id, new_quota):
        """အပတ်စဉ်ခွဲတမ်း ပြင်ဆင်ခြင်း (Admin အတွက်)"""
        try:
            result = self.client.table(self.table) \
                .update({
                'weekly_quota': new_quota,
                'updated_at': datetime.now().isoformat()
            }) \
                .eq('id', vehicle_id) \
                .execute()

            if result.data and len(result.data) > 0:
                return result.data[0]
            return {'error': 'ခွဲတမ်း ပြင်ဆင်ရာတွင် အမှားရှိနေပါသည်'}
        except Exception as e:
            print(f"❌ Error in update_weekly_quota: {e}")
            return {'error': str(e)}