from flask import Blueprint, jsonify, request

from rmi.proxies import get_qr_service, get_vehicle_service, get_fuel_service
from api.station_auth import register_station_auth_routes, require_station_auth

station_api = Blueprint("station_api", __name__, url_prefix="/api/v1/station")
register_station_auth_routes(station_api)


def _error(message, code, status=400, **extra):
    payload = {
        "success": False,
        "message": message,
        "code": code,
    }
    payload.update(extra)
    return jsonify(payload), status


@station_api.get("/health")
def health():
    """Lightweight station API health check."""
    qr = get_qr_service()
    vehicle = get_vehicle_service()
    fuel = get_fuel_service()
    return jsonify(
        {
            "success": bool(qr and vehicle and fuel),
            "services": {
                "qr": bool(qr),
                "vehicle": bool(vehicle),
                "fuel": bool(fuel),
            },
        }
    )


@station_api.post("/qr/verify")
@require_station_auth
def verify_qr():
    """Verify a scanned vehicle QR and return current vehicle/quota data."""
    body = request.get_json(silent=True) or {}
    qr_payload = body.get("qr_payload")

    if not isinstance(qr_payload, str) or not qr_payload.strip():
        return _error("qr_payload is required", "MISSING_QR_PAYLOAD")

    qr_service = get_qr_service()
    vehicle_service = get_vehicle_service()
    fuel_service = get_fuel_service()

    if not qr_service or not vehicle_service or not fuel_service:
        return _error("RMI service is unavailable", "RMI_UNAVAILABLE", 503)

    try:
        scan = qr_service.scan_qr_code(qr_payload)
        if not scan or not scan.get("success"):
            return _error(
                scan.get("error", "Invalid QR code") if scan else "Invalid QR code",
                scan.get("code", "INVALID_QR") if scan else "INVALID_QR",
            )

        vehicle_id = scan.get("vehicle_id")
        if not vehicle_id:
            return _error("Vehicle ID is missing from QR code", "MISSING_VEHICLE_ID")

        vehicle = vehicle_service.get_vehicle_by_id(vehicle_id)
        if not vehicle:
            return _error("Vehicle not found", "VEHICLE_NOT_FOUND", 404)
        if isinstance(vehicle, dict) and vehicle.get("error"):
            return _error(vehicle["error"], "VEHICLE_ERROR", 500)

        # The QR already identifies the vehicle. Confirm that its plate agrees
        # with the current database record before exposing station data.
        qr_plate = str(scan.get("plate", "")).strip().upper()
        db_plate = str(vehicle.get("plate_number", "")).strip().upper()
        if qr_plate and db_plate and qr_plate != db_plate:
            return _error(
                "QR and vehicle record do not match", "QR_VEHICLE_MISMATCH", 409
            )

        quota = fuel_service.check_available_quota(vehicle_id)
        if not quota or quota.get("error"):
            return _error(
                (
                    quota.get("error", "Quota unavailable")
                    if quota
                    else "Quota unavailable"
                ),
                "QUOTA_ERROR",
                500,
            )

        return jsonify(
            {
                "success": True,
                "message": "Vehicle QR verified",
                "vehicle": {
                    "id": vehicle.get("id"),
                    "plate_number": vehicle.get("plate_number"),
                    "vehicle_type": vehicle.get("vehicle_type"),
                    "engine_capacity": vehicle.get("engine_capacity"),
                    "fuel_type": vehicle.get("fuel_type"),
                },
                "quota": {
                    "weekly_quota": quota.get("weekly_quota", 0),
                    "used_this_week": quota.get("used_this_week", 0),
                    "remaining": quota.get("remaining", 0),
                    "can_fuel": quota.get("can_fuel", False),
                    "week": quota.get("week"),
                },
            }
        )

    except Exception as exc:
        return _error(f"QR verification failed: {exc}", "QR_VERIFY_ERROR", 500)


@station_api.post("/fuel")
@require_station_auth
def process_fuel():
    """Process a confirmed station fueling request through the RMI fuel service."""
    body = request.get_json(silent=True) or {}
    vehicle_id = body.get("vehicle_id")
    station_context = getattr(request, "station_context", {})
    station_id = station_context.get("station_id")
    liters = body.get("liters")

    if not vehicle_id or station_id is None or liters is None:
        return _error(
            "vehicle_id and liters are required",
            "MISSING_FIELDS",
        )

    station_id = int(station_id)

    try:
        liters = float(liters)
    except (TypeError, ValueError):
        return _error("liters must be a number", "INVALID_LITERS")

    if liters <= 0:
        return _error("liters must be greater than 0", "INVALID_LITERS")

    fuel_service = get_fuel_service()
    if not fuel_service:
        return _error("RMI fuel service is unavailable", "RMI_UNAVAILABLE", 503)

    try:
        result = fuel_service.process_fuel_request(
            str(vehicle_id),
            str(station_id),
            liters,
        )
        status = 200 if result and result.get("success") else 400
        return (
            jsonify(
                result
                or {
                    "success": False,
                    "message": "Fuel request failed",
                    "code": "FUEL_REQUEST_FAILED",
                }
            ),
            status,
        )
    except Exception as exc:
        return _error(f"Fuel request failed: {exc}", "FUEL_REQUEST_ERROR", 500)


@station_api.get("/transactions")
@require_station_auth
def station_transactions():
    station_id = int(request.station_context["station_id"])

    try:
        days = int(request.args.get("days", 1))
    except ValueError:
        return _error("days must be an integer", "INVALID_DAYS")

    days = max(1, min(days, 30))
    fuel_service = get_fuel_service()
    if not fuel_service:
        return _error("RMI fuel service is unavailable", "RMI_UNAVAILABLE", 503)

    try:
        transactions = fuel_service.get_station_transactions_range(station_id, days)
        summary = fuel_service.get_station_summary(station_id, days)
        return jsonify(
            {
                "success": True,
                "station": {
                    "id": station_id,
                },
                "range_days": days,
                "transactions": transactions or [],
                "summary": {
                    "total_transactions": int(
                        (summary or {}).get("total_transactions", 0) or 0
                    ),
                    "total_liters": float((summary or {}).get("total_liters", 0) or 0),
                    "unique_vehicles": int(
                        (summary or {}).get("unique_vehicles", 0) or 0
                    ),
                    "avg_liters": float((summary or {}).get("avg_liters", 0) or 0),
                },
            }
        )
    except Exception as exc:
        return _error(f"Could not load transactions: {exc}", "TRANSACTIONS_ERROR", 500)


@station_api.get("/pricing/current")
@require_station_auth
def current_fuel_price():
    fuel_type = (request.args.get("fuel_type") or "petrol_92").strip().lower()
    if not fuel_type:
        return _error("fuel_type is required", "MISSING_FUEL_TYPE")

    fuel_service = get_fuel_service()
    if not fuel_service:
        return _error("RMI fuel service is unavailable", "RMI_UNAVAILABLE", 503)

    try:
        price = fuel_service.get_current_fuel_price(fuel_type)
        if not price:
            return _error(
                f"No active fuel price configured for {fuel_type}",
                "FUEL_PRICE_NOT_CONFIGURED",
                404,
            )
        return jsonify(
            {
                "success": True,
                "fuel_type": price.get("fuel_type", fuel_type),
                "price_per_liter": float(price.get("price_per_liter", 0) or 0),
                "currency": price.get("currency", "MMK"),
                "effective_from": price.get("effective_from"),
            }
        )
    except Exception as exc:
        return _error(f"Could not load fuel price: {exc}", "FUEL_PRICE_ERROR", 500)
