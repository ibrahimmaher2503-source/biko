# مواصفات مكونات Flutter القابلة لإعادة الاستخدام

## AppScaffold
يدعم SafeArea، Loading Overlay، Background، AppBar، Bottom CTA.

## AppButton
Variants:
```text
primary
secondary
outline
danger
ghost
```
Props:
```text
label
onPressed
icon
isLoading
isFullWidth
variant
```

## AppTextField
```text
label
hint
prefixIcon
suffixIcon
errorText
keyboardType
enabled
```

## LocationField
Variants:
```text
pickup
destination
```

## ServiceCard
Ride / Delivery مع selected state.

## PriceInput
```text
amount
currency
suggestedPrice
validation
```

## DriverOfferCard
```text
driverName
photoUrl
rating
completedTrips
distance
eta
motorcycle
offerAmount
onSelect
```

## DriverSummaryCard
بعد الإسناد.

## OrderStatusChip
يأخذ OrderStatus ويقرأ اللون والنص من Tokens.

## OrderHistoryCard
Service + Date + Route + Price + Status.

## ActiveOrderBanner
يظهر في وجود طلب نشط.

## AppBottomSheet
Base لكل Bottom Sheets.

## ConfirmSheet
للإلغاء، الإنهاء، Logout، Suspend.

## LoadingSkeleton
Variants:
```text
driverOffer
historyCard
profile
mapSheet
```

## EmptyState
```text
icon
title
description
actionLabel
onAction
```

## ErrorState
```text
title
description
retryLabel
onRetry
```

## NoInternetBanner
شريط واضح أعلى الشاشة.

## RatingStars
Interactive / ReadOnly.

## OnlineToggle
```text
offline
connecting
online
disabled
```

## IncomingRequestCard
Service + Locations + Price + Accept + Counter + Reject.

## EarningsCard
Amount + Label + Icon.

## DocumentStatusCard
```text
pending
approved
rejected
expired
```

## قاعدة
إذا احتجت اختلافًا بصريًا استخدم Variant بدل إنشاء Widget جديد.
