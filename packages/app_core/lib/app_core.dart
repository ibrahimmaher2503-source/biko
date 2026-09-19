import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'operation_recovery.dart';
import 'auth_recovery.dart';
import 'biko_design.dart';
export 'biko_design.dart';
export 'app_environment.dart';
export 'auth_recovery.dart';
export 'operation_recovery.dart';
export 'operational_notifications.dart';
export 'order_presentation.dart';

enum ServiceType {
  ride('RIDE'),
  delivery('DELIVERY');

  const ServiceType(this.databaseValue);
  final String databaseValue;
}

enum DriverType {
  independent('INDEPENDENT'),
  officeDriver('OFFICE_DRIVER');

  const DriverType(this.databaseValue);
  final String databaseValue;
}

enum DriverStatus {
  pending('PENDING'),
  active('ACTIVE'),
  suspended('SUSPENDED'),
  rejected('REJECTED');

  const DriverStatus(this.databaseValue);
  final String databaseValue;
}

enum OrderStatus {
  draft('DRAFT'),
  bidding('BIDDING'),
  driverAssigned('DRIVER_ASSIGNED'),
  driverOnWay('DRIVER_ON_WAY'),
  driverArrived('DRIVER_ARRIVED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  expired('EXPIRED');

  const OrderStatus(this.databaseValue);
  final String databaseValue;
}

enum OfferStatus {
  active('ACTIVE'),
  selected('SELECTED'),
  rejected('REJECTED'),
  withdrawn('WITHDRAWN'),
  expired('EXPIRED'),
  closed('CLOSED');

  const OfferStatus(this.databaseValue);
  final String databaseValue;
}

GoRouter createAuthRouter({
  required AuthService authService,
  required Listenable refreshListenable,
  required WidgetBuilder authBuilder,
  required WidgetBuilder homeBuilder,
  List<RouteBase> authenticatedRoutes = const [],
  String authenticatedInitialLocation = '/home',
}) {
  return GoRouter(
    initialLocation: authService.isSignedIn
        ? authenticatedInitialLocation
        : '/auth',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final onRecoveryRoute = state.matchedLocation == '/auth/recovery';
      if (authService.hasRecoveryFlow) {
        return onRecoveryRoute ? null : '/auth/recovery';
      }
      if (onRecoveryRoute) {
        return authService.isSignedIn ? authenticatedInitialLocation : '/auth';
      }
      final onAuthRoute = state.matchedLocation == '/auth';
      if (!authService.isSignedIn && !onAuthRoute) return '/auth';
      if (authService.isSignedIn && onAuthRoute) {
        return authenticatedInitialLocation;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => authBuilder(context)),
      GoRoute(
        path: '/auth/recovery',
        builder: (_, _) => const PasswordRecoveryPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => homeBuilder(context)),
      ...authenticatedRoutes,
    ],
  );
}

enum AuthMode { signIn, signUp, forgotPassword }

class EmailPasswordAuthPage extends ConsumerStatefulWidget {
  const EmailPasswordAuthPage({
    required this.appName,
    required this.description,
    this.accentColor = BikoColors.primary,
    this.initialMode = AuthMode.signIn,
    super.key,
  });

  final String appName;
  final String description;
  final Color accentColor;
  final AuthMode initialMode;

  @override
  ConsumerState<EmailPasswordAuthPage> createState() =>
      _EmailPasswordAuthPageState();
}

