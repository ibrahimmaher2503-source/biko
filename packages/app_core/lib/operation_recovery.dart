import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'biko_design.dart';

// Transport attempts and UI recovery have independent finite budgets.
const transportTimeout = Duration(seconds: 8);
const mutationWaitTimeout = Duration(seconds: 12);
const recoveryReadTimeout = Duration(seconds: 10);
const boundedPostgrestOptions = PostgrestClientOptions(
  requestTimeout: transportTimeout,
  retryEnabled: false,
);

enum ReadFailureKind { unavailable, forbidden, auth, connection, unknown }

class ReadFailure implements Exception {
  const ReadFailure(this.kind);
  final ReadFailureKind kind;

  String get message => switch (kind) {
    ReadFailureKind.unavailable => 'الطلب لم يعد متاحًا',
    ReadFailureKind.forbidden => 'ليس لديك صلاحية لعرض هذه البيانات.',
    ReadFailureKind.auth => 'انتهت الجلسة. سجل الدخول مرة أخرى.',
    ReadFailureKind.connection => 'تعذر الاتصال. تحقق من الشبكة وأعد المحاولة.',
    ReadFailureKind.unknown => 'تعذر تحميل البيانات. أعد المحاولة.',
  };
}

bool isInvalidAuthSession(Object error) =>
    error is AuthException &&
    error is! AuthRetryableFetchException &&
    (error.statusCode == '401' ||
        (error.code?.contains('session') ?? false) ||
        (error.code?.contains('refresh_token') ?? false));

ReadFailure classifyReadError(Object error) {
  if (error is ReadFailure) return error;
  if (error is TimeoutException ||
      error is AuthRetryableFetchException ||
      error.toString().contains('SocketException') ||
      error.toString().contains('ClientException')) {
    return const ReadFailure(ReadFailureKind.connection);
  }
  if (isInvalidAuthSession(error)) {
    return const ReadFailure(ReadFailureKind.auth);
  }
  if (error is PostgrestException) {
    if (['PGRST301', 'PGRST302', 'PGRST303'].contains(error.code) ||
        error.message == 'Authentication required') {
      return const ReadFailure(ReadFailureKind.auth);
    }
    if (error.code == '42501') {
      return const ReadFailure(ReadFailureKind.forbidden);
    }
    if (error.code == 'P0002') {
      return const ReadFailure(ReadFailureKind.unavailable);
    }
  }
  return const ReadFailure(ReadFailureKind.unknown);
}

enum MutationOutcome { success, businessFailure, uncertain, authFailure }

enum RecoveryPhase { idle, submitting, checking, unavailable, authRequired }

class BusinessFailure implements Exception {
  const BusinessFailure(this.message);
  final String message;
}

MutationOutcome classifyMutationError(Object error) {
  if (error is ReadFailure && error.kind == ReadFailureKind.auth) {
    return MutationOutcome.authFailure;
  }
  if (error is BusinessFailure) return MutationOutcome.businessFailure;
  if (error is AuthRetryableFetchException || error is TimeoutException) {
    return MutationOutcome.uncertain;
  }
  if (error is AuthException) return MutationOutcome.authFailure;
  if (error is PostgrestException) {
    if (error.code == 'PGRST301' ||
        error.code == 'PGRST303' ||
        error.code == 'PGRST302' ||
        error.message == 'Authentication required') {
      return MutationOutcome.authFailure;
    }
    final code = error.code ?? '';
    if (code.startsWith('22') ||
        code.startsWith('23') ||
        code.startsWith('P000') ||
        code == '42501') {
      return MutationOutcome.businessFailure;
    }
  }
  // Unknown failures may have happened AFTER commit. Never replay the write.
  return MutationOutcome.uncertain;
}

String authErrorMessage(Object error) {
  if (error is AuthRetryableFetchException || error is TimeoutException) {
    return 'الاتصال غير متاح. تحقق من الإنترنت وحاول مرة أخرى.';
  }
  if (error is AuthException) {
    final code = error.code ?? '';
    final message = error.message.toLowerCase();
    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }
    if (code == 'email_address_invalid' ||
        message.contains('invalid email') ||
        message.contains('email address') && message.contains('invalid')) {
      return 'أدخل بريدًا إلكترونيًا صحيحًا.';
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('already registered')) {
      return 'يوجد حساب بهذا البريد. سجل الدخول أو استعد كلمة المرور.';
    }
    if (code == 'email_not_confirmed') return 'أكد بريدك الإلكتروني أولًا.';
    if (error.statusCode == '429' || code.contains('rate_limit')) {
      return 'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';
    }
    if (error.statusCode == '401' ||
        code.contains('session') ||
        code.contains('refresh_token')) {
      return 'انتهت الجلسة. سجل الدخول مرة أخرى.';
    }
    return 'تعذر إكمال العملية. حاول مرة أخرى.';
  }
  if (error.toString().contains('SocketException') ||
      error.toString().contains('ClientException')) {
    return 'الاتصال غير متاح. تحقق من الإنترنت وحاول مرة أخرى.';
  }
  return 'تعذر إكمال العملية. حاول مرة أخرى.';
}

