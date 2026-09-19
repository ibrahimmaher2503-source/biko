DESIGN.md

Mobile UI / UX Design Specification

Biko — Motorcycle Mobility & Delivery Platform

Version 2.0 — Approved Product Direction

1. Design Direction

The primary UI/UX direction for Biko is:

inDrive-like interaction clarity
+
Biko-specific visual identity

Use the simplicity, compactness, fast task flow, and operational clarity commonly found in modern mobility apps as the interaction benchmark.

The app must NOT copy another brand visually.

Biko must use its own:

brand name

logo

color system

typography

service icons

illustrations

maps

driver/order data

verification states

pricing model

operational actions

The target is a clean, premium, Arabic-first mobility experience that feels production-grade rather than like a generic Flutter dashboard.

2. Approved Biko Visual Identity

The approved visual direction is:

Primary Biko Red
+
White / Soft Neutral surfaces
+
Dark Charcoal text
+
Minimal semantic colors

Recommended design tokens:

Primary / Biko Red:      #E50914
Primary Dark:            #B70710
Primary Soft:            #FFF1F2

Background:              #F7F7F8
Surface:                 #FFFFFF
Surface Secondary:       #F3F4F6

Text Primary:            #111111
Text Secondary:          #6B7280
Text Muted:              #9CA3AF

Border:                  #E5E7EB

Success:                 #16A34A
Warning:                 #F59E0B
Error:                   #DC2626
Info:                    #2563EB

Important:

The primary color MUST be stored as a global design token.

Do not scatter raw color values across screens.

Red is for brand emphasis, primary actions, selected states, and important mobility cues.

Green is for success / verified / available only.

Orange or amber may be used for warning or Delivery-supporting accents, but not as a second competing brand color.

Avoid washed-out blue/gray interfaces.

Avoid excessive gradients.

3. Visual Personality

Biko should feel:

Fast
Confident
Urban
Practical
Trustworthy
Motorcycle-first
Arabic-native
Compact
Modern

Avoid:

generic Material demo appearance

oversized empty cards

huge unused whitespace

excessive decorative illustration

dashboard clutter

multiple equal-weight CTAs

heavy shadows

glassmorphism

unnecessary gradients

excessive animation

emoji as production icons

4. Core Layout Philosophy

Use a compact task-first composition.

Typical structure:

Top App Area
↓
Current Context / Primary Task
↓
Compact Service or Status Cards
↓
Main Action
↓
Operational / Recent Content
↓
Bottom Navigation

Home screens should not be large empty canvases.

Maps should appear when location or navigation is the current task, not as a permanent background for every screen.

5. Arabic-First Rule

Arabic is the primary language and RTL is the default layout direction.

Requirements:

Natural Arabic hierarchy

Correct RTL alignment

Correct back/forward icons

Correct mixed-direction handling

Numbers remain readable

Phone numbers use LTR when appropriate

Confirmation codes use LTR

Plate numbers use LTR when appropriate

Email uses LTR

Map overlays must not conflict with RTL layout

Bottom navigation labels remain centered

Long Arabic addresses must wrap or truncate safely

Do not blindly mirror inherently LTR content.

6. Typography

Preferred Arabic font:

Cairo

Alternative:

Tajawal

Recommended hierarchy:

Hero / Main Title:       24–28 Bold
Page Title:              20–24 SemiBold/Bold
Section Title:           16–18 SemiBold
Card Title:              15–17 SemiBold
Large Number / Price:    26–32 Bold
Body:                    14–16 Regular
Secondary:               12–14 Regular
Button Label:            14–16 SemiBold
Caption:                 11–12 Regular

Rules:

Do not make every label bold.

Price, status, and primary action should be visually dominant.

Long names and addresses must not overflow.

Use comfortable Arabic line height.

7. Spacing System

Use a consistent spacing scale:

4
8
12
16
20
24
32
40

Defaults:

Screen horizontal padding: 16px
Card inner padding:        14–16px
Section vertical gap:      20–24px
Compact card gap:          10–12px

Do not invent arbitrary spacing per screen.

8. Radius / Elevation

Recommended radius family:

Small:       10–12px
Default:     14–16px
Large:       18–20px
Bottom Sheet: 24px top corners

