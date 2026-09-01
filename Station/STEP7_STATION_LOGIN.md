# Step 7 — Real Station Operator Login

The station client no longer asks the operator to type a Station ID.

Login:
`Operator ID + Password`

Backend:
`Flutter -> Flask /api/v1/station/login -> Pyro5 Station Operator Service -> users + station_operators + fuel_stations`

The server returns a signed 8-hour bearer token. The Flutter app stores the
token using `flutter_secure_storage` and sends it as:
`Authorization: Bearer <token>`

Fuel transactions no longer send `station_id`. Flask derives the station from
the authenticated operator token.

For development, create the database table with:
`migrations/001_station_operators.sql`

Then map an existing test user to the test station using:
`migrations/001_station_operators_seed_example.sql`

Do not ship the service-role key in Flutter.
