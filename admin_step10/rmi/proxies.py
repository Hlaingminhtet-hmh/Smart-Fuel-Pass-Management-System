import Pyro5.api

RMI_SERVER = "127.0.0.1"
RMI_PORT = 9090


def _get_proxy(object_name: str):
    try:
        proxy = Pyro5.api.Proxy(f"PYRO:{object_name}@{RMI_SERVER}:{RMI_PORT}")
        proxy._pyroBind()
        return proxy
    except Exception as exc:
        print(f"Failed to create {object_name} proxy: {exc}")
        return None


def get_user_service():
    return _get_proxy("fuelpass.user")


def get_vehicle_service():
    return _get_proxy("fuelpass.vehicle")


def get_fuel_service():
    return _get_proxy("fuelpass.fuel")


def get_qr_service():
    return _get_proxy("fuelpass.qr")


def get_station_operator_service():
    return _get_proxy("fuelpass.station_operator")


def get_admin_service():
    return _get_proxy("fuelpass.admin")
