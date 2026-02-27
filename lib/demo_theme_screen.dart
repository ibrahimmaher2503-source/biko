import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';

/// Demo screen to showcase the theme system
/// Displays all theme colors, typography styles, and supports theme/language switching
class DemoThemeScreen extends StatefulWidget {
  const DemoThemeScreen({super.key});

  @override
  State<DemoThemeScreen> createState() => _DemoThemeScreenState();
}

class _DemoThemeScreenState extends State<DemoThemeScreen> {
  bool _isDarkMode = false;
  bool _isArabic = false;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isArabic ? 'عرض النظام المظهري' : 'Theme System Demo'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color Palette Section
            _buildSectionHeader('Color Palette', theme),
            const SizedBox(height: 16),
            _buildColorGrid(colorScheme),
            const SizedBox(height: 32),

            // Typography Section
            _buildSectionHeader('Typography', theme),
            const SizedBox(height: 16),
            _buildTypographyExamples(theme),
            const SizedBox(height: 32),

            // Components Section
            _buildSectionHeader('UI Components', theme),
            const SizedBox(height: 16),
            _buildComponentExamples(theme),
            const SizedBox(height: 32),

            // Border Radius Section
            _buildSectionHeader('Border Radius', theme),
            const SizedBox(height: 16),
            _buildBorderRadiusExamples(colorScheme),
            const SizedBox(height: 32),

            // Theme Info
            _buildThemeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.headlineMedium,
    );
  }

  Widget _buildColorGrid(ColorScheme colorScheme) {
    final colors = [
      ('Primary', AppTheme.primary, '#E0062E'),
      ('Primary Dark', AppTheme.primaryDark, '#B00423'),
      ('Background Light', AppTheme.backgroundLight, '#F8F5F6'),
      ('Background Dark', AppTheme.backgroundDark, '#230F13'),
      ('Neutral Tint', AppTheme.neutralTint, '#FCECEE'),
      ('Surface', colorScheme.surface, null),
      ('Error', colorScheme.error, null),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        return _buildColorCard(
          name: color.$1,
          color: color.$2,
          hexCode: color.$3,
        );
      }).toList(),
    );
  }

  Widget _buildColorCard({
    required String name,
    required Color color,
    String? hexCode,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: _getContrastColor(color),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (hexCode != null) ...[
              const SizedBox(height: 4),
              Text(
                hexCode,
                style: TextStyle(
                  color: _getContrastColor(color).withOpacity(0.8),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildTypographyExamples(ThemeData theme) {
    final styles = [
      ('Display Large', theme.textTheme.displayLarge),
      ('Display Medium', theme.textTheme.displayMedium),
      ('Display Small', theme.textTheme.displaySmall),
      ('Headline Large', theme.textTheme.headlineLarge),
      ('Headline Medium', theme.textTheme.headlineMedium),
      ('Headline Small', theme.textTheme.headlineSmall),
      ('Title Large', theme.textTheme.titleLarge),
      ('Title Medium', theme.textTheme.titleMedium),
      ('Title Small', theme.textTheme.titleSmall),
      ('Body Large', theme.textTheme.bodyLarge),
      ('Body Medium', theme.textTheme.bodyMedium),
      ('Body Small', theme.textTheme.bodySmall),
      ('Label Large', theme.textTheme.labelLarge),
      ('Label Medium', theme.textTheme.labelMedium),
      ('Label Small', theme.textTheme.labelSmall),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: styles.map((style) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                style.$1,
                style: style.$2,
              ),
              Text(
                '${style.$2?.fontSize?.toStringAsFixed(0)}sp • '
                '${_getFontWeightName(style.$2?.fontWeight)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getFontWeightName(FontWeight? weight) {
    if (weight == null) return 'Regular';
    if (weight.index <= FontWeight.w300.index) return 'Light';
    if (weight.index <= FontWeight.w400.index) return 'Regular';
    if (weight.index <= FontWeight.w500.index) return 'Medium';
    if (weight.index <= FontWeight.w600.index) return 'SemiBold';
    if (weight.index <= FontWeight.w700.index) return 'Bold';
    return 'ExtraBold';
  }

  Widget _buildComponentExamples(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Elevated Button'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Outlined Button'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {},
          child: const Text('Text Button'),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: _isArabic ? 'حقل النص' : 'Text Field',
            hintText: _isArabic ? 'أدخل النص هنا' : 'Enter text here',
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _isArabic ? 'مثال على البطاقة' : 'Card Example',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBorderRadiusExamples(ColorScheme colorScheme) {
    final radiusExamples = [
      ('Default (8dp)', AppTheme.radiusDefault),
      ('Large (12dp)', AppTheme.radiusLarge),
      ('XL (16dp)', AppTheme.radiusXl),
      ('Full', AppTheme.radiusFull),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: radiusExamples.map((radius) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(radius.$2),
          ),
          child: Center(
            child: Text(
              radius.$1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Theme Mode: ${_isDarkMode ? "Dark" : "Light"}'),
          Text('Language: ${_isArabic ? "Arabic (العربية)" : "English"}'),
          Text('Text Direction: ${_isArabic ? "RTL" : "LTR"}'),
          Text(
            'Font Family: ${_isArabic ? "Cairo" : "Plus Jakarta Sans"}',
          ),
        ],
      ),
    );
  }
}
