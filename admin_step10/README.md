# Smart Fuel Pass Backend — Step 10.2 CLEAN SERVER + ADMIN

This clean backend keeps:

- Flask/RMI server runtime
- Station API and station operator authentication
- Admin Web and Admin RMI service
- User/vehicle RMI services required by the Android Vehicle Owner app
- User API endpoints required by the Android Vehicle Owner app
- Supabase models/services
- QR generation
- Database migrations

Removed from this server package:

- Legacy browser-based Vehicle Owner UI
- Old `app.py` user web application
- Legacy user web templates
- Legacy `routes/vehicle_routes.py`
- Legacy standalone station RMI client
- Temporary step/test files and unused audio assets

Important: User backend API/service code remains intentionally. The Android
Vehicle Owner app still calls the backend for registration, login, approved
vehicle claim, QR and history.
