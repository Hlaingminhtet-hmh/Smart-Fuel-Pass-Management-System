import json
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import Pyro5.api
import Pyro5.core
from rmi.interfaces import (
    UserRMIInterface,
    VehicleRMIInterface,
    FuelRMIInterface,
    QRServiceInterface,
)
from rmi.interfaces import StationOperatorRMIInterface, AdminRMIInterface
from models.user import User
from models.vehicle import Vehicle
from models.transaction import FuelTransaction
from rmi.station_operator_service import StationOperatorRMIService
from rmi.admin_service import AdminRMIService
from services.quota_service import QuotaService
from models.fuel_price import FuelPrice
from services.fuel_service import FuelService
import logging
from dotenv import load_dotenv
import time
from datetime import datetime, timedelta, timezone

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@Pyro5.api.expose
class UserRMIService(UserRMIInterface):
    """RMI Wrapper for User model"""

    def __init__(self):
        self.user_model = User()
        logger.info("✅ UserRMIService initialized")

    def register_user(self, national_id, name, phone, password):
        try:
            logger.info(f"📝 RMI register_user called: {national_id}")
            result = self.user_model.create_user(national_id, name, phone, password)
            return result
        except Exception as e:
            logger.error(f"❌ RMI error: {str(e)}")
            return {"error": str(e)}

    def authenticate_user(self, national_id, password):
        try:
            logger.info(f"🔐 RMI authenticate_user called: {national_id}")
            return self.user_model.authenticate(national_id, password)
        except Exception as e:
            logger.error(f"❌ RMI error: {str(e)}")
            return None

    def get_user_by_id(self, user_id):
        try:
            return self.user_model.get_user_by_id(user_id)
        except Exception as e:
            logger.error(f"❌ RMI error: {str(e)}")
            return None


@Pyro5.api.expose
class StationOperatorRMIServiceExposed(
    StationOperatorRMIService,
    StationOperatorRMIInterface,
):
    """Pyro5-exposed wrapper for station operator authentication.

    Pyro5 does not reliably expose inherited methods from a parent class
    through this wrapper, so the public methods are explicitly overridden
    and decorated here.
    """

    @Pyro5.api.expose
    def authenticate_operator(self, operator_code, password):
        return super().authenticate_operator(operator_code, password)

    @Pyro5.api.expose
    def get_operator(self, operator_id):
        return super().get_operator(operator_id)


