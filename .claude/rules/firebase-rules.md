# Firebase & Data Rules

## Firestore (Source of Truth)
- Firestore holds all permanent data: users, trips, wallets, transactions, app_config.
- Use batch writes for multi-document atomic operations.
- Deploy indexes after adding new composite queries: `firebase deploy --only firestore:indexes`

## Realtime Database (Temporary Only)
- RTDB is strictly for sub-second temporary data: driver locations, active trips, live bids, chats.
- Cloud Functions clean up RTDB data after trip completion.
- Never store permanent records in RTDB.

## Forbidden Client Writes
- Flutter must NEVER write to `wallets/` or `transactions/` collections.
- Only Cloud Functions handle wallet and transaction writes.

## Configuration
- Never hardcode prices, commissions, bid timeouts, or business config values.
- Always read business config from the `app_config` Firestore document.

## Authentication
- Firebase Auth with Phone OTP, Google Sign-In, Facebook Sign-In.
- Admin routes must verify `role: admin` custom claims via Cloud Functions.
- Paymob webhooks must verify HMAC signatures before modifying balances.

## No REST API
- No Laravel, PHP, or traditional REST API backend.
- All server logic runs on Firebase Cloud Functions.
