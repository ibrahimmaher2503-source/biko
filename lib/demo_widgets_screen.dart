import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:biko/core/widgets/app_map_widget.dart';

/// Demo screen showcasing all BikeRide shared widgets
/// Demonstrates theme adaptation, RTL/LTR support, and widget functionality
class DemoWidgetsScreen extends StatefulWidget {
  const DemoWidgetsScreen({super.key});

  @override
  State<DemoWidgetsScreen> createState() => _DemoWidgetsScreenState();
}

class _DemoWidgetsScreenState extends State<DemoWidgetsScreen> {
  bool _isDarkMode = false;
  bool _isArabic = false;
  bool _showOverlayLoading = false;
  final _textController = TextEditingController();
  final _validatedController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _textController.dispose();
    _validatedController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    Get.changeThemeMode(_isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
    final newLocale = _isArabic ? const Locale('ar') : const Locale('en');
    Get.updateLocale(newLocale);
  }

  void _validateTextField() {
    setState(() {
      if (_validatedController.text.isEmpty) {
        _validationError = 'This field is required';
      } else if (_validatedController.text.length < 3) {
        _validationError = 'Minimum 3 characters required';
      } else {
        _validationError = null;
        AppSnackbar.success('Validation passed!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isArabic ? 'عرض الودجات' : 'Widgets Demo'),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _toggleLanguage,
            tooltip: 'Toggle language',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AppButton Section
                _buildSectionHeader('AppButton Examples', theme),
                const SizedBox(height: 16),
                AppButton(
                  text: _isArabic ? 'زر رئيسي' : 'Primary Button',
                  onPressed: () => AppSnackbar.success('Primary button tapped'),
                  variant: ButtonVariant.primary,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: _isArabic ? 'زر ثانوي' : 'Secondary Button',
                  onPressed: () => AppSnackbar.info('Secondary button tapped'),
                  variant: ButtonVariant.secondary,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: _isArabic ? 'زر محدد' : 'Outline Button',
                  onPressed: () => AppSnackbar.info('Outline button tapped'),
                  variant: ButtonVariant.outline,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: _isArabic ? 'زر نصي' : 'Text Button',
                  onPressed: () => AppSnackbar.info('Text button tapped'),
                  variant: ButtonVariant.text,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: _isArabic ? 'مع أيقونة' : 'With Icon',
                  onPressed: () {},
                  leadingIcon: Icons.star,
                  variant: ButtonVariant.primary,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: _isArabic ? 'جاري التحميل...' : 'Loading...',
                  onPressed: () {},
                  isLoading: true,
                  variant: ButtonVariant.primary,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: _isArabic ? 'زر معطل' : 'Disabled Button',
                  onPressed: null,
                  variant: ButtonVariant.primary,
                ),
                const SizedBox(height: 32),

                // AppTextField Section
                _buildSectionHeader('AppTextField Examples', theme),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _textController,
                  label: _isArabic ? 'البريد الإلكتروني' : 'Email',
                  hint: _isArabic ? 'أدخل بريدك الإلكتروني' : 'Enter your email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _validatedController,
                  label: _isArabic ? 'حقل مع التحقق' : 'Field with validation',
                  hint: _isArabic ? 'أدخل 3 أحرف على الأقل' : 'Enter at least 3 characters',
                  errorText: _validationError,
                  prefixIcon: Icons.text_fields,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: _isArabic ? 'تحقق' : 'Validate',
                  onPressed: _validateTextField,
                  variant: ButtonVariant.secondary,
                  width: 150,
                ),
                const SizedBox(height: 32),

                // AppCard Section
                _buildSectionHeader('AppCard Examples', theme),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic ? 'بطاقة ثابتة' : 'Static Card',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isArabic
                            ? 'هذه بطاقة ثابتة بدون تفاعل'
                            : 'This is a static card without interaction',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  onTap: () => AppSnackbar.info('Card tapped!'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.touch_app, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            _isArabic ? 'بطاقة قابلة للنقر' : 'Tappable Card',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isArabic ? 'انقر على هذه البطاقة' : 'Tap this card to see ripple effect',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // AppLoading Section
                _buildSectionHeader('AppLoading Examples', theme),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      Text(
                        _isArabic ? 'وضع مضمن' : 'Inline Mode',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        height: 100,
                        child: AppLoading(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      Text(
                        _isArabic ? 'مع رسالة' : 'With Message',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: AppLoading(
                          message: _isArabic ? 'جاري التحميل...' : 'Loading data...',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: _isArabic ? 'عرض تراكب التحميل' : 'Show Overlay Loading',
                  onPressed: () {
                    setState(() => _showOverlayLoading = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() => _showOverlayLoading = false);
                        AppSnackbar.success('Loading complete!');
                      }
                    });
                  },
                  variant: ButtonVariant.secondary,
                ),
                const SizedBox(height: 32),

                // AppSnackbar Section
                _buildSectionHeader('AppSnackbar Examples', theme),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppButton(
                      text: _isArabic ? 'نجاح' : 'Success',
                      onPressed: () => AppSnackbar.success(
                        _isArabic ? 'عملية ناجحة!' : 'Operation successful!',
                      ),
                      variant: ButtonVariant.primary,
                      width: 150,
                    ),
                    AppButton(
                      text: _isArabic ? 'خطأ' : 'Error',
                      onPressed: () => AppSnackbar.error(
                        _isArabic ? 'حدث خطأ!' : 'An error occurred!',
                      ),
                      variant: ButtonVariant.primary,
                      width: 150,
                    ),
                    AppButton(
                      text: _isArabic ? 'معلومات' : 'Info',
                      onPressed: () => AppSnackbar.info(
                        _isArabic ? 'معلومات مفيدة' : 'Useful information',
                      ),
                      variant: ButtonVariant.primary,
                      width: 150,
                    ),
                    AppButton(
                      text: _isArabic ? 'تحذير' : 'Warning',
                      onPressed: () => AppSnackbar.warning(
                        _isArabic ? 'تحذير: تحقق من الإدخال' : 'Warning: Check your input',
                      ),
                      variant: ButtonVariant.primary,
                      width: 150,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // AppMapWidget Section
                _buildSectionHeader('AppMapWidget Placeholder', theme),
                const SizedBox(height: 16),
                const AppMapWidget(
                  height: 250,
                  zoom: 14.0,
                ),
                const SizedBox(height: 16),
                Text(
                  _isArabic
                      ? 'سيتم تنفيذ الخريطة باستخدام google_maps_flutter في التحديث المستقبلي'
                      : 'Map will be implemented with google_maps_flutter in a future update',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Theme Info
                _buildThemeInfo(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Overlay loading
          if (_showOverlayLoading)
            AppLoading(
              showOverlay: true,
              message: _isArabic ? 'جاري التحميل...' : 'Loading...',
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.headlineSmall,
    );
  }

  Widget _buildThemeInfo() {
    return AppCard(
      backgroundColor: Theme.of(context).colorScheme.surfaceTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isArabic ? 'الإعدادات الحالية' : 'Current Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('${_isArabic ? "الوضع" : "Theme Mode"}: ${_isDarkMode ? (_isArabic ? "داكن" : "Dark") : (_isArabic ? "فاتح" : "Light")}'),
          Text('${_isArabic ? "اللغة" : "Language"}: ${_isArabic ? "العربية (RTL)" : "English (LTR)"}'),
          Text('${_isArabic ? "عائلة الخط" : "Font Family"}: ${_isArabic ? "Cairo" : "Plus Jakarta Sans"}'),
        ],
      ),
    );
  }
}
