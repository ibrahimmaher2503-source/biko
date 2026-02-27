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
        },
      };
}