@Pyro5.api.expose
class VehicleRMIService(VehicleRMIInterface):
    """RMI Wrapper for Vehicle model"""

    def __init__(self):
        self.vehicle_model = Vehicle()
        self.qr_service = QRService()
        logger.info("✅ VehicleRMIService initialized")

    def register_vehicle(
        self, user_id, plate_number, vehicle_type, engine_capacity=None
    ):
        try:
            logger.info(f"🚗 RMI register_vehicle called: {plate_number}")

            # Clean engine capacity
            if engine_capacity:
                import re

                numbers = re.findall(r"\d+", str(engine_capacity))
                engine_capacity = float(numbers[0]) if numbers else None

            result = self.vehicle_model.register_vehicle(
                user_id, plate_number, vehicle_type, engine_capacity
            )

            if result and "id" in result:
                logger.info(f"✅ Vehicle registered: {result['id']}")
            else:
                logger.error(f"❌ Vehicle registration failed: {result}")

            return result
        except Exception as e:
            logger.error(f"❌ RMI error in register_vehicle: {str(e)}")
            import traceback

            traceback.print_exc()
            return {"error": str(e)}

    def claim_approved_vehicle(self, user_id, plate_number):
        try:
            from database.db import SupabaseDB
            from datetime import datetime, timezone

            client = SupabaseDB().get_client()
            uid = int(user_id)
            plate = str(plate_number).strip().upper()
            reg = (
                client.table("admin_vehicle_registry")
                .select("*")
                .eq("plate_number", plate)
                .limit(1)
                .execute()
            )
            if not reg.data:
                return {"error": "This vehicle is not in the official registry"}
            official = reg.data[0]
            if official.get("status") != "approved":
                return {
                    "error": f"Vehicle is not approved (status: {official.get('status')})"
                }
            existing = (
                client.table("vehicles")
                .select("id,user_id")
                .eq("plate_number", plate)
                .limit(1)
                .execute()
            )
            if existing.data:
                return {"error": "This vehicle is already registered to a user"}
            now = datetime.now(timezone.utc).isoformat()
            row = {
                "user_id": uid,
                "plate_number": official["plate_number"],
                "vehicle_type": official["vehicle_type"],
                "engine_capacity": official.get("engine_capacity"),
                "weekly_quota": float(official["weekly_quota"]),
                "weekly_quota_liters": float(official["weekly_quota"]),
                "is_active": True,
                "fuel_type": official["fuel_type"],
                "qr_code_image": None,
                "qr_code_data": None,
                "qr_generated_at": None,
                "created_at": now,
                "updated_at": now,
            }
            ins = client.table("vehicles").insert(row).execute()
            if not ins.data:
                return {"error": "Vehicle registration failed"}
            v = ins.data[0]
            qr = self.qr_service.generate_qr_code(
                str(v["id"]), v["plate_number"], str(uid), v["vehicle_type"]
            )
            if qr and qr.get("success"):
                up = (
                    client.table("vehicles")
                    .update(
                        {
                            "qr_code_image": qr["qr_image"],
                            "qr_code_data": qr["qr_data"],
                            "qr_generated_at": now,
                            "updated_at": now,
                        }
                    )
                    .eq("id", v["id"])
                    .execute()
                )
                if up.data:
                    v = up.data[0]
            return v
        except Exception as e:
            logger.exception("claim_approved_vehicle failed")
            return {"error": str(e)}

    def get_vehicle_by_id(self, vehicle_id):
        try:
            return self.vehicle_model.get_vehicle_by_id(vehicle_id)
        except Exception as e:
            logger.error(f"❌ RMI error in get_vehicle_by_id: {str(e)}")
            return None

    def get_vehicles_by_user(self, user_id):
        try:
            vehicles = self.vehicle_model.get_vehicles_by_user(user_id)
            logger.info(f"📋 Found {len(vehicles)} vehicles for user {user_id}")
            return vehicles
        except Exception as e:
            logger.error(f"❌ RMI error in get_vehicles_by_user: {str(e)}")
            return []

    def get_vehicle_by_plate(self, plate_number):
        try:
            return self.vehicle_model.get_vehicle_by_plate(plate_number)
        except Exception as e:
            logger.error(f"❌ RMI error in get_vehicle_by_plate: {str(e)}")
            return None

    def update_vehicle_quota(self, vehicle_id, new_quota):
        try:
            return self.vehicle_model.update_weekly_quota(vehicle_id, new_quota)
        except Exception as e:
            logger.error(f"❌ RMI error in update_vehicle_quota: {str(e)}")
            return {"error": str(e)}

    def update_qr_code(self, vehicle_id, qr_image, qr_data=None):
        """Update vehicle QR code"""
        try:
            logger.info(f"📸 Updating QR code for vehicle: {vehicle_id}")
            return self.vehicle_model.update_qr_code(vehicle_id, qr_image, qr_data)
        except Exception as e:
            logger.error(f"❌ RMI error in update_qr_code: {str(e)}")
            return None

    def save_qr_code(self, vehicle_id, qr_image, qr_data):
        """Save QR code to database"""
        try:
            logger.info(f"💾 Saving QR code for vehicle: {vehicle_id}")
            return self.vehicle_model.save_qr_code(vehicle_id, qr_image, qr_data)
        except Exception as e:
            logger.error(f"❌ Error saving QR code: {str(e)}")
            return None

    def get_qr_code(self, vehicle_id):
        """Get QR code from database"""
        try:
            logger.info(f"📤 Getting QR code for vehicle: {vehicle_id}")
            return self.vehicle_model.get_qr_code(vehicle_id)
        except Exception as e:
            logger.error(f"❌ Error getting QR code: {str(e)}")
            return None


