# مواصفات UI لتطبيق السائق

## الهدف
واجهة تشغيلية سريعة، قليلة النصوص، بأزرار كبيرة وآمنة أثناء الحركة.

## Navigation
```text
الرئيسية | الرحلات | الأرباح | الحساب
```

## Home
- Map.
- Online / Offline Toggle هو العنصر الأهم.
- Trips Today.
- Earnings Today.

## Offline
```text
أنت غير متصل
فعّل الاتصال لاستقبال الطلبات
```
CTA: ابدأ العمل.

## Incoming Request
اعرض:
- Ride / Delivery.
- Pickup.
- Destination.
- Distance to Pickup.
- Trip Distance.
- Customer Price.

Actions:
```text
قبول السعر
تقديم سعر آخر
رفض
```

## Counter Offer
Bottom Sheet:
```text
سعر العميل: 80
عرضك: 95
```
CTA: إرسال العرض.

## Waiting
```text
تم إرسال عرضك
في انتظار اختيار العميل
```

## Selected
```text
تم اختيارك للرحلة
```
CTA: ابدأ التوجه.

## Assigned
- Customer.
- Pickup.
- Destination.
- Agreed Price.
- Navigation.
CTA: في الطريق.

## On Way
CTA: وصلت.

## Arrived
CTA: بدء الرحلة.

## Active Ride / Delivery
اعرض المعلومات المهمة فقط.
CTA: إنهاء الرحلة / تم التسليم.

## Verification
Pending:
```text
طلبك قيد المراجعة
```
Rejected:
```text
هناك مشكلة في بعض المستندات
```
Suspended:
```text
الحساب موقوف مؤقتًا
```

## Safety UX
- أزرار كبيرة.
- أقل كتابة ممكنة أثناء الحركة.
- CTA رئيسي واحد واضح.
- Status ظاهر دائمًا.

## Reusable UI
```text
OnlineToggle
IncomingRequestCard
OfferPriceSheet
ActiveTripCard
TripStatusHeader
NavigationCTA
EarningsCard
DocumentStatusCard
```
