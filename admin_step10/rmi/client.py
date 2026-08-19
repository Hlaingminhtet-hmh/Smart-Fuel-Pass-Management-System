import Pyro5.api
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import time


class RMIClient:
    """RMI Client for testing"""

    def __init__(self):
        self.user_service = None
        self.vehicle_service = None
        self.fuel_service = None

    def connect(self):
        """Connect to RMI server"""
        print("\n🔌 Connecting to RMI server...")

        try:
            # Use 127.0.0.1 instead of localhost
            self.user_service = Pyro5.api.Proxy("PYRO:fuelpass.user@127.0.0.1:9090")
            self.vehicle_service = Pyro5.api.Proxy("PYRO:fuelpass.vehicle@127.0.0.1:9090")
            self.fuel_service = Pyro5.api.Proxy("PYRO:fuelpass.fuel@127.0.0.1:9090")

            # Test connection
            test = self.user_service.get_user_by_id("test")
            print("✅ Connected to RMI server successfully!")
            return True

        except Exception as e:
            print(f"❌ Failed to connect: {str(e)}")
            return False

    def test_user_service(self):
        """Test user service"""
        print("\n" + "=" * 50)
        print("📝 TESTING USER SERVICE")
        print("=" * 50)

        try:
            # Test register
            print("\n1️⃣ Testing register_user...")
            import random
            test_id = str(random.randint(100000, 999999))  # Random ID တစ်ခုထုတ်
            result = self.user_service.register_user(
                test_id,  # Random ID သုံးမယ်
                "RMI Test User",
                "0999999999",
                "password123"
            )
            print(f"   📤 Result: {result}")

            if result and 'id' in result:
                # Test authenticate
                print("\n2️⃣ Testing authenticate_user...")
                auth = self.user_service.authenticate_user("999999", "password123")
                print(f"   🔐 Auth: {auth}")

                return result['id']
            else:
                print(f"   ❌ Register failed: {result}")

        except Exception as e:
            print(f"   ❌ Error: {str(e)}")

        return None

    def test_vehicle_service(self, user_id):
        """Test vehicle service"""
        print("\n" + "=" * 50)
        print("🚗 TESTING VEHICLE SERVICE")
        print("=" * 50)

        try:
            # Test register vehicle
            print("\n1️⃣ Testing register_vehicle...")
            result = self.vehicle_service.register_vehicle(
                user_id,
                "RMI-9999",
                "car",
                "1500"
            )
            print(f"   📤 Result: {result}")

            if result and 'id' in result:
                # Test get vehicles by user
                print("\n2️⃣ Testing get_vehicles_by_user...")
                vehicles = self.vehicle_service.get_vehicles_by_user(user_id)
                print(f"   📋 Found {len(vehicles)} vehicles")

                return result['id']
            else:
                print(f"   ❌ Register failed: {result}")

        except Exception as e:
            print(f"   ❌ Error: {str(e)}")

        return None

    def test_fuel_service(self, vehicle_id):
        """Test fuel service"""
        print("\n" + "=" * 50)
        print("⛽ TESTING FUEL SERVICE")
        print("=" * 50)

        try:
            # Test check quota
            print("\n1️⃣ Testing check_available_quota...")
            quota = self.fuel_service.check_available_quota(vehicle_id)
            print(f"   📊 Quota: {quota}")

            # Test process fuel request
            print("\n2️⃣ Testing process_fuel_request...")
            result = self.fuel_service.process_fuel_request(
                vehicle_id,
                "STATION001",
                20
            )
            print(f"   🛢️ Result: {result}")

        except Exception as e:
            print(f"   ❌ Error: {str(e)}")

    def run_all_tests(self):
        """Run all tests"""
        print("\n" + "=" * 60)
        print("🔧 FUEL PASS RMI CLIENT TEST")
        print("=" * 60)

        # Connect to server
        if not self.connect():
            return

        # Run tests
        print("\n🚀 Starting tests...")
        user_id = self.test_user_service()

        if user_id:
            vehicle_id = self.test_vehicle_service(user_id)
            if vehicle_id:
                self.test_fuel_service(vehicle_id)

        print("\n" + "=" * 60)
        print("✅ All tests completed!")
        print("=" * 60)


if __name__ == "__main__":
    client = RMIClient()
    client.run_all_tests()