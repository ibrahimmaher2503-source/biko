import 'package:get/get.dart';

/// Centralized translations for BikeRide multi-app architecture
///
/// Manages localization for Arabic and English across all three apps
/// (Customer, Driver, Admin). Translations are loaded from JSON files
/// in assets/lang/ directory.
///
/// Usage with GetX:
/// ```dart
/// GetMaterialApp(
///   translations: AppTranslations(),
///   locale: Locale('ar'),
///   fallbackLocale: Locale('en'),
/// )
/// ```
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        // Arabic translations
        'ar': {
          // Common strings
          'common.app_name': 'بايكرايد',
          'common.ok': 'موافق',
          'common.cancel': 'إلغاء',
          'common.save': 'حفظ',
          'common.delete': 'حذف',
          'common.edit': 'تعديل',
          'common.loading': 'جاري التحميل...',
          'common.error': 'خطأ',
          'common.success': 'نجاح',
          'common.confirm': 'تأكيد',
          'common.back': 'رجوع',
          'common.next': 'التالي',
          'common.done': 'تم',
          'common.yes': 'نعم',
          'common.no': 'لا',
          'common.search': 'بحث',
          'common.filter': 'تصفية',
          'common.sort': 'ترتيب',
          'common.refresh': 'تحديث',

          // Authentication
          'auth.sign_in': 'تسجيل الدخول',
          'auth.sign_up': 'إنشاء حساب',
          'auth.sign_out': 'تسجيل الخروج',
          'auth.email': 'البريد الإلكتروني',
          'auth.password': 'كلمة المرور',
          'auth.forgot_password': 'نسيت كلمة المرور؟',
          'auth.remember_me': 'تذكرني',

          // Validation messages
          'validation.required': 'هذا الحقل مطلوب',
          'validation.invalid_email': 'البريد الإلكتروني غير صالح',
          'validation.password_too_short': 'كلمة المرور قصيرة جداً',
          'validation.passwords_dont_match': 'كلمات المرور غير متطابقة',

          // Error messages
          'error.network': 'خطأ في الاتصال بالشبكة',
          'error.unknown': 'حدث خطأ غير متوقع',
          'error.permission_denied': 'تم رفض الإذن',
          'error.firebase_init': 'فشل تهيئة التطبيق',
          'error.initialization_failed': 'حدث خطأ أثناء بدء التطبيق',
          'error.retry': 'إعادة المحاولة',
          'error.invalid_phone': 'رقم هاتف غير صالح',
          'error.otp_failed': 'فشل التحقق. حاول مرة أخرى',
          'error.upload_failed': 'فشل رفع الملف',
          'error.file_too_large': 'حجم الملف يتجاوز 5 ميجابايت',
          'error.google_sign_in_failed': 'فشل تسجيل الدخول بجوجل. حاول مرة أخرى',

          // Splash
          'splash.initializing': 'جاري التهيئة...',

          // Customer Onboarding
          'onboarding.skip': 'تخطي',
          'onboarding.next': 'التالي',
          'onboarding.get_started': 'ابدأ الآن',
          'onboarding.customer.slide1.title': 'تغلّب على الزحام',
          'onboarding.customer.slide1.highlight': 'الزحام',
          'onboarding.customer.slide1.desc':
              'اختبر أسرع طريقة للتنقل في المدينة. دراجاتنا تتخطى الازدحام حتى لا تتأخر أبداً.',
          'onboarding.customer.slide2.title': 'سعرك، اختيارك',
          'onboarding.customer.slide2.highlight': 'اختيارك',
          'onboarding.customer.slide2.desc':
              'قدّم سعرك وتفاوض مباشرة مع السائقين. بدون رسوم خفية، فقط صفقات عادلة للجميع.',
          'onboarding.customer.slide3.title': 'توصيل سريع',
          'onboarding.customer.slide3.highlight': 'سريع',
          'onboarding.customer.slide3.desc':
              'أرسل واستقبل الطرود بسرعة البرق عبر المدينة. توصيل موثوق من الباب إلى الباب.',

          // Driver Onboarding
          'onboarding.driver.slide1.title': 'كن رئيس نفسك',
          'onboarding.driver.slide1.highlight': 'رئيس',
          'onboarding.driver.slide1.desc':
              'حدد جدولك، اقبل العروض التي تريدها، واكسب بشروطك مع حرية كاملة.',
          'onboarding.driver.slide2.title': 'آمن وموثوق',
          'onboarding.driver.slide2.highlight': 'وموثوق',
          'onboarding.driver.slide2.desc':
              'كل رحلة مؤمّنة وجميع الركاب تم التحقق منهم لسلامتك وراحة بالك على الطريق.',
          'onboarding.driver.slide3.title': 'اكسب أكثر',
          'onboarding.driver.slide3.highlight': 'أكثر',
          'onboarding.driver.slide3.desc':
              'زِد أرباحك مع عمولات تنافسية ونظام مكافآت يكافئ عملك الدؤوب.',

          // Phone Login
          'phone.title': '!يلّا',
          'phone.subtitle': 'يلّا نتحرك',
          'phone.tagline': 'توصيل أو ركوب عبر القاهرة.',
          'phone.mobile_number': 'رقم الهاتف',
          'phone.placeholder': '1x xxx xxxx',
          'phone.continue': 'متابعة',
          'phone.sms_notice': 'سنرسل لك رمز تحقق عبر رسالة نصية.',
          'phone.or_continue': 'أو تابع عبر',
          'phone.google': 'جوجل',
          'phone.facebook': 'فيسبوك',
          'phone.terms_prefix': 'بالمتابعة، أنت توافق على',
          'phone.terms': 'شروط الخدمة',
          'phone.and': 'و',
          'phone.privacy': 'سياسة الخصوصية',
          'phone.coming_soon': 'قريباً',

          // OTP Verification
          'otp.title': 'تحقق من رقمك',
          'otp.subtitle': 'أدخل الرمز المكون من 4 أرقام المرسل إلى رقم هاتفك المنتهي بـ',
          'otp.verify': 'تحقق',
          'otp.didnt_receive': 'لم تستلم الرمز؟',
          'otp.resend': 'إعادة إرسال الرمز',

          // Profile Setup
          'profile.title': 'إعداد الملف الشخصي',
          'profile.upload_photo': 'رفع صورة',
          'profile.upload_hint': 'أظهر لنا ابتسامتك!',
          'profile.full_name': 'الاسم الكامل',
          'profile.name_hint': 'أدخل اسمك الكامل',
          'profile.select_language': 'اختر اللغة',
          'profile.english': 'English',
          'profile.arabic': 'العربية',
          'profile.complete': 'إكمال الملف الشخصي',
          'profile.name_required': 'الاسم مطلوب',
          'profile.pick_camera': 'الكاميرا',
          'profile.pick_gallery': 'المعرض',

          // Driver Registration
          'registration.title': 'تسجيل السائق',
          'registration.section_title': 'المركبة والمستندات',
          'registration.section_desc':
              'يرجى إدخال تفاصيل مركبتك ورفع المستندات القانونية المطلوبة.',
          'registration.motorcycle_model': 'موديل الدراجة',
          'registration.motorcycle_hint': 'مثال: هوندا وينج 2022',
          'registration.plate_number': 'رقم اللوحة',
          'registration.plate_hint': 'مثال: أ ب ج 123',
          'registration.required_docs': 'المستندات المطلوبة',
          'registration.national_id': 'بطاقة الرقم القومي',
          'registration.national_id_hint': 'الوجه الأمامي والخلفي',
          'registration.driving_license': 'رخصة القيادة',
          'registration.license_hint': 'رخصة دراجة نارية سارية',
          'registration.vehicle_reg': 'رخصة المركبة',
          'registration.vehicle_reg_hint': 'إثبات الملكية',
          'registration.criminal_record': 'الفيش والتشبيه',
          'registration.criminal_hint': 'شهادة حديثة',
          'registration.tip':
              'تأكد من أن جميع الصور واضحة والنص مقروء. المستندات غير الواضحة قد تؤخر تفعيل حسابك.',
          'registration.submit': 'تقديم الطلب',
          'registration.help': 'مساعدة',
          'registration.upload_all': 'يرجى رفع جميع المستندات المطلوبة',
          'registration.fill_all': 'يرجى ملء جميع الحقول المطلوبة',

          // Pending Status
          'pending.title': 'الحالة',
          'pending.heading': 'الطلب قيد المراجعة',
          'pending.description':
              'لقد استلمنا طلبك. سنقوم بإخطارك خلال 24 ساعة.',
          'pending.docs_submitted': 'تم تقديم المستندات',
          'pending.verification': 'التحقق جارٍ',
          'pending.contact_support': 'تواصل مع الدعم',
          'pending.back_home': 'العودة للرئيسية',
        },

        // English translations
        'en': {
          // Common strings
          'common.app_name': 'BikeRide',
          'common.ok': 'OK',
          'common.cancel': 'Cancel',
          'common.save': 'Save',
          'common.delete': 'Delete',
          'common.edit': 'Edit',
          'common.loading': 'Loading...',
          'common.error': 'Error',
          'common.success': 'Success',
          'common.confirm': 'Confirm',
          'common.back': 'Back',
          'common.next': 'Next',
          'common.done': 'Done',
          'common.yes': 'Yes',
          'common.no': 'No',
          'common.search': 'Search',
          'common.filter': 'Filter',
          'common.sort': 'Sort',
          'common.refresh': 'Refresh',

          // Authentication
          'auth.sign_in': 'Sign In',
          'auth.sign_up': 'Sign Up',
          'auth.sign_out': 'Sign Out',
          'auth.email': 'Email',
          'auth.password': 'Password',
          'auth.forgot_password': 'Forgot Password?',
          'auth.remember_me': 'Remember Me',

          // Validation messages
          'validation.required': 'This field is required',
          'validation.invalid_email': 'Invalid email address',
          'validation.password_too_short': 'Password is too short',
          'validation.passwords_dont_match': 'Passwords do not match',

          // Error messages
          'error.network': 'Network connection error',
          'error.unknown': 'An unexpected error occurred',
          'error.permission_denied': 'Permission denied',
          'error.firebase_init': 'Failed to initialize app',
          'error.initialization_failed': 'Something went wrong while starting the app',
          'error.retry': 'Retry',
          'error.invalid_phone': 'Invalid phone number',
          'error.otp_failed': 'Verification failed. Please try again',
          'error.upload_failed': 'File upload failed',
          'error.file_too_large': 'File size exceeds 5MB limit',
          'error.google_sign_in_failed': 'Google sign-in failed. Please try again',

          // Splash
          'splash.initializing': 'Initializing...',

          // Customer Onboarding
          'onboarding.skip': 'Skip',
          'onboarding.next': 'Next',
          'onboarding.get_started': 'Get Started',
          'onboarding.customer.slide1.title': 'Beat the Traffic',
          'onboarding.customer.slide1.highlight': 'Traffic',
          'onboarding.customer.slide1.desc':
              'Experience the fastest way to get around the city. Our agile motorbikes cut through jams so you\'re never late.',
          'onboarding.customer.slide2.title': 'Your Price, Your Choice',
          'onboarding.customer.slide2.highlight': 'Choice',
          'onboarding.customer.slide2.desc':
              'Offer your own price and negotiate directly with drivers. No hidden fees, just fair deals for everyone involved.',
          'onboarding.customer.slide3.title': 'Fast Delivery',
          'onboarding.customer.slide3.highlight': 'Delivery',
          'onboarding.customer.slide3.desc':
              'Send and receive packages at lightning speed across the city. Reliable door-to-door delivery you can count on.',

          // Driver Onboarding
          'onboarding.driver.slide1.title': 'Be Your Own Boss',
          'onboarding.driver.slide1.highlight': 'Boss',
          'onboarding.driver.slide1.desc':
              'Set your own schedule, accept the bids you want, and earn on your terms with total freedom.',
          'onboarding.driver.slide2.title': 'Safe & Reliable',
          'onboarding.driver.slide2.highlight': 'Reliable',
          'onboarding.driver.slide2.desc':
              'Every ride is insured and all riders are verified for your safety and peace of mind on the road. Drive with confidence.',
          'onboarding.driver.slide3.title': 'Earn More',
          'onboarding.driver.slide3.highlight': 'More',
          'onboarding.driver.slide3.desc':
              'Maximize your earnings with competitive commissions and a reward system that values your hard work.',

          // Phone Login
          'phone.title': 'Yalla!',
          'phone.subtitle': 'Let\'s get moving',
          'phone.tagline': 'Ride or deliver across Cairo.',
          'phone.mobile_number': 'Mobile Number',
          'phone.placeholder': '1x xxx xxxx',
          'phone.continue': 'Continue',
          'phone.sms_notice':
              'We\'ll send you a verification code via SMS.',
          'phone.or_continue': 'OR CONTINUE WITH',
          'phone.google': 'Google',
          'phone.facebook': 'Facebook',
          'phone.terms_prefix': 'By continuing, you agree to our',
          'phone.terms': 'Terms of Service',
          'phone.and': 'and',
          'phone.privacy': 'Privacy Policy',
          'phone.coming_soon': 'Coming Soon',

          // OTP Verification
          'otp.title': 'Verify Your Number',
          'otp.subtitle':
              'Enter the 4-digit code sent to your phone number ending in',
          'otp.verify': 'Verify',
          'otp.didnt_receive': 'Didn\'t receive the code?',
          'otp.resend': 'Resend Code',

          // Profile Setup
          'profile.title': 'Set Up Profile',
          'profile.upload_photo': 'Upload Photo',
          'profile.upload_hint': 'Show us your smile!',
          'profile.full_name': 'Full Name',
          'profile.name_hint': 'Enter your full name',
          'profile.select_language': 'Select Language',
          'profile.english': 'English',
          'profile.arabic': 'العربية',
          'profile.complete': 'Complete Profile',
          'profile.name_required': 'Name is required',
          'profile.pick_camera': 'Camera',
          'profile.pick_gallery': 'Gallery',

          // Driver Registration
          'registration.title': 'Driver Registration',
          'registration.section_title': 'Vehicle & Documents',
          'registration.section_desc':
              'Please fill in your vehicle details and upload the required legal documents.',
          'registration.motorcycle_model': 'Motorcycle Model',
          'registration.motorcycle_hint': 'e.g. Honda Wing 2022',
          'registration.plate_number': 'Plate Number',
          'registration.plate_hint': 'e.g. ABC 123',
          'registration.required_docs': 'Required Documents',
          'registration.national_id': 'National ID Card',
          'registration.national_id_hint': 'Front and back side',
          'registration.driving_license': 'Driving License',
          'registration.license_hint': 'Valid motorcycle license',
          'registration.vehicle_reg': 'Vehicle Registration',
          'registration.vehicle_reg_hint': 'Proof of ownership',
          'registration.criminal_record': 'Criminal Record',
          'registration.criminal_hint': 'Recent certificate (Fish w Tashbih)',
          'registration.tip':
              'Ensure all photos are clear and text is readable. Blurry documents may delay your activation process.',
          'registration.submit': 'Submit Application',
          'registration.help': 'Help',
          'registration.upload_all':
              'Please upload all required documents',
          'registration.fill_all': 'Please fill in all required fields',

          // Pending Status
          'pending.title': 'Status',
          'pending.heading': 'Application Under Review',
          'pending.description':
              'We have received your application. We will notify you within 24 hours.',
          'pending.docs_submitted': 'Documents Submitted',
          'pending.verification': 'Verification Pending',
          'pending.contact_support': 'Contact Support',
          'pending.back_home': 'Back to Home',
        },
      };
}
