# Edge Functions

- `places`: authenticated, field-limited Google Places autocomplete/details boundary.
- `route-quote`: authenticated Google Routes call followed by a service-role-only trusted quote RPC.

Both require the hosted secret `GOOGLE_MAPS_SERVER_API_KEY`. Never expose this key to Flutter.
