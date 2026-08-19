from datetime import datetime, timezone
from database.db import SupabaseDB, handle_supabase_error
from werkzeug.security import check_password_hash


class StationOperator:
    """Station operator authentication and station assignment.

    A station operator is a normal user linked to exactly one fuel station
    through the station_operators table.
    """

    def __init__(self):
        db = SupabaseDB()
        self.client = db.get_client()
        self.table = 'station_operators'

    @handle_supabase_error
    def get_by_operator_code(self, operator_code):
        result = (
            self.client.table(self.table)
            .select('*')
            .eq('operator_code', operator_code)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    @handle_supabase_error
    def authenticate(self, operator_code, password):
        operator = self.get_by_operator_code(operator_code)
        if not operator:
            return None

        if operator.get('status') != 'active':
            return {'error': 'Operator account is inactive'}

        user_result = (
            self.client.table('users')
            .select('id,name,national_id,phone,password_hash,role,is_admin')
            .eq('id', operator['user_id'])
            .limit(1)
            .execute()
        )
        user = user_result.data[0] if user_result.data else None
        if not user or not user.get('password_hash'):
            return None

        if user.get('role') != 'station_operator':
            return {'error': 'User is not a dedicated station operator'}

        try:
            password_ok = check_password_hash(user['password_hash'], password)
        except Exception:
            password_ok = False

        if not password_ok:
            return None

        station_result = (
            self.client.table('fuel_stations')
            .select('id,station_name,license_no,region_zone,contact_number,status')
            .eq('id', operator['station_id'])
            .limit(1)
            .execute()
        )
        station = station_result.data[0] if station_result.data else None
        if not station:
            return {'error': 'Assigned fuel station was not found'}
        if station.get('status') not in (None, 'active'):
            return {'error': 'Assigned fuel station is inactive'}

        now = datetime.now(timezone.utc).isoformat()
        self.client.table(self.table).update({
            'last_login_at': now,
            'updated_at': now,
        }).eq('id', operator['id']).execute()

        return {
            'operator': {
                'id': operator['id'],
                'operator_code': operator['operator_code'],
                'user_id': user['id'],
                'name': user.get('name'),
                'national_id': user.get('national_id'),
            },
            'station': station,
        }
