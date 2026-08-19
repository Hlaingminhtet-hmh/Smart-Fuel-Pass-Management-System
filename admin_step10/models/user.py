from database.db import SupabaseDB, handle_supabase_error
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash


class User:
    def __init__(self):
        self.db = SupabaseDB()
        self.client = self.db.get_client()
        self.table = 'users'

    @handle_supabase_error
    def create_user(self, national_id, name, phone, password, is_admin=False):
        """အသုံးပြုသူအသစ် ဖန်တီးခြင်း"""

        # နိုင်ငံသားမှတ်ပုံတင် ရှိပြီးသားလား စစ်ဆေး
        existing = self.get_user_by_national_id(national_id)
        if existing:
            return {'error': 'မှတ်ပုံတင်နံပါတ် ရှိပြီးသားဖြစ်ပါသည်'}

        user_data = {
            'national_id': national_id,
            'name': name,
            'phone': phone,
            'password_hash': generate_password_hash(password),
            'role': 'user',
            'is_admin': is_admin,
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }

        # Insert user
        result = self.client.table(self.table).insert(user_data).execute()

        # Debug: ဘာတွေပြန်လာလဲဆိုတာ အသေးစိတ်ကြည့်မယ်
        print("=" * 60)
        print("SUPABASE INSERT RESULT:")
        print(f"Type: {type(result)}")
        print(f"Dir: {dir(result)}")
        print(f"Has data: {hasattr(result, 'data')}")

        if hasattr(result, 'data'):
            print(f"Data: {result.data}")
            print(f"Data type: {type(result.data)}")
            if result.data and len(result.data) > 0:
                print(f"First item: {result.data[0]}")
                print(f"First item type: {type(result.data[0])}")
                print(f"First item keys: {result.data[0].keys() if isinstance(result.data[0], dict) else 'Not a dict'}")

        print("=" * 60)

        if result.data and len(result.data) > 0:
            return result.data[0]
        return {'error': 'အသုံးပြုသူ ဖန်တီးရာတွင် အမှားရှိနေပါသည်'}

    @handle_supabase_error
    def get_user_by_national_id(self, national_id):
        """နိုင်ငံသားမှတ်ပုံတင်နံပါတ်ဖြင့် ရှာဖွေခြင်း"""
        result = self.client.table(self.table) \
            .select('*') \
            .eq('national_id', national_id) \
            .execute()

        if result.data and len(result.data) > 0:
            return result.data[0]
        return None

    @handle_supabase_error
    def authenticate(self, national_id, password):
        """Login ဝင်ရန် စစ်ဆေးခြင်း"""
        user = self.get_user_by_national_id(national_id)

        if user and check_password_hash(user['password_hash'], password):
            # လျှို့ဝှက်နံပါတ်ကို ဖယ်ရှားပြီး return ပြန်ခြင်း
            user.pop('password_hash', None)
            return user

        return None