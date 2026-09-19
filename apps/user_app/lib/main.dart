import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/user_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configured = AppEnvironment.hasSupabase;

  PushNotifications? push;
  if (configured) {
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      publishableKey: AppEnvironment.supabasePublishableKey,
      postgrestOptions: boundedPostgrestOptions,
      debug: false,
    );
    try {
      if (await initializeBikoFirebase()) {
        push = PushNotifications(Supabase.instance.client, appKind: 'USER');
      }
    } catch (_) {
      // External Firebase configuration is optional for core app startup.
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        authRecoveryRedirectProvider.overrideWithValue(userRecoveryRedirect),
        if (push != null)
          pushTokenCleanupProvider.overrideWithValue(push.revokeCurrentToken),
      ],
      child: UserApp(configured: configured, push: push),
    ),
  );
}
