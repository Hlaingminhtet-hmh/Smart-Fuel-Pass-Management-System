# Step 8 — Real Station Statistics + Transaction History

Added:
- authenticated station report API usage
- real Today dashboard KPIs
- real recent transactions
- dedicated Transaction History screen
- pull-to-refresh
- loading, error and empty states
- model parsing tests

The API uses `/api/v1/station/transactions?days=1..30`. The backend determines
the station from the authenticated operator token, so the client cannot ask
for another station's data.