@Pyro5.api.expose
class FuelRMIService(FuelRMIInterface):
    """RMI Wrapper for Fuel services"""

    def __init__(self):
        # Create instances
        self.transaction_model = FuelTransaction()
        self.quota_service = QuotaService()
        self.fuel_service = FuelService()
        self.price_model = FuelPrice()
        logger.info("✅ FuelRMIService initialized")

    def process_fuel_request(self, vehicle_id, station_id, liters):
        try:
            logger.info(
                f"⛽ Processing fuel request: vehicle={vehicle_id}, station={station_id}, liters={liters}"
            )

            # Check quota first
            quota = self.quota_service.check_available_quota(vehicle_id)

            if not quota:
                return {"success": False, "message": "Quota information not available"}

            if not quota.get("can_fuel"):
                return {
                    "success": False,
                    "message": "ခွဲတမ်းပြည့်နေပါသည်",
                    "quota": quota,
                }

            if liters > quota["remaining"]:
                return {
                    "success": False,
                    "message": f'တောင်းဆိုထားသော ပမာဏ ({liters}L) သည် ကျန်ရှိခွဲတမ်း ({quota["remaining"]}L) ထက် များနေပါသည်',
                    "max_allowed": quota["remaining"],
                }

            # Process fuel request
            # FuelService owns the transaction write. Do not insert a second
            # record here; doing so used to create duplicate transactions.
            result = self.fuel_service.process_fuel_request(
                vehicle_id, station_id, liters
            )
            return result

        except Exception as e:
            logger.error(f"❌ RMI error in process_fuel_request: {str(e)}")
            import traceback

            traceback.print_exc()
            return {"success": False, "message": str(e)}

    def check_available_quota(self, vehicle_id):
        """Check available quota for vehicle"""
        try:
            return self.quota_service.check_available_quota(vehicle_id)
        except Exception as e:
            logger.error(f"❌ RMI error in check_available_quota: {str(e)}")
            return {"error": str(e)}

    def get_vehicle_transactions(self, vehicle_id, limit=10):
        """Get transactions for a vehicle"""
        try:
            return self.transaction_model.get_vehicle_transactions(vehicle_id, limit)
        except Exception as e:
            logger.error(f"❌ RMI error in get_vehicle_transactions: {str(e)}")
            return []

    def get_station_transactions(self, station_id, date=None):
        """Get transactions for a station (original method)"""
        try:
            return self.transaction_model.get_station_transactions(station_id, date)
        except Exception as e:
            logger.error(f"❌ RMI error in get_station_transactions: {str(e)}")
            return []

    # NEW METHOD for station client with date range
    def get_station_transactions_range(self, station_id, days=7):
        """Get station transactions for the last N days (for station client)"""
        try:
            logger.info(
                f"📊 Getting station transactions for {station_id}, last {days} days"
            )

            from database.db import SupabaseDB

            db = SupabaseDB()
            client = db.get_client()

            cutoff = datetime.now(timezone.utc) - timedelta(days=days)

            result = (
                client.table("fuel_transactions")
                .select(
                    "id,vehicle_id,station_id,liters_pumped,amount_paid,pumped_at,sync_status,fuel_type,unit_price"
                )
                .eq("station_id", station_id)
                .gte("pumped_at", cutoff.isoformat())
                .order("pumped_at", desc=True)
                .execute()
            )

            transactions = result.data if result.data else []
            vehicle_ids = sorted(
                {
                    int(row["vehicle_id"])
                    for row in transactions
                    if row.get("vehicle_id") is not None
                }
            )
            if vehicle_ids:
                vehicle_result = (
                    client.table("vehicles")
                    .select("id,plate_number,vehicle_type,fuel_type")
                    .in_("id", vehicle_ids)
                    .execute()
                )
                vehicle_map = {
                    int(row["id"]): row for row in (vehicle_result.data or [])
                }
                for row in transactions:
                    vehicle_id = row.get("vehicle_id")
                    row["vehicle"] = (
                        vehicle_map.get(int(vehicle_id), {})
                        if vehicle_id is not None
                        else {}
                    )
            logger.info(f"✅ Found {len(transactions)} transactions")
            return transactions

        except Exception as e:
            logger.error(f"❌ Error getting station transactions range: {e}")
            return []

    # NEW METHOD for station client to get summary
    def get_station_summary(self, station_id, days=7):
        """Get summary statistics for station"""
        try:
            transactions = self.get_station_transactions_range(station_id, days)

            if not transactions:
                return {
                    "total_transactions": 0,
                    "total_liters": 0,
                    "unique_vehicles": 0,
                    "avg_liters": 0,
                }

            total_liters = sum(
                float(t.get("liters_pumped", 0) or 0) for t in transactions
            )
            unique_vehicles = len(set([t["vehicle_id"] for t in transactions]))

            return {
                "total_transactions": len(transactions),
                "total_liters": round(total_liters, 2),
                "unique_vehicles": unique_vehicles,
                "avg_liters": (
                    round(total_liters / len(transactions), 2) if transactions else 0
                ),
            }

        except Exception as e:
            logger.error(f"❌ Error getting station summary: {e}")
            return {
                "total_transactions": 0,
                "total_liters": 0,
                "unique_vehicles": 0,
                "avg_liters": 0,
            }

    def get_fuel_prices(self):
        """Return current active prices for all fuel types."""
        try:
            return self.price_model.list_current()
        except Exception as e:
            logger.error(f"❌ Error getting fuel prices: {e}")
            return []

    # NEW METHOD for station client to get fuel price
    def get_current_fuel_price(self, fuel_type="petrol_92"):
        """Get current price for a specific fuel type."""
        try:
            row = self.price_model.get_current(fuel_type)
            if row:
                return {
                    "fuel_type": row.get("fuel_type", fuel_type),
                    "price_per_liter": float(row.get("price_per_liter", 0) or 0),
                    "currency": row.get("currency", "MMK"),
                    "effective_from": row.get("effective_from"),
                    "effective_to": row.get("effective_to"),
                    "status": row.get("status", "active"),
                }
            return {"error": "Fuel price not configured", "fuel_type": fuel_type}
        except Exception as e:
            logger.error(f"❌ Error getting fuel price for {fuel_type}: {e}")
            return {"error": str(e), "fuel_type": fuel_type}


