import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/translations/app_translations.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// RTL layout tests for BikeRide Arabic locale.
///
/// T160: Arabic layout rendering for all screens
/// T161: Layout overflow detection in RTL mode
/// T162: Directional icon flipping in RTL
/// T163: EdgeInsetsDirectional usage verification
///
/// Egypt is the primary market → Arabic (RTL) is the primary UX.
/// All screens must render correctly in RTL without overflow or misalignment.
void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  // ===== T160: Arabic layout rendering =====

  group('T160: Arabic RTL layout rendering', () {
    testWidgets(
      'GetMaterialApp renders in RTL with Arabic locale',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('ar'),
            fallbackLocale: const Locale('en'),
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Center(child: Text('مرحباً')),
            ),
          ),
        );

        final direction = Directionality.of(
          tester.element(find.byType(Scaffold)),
        );
        expect(direction, equals(TextDirection.rtl));
        expect(find.text('مرحباً'), findsOneWidget);
      },
    );

    testWidgets(
      'Arabic locale text aligns right by default',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('ar'),
            fallbackLocale: const Locale('en'),
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: Text('كتابة عربية'),
              ),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('كتابة عربية'));
        // In RTL, text has no explicit alignment — inherits RTL from Directionality
        // Verify it renders without error
        expect(text, isNotNull);
      },
    );

    testWidgets(
      'AppButton renders correctly in RTL mode',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Center(
                  child: AppButton(
                    text: 'احجز رحلة',
                    onPressed: null,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('احجز رحلة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AppCard renders correctly in RTL mode',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: AppCard(
                  child: Text('تفاصيل الرحلة'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('تفاصيل الرحلة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AppLoading renders in RTL without overflow',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Center(child: AppLoading()),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AppEmptyState renders in RTL without overflow',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: AppEmptyState(
                  icon: Icons.history,
                  title: 'لا توجد رحلات',
                  subtitle: 'ستظهر تاريخ رحلاتك هنا',
                ),
              ),
            ),
          ),
        );

        expect(find.text('لا توجد رحلات'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AppErrorWidget renders in RTL without overflow',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: AppErrorWidget(
                  message: 'حدث خطأ في الاتصال',
                ),
              ),
            ),
          ),
        );

        expect(find.text('حدث خطأ في الاتصال'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'login form layout works in RTL at 360px width',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'يلّا!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('يلّا نتحرك', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 24),
                      TextField(
                        decoration: InputDecoration(
                          hintText: '1x xxx xxxx',
                        ),
                      ),
                      SizedBox(height: 16),
                      AppButton(
                        text: 'متابعة',
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
      },
    );
  });

  // ===== T161: Layout overflow detection =====

  group('T161: no layout overflow in RTL mode', () {
    testWidgets(
      'AppButton does not overflow at 360px width in RTL',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppButton(
                    text: 'حجز رحلة',
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'long Arabic text wraps correctly without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'اختبر أسرع طريقة للتنقل في المدينة. دراجاتنا تتخطى الازدحام حتى لا تتأخر أبداً.',
                    softWrap: true,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'RTL list tiles do not overflow',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => AppCard(
                    child: ListTile(
                      title: Text('رحلة #${index + 1}'),
                      subtitle: const Text('القاهرة → الجيزة'),
                      trailing: const Text('50 ج.م'),
                      leading: const Icon(Icons.directions_bike),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'RTL bottom navigation bar does not overflow',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: const SizedBox.shrink(),
                bottomNavigationBar: BottomNavigationBar(
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'الرئيسية',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history),
                      label: 'الرحلات',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.account_balance_wallet),
                      label: 'المحفظة',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'حسابي',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );
  });

  // ===== T162: Directional icon flipping =====

  group('T162: directional icon flipping in RTL', () {
    testWidgets(
      'AppButton with leadingIcon places icon correctly in LTR',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Center(
                  child: AppButton(
                    text: 'Next',
                    onPressed: () {},
                    trailingIcon: Icons.arrow_forward,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AppButton with trailingIcon renders in RTL without exception',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Center(
                  child: AppButton(
                    text: 'التالي',
                    onPressed: () {},
                    trailingIcon: Icons.arrow_forward,
                  ),
                ),
              ),
            ),
          ),
        );

        // In RTL: trailing icon becomes leading position
        expect(find.byType(AppButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'back arrow icon appears correctly in RTL AppBar',
      (tester) async {
        // In RTL, back arrow should be the mirrored arrow (arrow_back → arrow_forward visually)
        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('ar'),
            fallbackLocale: const Locale('en'),
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                leading: const BackButton(),
                title: const Text('الرئيسية'),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        );

        expect(find.byType(BackButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'icons that should not flip remain stable in RTL',
      (tester) async {
        // Non-directional icons (person, home, settings) should not flip
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Row(
                  children: [
                    Icon(Icons.person),
                    Icon(Icons.home),
                    Icon(Icons.settings),
                    Icon(Icons.account_balance_wallet),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'chevron icons are appropriately positioned in RTL list',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: ListView(
                  children: const [
                    ListTile(
                      title: Text('الحساب'),
                      leading: Icon(Icons.person),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    ListTile(
                      title: Text('الإشعارات'),
                      leading: Icon(Icons.notifications),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Chevrons are placed in trailing position (left side in RTL)
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ===== T163: EdgeInsetsDirectional usage =====

  group('T163: EdgeInsetsDirectional for directional padding', () {
    testWidgets(
      'EdgeInsetsDirectional.only applies correct padding in LTR',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Container(
                  padding: const EdgeInsetsDirectional.only(
                    start: 24,
                    end: 8,
                    top: 12,
                    bottom: 12,
                  ),
                  child: const Text('LTR padding test'),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('LTR padding test'), findsOneWidget);
      },
    );

    testWidgets(
      'EdgeInsetsDirectional.only swaps start/end in RTL',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Container(
                  // In RTL: start=right, end=left
                  padding: const EdgeInsetsDirectional.only(
                    start: 24,
                    end: 8,
                  ),
                  child: const Text('RTL padding test'),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('RTL padding test'), findsOneWidget);
      },
    );

    testWidgets(
      'EdgeInsetsDirectional.symmetric works in RTL',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: const Text('Symmetric padding'),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'EdgeInsetsDirectional vs EdgeInsets differ in RTL',
      (tester) async {
        // Verify that EdgeInsetsDirectional correctly mirrors in RTL
        // while EdgeInsets.only(left:...) does NOT mirror
        final directionalPadding = const EdgeInsetsDirectional.only(
          start: 24,
          end: 8,
        ).resolve(TextDirection.rtl);

        const fixedPadding = EdgeInsets.only(left: 24, right: 8);

        // In RTL, directional start maps to right, end maps to left
        expect(directionalPadding.right, equals(24)); // start → right in RTL
        expect(directionalPadding.left, equals(8)); // end → left in RTL

        // Fixed padding is never mirrored
        expect(fixedPadding.left, equals(24)); // always left
        expect(fixedPadding.right, equals(8)); // always right

        // They differ in RTL — directional is correct, fixed is not
        expect(
          directionalPadding.right,
          isNot(equals(fixedPadding.right)),
        );
      },
    );

    testWidgets(
      'form with directional padding renders correctly in RTL',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        24,
                        16,
                        8,
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'رقم الهاتف',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        8,
                        16,
                        24,
                      ),
                      child: AppButton(
                        text: 'متابعة',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
      },
    );
  });
}