class _EmailPasswordAuthPageState extends ConsumerState<EmailPasswordAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AuthMode _mode = widget.initialMode;
  String? _message;
  String? _error;
  bool _isLoading = false;
  bool _obscurePassword = true;

  AuthService get _auth => ref.read(authServiceProvider);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _title => switch (_mode) {
    AuthMode.signIn => 'تسجيل الدخول',
    AuthMode.signUp => 'إنشاء حساب',
    AuthMode.forgotPassword => 'استعادة كلمة المرور',
  };

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _error = null;
    });

    final email = _emailController.text.trim();
    try {
      switch (_mode) {
        case AuthMode.signIn:
          await _auth.signIn(email: email, password: _passwordController.text);
        case AuthMode.signUp:
          final response = await _auth.signUp(
            email: email,
            password: _passwordController.text,
          );
          if (response.session == null && mounted) {
            setState(() {
              _message =
                  'تم إنشاء الحساب. تحقق من بريدك الإلكتروني ثم سجل الدخول.';
            });
          }
        case AuthMode.forgotPassword:
          await _auth.requestPasswordReset(email);
          if (mounted) {
            setState(() {
              _message = 'تم إرسال تعليمات الاستعادة إلى بريدك الإلكتروني.';
            });
          }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = authErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _message = null;
      _error = null;
      _passwordController.clear();
      _obscurePassword = true;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@') || email.endsWith('@')) {
      return 'أدخل بريدًا إلكترونيًا صحيحًا.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (_mode == AuthMode.forgotPassword) return null;
    if ((value ?? '').length < 6) return 'كلمة المرور 6 أحرف على الأقل.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final showPassword = _mode != AuthMode.forgotPassword;

    return Scaffold(
      appBar: AppTopBar(title: widget.appName),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            BikoSpace.md,
            BikoSpace.lg,
            BikoSpace.md,
            BikoSpace.xl,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(BikoRadius.large),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(BikoSpace.md),
                        child: Row(
                          children: [
                            Icon(
                              Icons.two_wheeler_rounded,
                              color: BikoColors.surface,
                              size: 28,
                            ),
                            SizedBox(width: BikoSpace.sm),
                            Expanded(
                              child: Text(
                                'بيكو، مشوارك أسهل',
                                style: TextStyle(
                                  color: BikoColors.surface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: BikoSpace.lg),
                    Text(
                      _title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: BikoSpace.xs),
                    Text(
                      _mode == AuthMode.forgotPassword
                          ? 'أدخل بريدك الإلكتروني لنرسل لك رابط استعادة كلمة المرور.'
                          : widget.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: BikoSpace.lg),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      textInputAction: showPassword
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: showPassword ? null : (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                    ),
                    if (showPassword) ...[
                      const SizedBox(height: BikoSpace.gap),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration:
                            const InputDecoration(
                              labelText: 'كلمة المرور',
                              border: OutlineInputBorder(),
                            ).copyWith(
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'إظهار كلمة المرور'
                                    : 'إخفاء كلمة المرور',
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        autofillHints: _mode == AuthMode.signUp
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        validator: _validatePassword,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: BikoSpace.gap),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: BikoSpace.gap),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: BikoSpace.md),
                    PrimaryButton(
                      onPressed: _submit,
                      backgroundColor: widget.accentColor,
                      isLoading: _isLoading,
                      label: _title,
                    ),
                    const SizedBox(height: BikoSpace.gap),
                    if (_mode == AuthMode.signIn)
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => _changeMode(AuthMode.forgotPassword),
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => _changeMode(
                              _mode == AuthMode.signUp
                                  ? AuthMode.signIn
                                  : AuthMode.signUp,
                            ),
                      child: Text(
                        _mode == AuthMode.signUp
                            ? 'لديك حساب؟ تسجيل الدخول'
                            : 'ليس لديك حساب؟ إنشاء حساب',
                      ),
                    ),
                    if (_mode == AuthMode.forgotPassword)
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => _changeMode(AuthMode.signIn),
                        child: const Text('العودة إلى تسجيل الدخول'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthenticatedHomeScaffold extends ConsumerWidget {
  const AuthenticatedHomeScaffold({
    required this.title,
    required this.heading,
    required this.description,
    super.key,
  });

  final String title;
  final String heading;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTopBar(title: title, actions: [const SafeSignOutButton()]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(heading, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}
