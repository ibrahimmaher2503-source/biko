# Cloud Functions API Contracts: Admin Dashboard

**Branch**: `013-admin-dashboard` | **Date**: 2026-03-02

The admin dashboard calls existing Cloud Functions via HTTP. These contracts document the expected request/response format for admin operations.

## Existing Functions (Called by Admin Dashboard)

### POST `approveDriver`

**Caller**: Admin Dashboard (Document Review screen)
**Auth**: Requires `role: admin` or `role: super_admin` custom claim in ID token

**Request**:
```json
{
  "driver_uid": "string"
}
```

**Response (200)**:
```json
{
  "success": true,
  "message": "Driver approved successfully"
}
```

**Side effects**:
- Sets `is_approved: true` on `driver_profiles/{driver_uid}`
- Sets `status: 'approved'` on all `documents` where `driver_uid` matches and `status == 'pending'`
- Sends FCM notification to driver: "Your documents have been approved"

---

### POST `suspendUser`

**Caller**: Admin Dashboard (Customer/Driver detail screen)
**Auth**: Requires `role: admin` or `role: super_admin` custom claim

**Request**:
```json
{
  "uid": "string",
  "reason": "string"
}
```

**Response (200)**:
```json
{
  "success": true,
  "message": "User suspended"
}
```

**Side effects**:
- Disables Firebase Auth account (`auth.updateUser(uid, { disabled: true })`)
- Sets `status: 'suspended'` on `users/{uid}`

---

### POST `adjustWalletBalance`

**Caller**: Admin Dashboard (Customer/Driver detail screen)
**Auth**: Requires `role: admin` or `role: super_admin` custom claim

**Request**:
```json
{
  "uid": "string",
  "amount": "number (positive for credit, negative for debit)",
  "reason": "string"
}
```

**Response (200)**:
```json
{
  "success": true,
  "new_balance": "number",
  "transaction_id": "string"
}
```

**Side effects**:
- Updates `wallets/{uid}.balance` (atomic increment)
- Creates `transactions/{txn_id}` record with type credit/debit

---

### POST `updateAppConfig`

**Caller**: Admin Dashboard (Config screen)
**Auth**: Requires `role: super_admin` custom claim

**Request**:
```json
{
  "base_fare": "number",
  "price_per_km": "number",
  "price_per_min": "number",
  "surge_multiplier": "number",
  "commission_ride": "number (0-1)",
  "commission_c2c": "number (0-1)",
  "commission_b2b": "number (0-1)",
  "min_bid_radius_km": "number",
  "bid_timeout_seconds": "number",
  "referrer_reward": "number",
  "referee_reward": "number",
  "maintenance_mode": "boolean"
}
```

**Response (200)**:
```json
{
  "success": true,
  "message": "Config updated"
}
```

**Side effects**:
- Writes to `app_config/config` document
- All connected apps receive update via Firestore snapshot listener

---

### POST `sendToSegment`

**Caller**: Admin Dashboard (Notifications screen)
**Auth**: Requires `role: admin` or `role: super_admin` custom claim

**Request**:
```json
{
  "segment": "string (all | customers | drivers)",
  "title_ar": "string",
  "title_en": "string",
  "body_ar": "string",
  "body_en": "string"
}
```

**Response (200)**:
```json
{
  "success": true,
  "sent_count": "number"
}
```

---

### `sendToUser` (Internal helper, called via Cloud Function wrapper)

**Request**:
```json
{
  "uid": "string",
  "title_ar": "string",
  "title_en": "string",
  "body_ar": "string",
  "body_en": "string"
}
```

**Response (200)**:
```json
{
  "success": true
}
```

---

## New Firestore Security Rules (Admin Dashboard)

```
// admin_notifications collection
match /admin_notifications/{notifId} {
  allow read, write: if request.auth != null
    && request.auth.token.role in ['admin', 'super_admin'];
}
```

These rules must be appended to the existing `firestore.rules` file.
