from datetime import datetime, timezone
from werkzeug.security import generate_password_hash

from database.db import SupabaseDB


class StationOperatorService:
    """Management + authentication service for dedicated station operators."""

    def __init__(self):
        self.client = SupabaseDB().get_client()

    def create_operator(
        self,
        *,
        name: str,
        operator_code: str,
        password: str,
        station_id: int,
        phone: str | None = None,
        national_id: str | None = None,
    ):
        """Create a dedicated operator identity and station assignment.

        The operator gets its own user row; vehicle-owner/admin users are not
        reused. The caller should be an authorized admin management flow.
        """
        if not name.strip():
            return {"error": "name is required"}

        operator_code = operator_code.strip().upper()
        if not operator_code:
            return {"error": "operator_code is required"}

        if len(password) < 8:
            return {"error": "password must be at least 8 characters"}

        station_id = int(station_id)

        station_result = (
            self.client.table("fuel_stations")
            .select("id,station_name,status")
            .eq("id", station_id)
            .limit(1)
            .execute()
        )
        station = station_result.data[0] if station_result and station_result.data else None
        if not station:
            return {"error": "station not found"}
        if station.get("status") != "active":
            return {"error": "station is not active"}

        existing_result = (
            self.client.table("station_operators")
            .select("id")
            .eq("operator_code", operator_code)
            .limit(1)
            .execute()
        )
        if existing_result and existing_result.data:
            return {"error": "operator_code already exists"}

        # User identity is operator-specific. Do not use an existing vehicle
        # owner's user row.
        payload = {
            "name": name.strip(),
            "phone": phone,
            "national_id": national_id,
            "password_hash": generate_password_hash(password),
            "role": "station_operator",
            "is_admin": False,
        }

        user_result = (
            self.client.table("users")
            .insert(payload)
            .execute()
        )
        if not user_result.data:
            return {"error": "operator user could not be created"}

        user = user_result.data[0]

        operator_result = (
            self.client.table("station_operators")
            .insert(
                {
                    "user_id": user["id"],
                    "station_id": station_id,
                    "operator_code": operator_code,
                    "status": "active",
                }
            )
            .execute()
        )

        if not operator_result.data:
            # Rollback the dedicated identity if the assignment fails.
            try:
                self.client.table("users").delete().eq("id", user["id"]).execute()
            except Exception:
                pass
            return {"error": "station operator assignment failed"}

        return {
            "success": True,
            "operator": operator_result.data[0],
            "user": {
                "id": user["id"],
                "name": user["name"],
                "role": user["role"],
                "is_admin": user["is_admin"],
            },
            "station": station,
        }

    def disable_operator(self, operator_id: int):
        result = (
            self.client.table("station_operators")
            .update(
                {
                    "status": "inactive",
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                }
            )
            .eq("id", int(operator_id))
            .execute()
        )
        return result.data[0] if result.data else {"error": "operator not found"}
