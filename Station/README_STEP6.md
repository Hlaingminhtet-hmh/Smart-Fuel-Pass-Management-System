# Smart Fuel Pass — Flutter Station Client — Step 6

Step 6 adds the real fuel transaction workflow while preserving the existing architecture:

Flutter Station App
  -> HTTP
Flask Station API
  -> Pyro5 RMI
RMI Fuel Service
  -> Supabase PostgreSQL

## New flow

Scan QR -> Vehicle Verification -> Fuel Entry -> Confirmation -> Real Transaction -> Success

## Important

The Station ID entered on the login screen is the numeric `station_id` used by the backend. Use an actual station ID from your database.

The app still uses the development LAN API endpoint:
`http://10.11.70.123:9091`

## Backend endpoint

`POST /api/v1/station/fuel`

Request:
```json
{
  "vehicle_id": 2,
  "station_id": 1,
  "liters": 10
}
```

The backend is responsible for quota validation and transaction creation. Flutter does not directly access Supabase.

## Validation

Before running the app:
1. Start Pyro5 RMI server on port 9090.
2. Start Flask on port 9091.
3. Confirm `/api/v1/station/health` works from the phone.
4. Run `flutter pub get`.
5. Run `flutter analyze`.
6. Run `flutter test`.
7. Run `flutter run` on the physical phone.
