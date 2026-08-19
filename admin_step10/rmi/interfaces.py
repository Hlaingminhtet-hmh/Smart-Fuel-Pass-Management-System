from abc import ABC, abstractmethod
from typing import Dict, List, Any, Optional


class UserRMIInterface(ABC):
    @abstractmethod
    def register_user(self, national_id: str, name: str, phone: str, password: str) -> Dict[str, Any]:
        pass

    @abstractmethod
    def authenticate_user(self, national_id: str, password: str) -> Optional[Dict[str, Any]]:
        pass

    @abstractmethod
    def get_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        pass


class VehicleRMIInterface(ABC):
    @abstractmethod
    def register_vehicle(self, user_id: str, plate_number: str, vehicle_type: str, engine_capacity: float = None) -> Dict[str, Any]:
        pass

    @abstractmethod
    def get_vehicles_by_user(self, user_id: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    def get_vehicle_by_plate(self, plate_number: str) -> Optional[Dict[str, Any]]:
        pass

    @abstractmethod
    def get_vehicle_by_id(self, vehicle_id: str) -> Optional[Dict[str, Any]]:
        pass

    @abstractmethod
    def claim_approved_vehicle(self, user_id: str, plate_number: str) -> Dict[str, Any]:
        pass


class FuelRMIInterface(ABC):
    @abstractmethod
    def check_available_quota(self, vehicle_id: str) -> Dict[str, Any]:
        pass

    @abstractmethod
    def process_fuel_request(self, vehicle_id: str, station_id: str, liters: float) -> Dict[str, Any]:
        pass

    @abstractmethod
    def get_vehicle_transactions(self, vehicle_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    def get_station_transactions_range(self, station_id: str, days: int = 7) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    def get_station_summary(self, station_id: str, days: int = 7) -> Dict[str, Any]:
        pass

    @abstractmethod
    def get_current_fuel_price(self, fuel_type: str = 'petrol_92') -> Optional[Dict[str, Any]]:
        pass

    @abstractmethod
    def get_fuel_prices(self) -> List[Dict[str, Any]]:
        pass


class QRServiceInterface(ABC):
    @abstractmethod
    def generate_qr_code(self, vehicle_id: str, plate_number: str, user_id: str = None, vehicle_type: str = None) -> Dict[str, Any]:
        pass

    @abstractmethod
    def scan_qr_code(self, qr_data: str) -> Dict[str, Any]:
        pass

    @abstractmethod
    def verify_qr_code(self, qr_data: str, vehicle_id: str) -> bool:
        pass


class StationOperatorRMIInterface(ABC):
    @abstractmethod
    def authenticate_operator(self, operator_code: str, password: str) -> Optional[Dict[str, Any]]:
        pass

    @abstractmethod
    def get_operator(self, operator_id: str) -> Optional[Dict[str, Any]]:
        pass


class NotificationServiceInterface(ABC):
    @abstractmethod
    def send_sms(self, phone_number: str, message: str) -> bool:
        pass

    @abstractmethod
    def send_email(self, email: str, subject: str, message: str) -> bool:
        pass

    @abstractmethod
    def send_push_notification(self, user_id: str, title: str, message: str) -> bool:
        pass

class AdminRMIInterface(ABC):
    @abstractmethod
    def get_dashboard_summary(self) -> Dict[str, Any]:
        pass

    @abstractmethod
    def list_registry(self, status: Optional[str] = None, search: Optional[str] = None, limit: int = 100) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    def create_registry_vehicle(self, payload: Dict[str, Any], admin_user_id: int) -> Dict[str, Any]:
        pass

    @abstractmethod
    def update_registry_status(self, registry_id: int, status: str, admin_user_id: int) -> Dict[str, Any]:
        pass

    @abstractmethod
    def list_quota_policies(self, status: Optional[str] = None) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    def create_quota_policy(self, payload: Dict[str, Any], admin_user_id: int) -> Dict[str, Any]:
        pass

    @abstractmethod
    def update_quota_policy(self, policy_id: int, weekly_quota_liters: float, status: str, admin_user_id: int) -> Dict[str, Any]:
        pass
