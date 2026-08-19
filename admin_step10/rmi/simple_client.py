import Pyro5.api
import sys

print("=" * 60)
print("SIMPLE RMI CLIENT TEST")
print("=" * 60)

try:
    # Try with 127.0.0.1 instead of localhost
    print("\n1. Trying with 127.0.0.1...")
    uri = "PYRO:fuelpass.user@127.0.0.1:9090"
    print(f"   URI: {uri}")

    proxy = Pyro5.api.Proxy(uri)
    # Simple test
    result = proxy.get_user_by_id("test")
    print("   ✅ Connection successful!")

except Exception as e:
    print(f"   ❌ Failed: {type(e).__name__}: {e}")

    try:
        print("\n2. Trying with localhost...")
        uri = "PYRO:fuelpass.user@localhost:9090"
        print(f"   URI: {uri}")

        proxy = Pyro5.api.Proxy(uri)
        result = proxy.get_user_by_id("test")
        print("   ✅ Connection successful!")

    except Exception as e:
        print(f"   ❌ Failed: {type(e).__name__}: {e}")

        try:
            print("\n3. Trying with computer name...")
            import socket

            hostname = socket.gethostname()
            uri = f"PYRO:fuelpass.user@{hostname}:9090"
            print(f"   URI: {uri}")

            proxy = Pyro5.api.Proxy(uri)
            result = proxy.get_user_by_id("test")
            print("   ✅ Connection successful!")

        except Exception as e:
            print(f"   ❌ Failed: {type(e).__name__}: {e}")

            print("\n4. Trying with broadcast...")
            print("   This might take a few seconds...")
            try:
                # Try to find any Pyro object
                with Pyro5.api.locate_ns() as ns:
                    print("   Found name server!")
                    print(f"   Registered objects: {ns.list()}")
            except:
                print("   No name server found")

print("\n" + "=" * 60)
print("DEBUGGING INFO:")
print("-" * 40)
print(f"Server port 9090 is LISTENING: Yes (from netstat)")
print(f"Firewall: May be blocking (but port is listening)")
print(f"Try turning off Windows Firewall temporarily to test")
print("=" * 60)