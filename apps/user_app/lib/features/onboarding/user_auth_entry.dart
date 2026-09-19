import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingSeenKey = 'user_onboarding_seen_v1';

class UserAuthEntry extends StatefulWidget {
  const UserAuthEntry({super.key});

  @override
  State<UserAuthEntry> createState() => _UserAuthEntryState();
}

class _UserAuthEntryState extends State<UserAuthEntry> {
  SharedPreferences? _preferences;
  bool? _seen;
  int _page = 0;
  AuthMode? _authMode;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadSeenState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSeenState() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      _seen = _preferences!.getBool(_onboardingSeenKey) ?? false;
    } catch (_) {
      // Storage is optional. A failure must not block authentication.
      _seen = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _finishOnboarding() async {
    setState(() => _seen = true);
    try {
      await _preferences?.setBool(_onboardingSeenKey, true);
    } catch (_) {
      // The local transition already succeeded; retry persistence next launch.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_seen == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_authMode case final mode?) {
      return EmailPasswordAuthPage(
        key: ValueKey(mode),
        appName: 'بيكو',
        description: 'سجل دخولك لإدارة رحلاتك وطلبات التوصيل.',
        initialMode: mode,
      );
    }
    return _seen!
        ? _AuthChoice(onModeSelected: _selectMode)
        : _Onboarding(
            page: _page,
            controller: _pageController,
            onPageChanged: (page) => setState(() => _page = page),
            onComplete: _finishOnboarding,
          );
  }

  void _selectMode(AuthMode mode) => setState(() => _authMode = mode);
}

class _Onboarding extends StatelessWidget {
  const _Onboarding({
    required this.page,
    required this.controller,
    required this.onPageChanged,
    required this.onComplete,
  });

  final int page;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onComplete;

  static const _steps = [
    _OnboardingStep(
      title: 'مرحبًا بك في بيكو',
      description: 'تنقل وتوصيل سريع بالدراجة، بسعر تقترحه أنت.',
      icon: Icons.two_wheeler_rounded,
    ),
    _OnboardingStep(
      title: 'اطلب بطريقتك',
      description: 'اختر رحلة أو توصيلًا، وحدد نقطة البداية والوجهة بسهولة.',
      icon: Icons.route_rounded,
    ),
    _OnboardingStep(
      title: 'اطلب وأنت مطمئن',
      description: 'تابع حالة طلبك وتعرّف إلى السائق والدراجة عند الإسناد.',
      icon: Icons.verified_user_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: onComplete,
                child: const Text('تخطي'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: _steps.length,
                onPageChanged: onPageChanged,
                itemBuilder: (_, index) => _OnboardingPage(step: _steps[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: index == page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: page == _steps.length - 1 ? 'ابدأ الآن' : 'التالي',
              onPressed: page == _steps.length - 1
                  ? onComplete
                  : () => controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - 32)
              .clamp(0, double.infinity)
              .toDouble(),
          maxWidth: 420,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BikoGraphic(icon: step.icon),
              const SizedBox(height: 32),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BikoGraphic extends StatelessWidget {
  const _BikoGraphic({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'بيكو',
    image: true,
    child: Container(
      width: 196,
      height: 196,
      decoration: BoxDecoration(
        color: BikoColors.textPrimary,
        borderRadius: BorderRadius.circular(BikoRadius.sheet),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 28,
            child: Text(
              'BIKO',
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: BikoColors.surface,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: BikoColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: BikoColors.surface, size: 56),
          ),
          const Positioned(
            bottom: 26,
            child: SizedBox(
              width: 112,
              child: Divider(color: BikoColors.primary, thickness: 4),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AuthChoice extends StatelessWidget {
  const _AuthChoice({required this.onModeSelected});

  final ValueChanged<AuthMode> onModeSelected;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: _BikoGraphic(icon: Icons.two_wheeler_rounded),
                ),
                const SizedBox(height: 32),
                Text(
                  'كيف تريد المتابعة؟',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'أنشئ حسابًا جديدًا أو سجّل الدخول إلى حسابك.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'إنشاء حساب',
                  onPressed: () => onModeSelected(AuthMode.signUp),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'تسجيل الدخول',
                  onPressed: () => onModeSelected(AuthMode.signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
