from flask import Flask, render_template, request, redirect, url_for, session
from dotenv import load_dotenv
import os

load_dotenv()

from api.admin_routes import admin_api
from api.admin_station_operator import admin_station_operator_api
from api.station_routes import station_api
from api.user_routes import user_api
from rmi.proxies import get_user_service, get_admin_service

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "dev-key")
app.debug = os.getenv("FLASK_DEBUG", "False").lower() == "true"

# Android User App API remains available; this is not a User Web UI.
app.register_blueprint(user_api)
app.register_blueprint(station_api)
app.register_blueprint(admin_api)
app.register_blueprint(admin_station_operator_api)


@app.get("/")
def home():
    if session.get("is_admin"):
        return redirect(url_for("admin_api.admin_dashboard"))
    return redirect(url_for("rmi_login"))


@app.route("/rmi-login", methods=["GET", "POST"])
def rmi_login():
    if session.get("is_admin"):
        return redirect(url_for("admin_api.admin_dashboard"))

    error = None

    if request.method == "POST":
        national_id = (request.form.get("national_id") or "").strip()
        password = request.form.get("password") or ""

        if not national_id or not password:
            error = "National ID and password are required."
        else:
            user_service = get_user_service()

            if not user_service:
                error = "RMI Server is not connected."
            else:
                try:
                    user = user_service.authenticate_user(
                        national_id,
                        password,
                    )

                    if not user:
                        error = "Invalid credentials."
                    elif not bool(user.get("is_admin")) or user.get("role") != "admin":
                        error = "This portal is for administrators only."
                    else:
                        session.clear()
                        session["user_id"] = user["id"]
                        session["name"] = user.get("name", "Admin User")
                        session["role"] = user.get("role")
                        session["is_admin"] = True

                        return redirect(url_for("admin_api.admin_dashboard"))

                except Exception as exc:
                    error = f"Login error: {exc}"

    return render_template(
        "admin/login.html",
        error=error,
    )


@app.get("/rmi-logout")
def rmi_logout():
    session.clear()
    return redirect(url_for("rmi_login"))


if __name__ == "__main__":
    print("\n============================================================")
    print("🔧 Fuel Pass Admin Flask App")
    print("============================================================")
    print("✅ Android User API: /api/v1/user/*")
    print("✅ Station API:      /api/v1/station/*")
    print("✅ Admin Web:        /admin")
    print("✅ Admin Login:      /rmi-login")
    print("============================================================\n")

    app.run(
        host="0.0.0.0",
        port=9091,
        debug=app.debug,
    )
