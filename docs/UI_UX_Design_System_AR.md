# نظام التصميم UI/UX

## الهدف
توحيد شكل وسلوك تطبيق العميل، تطبيق السائق، والـ Dashboard مع الحفاظ على سرعة التنفيذ وجودة الواجهة.

## المبادئ
- واجهة حديثة ونظيفة.
- إجراء رئيسي واضح في كل شاشة.
- أقل عدد ممكن من العناصر.
- Map-centric في الشاشات التشغيلية.
- High contrast.
- Arabic-first وRTL.
- لا تستخدم أكثر من خط أساسي واحد.

## الألوان
```text
Primary:        #2563EB
Primary Dark:   #1D4ED8
Background:     #F8FAFC
Surface:        #FFFFFF
Text Primary:   #0F172A
Text Secondary: #64748B
Border:         #E2E8F0
Success:        #16A34A
Warning:        #F59E0B
Error:          #DC2626
Info:           #0EA5E9
```

## حالات الطلب
```text
BIDDING         → Info
DRIVER_ASSIGNED → Primary
DRIVER_ON_WAY   → Primary
DRIVER_ARRIVED  → Warning
IN_PROGRESS     → Success
COMPLETED       → Success
CANCELLED       → Error
EXPIRED         → Neutral
```

## الخطوط
ترشيح: Cairo أو Tajawal أو Noto Sans Arabic.

```text
Display Large  32 Bold
Title Large    24 Bold
Title Medium   20 SemiBold
Title Small    18 SemiBold
Body Large     16 Regular
Body Medium    14 Regular
Body Small     12 Regular
Label Large    14 SemiBold
```

## Spacing
استخدم 4pt system:
```text
4, 8, 12, 16, 20, 24, 32, 40, 48, 64
```

## Radius
```text
Small 8
Medium 12
Large 16
XLarge 24
Pill 999
```

## Buttons
- ارتفاع 52–56.
- Primary CTA Full Width عند الحاجة.
- حالات: normal / pressed / loading / disabled.
- Danger فقط للإلغاء والحذف والإيقاف.

## Inputs
- Label.
- Placeholder.
- Error.
- Focus.
- Disabled.
- Price field يعرض EGP / ج.م.

## Cards
استخدمها في:
- Service Selection.
- Driver Offer.
- Order Summary.
- Driver Summary.
- Earnings.

## Bottom Sheets
عنصر أساسي لاختيار الخدمة، السعر، العروض، الإلغاء، والتأكيد.

## Maps
الخريطة نظيفة. العناصر العائمة فقط:
- Current Location.
- Location Search.
- Active Order Card.
- Bottom Sheet.

## Motion
```text
Fast 150ms
Normal 250ms
Slow 350ms
```
استخدم الحركة للانتقال والحالة، وليس للزينة.

## Accessibility
- Tap target >= 44px.
- نص أساسي >= 14px.
- Contrast واضح.
- لا تعتمد على اللون فقط.

## قاعدة الاتساق
إذا تكرر عنصر مرتين أو أكثر، حوّله إلى Reusable Component أو Variant.
