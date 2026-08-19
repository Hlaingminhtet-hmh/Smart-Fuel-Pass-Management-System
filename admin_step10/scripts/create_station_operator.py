import getpass
import os
import sys

from dotenv import load_dotenv
from werkzeug.security import generate_password_hash
from supabase import create_client

load_dotenv()


def required(name):
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"{name} is required in .env")
    return value


def main():
    url = required("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY")
    if not key:
        raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY is required for operator bootstrap")

    client = create_client(url, key)

    print("\n=== Create Dedicated Station Operator ===\n")
    name = input("Operator name: ").strip()
    operator_code = input("Operator code (e.g. OP-001): ").strip().upper()
    phone = input("Phone (optional): ").strip() or None
    national_id = input("National ID (optional): ").strip() or None
    station_id_text = input("Station ID: ").strip()
    password = getpass.getpass("Password (min 8 chars): ")
    confirm = getpass.getpass("Confirm password: ")

    if not name or not operator_code or not station_id_text:
        raise ValueError("Name, operator code and station ID are required")
    if password != confirm:
        raise ValueError("Passwords do not match")
    if len(password) < 8:
        raise ValueError("Password must be at least 8 characters")

    station_id = int(station_id_text)
    station_result = client.table("fuel_stations").select("id,station_name,status").eq("id", station_id).limit(1).execute()
    station_row = station_result.data[0] if station_result and station_result.data else None
    if not station_row:
        raise ValueError("Station not found")
    if station_row.get("status") != "active":
        raise ValueError("Station is not active")

    exists_result = client.table("station_operators").select("id").eq("operator_code", operator_code).limit(1).execute()
    if exists_result and exists_result.data:
        raise ValueError("Operator code already exists")

    user = client.table("users").insert({
        "name": name,
        "password_hash": generate_password_hash(password),
        "role": "station_operator",
        "phone": phone,
        "national_id": national_id,
        "is_admin": False,
    }).execute()

    if not user.data:
        raise RuntimeError("Could not create public.users row")

    user_row = user.data[0]

    try:
        op = client.table("station_operators").insert({
            "user_id": user_row["id"],
            "station_id": station_id,
            "operator_code": operator_code,
            "status": "active",
        }).execute()
        if not op.data:
            raise RuntimeError("Could not create station_operators row")
    except Exception:
        client.table("users").delete().eq("id", user_row["id"]).execute()
        raise

    print("\n✅ Dedicated operator created successfully")
    print(f"User ID: {user_row['id']}")
    print(f"Operator Code: {operator_code}")
    print(f"Station ID: {station_id}")
    print(f"Station: {station.data['station_name']}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"❌ {exc}")
        sys.exit(1)
