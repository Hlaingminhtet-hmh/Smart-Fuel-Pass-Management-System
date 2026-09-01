# Step 7.1 — Real dedicated operator login

Flow:

Flutter OP-001/password
 -> Flask `/api/v1/station/login`
 -> Pyro5 `fuelpass.station_operator`
 -> `public.station_operators`
 -> `public.users` password hash
 -> `public.fuel_stations`
 -> signed station token
 -> Flutter secure storage

No Station ID is entered by the operator. Fuel requests use the authenticated station token server-side.

Use the backend bootstrap command:
`python scripts\create_station_operator.py`