Cards should use:

subtle border OR subtle shadow

not both heavily

consistent internal padding

compact vertical height

Avoid oversized rounded rectangles with large empty interiors.

9. Buttons

Primary CTA:

Height:        52–56px
Radius:        14–16px
Color:         Biko Red
Text:          White
Width:         Full width when task-critical

Rules:

One dominant CTA per operational state.

Secondary actions should be outline / text / neutral.

Destructive actions must not compete visually with the main task.

Buttons must have loading, disabled, pressed, and error-safe states.

Primary CTAs should remain reachable above the safe area and keyboard.

10. Inputs

Inputs should be clean and compact.

Required states:

Normal
Focused
Filled
Error
Disabled
Loading / resolving where relevant

Location input:

Icon
Label
Address / placeholder

Price input:

Large amount
ج.م
Supporting guidance

Do not validate numeric input so aggressively that normal typing becomes frustrating.

11. Bottom Navigation

Bottom navigation should be light, compact, and obvious.

Do NOT use an oversized pale pill that dominates the screen.

Customer App

Recommended implemented destinations:

الرئيسية
طلباتي
الحساب

Notifications should normally be accessible from the top bar / bell unless the product explicitly introduces a dedicated notification destination.

Driver App

Recommended primary destinations:

الرئيسية
الطلبات / الرحلات
الحساب

History, verification, documents, and earnings summaries may be reached from Driver Home/Profile according to current implemented routing.

Do not add a bottom-nav destination for a feature that does not exist.

Selected state must be unmistakable using:

primary color

icon emphasis

label emphasis

restrained background treatment

12. Splash / Welcome

The welcome experience should establish Biko immediately.

Recommended structure:

Motorcycle hero visual
Biko logo
Short value proposition
Primary CTA
Secondary login action

Rules:

Strong dark or image-led hero is allowed here.

Keep text minimal.

Do not imitate another brand's artwork.

No wallet, rewards, or unsupported service marketing.

13. Customer Home

The Customer Home is the most important visual benchmark.

It must answer immediately:

What can I book?
Where am I going?
Do I have an active order?
What happened recently?

Recommended structure:

Top Bar
- location / city context
- notification icon
- optional greeting

Primary Service Area
- Ride
- Delivery

Location Block
- Pickup
- Destination

Optional Recent / Active Order Summary

Bottom Navigation

Service cards should be compact.

Do NOT reproduce the rejected pattern of two oversized blank cards followed by large unused whitespace.

If an active order exists:

Active Order > New Booking

The active order card must become the dominant item.

14. Ride / Delivery Service Selection

The two services must be instantly distinguishable.

Ride

Use:

motorcycle icon

short label

one-line explanation only if needed

Delivery

Use:

parcel / delivery icon

short label

one-line explanation only if needed

Avoid marketing paragraphs inside service cards.

15. Booking Flow

Booking should feel progressive and fast.

Preferred user mental model:

Choose service
→ Pickup
→ Destination
→ Service-specific details
→ Suggested Price
→ Proposed Price
→ Submit

Avoid:

repeated confirmations

duplicate route summaries

re-entering data

unnecessary modal chains

hidden CTA below long forms

16. Map / Location Selection

Maps are prominent only when location is the task.

Required:

pickup marker

destination marker

readable selected addresses

current-location action

search access

route preview when available

confirm / continue CTA

Map controls must remain visible above:

safe areas

bottom sheets

system navigation

attribution

The map should support the task, not dominate the entire product.

17. Route Quote / Pricing

Biko pricing uses:

Trusted Suggested Price
+
Customer Proposed Price
+
70% minimum rule

The UI must clearly distinguish:

Suggested Price
Minimum Allowed
Your Proposed Price

Recommended hierarchy:

Suggested Price: prominent but secondary to the user's final editable amount

Customer Proposed Price: strongest editable price element

Minimum: contextual guidance, not visual clutter

Do not show unsupported pricing components.

Cash is the MVP payment method.

Do NOT add:

wallet

card payment

stored balance

promo wallet

tipping flow

unless separately approved later.

18. Bidding Screen

Bidding is a hero flow.

Top summary should show:

