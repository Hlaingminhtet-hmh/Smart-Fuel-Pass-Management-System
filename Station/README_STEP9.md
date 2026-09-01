# Step 9 — Fuel Pricing + Receipt

Flow:
QR -> Vehicle/Fuel Type -> Current Price -> Fuel Entry -> Confirmation -> Transaction -> Receipt

The app now:
- Loads the current configured price before confirmation.
- Shows price/liter and estimated amount.
- Receives the authoritative price and amount from the backend on commit.
- Shows price, fuel type, amount, quota and transaction ID on success.
- Provides a receipt-style screen.

The backend remains authoritative for pricing and charging.
