# Step 7 — Dedicated Station Operator Login

Station ID is intentionally removed from the operator login form.

Login:
  operator_code + password
  -> Flask `/api/v1/station/login`
  -> station_operators
  -> fuel_stations

The response contains station identity. The client stores the bearer token
using `flutter_secure_storage` and uses it for authenticated API calls.

The station ID used by transactions must come from the authenticated backend
session, not from user input.