Service type
Pickup / destination summary
Customer proposed price
Time remaining
Current offer count

Then show Driver Offer Cards.

The countdown should be calm and readable.

Avoid aggressive flashing.

Manual refresh remains a fallback, while Realtime updates should feel quiet and natural.

19. Driver Offer Card

The card must only display backend-supported, privacy-safe information.

Required / allowed when present:

Driver photo
First name
Verified state
Motorcycle type/model
Plate number
Completed trips
Driver type / Office
Offer amount

Only show rating if a real rating system is implemented and authoritative.

Only show ETA if real authoritative ETA exists.

Do NOT invent:

rating

ETA

phone

private documents

internal dispatch data

Offer amount must be visually prominent.

Primary CTA:

اختيار

20. Assigned Driver — Customer

The assigned Driver screen must be easy to visually verify in the real world.

Priority:

Driver photo
First name
Verified badge
Motorcycle
Plate number
Agreed price
Current lifecycle status

Plate number must NOT be buried in metadata.

Current status should use human Arabic such as:

السائق في الطريق
وصل السائق
الرحلة جارية

Do not expose enum labels.

Contact actions should appear only if allowed by the backend/privacy contract.

21. Ride Flow — Customer

Ride has NO operational OTP.

Approved normal flow:

Driver On Way
→ Driver Arrived
→ Ride In Progress
→ Completed

The Customer App must not display:

Ride Start OTP

Ride Completion OTP

SMS-style code entry for Ride

Safety identity should rely on trusted Driver/motorcycle presentation and backend lifecycle/geofence rules.

22. Delivery Flow — Customer

Delivery pickup has NO OTP.

Only final handoff uses:

Delivery Confirmation Code

Customer may see the code only at the appropriate active Delivery stage.

Code card should use:

large readable digits

strong visual hierarchy

short explanation

LTR numeric presentation

no login/OTP language

Recommended Arabic helper:

أعطِ هذا الكود للمستلم ليقدمه للسائق عند استلام الشحنة.

Do not expose the code unnecessarily early.

23. Terminal Customer States

Required clear terminal experiences:

Completed
Cancelled
Expired

Actions may include:

Book Again
Home
History

No stale active-order controls may remain.

Book Again creates a NEW order and must not visually imply reuse of an old quote.

24. Customer History

History cards should remain compact.

Show:

Service
Date / time
Route summary
Agreed/final price
Terminal status

Do not display internal IDs.

25. Customer Profile

Keep Profile simple.

Show only implemented settings:

account identity

optional phone if supported

account actions

sign out

Do not add decorative or non-working settings.

26. Driver Home

Driver Home is an operational command center.

Priority order:

1. Active Trip
2. Online / Offline
3. Readiness / Verification
4. Nearby Requests
5. Secondary summaries

Active Trip must always visually outrank dashboard statistics.

Do not bury active work under earnings/history cards.

27. Driver Online / Offline

Online state is one of the most important controls.

Required states:

Offline
Going Online
Online
Blocked

The UI must not claim Online until backend eligibility and required location state succeed.

When blocked, show one clear reason and action.

Examples:

فعّل الموقع للبدء في استقبال الطلبات
أكمل التحقق للبدء في استقبال الطلبات
انتهت صلاحية رخصة القيادة

Do not show multiple duplicate warnings.

28. Driver Requests

Request cards must be compact and scan-friendly.

Show only available trusted data:

Ride / Delivery
Pickup area
Destination area
Customer proposed price
Distance to pickup
Trip distance
Trip duration if available

Do not expose internal dispatch radius.

Primary decisions:

Accept Customer Price
Counter Offer
Ignore

If an offer has already been submitted, show the correct waiting/withdraw state according to business rules.

29. Counter Offer

Counter Offer should be fast.

Show:

Customer price
Driver proposed price
Submit

Use a numeric keyboard.

Do not use backend language such as:

create new offer row
replace offer

The UI should explain the action in normal Arabic.

30. Driver Active Trip

The active trip screen must have:

Map / route where operationally useful
Essential route information
One dominant lifecycle CTA
Navigation action

Avoid dashboard clutter during active work.

Ride CTA sequence

ابدأ التحرك
→ وصلت
→ ابدأ الرحلة
→ إنهاء الرحلة

