# تعليمات تطوير تطبيقات Flutter
## Motorcycle Mobility & Delivery Platform

**الهدف:** إنهاء تطبيق العميل وتطبيق السائق بأسرع وقت ممكن، مع الحفاظ على كود منظم وقابل للتوسع بدون تعقيد زائد.

---

# 1. الـ Flutter Stack المعتمد

استخدم فقط المكتبات التالية في البداية:

```text
supabase_flutter
flutter_riverpod
go_router
google_maps_flutter
geolocator
firebase_core
firebase_messaging
flutter_local_notifications
image_picker
file_picker
shared_preferences
intl
```

## وظيفة كل مكتبة

| الوظيفة | المكتبة |
|---|---|
| Backend / Auth / Database / Realtime / Storage / RPC | `supabase_flutter` |
| State Management | `flutter_riverpod` |
| Navigation | `go_router` |
| Maps | `google_maps_flutter` |
| GPS / Location | `geolocator` |
| Firebase Setup | `firebase_core` |
| Push Notifications | `firebase_messaging` |
| Local Notifications | `flutter_local_notifications` |
| اختيار الصور والكاميرا | `image_picker` |
| رفع ملفات ومستندات السائق | `file_picker` |
| إعدادات بسيطة محليًا | `shared_preferences` |
| تواريخ وأرقام وعملات | `intl` |

---

# 2. أوامر تثبيت المكتبات

## User App

```bash
flutter pub add supabase_flutter flutter_riverpod go_router google_maps_flutter geolocator firebase_core firebase_messaging flutter_local_notifications image_picker shared_preferences intl
```

## Driver App

```bash
flutter pub add supabase_flutter flutter_riverpod go_router google_maps_flutter geolocator firebase_core firebase_messaging flutter_local_notifications image_picker file_picker shared_preferences intl
```

---

# 3. لا تستخدم حاليًا

لتقليل وقت التطوير، لا تضف هذه التقنيات في البداية:

```text
Bloc
GetX
Provider
GetIt
Dio
Retrofit
Hive
Isar
Freezed
Build Runner
Clean Architecture معقدة
Background Services من أول يوم
```

هذه الأدوات ليست سيئة، لكنها ليست ضرورية للـ MVP الحالي.

---

# 4. قاعدة مهمة: Supabase هو الـ Backend

لا تضف Backend HTTP Layer منفصل بدون حاجة.

استخدم:

```dart
Supabase.instance.client
```

للتعامل مع:

```text
Authentication
Database
Realtime
Storage
RPC / Database Functions
Edge Functions
```

لا تستخدم `Dio` أو `Retrofit` في البداية إلا إذا أضفنا Backend خارجي لاحقًا.

---

# 5. هيكل المشروع العام

يفضل تنظيم المشروع كالتالي:

```text
motorcycle_platform/
│
├── apps/
│   ├── user_app/
│   └── driver_app/
│
├── packages/
│   └── app_core/
│
└── docs/
```

---

# 6. Shared Core

لا تكرر نفس الـ Models والـ Services في التطبيقين.

ضع الكود المشترك داخل:

```text
packages/app_core/
```

مثال:

```text
app_core/
└── lib/
    ├── models/
    │   ├── order.dart
    │   ├── offer.dart
    │   ├── driver.dart
    │   ├── motorcycle.dart
    │   └── office.dart
    │
    ├── enums/
    │   ├── order_status.dart
    │   ├── offer_status.dart
    │   ├── service_type.dart
    │   └── driver_type.dart
    │
    ├── services/
    │   ├── auth_service.dart
    │   ├── order_service.dart
    │   ├── bidding_service.dart
    │   ├── realtime_service.dart
    │   └── location_service.dart
    │
    ├── errors/
    ├── constants/
    ├── utils/
    └── core.dart
```

---

# 7. هيكل كل تطبيق

استخدم Feature-First Architecture بسيطة.

```text
lib/
│
├── main.dart
├── app.dart
│
├── core/
│   ├── config/
│   ├── router/
│   ├── theme/
│   └── localization/
│
└── features/
    ├── auth/
    ├── home/
    ├── orders/
    ├── bidding/
    ├── trip/
    ├── history/
    └── profile/
```

مثال:

```text
features/
└── bidding/
    ├── bidding_screen.dart
    ├── bidding_provider.dart
    └── widgets/
        └── offer_card.dart
```

لا تنشئ طبقات كثيرة غير ضرورية مثل:

```text
data/
domain/
presentation/
repositories/
usecases/
entities/
datasources/
interfaces/
implementations/
```

في الـ MVP الحالي.

---

# 8. Riverpod Pattern

استخدم المسار التالي:

```text
UI
↓
Riverpod Provider
↓
Service
↓
Supabase
```

مثال:

```text
BiddingScreen
↓
offersProvider
↓
BiddingService
↓
Supabase Realtime
```

لا تضع استعلامات Supabase مباشرة داخل الشاشات إلا للحالات البسيطة جدًا.

---

# 9. Models

ابدأ بـ Dart Classes بسيطة.

مثال:

```dart
class Offer {
  final String id;
  final String driverId;
  final double amount;

  Offer({
    required this.id,
    required this.driverId,
    required this.amount,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'],
      driverId: json['driver_id'],
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
```

لا تستخدم Freezed وBuild Runner من أول يوم.

يمكن إضافتهما لاحقًا إذا كبر عدد الـ Models.

---

# 10. User App: ترتيب التنفيذ

ابدأ فقط بهذه المكتبات أولًا:

```text
supabase_flutter
flutter_riverpod
go_router
google_maps_flutter
geolocator
```

ثم نفذ بالترتيب:

