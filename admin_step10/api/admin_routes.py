from flask import (
    Blueprint,
    jsonify,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from rmi.proxies import get_admin_service

admin_api = Blueprint("admin_api", __name__)


def _require_admin_page():
    return session.get("user_id") is not None and bool(session.get("is_admin"))


def _require_admin_api():
    return _require_admin_page()


def _service_or_error():
    service = get_admin_service()
    if not service:
        return None, (
            jsonify({"success": False, "message": "RMI Admin service unavailable"}),
            503,
        )
    return service, None


@admin_api.get("/admin")
def admin_dashboard():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    if not service:
        return render_template(
            "admin/dashboard.html",
            error="RMI Admin service unavailable",
            summary={},
            registry=[],
            admin_name=session.get("name"),
        )
    try:
        return render_template(
            "admin/dashboard.html",
            summary=service.get_dashboard_summary(),
            registry=service.list_registry(limit=10),
            admin_name=session.get("name", "Admin User"),
        )
    except Exception as exc:
        return render_template(
            "admin/dashboard.html",
            error=str(exc),
            summary={},
            registry=[],
            admin_name=session.get("name"),
        )


@admin_api.get("/admin/vehicles")
def admin_vehicles():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    if not service:
        return render_template(
            "admin/vehicles.html", error="RMI Admin service unavailable", vehicles=[]
        )
    status = request.args.get("status") or None
    search = request.args.get("search") or None
    return render_template(
        "admin/vehicles.html",
        vehicles=service.list_registry(status=status, search=search, limit=200),
        policies=service.list_quota_policies(status="active"),
        status=status or "",
        search=search or "",
        admin_name=session.get("name"),
    )


@admin_api.post("/admin/vehicles")
def create_admin_vehicle():
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    payload = (
        request.get_json(silent=True) if request.is_json else request.form.to_dict()
    )
    result = service.create_registry_vehicle(payload or {}, session["user_id"])
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "vehicle": result}), 201


@admin_api.post("/admin/vehicles/<int:registry_id>/status")
def update_admin_vehicle_status(registry_id):
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    payload = request.get_json(silent=True) or request.form.to_dict()
    result = service.update_registry_status(
        registry_id, payload.get("status"), session["user_id"]
    )
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "vehicle": result})


@admin_api.get("/admin/quota-policies")
def admin_quota_policies():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    if not service:
        return render_template(
            "admin/quota_policies.html",
            error="RMI Admin service unavailable",
            policies=[],
        )
    return render_template(
        "admin/quota_policies.html",
        policies=service.list_quota_policies(),
        admin_name=session.get("name"),
    )


@admin_api.post("/admin/quota-policies")
def create_quota_policy():
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    payload = (
        request.get_json(silent=True) if request.is_json else request.form.to_dict()
    )
    result = service.create_quota_policy(payload or {}, session["user_id"])
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "policy": result}), 201


@admin_api.post("/admin/quota-policies/<int:policy_id>")
def update_quota_policy(policy_id):
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    payload = request.get_json(silent=True) or request.form.to_dict()
    result = service.update_quota_policy(
        policy_id,
        payload.get("weekly_quota_liters"),
        payload.get("status", "active"),
        session["user_id"],
    )
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "policy": result})


@admin_api.get("/admin/owners")
def admin_owners():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    search = request.args.get("search") or None
    return render_template(
        "admin/owners.html",
        owners=service.list_users(None, search),
        search=search or "",
        admin_name=session.get("name"),
    )


@admin_api.get("/admin/stations")
def admin_stations():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    search, status = (
        request.args.get("search") or None,
        request.args.get("status") or None,
    )
    return render_template(
        "admin/stations.html",
        stations=service.list_stations(status, search),
        search=search or "",
        status=status or "",
        admin_name=session.get("name"),
    )


@admin_api.post("/admin/stations")
def create_station():
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    result = service.create_station(
        request.get_json(silent=True) or request.form.to_dict()
    )
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "station": result}), 201


@admin_api.post("/admin/stations/<int:station_id>")
def update_station(station_id):
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    result = service.update_station(
        station_id, request.get_json(silent=True) or request.form.to_dict()
    )
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "station": result})


@admin_api.get("/admin/operators")
def admin_operators():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    search, status = (
        request.args.get("search") or None,
        request.args.get("status") or None,
    )
    return render_template(
        "admin/operators.html",
        operators=service.list_operators(status, search),
        stations=service.list_stations(status="active"),
        search=search or "",
        status=status or "",
        admin_name=session.get("name"),
    )


@admin_api.post("/admin/operators/<int:operator_id>/status")
def update_operator_status(operator_id):
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    result = service.update_operator_status(
        operator_id,
        (request.get_json(silent=True) or request.form.to_dict()).get("status"),
    )
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "operator": result})


@admin_api.get("/admin/prices")
def admin_prices():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    return render_template(
        "admin/prices.html",
        prices=service.list_current_prices(),
        history=service.list_price_history(),
        admin_name=session.get("name"),
    )


@admin_api.post("/admin/prices")
def create_price():
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    body = request.get_json(silent=True) or request.form.to_dict()
    result = service.create_fuel_price(
        body.get("fuel_type"), body.get("price_per_liter"), body.get("currency", "MMK")
    )
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "price": result}), 201


@admin_api.post("/admin/prices/<int:price_id>/deactivate")
def deactivate_price(price_id):
    if not _require_admin_api():
        return jsonify({"success": False, "message": "Admin access required"}), 403
    service, err = _service_or_error()
    if err:
        return err
    result = service.deactivate_price(price_id)
    if result.get("error"):
        return jsonify({"success": False, "message": result["error"]}), 400
    return jsonify({"success": True, "price": result})


@admin_api.get("/admin/transactions")
def admin_transactions():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    search = request.args.get("search") or None
    fuel_type = request.args.get("fuel_type") or None
    station_id = request.args.get("station_id") or None
    days = int(request.args.get("days", 30))
    return render_template(
        "admin/transactions.html",
        transactions=service.list_transactions(search, fuel_type, station_id, days),
        stations=service.list_stations(),
        search=search or "",
        fuel_type=fuel_type or "",
        station_id=station_id or "",
        days=days,
        admin_name=session.get("name"),
    )


@admin_api.get("/admin/reports")
def admin_reports():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    service = get_admin_service()
    days = int(request.args.get("days", 30))
    return render_template(
        "admin/reports.html",
        report=service.build_report(days),
        days=days,
        admin_name=session.get("name"),
    )


@admin_api.get("/admin/settings")
def admin_settings():
    if not _require_admin_page():
        return redirect(url_for("rmi_login"))
    return render_template(
        "admin/settings.html",
        admin_name=session.get("name", "Admin User"),
        admin_user_id=session.get("user_id"),
        admin_role=session.get("role"),
        admin_name_for_form=session.get("name"),
    )