No Ride OTP.

Delivery CTA sequence

ابدأ التحرك
→ وصلت
→ تم استلام الشحنة
→ إدخال كود تأكيد التسليم
→ إتمام التسليم

No Delivery Pickup OTP.

31. Geofence UX

Backend authority:

Arrival / Pickup: <= 200m
Completion:       <= 300m

Flutter may explain the result but does not authorize distance.

Example messages:

Outside arrival geofence:

اقترب أكثر من نقطة الالتقاء لتأكيد الوصول.

Stale location:

حدّث موقعك وحاول مرة أخرى.

Do not show raw PostGIS or backend errors.

32. Driver Verification

Verification screens should feel like a compact checklist, not a compliance portal.

Possible visible states:

Required
Uploaded
Pending Review
Verified
Rejected
Expired

Use:

status icon

status text

expiry date where relevant

upload / replace action

safe rejection reason if available

Do not rely on color alone.

33. Driver Documents

Document UI should support:

required-document checklist

upload

replacement

progress

retry

status

expiry

verification warning

Customer App must NEVER display private document content.

Do not expose:

storage paths

private signed URLs in general lists

national ID scans

licences

private verification metadata

34. Earnings / Finance Presentation

Finance is not part of the current MVP scope.

If the Driver App already contains a bounded earnings summary derived from terminal orders, it may remain as a compact informational view.

Do NOT expand into:

wallet

ledger

settlement engine

commission management

payout flow

stored balance

without a separate approved milestone.

35. Notifications / Realtime UX

Realtime should feel quiet.

Do NOT:

flash the whole screen

reset scroll position

show a spinner for every event

Prefer:

Signal
→ authoritative refresh
→ subtle UI update

Push notifications should never be treated as business truth.

Opening a notification must resolve auth and then fetch authoritative state.

36. Loading States

Avoid giant full-screen spinners for small refreshes.

Use context-appropriate states:

Skeleton
Inline progress
Button loading
Existing-content refresh

Never show an empty white screen while loading meaningful content.

37. Empty States

Every empty state should answer:

What happened?
Is this normal?
What can I do next?

Examples:

لا توجد طلبات سابقة بعد.
لم يصل أي عرض حتى الآن.
لا توجد طلبات قريبة حاليًا.
لم ترفع المستندات المطلوبة بعد.

Avoid generic:

لا توجد بيانات

when a clearer message exists.

38. Error States

Differentiate:

Network
Permission
Location
Business rejection
Expired state
Authorization
Temporary backend error

Do not map every failure to:

تحقق من اتصال الإنترنت

Never show raw backend exceptions.

39. Bottom Sheets

Use bottom sheets for task-focused actions only.

Good candidates:

Location search
Service selection
Proposed price
Counter offer
Driver details
Cancel confirmation
Delivery confirmation

Required:

rounded top corners

drag handle where appropriate

compact title

primary CTA

keyboard-safe layout

safe-area padding

Do not turn every screen into a bottom sheet.

40. Cards

Cards remain a major building block, but they must be compact.

Default:

White / light surface
14–18px radius
Subtle border or shadow
Clear hierarchy
Consistent padding
Minimal empty height

Do not create large empty cards for two lines of content.

41. Icons

Use one coherent icon family.

Rules:

semantic

simple

high contrast

visually balanced

no emoji in production UI

service icons may use custom Biko assets

Motorcycle and Delivery must remain distinguishable at a glance.

42. Motion

Motion should be restrained.

Timing:

Fast:    150ms
Normal:  250ms
Slow:    350ms

Good uses:

bottom sheet

selected state

offer arrival

Online state transition

lifecycle change

card expansion

Avoid:

continuous pulsing

decorative bouncing

confetti

long entrance animations

43. Accessibility

Required:

comfortable touch targets

readable contrast

text scaling tolerance

semantics for icon-only actions

status not represented by color alone

important numeric values remain readable

keyboard-safe forms

Critical actions should have approximately 44–48px minimum effective tap areas.

44. Responsive Layout

Visually accept at least:

Small Android phone
Typical Android phone
Large phone

Must handle:

long Arabic addresses

long Driver names

long Office names

long motorcycle descriptions