@Pyro5.api.expose
class QRService(QRServiceInterface):
    """QR code service implementation"""

    def __init__(self):
        try:
            import qrcode
            import io
            import base64
            from PIL import Image
            import json
            from datetime import datetime

            self.qrcode = qrcode
            self.io = io
            self.base64 = base64
            self.Image = Image
            self.json = json
            self.datetime = datetime
            print("✅ QRService initialized")
        except ImportError as e:
            print(f"❌ QRService import error: {e}")
            raise e

    def generate_qr_code(
        self, vehicle_id, plate_number, user_id=None, vehicle_type=None
    ):
        """Generate QR code with vehicle information"""
        try:
            print(f"📸 Generating QR code for vehicle: {plate_number}")

            # Create QR code data
            qr_data = {
                "vehicle_id": str(vehicle_id),
                "plate": str(plate_number),
                "user_id": str(user_id) if user_id else None,
                "vehicle_type": str(vehicle_type) if vehicle_type else None,
                "type": "fuel_pass",
                "version": "2.0",
                "timestamp": self.datetime.now().isoformat(),
                "valid": True,
            }

            # Convert to JSON
            qr_json = self.json.dumps(qr_data)

            # Generate QR code
            qr = self.qrcode.QRCode(
                version=1,
                error_correction=self.qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            qr.add_data(qr_json)
            qr.make(fit=True)

            # Create image
            img = qr.make_image(fill_color="black", back_color="white")

            # Convert to base64
            buffered = self.io.BytesIO()
            img.save(buffered, format="PNG")
            img_base64 = self.base64.b64encode(buffered.getvalue()).decode()

            return {
                "success": True,
                "qr_data": qr_json,
                "qr_image": img_base64,
                "vehicle_id": vehicle_id,
                "plate": plate_number,
            }

        except Exception as e:
            print(f"❌ Error generating QR code: {str(e)}")
            return {"success": False, "error": str(e)}

    def scan_qr_code(self, qr_data):
        """Scan and decode QR code"""
        try:
            print(f"\n🔍 QR Service scanning...")

            # Try to parse as JSON
            try:
                data = self.json.loads(qr_data)
                print(f"   ✅ JSON parsed successfully")
                print(f"   Keys found: {list(data.keys())}")
            except self.json.JSONDecodeError as e:
                print(f"   ❌ JSON decode error: {e}")
                return {
                    "success": False,
                    "error": f"Invalid JSON: {str(e)}",
                    "code": "INVALID_JSON",
                }

            # Validate required fields
            required_fields = ["vehicle_id", "plate"]
            missing = []
            for field in required_fields:
                if field not in data:
                    missing.append(field)

            if missing:
                print(f"   ❌ Missing fields: {missing}")
                return {
                    "success": False,
                    "error": f"Missing required fields: {missing}",
                    "code": "MISSING_FIELDS",
                }

            # Check valid flag
            if data.get("valid") == False:
                print(f"   ❌ QR code is marked invalid")
                return {
                    "success": False,
                    "error": "QR code is invalid",
                    "code": "INVALID",
                }

            # Add scan timestamp
            data["scanned_at"] = self.datetime.now().isoformat()

            print(f"   ✅ Scan successful for vehicle: {data['plate']}")

            return {
                "success": True,
                "data": data,
                "vehicle_id": data["vehicle_id"],
                "plate": data["plate"],
            }

        except Exception as e:
            print(f"   ❌ Unexpected error: {str(e)}")
            import traceback

            traceback.print_exc()
            return {"success": False, "error": str(e), "code": "UNKNOWN_ERROR"}

    def verify_qr_code(self, qr_data, vehicle_id):
        """Verify QR code matches vehicle"""
        try:
            scan_result = self.scan_qr_code(qr_data)

            if not scan_result.get("success"):
                return False

            data = scan_result.get("data", {})

            # Check if vehicle_id matches
            return data.get("vehicle_id") == vehicle_id

        except Exception as e:
            logger.error(f"❌ Error verifying QR code: {str(e)}")
            return False


def start_rmi_server():
    """Start RMI server"""
    try:
        print("\n" + "=" * 60)
        print("🔥 STARTING FUEL PASS RMI SERVER...")
        print("=" * 60)

        # Create Pyro daemon on specific host and port
        daemon = Pyro5.server.Daemon(host="127.0.0.1", port=9090)
        print(f"📡 Pyro daemon started on port 9090")

        # Create service instances
        user_service = UserRMIService()
        vehicle_service = VehicleRMIService()
        fuel_service = FuelRMIService()
        qr_service = QRService()
        station_operator_service = StationOperatorRMIServiceExposed()
        admin_service = AdminRMIService()

        # Register with names
        uri_user = daemon.register(user_service, "fuelpass.user")
        uri_vehicle = daemon.register(vehicle_service, "fuelpass.vehicle")
        uri_fuel = daemon.register(fuel_service, "fuelpass.fuel")
        uri_qr = daemon.register(qr_service, "fuelpass.qr")
        uri_station_operator = daemon.register(
            station_operator_service, "fuelpass.station_operator"
        )
        uri_admin = daemon.register(admin_service, "fuelpass.admin")

        print("\n" + "=" * 60)
        print("🚀 FUEL PASS RMI SERVER IS RUNNING!")
        print("=" * 60)
        print(f"📍 User Service:    {uri_user}")
        print(f"📍 Vehicle Service: {uri_vehicle}")
        print(f"📍 Fuel Service:    {uri_fuel}")
        print(f"📍 QR Service:      {uri_qr}")
        print(f"📍 Station Operator: {uri_station_operator}")
        print(f"📍 Admin Service:     {uri_admin}")
        print("=" * 60)
        print("📡 Waiting for RMI clients...")
        print("💡 Press Ctrl+C to stop the server\n")

        # Start daemon
        daemon.requestLoop()

    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
    except Exception as e:
        logger.error(f"❌ Failed to start RMI server: {str(e)}")
        print(f"❌ Error: {str(e)}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    start_rmi_server()
