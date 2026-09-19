import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/profile/profile_model.dart';
import 'package:user_app/features/profile/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>(
  (_) => ProfileService(Supabase.instance.client),
);

final profileProvider = FutureProvider<CustomerProfile>(
  (ref) => ref.watch(profileServiceProvider).load(),
);
