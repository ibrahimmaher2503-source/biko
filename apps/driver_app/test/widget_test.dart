import 'package:driver_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the safe setup state without credentials', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DriverApp(configured: false)),
    );

    expect(find.textContaining('أضف إعدادات Supabase'), findsOneWidget);
  });
}