```text
Login
↓
Home
↓
Ride / Delivery
↓
Create Order
↓
Bidding
↓
Offers List
↓
Select Driver
↓
Active Trip
↓
Complete
↓
History
```

بعد نجاح الـ Core Flow:

```text
Add Firebase Notifications
Add Local Notifications
Add Image Picker
```

---

# 11. Driver App: ترتيب التنفيذ

ابدأ بنفس الأساس:

```text
supabase_flutter
flutter_riverpod
go_router
google_maps_flutter
geolocator
```

ثم نفذ:

```text
Login
↓
Driver Home
↓
Online / Offline
↓
Incoming Request
↓
Accept Price / Counter Offer
↓
Waiting
↓
Selected
↓
On Way
↓
Arrived
↓
Start
↓
Complete
↓
History
↓
Earnings
```

بعد نجاح الـ Core Flow أضف:

```text
firebase_messaging
flutter_local_notifications
file_picker
image_picker
```

---

# 12. Realtime

استخدم Supabase Realtime في:

```text
New Driver Offers
Offer Selected
Order Status Changes
Driver Assignment
Driver Location Updates
```

المبدأ:

```text
Database = Source of Truth
Realtime = UI Sync
```

بعد Reconnect يجب إعادة تحميل الحالة الحقيقية من قاعدة البيانات.

---

# 13. Maps

لا تبدأ بالخرائط قبل نجاح الطلب والمزايدة.

بعد نجاح الـ Core Bidding Flow أضف:

```text
Current Location
Pickup
Destination
Route
Distance
ETA
Driver Live Location
```

---

# 14. Driver Location

في البداية:

```text
Driver App Foreground
+
Geolocator Position Stream
+
Supabase driver_locations
```

لا تبدأ Background Tracking المعقد من أول مرحلة.

بعد نجاح الرحلات في Foreground، أضف Android Foreground Location Service إذا احتجنا التشغيل أثناء الخلفية.

---

# 15. Notifications

استخدم:

```text
Supabase Realtime
```

عندما يكون التطبيق مفتوحًا.

واستخدم:

```text
Firebase Cloud Messaging
```

عندما يكون التطبيق:

```text
Background
Closed
```

الأحداث المهمة:

```text
New Request
New Offer
Offer Selected
Driver On Way
Driver Arrived
Trip Started
Trip Completed
Cancelled
Expired
```

---

# 16. Shared Preferences

استخدم `shared_preferences` فقط للبيانات البسيطة مثل:

```text
language
theme
onboarding_seen
last_selected_service
```

لا تستخدمها لتخزين:

```text
current_order
agreed_price
driver_assignment
financial_data
permissions
authorization
```

هذه البيانات يجب أن تأتي من Supabase.

---

# 17. Navigation

استخدم `go_router`.

المسارات الرئيسية في User App:

```text
/login
/home
/create-order
/bidding/:orderId
/order/:orderId
/history
/profile
```

Driver App:

```text
/login
/home
/request/:orderId
/offer/:orderId
/active-order/:orderId
/history
/earnings
/profile
```

احرص على دعم Redirect حسب Authentication والحالة النشطة.

---

# 18. Active Order Recovery

عند فتح التطبيق:

```text
Check Authentication
↓
Check Active Order
↓
If Active Order Exists
    Open Active Order Screen
Else
    Open Home
```

لا تعتمد على آخر شاشة محفوظة محليًا.

---

# 19. قواعد مهمة للكود

1. لا تكرر Supabase logic بين الشاشات.
2. لا تضع Business Logic داخل Widgets.
3. لا تغيّر Order Status مباشرة من Flutter إذا كانت العملية حساسة.
4. استخدم RPC / Database Functions للعمليات الحساسة.
5. لا تحفظ Supabase Service Role Key داخل التطبيق.
6. لا تعتمد على UI لمنع الوصول غير المصرح.
7. لا تكتب نفس Models مرتين في User App وDriver App.
8. لا تضف مكتبة بدون سبب واضح.
9. اجعل كل Feature صغيرة وقابلة للاختبار.
10. أنجز الـ Core Flow قبل تحسين التصميم.

---

# 20. الأولوية القصوى

الهدف الأول ليس شكل التطبيق.

الهدف الأول هو نجاح هذا السيناريو:

```text
Customer creates order
↓
Drivers receive request
↓
Drivers bid
↓
Customer sees offers
↓
Customer selects one driver
↓
Exactly one driver is assigned
↓
Driver goes On Way
↓
Driver Arrives
↓
Trip Starts
↓
Trip Completes
```

بعد نجاح السيناريو بالكامل:

```text
Maps
↓
Realtime polishing
↓
Push Notifications
↓
UI Polish
↓
Advanced Features
```

---

# 21. الـ Flutter Stack النهائي

```text
Flutter
│
├── flutter_riverpod
│   └── State Management
│
├── go_router
│   └── Navigation
│
├── supabase_flutter
│   ├── Auth
│   ├── Database
│   ├── Realtime
│   ├── Storage
│   └── RPC
│
├── google_maps_flutter
│   └── Maps
│
├── geolocator
│   └── GPS
│
├── firebase_messaging
│   └── Push Notifications
│
├── flutter_local_notifications
│   └── Foreground Notifications
│
├── image_picker
│   └── Camera / Photos
│
├── file_picker
│   └── Driver Documents
│
├── shared_preferences
│   └── Simple Local Preferences
│
└── intl
    └── Dates / Numbers / Currency
```

---

# 22. قاعدة القرار

قبل إضافة أي Package اسأل:

```text
هل هذه المكتبة مطلوبة الآن لإنهاء Core Flow؟
```

إذا كانت الإجابة:

```text
لا
```

لا تضفها الآن.

**الهدف: أقل عدد مكتبات + أقل Boilerplate + أسرع MVP قابل للتشغيل.**
