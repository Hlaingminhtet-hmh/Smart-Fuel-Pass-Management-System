# Smart Fuel Pass — Flutter Station Client

This is the Flutter Station Operator client for the existing Smart Fuel Pass backend.

Architecture:

Flutter Station App
  -> HTTP/JSON
Flask Station API
  -> Pyro5 RMI
RMI Services
  -> Supabase

The Flutter app must not connect directly to Supabase.

## First run

1. Install Flutter.
2. Run `flutter pub get`.
3. Run `flutter analyze`.
4. Run `flutter test`.
5. For Android emulator, the API base URL defaults to `http://10.0.2.2:5000`.
6. For a physical device, change `ApiClient.baseUrl` to the development PC's LAN IP.

## Current implementation

- App theme foundation
- API client foundation
- Station login UI shell
- Station dashboard UI shell
- QR scanner
- Vehicle verification UI shell

Backend authentication and QR verification are intentionally connected only after the exact existing Flask API contract is verified.