large fare values

keyboard-open state

bottom gesture area

status bar

map bottom sheets

No critical overflow is acceptable.

45. Reusable Flutter Components

Create/reuse only genuinely repeated components.

Recommended:

AppScaffold
AppTopBar
AppBottomNavigation
PrimaryButton
SecondaryButton
AppTextField
LocationField
PriceInput
ServiceCard
DriverOfferCard
DriverIdentityCard
OrderStatusCard
ActiveOrderCard
IncomingRequestCard
OnlineStatusCard
VerificationStatusCard
DocumentCard
HistoryCard
EmptyState
ErrorState
LoadingSkeleton
AppBottomSheet
PriceDisplay
StatusChip

Do not create dozens of tiny speculative abstractions.

46. Theme / Tokens

The UI must be Theme-native.

No shared widget should hardcode a color that should come from Theme.

Shared presentation should consume semantic tokens such as:

primary
surface
textPrimary
textSecondary
success
warning
error
border

This requirement applies to both User App and Driver App.

47. Business-Truth UI Rules

The UI must never invent product data.

Do NOT display unless authoritative backend data exists:

fake ratings

fake ETA

fake distance

fake live tracking

fake promotions

fake wallet balance

fake earnings

fake Driver availability

fake verification

If a value is unavailable, hide it or present a truthful unavailable state.

48. Feature Truth — Current Product

Current approved UI must reflect:

Services:
- RIDE
- DELIVERY

Auth:
- Email + Password

Payments:
- CASH only

Ride:
- NO Ride OTP

Delivery:
- NO Pickup OTP
- ONE final Delivery Confirmation Code

Pricing:
- Suggested Price
- Customer Proposed Price
- 70% minimum
- Driver accept / counter

Driver:
- Online / Offline
- verification
- documents
- motorcycle identity
- request discovery
- one active job

Maps:
- location selection
- route preview
- operational navigation

Do not visually introduce future features as if already implemented.

49. Explicitly Out of Scope for Current Design

Do NOT design as active product features:

Phone Auth OTP

Ride OTP

Delivery Pickup OTP

Wallet

Stored balance

Card payment

Tips

Promo wallet

Referral rewards

Ratings unless implemented later

Live ETA unless implemented later

Customer-driver chat unless separately approved

Scheduled rides

Multi-stop

Full finance / settlement

Commission dashboard

AI safety detection

continuous background GPS

recipient account/app

50. UI QA Gate

A screen is not Done unless:

No overflow
RTL correct
Correct LTR exceptions
Consistent cards
Consistent spacing
Consistent radius
Consistent typography
Primary CTA obvious
Loading state
Empty state
Error state
Keyboard safe
Safe-area safe
Small-screen safe
Large-screen safe
No invented product data
No stale actions

51. Visual Acceptance Rule

Widget tests and Flutter Analyze are NOT enough to claim visual completion.

For major UI changes:

Run app
→ inspect real rendered states
→ capture representative screenshots
→ fix actual rendering defects

If Maps / Push / GPS cannot be exercised because external configuration is pending:

mark:

LIVE VISUAL ACCEPTANCE PENDING

Do not fake live acceptance.

52. Agent Implementation Order

When implementing mobile UI:

Read this DESIGN.md first.

Preserve existing business logic and architecture.

Use Biko's approved red / black / white visual system.

Build User Home as the primary visual benchmark.

Apply the same visual grammar to Driver Home.

Polish booking, bidding, active-order, verification, and Delivery flows.

Reuse shared components only where truly repeated.

Keep screens compact and task-first.

Do not fall back to generic Material defaults.

Run targeted visual acceptance before declaring UI complete.

Do not add unsupported features to make screenshots look richer.

53. Final Design Principle

Every Biko screen should answer three questions immediately:

Where am I?
What is happening?
What should I do next?

If the user must study the screen to discover the answer, the design is not finished.

For Driver screens, this rule is even stricter:

One operational state
+
One dominant next action
+
Minimum distraction

For Customer screens:

Clear service
+
Clear price
+
Clear Driver/order state
+
Fast next action

This specification is the current source of truth for Biko mobile presentation and supersedes the previous Ana Vodafone-oriented DESIGN.md.