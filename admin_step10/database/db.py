from supabase import create_client, Client
import os
from dotenv import load_dotenv
import functools

load_dotenv()


class SupabaseDB:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)

            url = os.getenv("SUPABASE_URL")

            # Server-side backend should use the Supabase service-role key so
            # RLS is not blocking trusted backend writes. Never expose this
            # key to Flutter or browser clients.
            service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
            legacy_key = os.getenv("SUPABASE_KEY")
            key = service_role_key or legacy_key

            if not url or not key:
                raise ValueError(
                    "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY "
                    "(or legacy SUPABASE_KEY) must be set in .env"
                )

            # Do not print the secret/key value.
            key_source = (
                "SUPABASE_SERVICE_ROLE_KEY"
                if service_role_key
                else "SUPABASE_KEY"
            )
            print(f"Supabase client created using {key_source}")

            cls._instance.client = create_client(url, key)
            print("Supabase client created successfully!")

        return cls._instance

    def get_client(self):
        return self.client


def handle_supabase_error(func):
    """Handle Supabase exceptions consistently."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            print(f"Supabase error in {func.__name__}: {e}")
            return {"error": str(e)}

    return wrapper
