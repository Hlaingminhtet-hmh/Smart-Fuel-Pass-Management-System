from datetime import datetime, timezone, timedelta

from database.db import SupabaseDB


class AdminService:
    """Central admin data/service layer used by the Admin web portal."""

    VEHICLE_TYPES = {'car', 'bike', 'three_wheel', 'bus', 'truck'}
    FUEL_TYPES = {'petrol_92', 'petrol_95', 'diesel'}
    USER_ROLES = {'user', 'admin', 'station_operator'}
    STATION_STATUSES = {'active', 'inactive', 'suspended'}
    OPERATOR_STATUSES = {'active', 'inactive', 'suspended'}

    def __init__(self):
        self.client = SupabaseDB().get_client()

    @staticmethod
    def _text(value):
        return str(value or '').strip()

    @staticmethod
    def _now():
        return datetime.now(timezone.utc)

    def _rows(self, table, columns='*', limit=1000):
        return self.client.table(table).select(columns).limit(limit).execute().data or []

    # ---------------- Dashboard ----------------

    def get_dashboard_summary(self):
        vehicles = self._rows('vehicles', 'id,is_active')
        stations = self._rows('fuel_stations', 'id,status')
        users = self._rows('users', 'id,role,is_admin')
        operators = self._rows('station_operators', 'id,status')
        tx = self._rows('fuel_transactions', 'id,vehicle_id,station_id,liters_pumped,amount_paid,pumped_at,fuel_type,unit_price', 2000)
        registry = self._rows('admin_vehicle_registry', 'id,status')
        policies = self._rows('fuel_quota_policies', 'id,status')
        prices = self.list_current_prices()

        day_start = self._now().replace(hour=0, minute=0, second=0, microsecond=0)
        today_tx = [t for t in tx if t.get('pumped_at') and str(t['pumped_at']) >= day_start.isoformat()]

        return {
            'total_vehicles': len(vehicles),
            'active_vehicles': sum(1 for v in vehicles if v.get('is_active')),
            'active_stations': sum(1 for s in stations if s.get('status') == 'active'),
            'total_stations': len(stations),
            'total_users': len(users),
            'active_operators': sum(1 for o in operators if o.get('status') == 'active'),
            'today_transactions': len(today_tx),
            'today_liters': round(sum(float(t.get('liters_pumped', 0) or 0) for t in today_tx), 2),
            'today_amount': round(sum(float(t.get('amount_paid', 0) or 0) for t in today_tx), 2),
            'registry_pending': sum(1 for r in registry if r.get('status') == 'pending'),
            'registry_approved': sum(1 for r in registry if r.get('status') == 'approved'),
            'active_quota_policies': sum(1 for p in policies if p.get('status') == 'active'),
            'fuel_prices': prices,
        }

    # ---------------- Vehicle Registry ----------------

    def list_registry(self, status=None, search=None, limit=100):
        rows = self.client.table('admin_vehicle_registry').select('*').order('created_at', desc=True).limit(limit).execute().data or []
        if status:
            rows = [r for r in rows if r.get('status') == status]
        if search:
            q = self._text(search).lower()
            rows = [r for r in rows if any(q in self._text(r.get(k)).lower() for k in ('plate_number', 'registration_no', 'owner_name', 'owner_national_id'))]
        return rows

    def _get_active_quota_policy(self, vehicle_type, fuel_type):
        result = (self.client.table('fuel_quota_policies').select('*')
                  .eq('vehicle_type', vehicle_type).eq('fuel_type', fuel_type)
                  .eq('status', 'active').order('effective_from', desc=True).limit(1).execute())
        return result.data[0] if result.data else None

    def create_registry_vehicle(self, payload, admin_user_id):
        required = ['registration_no', 'plate_number', 'owner_name', 'vehicle_type', 'fuel_type']
        missing = [k for k in required if not self._text(payload.get(k))]
        if missing:
            return {'error': f'Missing required fields: {missing}'}
        vehicle_type = self._text(payload['vehicle_type']).lower()
        fuel_type = self._text(payload['fuel_type']).lower()
        if vehicle_type not in self.VEHICLE_TYPES:
            return {'error': 'Invalid vehicle type'}
        if fuel_type not in self.FUEL_TYPES:
            return {'error': 'Invalid fuel type'}
        policy = self._get_active_quota_policy(vehicle_type, fuel_type)
        if not policy:
            return {'error': f'No active quota policy for {vehicle_type} + {fuel_type}.'}
        status = self._text(payload.get('status') or 'pending').lower()
        if status not in {'pending', 'approved'}:
            return {'error': 'Initial status must be pending or approved'}
        row = {
            'registration_no': self._text(payload['registration_no']).upper(),
            'plate_number': self._text(payload['plate_number']).upper(),
            'owner_name': self._text(payload['owner_name']),
            'owner_national_id': self._text(payload.get('owner_national_id')) or None,
            'vehicle_type': vehicle_type,
            'engine_capacity': self._text(payload.get('engine_capacity')) or None,
            'fuel_type': fuel_type,
            'weekly_quota': float(policy['weekly_quota_liters']),
            'status': status,
            'approved_by': int(admin_user_id) if status == 'approved' else None,
            'approved_at': self._now().isoformat() if status == 'approved' else None,
        }
        result = self.client.table('admin_vehicle_registry').insert(row).execute()
        return result.data[0] if result.data else {'error': 'Vehicle registry record was not created'}

    def update_registry_status(self, registry_id, status, admin_user_id):
        if status not in {'pending', 'approved', 'rejected', 'suspended'}:
            return {'error': 'Invalid registry status'}
        existing = self.client.table('admin_vehicle_registry').select('*').eq('id', int(registry_id)).limit(1).execute()
        if not existing.data:
            return {'error': 'Registry record not found'}
        record = existing.data[0]
        row = {'status': status, 'approved_by': int(admin_user_id) if status == 'approved' else None,
               'approved_at': self._now().isoformat() if status == 'approved' else None}
        if status == 'approved':
            policy = self._get_active_quota_policy(record['vehicle_type'], record['fuel_type'])
            if not policy:
                return {'error': f'No active quota policy exists for {record["vehicle_type"]} + {record["fuel_type"]}.'}
            row['weekly_quota'] = float(policy['weekly_quota_liters'])
        result = self.client.table('admin_vehicle_registry').update(row).eq('id', int(registry_id)).execute()
        return result.data[0] if result.data else {'error': 'Registry record not found'}

    # ---------------- Quotas ----------------

    def list_quota_policies(self, status=None):
        query = self.client.table('fuel_quota_policies').select('*').order('vehicle_type').order('fuel_type')
        if status:
            query = query.eq('status', status)
        return query.execute().data or []

    def create_quota_policy(self, payload, admin_user_id):
        vehicle_type = self._text(payload.get('vehicle_type')).lower()
        fuel_type = self._text(payload.get('fuel_type')).lower()
        if vehicle_type not in self.VEHICLE_TYPES:
            return {'error': 'Invalid vehicle type'}
        if fuel_type not in self.FUEL_TYPES:
            return {'error': 'Invalid fuel type'}
        try:
            weekly_quota = float(payload.get('weekly_quota_liters'))
        except (TypeError, ValueError):
            return {'error': 'Weekly quota must be a number'}
        if weekly_quota < 0:
            return {'error': 'Weekly quota cannot be negative'}
        existing = self.client.table('fuel_quota_policies').select('id').eq('vehicle_type', vehicle_type).eq('fuel_type', fuel_type).limit(1).execute()
        if existing.data:
            return {'error': 'A quota policy already exists for this vehicle type + fuel type'}
        row = {'vehicle_type': vehicle_type, 'fuel_type': fuel_type, 'weekly_quota_liters': weekly_quota,
               'status': 'active', 'created_by': int(admin_user_id)}
        result = self.client.table('fuel_quota_policies').insert(row).execute()
        return result.data[0] if result.data else {'error': 'Quota policy was not created'}

    def update_quota_policy(self, policy_id, weekly_quota_liters, status, admin_user_id):
        try:
            quota = float(weekly_quota_liters)
        except (TypeError, ValueError):
            return {'error': 'Weekly quota must be a number'}
        if quota < 0 or status not in {'active', 'inactive'}:
            return {'error': 'Invalid quota or status'}
        existing = self.client.table('fuel_quota_policies').select('*').eq('id', int(policy_id)).limit(1).execute()
        if not existing.data:
            return {'error': 'Quota policy not found'}
        policy = existing.data[0]
        result = self.client.table('fuel_quota_policies').update({'weekly_quota_liters': quota, 'status': status, 'created_by': int(admin_user_id)}).eq('id', int(policy_id)).execute()
        if not result.data:
            return {'error': 'Quota policy update failed'}
        try:
            self.client.table('admin_vehicle_registry').update({'weekly_quota': quota}).eq('vehicle_type', policy['vehicle_type']).eq('fuel_type', policy['fuel_type']).execute()
        except Exception:
            pass
        try:
            self.client.table('vehicles').update({'weekly_quota': quota, 'weekly_quota_liters': quota}).eq('vehicle_type', policy['vehicle_type']).eq('fuel_type', policy['fuel_type']).execute()
        except Exception:
            pass
        return result.data[0]

    # ---------------- Users / Owners ----------------

    def list_users(self, role=None, search=None, limit=500):
        rows = self.client.table('users').select('*').order('id', desc=True).limit(limit).execute().data or []
        if role:
            rows = [r for r in rows if r.get('role') == role]
        if search:
            q = self._text(search).lower()
            rows = [r for r in rows if any(q in self._text(r.get(k)).lower() for k in ('name', 'national_id', 'phone', 'email', 'role'))]
        return rows

    def list_vehicle_owners(self, search=None):
        return self.list_users(role='user', search=search)

    # ---------------- Stations ----------------

    def list_stations(self, status=None, search=None):
        rows = self.client.table('fuel_stations').select('*').order('id').execute().data or []
        if status:
            rows = [r for r in rows if r.get('status') == status]
        if search:
            q = self._text(search).lower()
            rows = [r for r in rows if any(q in self._text(r.get(k)).lower() for k in ('station_name', 'license_no', 'region_zone', 'address', 'city'))]
        return rows

    def create_station(self, payload):
        name = self._text(payload.get('station_name'))
        if not name:
            return {'error': 'Station name is required'}
        row = {'station_name': name, 'license_no': self._text(payload.get('license_no')) or None,
               'region_zone': self._text(payload.get('region_zone')) or None,
               'status': self._text(payload.get('status') or 'active').lower()}
        if row['status'] not in self.STATION_STATUSES:
            return {'error': 'Invalid station status'}
        # Only write columns that are part of this project's known station schema.
        result = self.client.table('fuel_stations').insert(row).execute()
        return result.data[0] if result.data else {'error': 'Station was not created'}

    def update_station(self, station_id, payload):
        status = self._text(payload.get('status')).lower()
        if status not in self.STATION_STATUSES:
            return {'error': 'Invalid station status'}
        row = {'status': status}
        for key in ('station_name', 'license_no', 'region_zone'):
            if key in payload:
                row[key] = self._text(payload.get(key)) or None
        result = self.client.table('fuel_stations').update(row).eq('id', int(station_id)).execute()
        return result.data[0] if result.data else {'error': 'Station not found'}

    # ---------------- Operators ----------------

    def list_operators(self, status=None, search=None):
        query = self.client.table('station_operators').select('*').order('id', desc=True)
        if status:
            query = query.eq('status', status)
        rows = query.execute().data or []
        stations = {int(s['id']): s for s in self.list_stations() if s.get('id') is not None}
        users = {int(u['id']): u for u in self._rows('users') if u.get('id') is not None}
        for row in rows:
            row['station'] = stations.get(int(row['station_id']), {}) if row.get('station_id') is not None else {}
            row['user'] = users.get(int(row['user_id']), {}) if row.get('user_id') is not None else {}
        if search:
            q = self._text(search).lower()
            rows = [r for r in rows if q in self._text(r.get('operator_code')).lower() or q in self._text(r.get('user', {}).get('name')).lower() or q in self._text(r.get('station', {}).get('station_name')).lower()]
        return rows

    def update_operator_status(self, operator_id, status):
        if status not in self.OPERATOR_STATUSES:
            return {'error': 'Invalid operator status'}
        result = self.client.table('station_operators').update({'status': status, 'updated_at': self._now().isoformat()}).eq('id', int(operator_id)).execute()
        return result.data[0] if result.data else {'error': 'Operator not found'}

    # ---------------- Fuel Prices ----------------

    def list_current_prices(self):
        rows = self.client.table('fuel_prices').select('*').eq('status', 'active').order('effective_from', desc=True).execute().data or []
        now = self._now().isoformat()
        current = {}
        for row in rows:
            fuel = row.get('fuel_type')
            if not fuel or fuel in current:
                continue
            if row.get('effective_from') and row['effective_from'] > now:
                continue
            if row.get('effective_to') and row['effective_to'] < now:
                continue
            current[fuel] = row
        return [current[f] for f in ('petrol_92', 'petrol_95', 'diesel') if f in current]

    def list_price_history(self):
        return self.client.table('fuel_prices').select('*').order('effective_from', desc=True).limit(300).execute().data or []

    def create_fuel_price(self, fuel_type, price_per_liter, currency='MMK'):
        fuel_type = self._text(fuel_type).lower()
        if fuel_type not in self.FUEL_TYPES:
            return {'error': 'Invalid fuel type'}
        try:
            price = float(price_per_liter)
        except (TypeError, ValueError):
            return {'error': 'Price must be a number'}
        if price <= 0:
            return {'error': 'Price must be greater than 0'}
        now = self._now()
        self.client.table('fuel_prices').update({'status': 'inactive', 'effective_to': now.isoformat(), 'updated_at': now.isoformat()}).eq('fuel_type', fuel_type).eq('status', 'active').execute()
        result = self.client.table('fuel_prices').insert({'fuel_type': fuel_type, 'price_per_liter': price, 'currency': self._text(currency) or 'MMK', 'effective_from': now.isoformat(), 'status': 'active', 'created_at': now.isoformat(), 'updated_at': now.isoformat()}).execute()
        return result.data[0] if result.data else {'error': 'Price was not created'}

    def deactivate_price(self, price_id):
        result = self.client.table('fuel_prices').update({'status': 'inactive', 'effective_to': self._now().isoformat(), 'updated_at': self._now().isoformat()}).eq('id', int(price_id)).execute()
        return result.data[0] if result.data else {'error': 'Price not found'}

    # ---------------- Transactions / Reports ----------------

    def list_transactions(self, search=None, fuel_type=None, station_id=None, days=30, limit=500):
        cutoff = self._now() - timedelta(days=int(days))
        rows = (self.client.table('fuel_transactions').select('*').gte('pumped_at', cutoff.isoformat()).order('pumped_at', desc=True).limit(limit).execute().data or [])
        vehicles = {int(v['id']): v for v in self._rows('vehicles') if v.get('id') is not None}
        stations = {int(s['id']): s for s in self._rows('fuel_stations') if s.get('id') is not None}
        for row in rows:
            row['vehicle'] = vehicles.get(int(row['vehicle_id']), {}) if row.get('vehicle_id') is not None else {}
            row['station'] = stations.get(int(row['station_id']), {}) if row.get('station_id') is not None else {}
        if fuel_type:
            rows = [r for r in rows if r.get('fuel_type') == fuel_type]
        if station_id:
            rows = [r for r in rows if str(r.get('station_id')) == str(station_id)]
        if search:
            q = self._text(search).lower()
            rows = [r for r in rows if q in self._text(r.get('fuel_type')).lower() or q in self._text(r.get('vehicle', {}).get('plate_number')).lower() or q in self._text(r.get('station', {}).get('station_name')).lower()]
        return rows

    def build_report(self, days=30):
        rows = self.list_transactions(days=days, limit=2000)
        by_fuel = {f: {'transactions': 0, 'liters': 0.0, 'amount': 0.0} for f in self.FUEL_TYPES}
        by_station = {}
        for row in rows:
            fuel = row.get('fuel_type') or 'petrol_92'
            if fuel not in by_fuel:
                by_fuel[fuel] = {'transactions': 0, 'liters': 0.0, 'amount': 0.0}
            by_fuel[fuel]['transactions'] += 1
            by_fuel[fuel]['liters'] += float(row.get('liters_pumped', 0) or 0)
            by_fuel[fuel]['amount'] += float(row.get('amount_paid', 0) or 0)
            station = row.get('station', {})
            key = station.get('station_name') or f"Station #{row.get('station_id')}"
            by_station.setdefault(key, {'transactions': 0, 'liters': 0.0, 'amount': 0.0})
            by_station[key]['transactions'] += 1
            by_station[key]['liters'] += float(row.get('liters_pumped', 0) or 0)
            by_station[key]['amount'] += float(row.get('amount_paid', 0) or 0)
        for data in list(by_fuel.values()) + list(by_station.values()):
            data['liters'] = round(data['liters'], 2)
            data['amount'] = round(data['amount'], 2)
        return {'days': days, 'transactions': len(rows), 'liters': round(sum(x['liters'] for x in by_fuel.values()), 2), 'amount': round(sum(x['amount'] for x in by_fuel.values()), 2), 'by_fuel': by_fuel, 'by_station': by_station}