/// Owns no business data. Retry retains ONLY the authoritative read callback.
class MutationReconciler extends ChangeNotifier {
  MutationReconciler({
    this.mutationTimeout = mutationWaitTimeout,
    this.readTimeout = recoveryReadTimeout,
    this.readAttempts = 2,
  }) : assert(readAttempts > 0);

  final Duration mutationTimeout;
  final Duration readTimeout;
  final int readAttempts;
  RecoveryPhase phase = RecoveryPhase.idle;
  MutationOutcome? outcome;
  Object? error;
  Object? readError;
  bool get blocksActions => phase != RecoveryPhase.idle;
  bool get isWaiting =>
      phase == RecoveryPhase.submitting || phase == RecoveryPhase.checking;
  Future<bool> Function()? _read;
  Future<void> Function()? _auth;
  int _generation = 0;

  void _setPhase(RecoveryPhase next) {
    phase = next;
    notifyListeners();
  }

  Future<void> run({
    required Future<void> Function() mutate,
    required Future<bool> Function() refresh,
    required Future<void> Function() revalidateAuth,
  }) async {
    if (blocksActions) return;
    final generation = _generation;
    _read = refresh;
    _auth = revalidateAuth;
    error = null;
    readError = null;
    outcome = null;
    _setPhase(RecoveryPhase.submitting);
    try {
      await mutate().timeout(mutationTimeout);
      if (generation != _generation) return;
      outcome = MutationOutcome.success;
    } catch (failure) {
      if (generation != _generation) return;
      error = failure;
      outcome = classifyMutationError(failure);
    }
    if (generation != _generation) return;
    await _check();
  }

  Future<void> retryRead() async {
    if (_read == null || isWaiting) return;
    await _check();
  }

  Future<void> _check() async {
    final read = _read!;
    final auth = _auth!;
    final generation = _generation;
    _setPhase(RecoveryPhase.checking);
    for (var attempt = 0; attempt < readAttempts; attempt++) {
      try {
        if (outcome == MutationOutcome.authFailure) {
          await auth().timeout(readTimeout);
        }
        if (generation != _generation) return;
        final applied = await read().timeout(readTimeout);
        if (generation != _generation) return;
        readError = null;
        // An unchanged snapshot cannot prove a timed-out write will not commit.
        if (outcome == MutationOutcome.uncertain && !applied) {
          _setPhase(RecoveryPhase.unavailable);
          return;
        }
        _read = null;
        _auth = null;
        _setPhase(RecoveryPhase.idle);
        return;
      } catch (failure) {
        if (generation != _generation) return;
        readError = classifyReadError(failure);
        if ((readError! as ReadFailure).kind == ReadFailureKind.auth) {
          outcome = MutationOutcome.authFailure;
          try {
            await auth().timeout(readTimeout);
          } catch (_) {
            // The Auth service exposes its safe session/transport recovery state.
          }
          if (generation != _generation) return;
          _setPhase(RecoveryPhase.authRequired);
          return;
        }
        if ((readError! as ReadFailure).kind != ReadFailureKind.connection) {
          break;
        }
      }
    }
    _setPhase(RecoveryPhase.unavailable);
  }

  void resetForSessionChange() {
    _generation++;
    _read = null;
    _auth = null;
    error = null;
    readError = null;
    outcome = null;
    _setPhase(RecoveryPhase.idle);
  }

  @override
  void dispose() {
    _generation++;
    _read = null;
    _auth = null;
    super.dispose();
  }
}

class ConnectionStateView extends StatelessWidget {
  const ConnectionStateView({
    required this.phase,
    this.onRetry,
    this.message,
    super.key,
  });
  final RecoveryPhase phase;
  final VoidCallback? onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final checking =
        phase == RecoveryPhase.checking || phase == RecoveryPhase.submitting;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (checking)
              const LinearProgressIndicator()
            else
              const Icon(Icons.cloud_off_rounded, size: 44),
            const SizedBox(height: 16),
            Text(
              message ??
                  switch (phase) {
                    RecoveryPhase.submitting => 'جاري تنفيذ الإجراء...',
                    RecoveryPhase.checking => 'جاري التحقق من الحالة...',
                    RecoveryPhase.authRequired =>
                      'انتهت الجلسة. أعد تسجيل الدخول.',
                    RecoveryPhase.unavailable =>
                      'الاتصال غير متاح. لم نتمكن من التحقق من الحالة.',
                    RecoveryPhase.idle => 'تم تحديث الحالة.',
                  },
              textAlign: TextAlign.center,
            ),
            if (!checking && onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('إعادة التحقق'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'جاري تحميل البيانات',
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final height in [32.0, 100.0, 64.0])
            Container(
              height: height,
              margin: const EdgeInsets.only(bottom: BikoSpace.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(BikoRadius.medium),
              ),
            ),
        ],
      ),
    ),
  );
}
