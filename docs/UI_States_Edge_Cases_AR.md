# حالات UI والحالات الطرفية

## الحالات العامة
كل شاشة Data:
```text
Initial
Loading
Success
Empty
Error
No Internet
Retrying
```

## Authentication
```text
OTP Sending
OTP Sent
Invalid OTP
Expired OTP
Too Many Attempts
Account Suspended
```

## Location
```text
Permission Not Asked
Granted
Denied
Permanently Denied
GPS Disabled
Loading
Failed
```

## Map
```text
Map Loading
Map Failed
Route Loading
Route Failed
Place Search Empty
Place Search Failed
```

## Create Order
```text
Missing Pickup
Missing Destination
Invalid Price
Service Disabled
Outside Zone
Network Failure
Duplicate Tap
```

## Bidding
```text
Waiting for Offers
One Offer
Multiple Offers
Offer Updated
Offer Withdrawn
Offer Expired
Order Expired
No Drivers
No Offers
Realtime Reconnecting
```

## Offer Selection
```text
Selecting
Selected
Offer No Longer Active
Driver Unavailable
Network Timeout
Order Already Assigned
```

## Driver Operations
```text
Offline
Going Online
Online
Cannot Go Online
Suspended
Documents Pending
Motorcycle Invalid
```

## Completion
```text
Completing
Completed
Duplicate Tap
Network Timeout
Already Completed
Invalid Status
```

## Documents
```text
Uploading
Uploaded
Pending
Approved
Rejected
Expired
Upload Failed
Invalid File
```

## Error Messages
لا تعرض:
```text
PostgrestException
SocketException
HTTP 409
```
للمستخدم.

حوّل الخطأ إلى رسالة مفهومة.

## Retry
العمليات الحساسة مثل Create Order وAccept Offer وComplete Trip يجب أن تكون Idempotent قبل أي Retry تلقائي.
