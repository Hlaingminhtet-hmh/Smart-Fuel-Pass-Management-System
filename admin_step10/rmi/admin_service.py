import logging
import Pyro5.api

from services.admin_service import AdminService
from rmi.interfaces import AdminRMIInterface

logger = logging.getLogger(__name__)


@Pyro5.api.expose
class AdminRMIService(AdminRMIInterface):
    def __init__(self):
        self.service = AdminService()
        logger.info('AdminRMIService initialized')

    def __getattr__(self, name):
        # Pyro only exposes explicit methods; this fallback is not relied upon
        # remotely but keeps local callers predictable.
        return getattr(self.service, name)

    @Pyro5.api.expose
    def get_dashboard_summary(self): return self.service.get_dashboard_summary()
    @Pyro5.api.expose
    def list_registry(self, status=None, search=None, limit=100): return self.service.list_registry(status, search, limit)
    @Pyro5.api.expose
    def create_registry_vehicle(self, payload, admin_user_id): return self.service.create_registry_vehicle(payload, admin_user_id)
    @Pyro5.api.expose
    def update_registry_status(self, registry_id, status, admin_user_id): return self.service.update_registry_status(registry_id, status, admin_user_id)
    @Pyro5.api.expose
    def list_quota_policies(self, status=None): return self.service.list_quota_policies(status)
    @Pyro5.api.expose
    def create_quota_policy(self, payload, admin_user_id): return self.service.create_quota_policy(payload, admin_user_id)
    @Pyro5.api.expose
    def update_quota_policy(self, policy_id, weekly_quota_liters, status, admin_user_id): return self.service.update_quota_policy(policy_id, weekly_quota_liters, status, admin_user_id)
    @Pyro5.api.expose
    def list_users(self, role=None, search=None, limit=500): return self.service.list_users(role, search, limit)
    @Pyro5.api.expose
    def list_stations(self, status=None, search=None): return self.service.list_stations(status, search)
    @Pyro5.api.expose
    def create_station(self, payload): return self.service.create_station(payload)
    @Pyro5.api.expose
    def update_station(self, station_id, payload): return self.service.update_station(station_id, payload)
    @Pyro5.api.expose
    def list_operators(self, status=None, search=None): return self.service.list_operators(status, search)
    @Pyro5.api.expose
    def update_operator_status(self, operator_id, status): return self.service.update_operator_status(operator_id, status)
    @Pyro5.api.expose
    def list_current_prices(self): return self.service.list_current_prices()
    @Pyro5.api.expose
    def list_price_history(self): return self.service.list_price_history()
    @Pyro5.api.expose
    def create_fuel_price(self, fuel_type, price_per_liter, currency='MMK'): return self.service.create_fuel_price(fuel_type, price_per_liter, currency)
    @Pyro5.api.expose
    def deactivate_price(self, price_id): return self.service.deactivate_price(price_id)
    @Pyro5.api.expose
    def list_transactions(self, search=None, fuel_type=None, station_id=None, days=30, limit=500): return self.service.list_transactions(search, fuel_type, station_id, days, limit)
    @Pyro5.api.expose
    def build_report(self, days=30): return self.service.build_report(days)
