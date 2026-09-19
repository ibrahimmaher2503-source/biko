# مواصفات UI لتطبيق العميل

## الهدف
أقصر رحلة ممكنة:
```text
فتح التطبيق → تحديد Pickup → Destination → السعر → إرسال الطلب
```

## Navigation
```text
الرئيسية | الطلبات | الحساب
```
إذا يوجد Active Order يظهر Banner دائم.

## Home
- Map full screen.
- سؤال: "أين تريد أن تذهب؟"
- Service Cards:
  - Ride — توصيل شخص.
  - Delivery — إرسال حاجة.

## Pickup / Destination
حقول:
```text
من
إلى
```
مع Search + Map Pin.

## Route Preview
اعرض:
- Distance.
- ETA.
- Service Type.

## السعر
عنوان:
```text
كم تريد أن تدفع؟
```
Price Input كبير.
Suggested Price يظهر فقط إذا كان مفعلًا.

## Order Review
- Pickup.
- Destination.
- Service.
- Proposed Price.
- Notes.
CTA: تأكيد الطلب.

## Bidding Screen
- حالة البحث.
- عرض العميل.
- عدد العروض.
- Driver Offer Cards Realtime.

## Driver Offer Card
- Photo.
- Name.
- Rating.
- Trips.
- Distance.
- ETA.
- Motorcycle.
- Driver Offer.
CTA: اختيار.

## Assigned Driver
- Map.
- Driver.
- Motorcycle.
- Rating.
- ETA.
- Agreed Price.
- Current Status.

## الحالات
```text
السائق في الطريق
السائق وصل
الرحلة بدأت
تمت الرحلة
```

## Completion
- Driver.
- Route summary.
- Agreed Price.
- Cash.
ثم Rating.

## History
Tabs:
```text
الكل | Ride | Delivery
```

## Reusable UI
```text
ServiceCard
LocationInput
PriceInput
DriverOfferCard
DriverSummaryCard
OrderStatusCard
OrderHistoryCard
RatingSheet
ActiveOrderBanner
```

## قاعدة UX
لا تجعل العميل يمر بأكثر من 3–4 خطوات قبل إنشاء الطلب.
