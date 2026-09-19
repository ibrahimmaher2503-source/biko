import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'operation_recovery.dart';

const driverRecoveryRedirect = 'biko-driver-dev://auth-callback/';
const userRecoveryRedirect = 'biko-user-dev://auth-callback/';
final authRecoveryRedirectProvider = Provider<String>(
  (_) => userRecoveryRedirect,
);
final pushTokenCleanupProvider = Provider<Future<void> Function()?>(
  (_) => null,
);

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService(
    Supabase.instance.client,
    recoveryRedirect: ref.watch(authRecoveryRedirectProvider),
    beforeSignOut: ref.watch(pushTokenCleanupProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// One SDK subscription owns session errors and trusted recovery events.
class AuthService extends ChangeNotifier {
  AuthService(
    SupabaseClient client, {
    this.recoveryRedirect = userRecoveryRedirect,
    this.requestTimeout = transportTimeout,
    this.beforeSignOut,
  }) : _auth = client.auth {
    _subscription = _auth.onAuthStateChange.listen(_onState, onError: _onError);
  }

  final GoTrueClient _auth;
  final String recoveryRedirect;
  final Duration requestTimeout;
  final Future<void> Function()? beforeSignOut;
  late final StreamSubscription<AuthState> _subscription;
  String? _recoveryUserId;
  bool recoveryCompleted = false;
  bool _invalidSession = false;
  bool _disposed = false;
  bool _updatingPassword = false;
  String? sessionMessage;

  Session? get currentSession => _auth.currentSession;
  bool get isSignedIn => currentSession != null && !_invalidSession;
  bool get hasRecoveryFlow => _recoveryUserId != null || recoveryCompleted;
  bool get canResetPassword =>
      !recoveryCompleted &&
      isSignedIn &&
      _recoveryUserId == currentSession?.user.id &&
      _recoveryUserId != null &&
      !currentSession!.isExpired;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onState(AuthState state) {
    if (_disposed) return;
    if (state.event == AuthChangeEvent.passwordRecovery &&
        state.session != null) {
      _recoveryUserId = state.session!.user.id;
      recoveryCompleted = false;
    } else if (state.event == AuthChangeEvent.signedOut ||
        state.session?.user.id != _recoveryUserId) {
      _recoveryUserId = null;
      recoveryCompleted = false;
    }
    _invalidSession = false;
    sessionMessage = null;
    _notify();
  }

  void _onError(Object error, [StackTrace? stack]) {
    if (_disposed) return;
    // Transient refresh/network failures preserve the existing session.
    if (isInvalidAuthSession(error)) {
      _invalidSession = true;
      _recoveryUserId = null;
      recoveryCompleted = false;
    }
    sessionMessage = authErrorMessage(error);
    _notify();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) => _auth.signUp(email: email, password: password).timeout(requestTimeout);
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => _auth
      .signInWithPassword(email: email, password: password)
      .timeout(requestTimeout);
  Future<void> signOut() async {
    try {
      await beforeSignOut?.call().timeout(requestTimeout);
    } catch (_) {
      // Best effort: a remote token cleanup failure must not trap the user.
    }
    await _auth.signOut(scope: SignOutScope.local).timeout(requestTimeout);
  }

  Future<void> revalidateSession() async {
    try {
      if (currentSession == null) {
        throw const AuthException('Session expired', code: 'session_not_found');
      }
      if (currentSession!.isExpired) {
        await _auth.refreshSession().timeout(requestTimeout);
      }
      await _auth.getUser().timeout(requestTimeout);
      _invalidSession = false;
      sessionMessage = null;
      _notify();
    } catch (error) {
      _onError(error);
      rethrow;
    }
  }

  Future<void> requestPasswordReset(String email) => _auth
      .resetPasswordForEmail(email, redirectTo: recoveryRedirect)
      .timeout(requestTimeout);

  Future<void> completePasswordRecovery(
    String password,
    String confirmation,
  ) async {
    if (_updatingPassword) return;
    if (password.length < 6 || password != confirmation) {
      throw const AuthException('Invalid password input');
    }
    if (!canResetPassword) {
      throw const AuthException(
        'Recovery session expired',
        code: 'session_not_found',
      );
    }
    final recoveryUser = _recoveryUserId;
    _updatingPassword = true;
    try {
      final user = await _auth.getUser().timeout(requestTimeout);
      if (!canResetPassword || user.user?.id != recoveryUser) {
        throw const AuthException(
          'Recovery session expired',
          code: 'session_not_found',
        );
      }
      await _auth
          .updateUser(UserAttributes(password: password))
          .timeout(requestTimeout);
      if (_disposed || _recoveryUserId != recoveryUser) return;
      recoveryCompleted = true;
      _notify();
    } finally {
      _updatingPassword = false;
    }
  }

  void finishRecovery() {
    _recoveryUserId = null;
    recoveryCompleted = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({super.key});
  @override
  ConsumerState<PasswordRecoveryPage> createState() =>
      _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _error;

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .completePasswordRecovery(_password.text, _confirmation.text);
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('تعيين كلمة مرور جديدة')),
      body: ListenableBuilder(
        listenable: auth,
        builder: (context, _) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: auth.recoveryCompleted
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تم تحديث كلمة المرور بنجاح.'),
                        FilledButton(
                          onPressed: auth.finishRecovery,
                          child: const Text('متابعة'),
                        ),
                      ],
                    )
                  : !auth.canResetPassword
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'رابط الاستعادة غير صالح أو انتهت صلاحيته. اطلب رابطًا جديدًا.',
                        ),
                        TextButton(
                          onPressed: auth.finishRecovery,
                          child: const Text('العودة لتسجيل الدخول'),
                        ),
                        const SafeSignOutButton(),
                      ],
                    )
                  : Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور الجديدة',
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'إظهار كلمة المرور'
                                    : 'إخفاء كلمة المرور',
                                onPressed: _busy
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
                            validator: (value) => (value ?? '').length < 6
                                ? 'كلمة المرور 6 أحرف على الأقل.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmation,
                            enabled: !_busy,
                            obscureText: _obscureConfirmation,
                            textInputAction: TextInputAction.done,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmation
                                    ? 'إظهار تأكيد كلمة المرور'
                                    : 'إخفاء تأكيد كلمة المرور',
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _obscureConfirmation =
                                            !_obscureConfirmation,
                                      ),
                                icon: Icon(
                                  _obscureConfirmation
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => value != _password.text
                                ? 'كلمتا المرور غير متطابقتين.'
                                : null,
                            onFieldSubmitted: (_) => _save(),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _busy ? null : _save,
                            child: Text(
                              _busy ? 'جاري الحفظ...' : 'حفظ كلمة المرور',
                            ),
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

class SafeSignOutButton extends ConsumerStatefulWidget {
  const SafeSignOutButton({super.key});
  @override
  ConsumerState<SafeSignOutButton> createState() => _SafeSignOutButtonState();
}

class _SafeSignOutButtonState extends ConsumerState<SafeSignOutButton> {
  bool _busy = false;
  String? _error;
  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextButton.icon(
        onPressed: _busy ? null : _signOut,
        icon: const Icon(Icons.logout),
        label: Text(_busy ? 'جاري الخروج...' : 'تسجيل الخروج'),
      ),
      if (_error != null) Text(_error!),
    ],
  );
}

class AuthSessionBoundary extends ConsumerStatefulWidget {
  const AuthSessionBoundary({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<AuthSessionBoundary> createState() =>
      _AuthSessionBoundaryState();
}

class _AuthSessionBoundaryState extends ConsumerState<AuthSessionBoundary> {
  bool _busy = false;
  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).revalidateSession();
    } catch (_) {
      /* Safe state belongs to AuthService, never raw SDK text. */
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => Column(
        children: [
          if (auth.sessionMessage case final message?)
            Material(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(child: Text(message)),
                      TextButton(
                        onPressed: _busy ? null : _retry,
                        child: Text(_busy ? 'جاري التحقق...' : 'إعادة التحقق'),
                      ),
                      const SafeSignOutButton(),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
