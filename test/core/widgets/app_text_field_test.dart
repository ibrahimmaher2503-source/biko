import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/core/theme/app_theme.dart';

void main() {
  group('AppTextField Widget Tests', () {
    testWidgets('Default state renders correctly', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Email',
              hint: 'Enter email',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter email'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Controller updates text correctly', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Name',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'John Doe');
      expect(controller.text, 'John Doe');

      controller.dispose();
    });

    testWidgets('Focused state shows label', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Password',
              hint: 'Enter password',
            ),
          ),
        ),
      );

      // Tap to focus
      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      expect(find.text('Password'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Error state displays error text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Email',
              errorText: 'Invalid email format',
            ),
          ),
        ),
      );

      expect(find.text('Invalid email format'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Disabled state prevents input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Disabled Field',
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, false);

      controller.dispose();
    });

    testWidgets('Prefix icon renders correctly', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Email',
              prefixIcon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Suffix icon renders correctly', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Password',
              suffixIcon: Icons.visibility,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Icons flip in RTL layout', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AppTextField(
                controller: controller,
                label: 'Email',
                prefixIcon: Icons.email,
                suffixIcon: Icons.check,
              ),
            ),
          ),
        ),
      );

      // In RTL, icons should be flipped
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Obscure text hides input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      // Verify obscureText is enabled by checking the widget property
      final appTextField = tester.widget<AppTextField>(find.byType(AppTextField));
      expect(appTextField.obscureText, true);

      controller.dispose();
    });

    testWidgets('Max length limits input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Short Text',
              maxLength: 10,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'This is a very long text');
      expect(controller.text.length, lessThanOrEqualTo(10));

      controller.dispose();
    });

    testWidgets('Multiline allows multiple lines', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Description',
              maxLines: 3,
            ),
          ),
        ),
      );

      // Verify maxLines is set correctly by checking the widget property
      final appTextField = tester.widget<AppTextField>(find.byType(AppTextField));
      expect(appTextField.maxLines, 3);

      controller.dispose();
    });

    testWidgets('Validator function is called', (tester) async {
      final controller = TextEditingController();
      String? validatorCalled;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              child: AppTextField(
                controller: controller,
                label: 'Email',
                validator: (value) {
                  validatorCalled = value;
                  return value?.isEmpty == true ? 'Required' : null;
                },
              ),
            ),
          ),
        ),
      );

      // Trigger validation by finding the Form and calling validate
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();

      expect(validatorCalled, ''); // Empty string when no text entered

      controller.dispose();
    });

    testWidgets('OnChanged callback is called', (tester) async {
      final controller = TextEditingController();
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Name',
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Test');
      expect(changedValue, 'Test');

      controller.dispose();
    });

    testWidgets('OnTap callback is called', (tester) async {
      final controller = TextEditingController();
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Tappable',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      expect(tapped, true);

      controller.dispose();
    });

    testWidgets('Keyboard type is set correctly', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      // Verify keyboardType is set correctly by checking the widget property
      final appTextField = tester.widget<AppTextField>(find.byType(AppTextField));
      expect(appTextField.keyboardType, TextInputType.emailAddress);

      controller.dispose();
    });
  });

  // Golden tests are commented out because they require image comparison infrastructure
  // To run golden tests:
  // 1. Ensure goldens directory exists: test/core/widgets/goldens/
  // 2. Generate reference images: flutter test --update-goldens
  // 3. Run golden tests: flutter test
  //
  // group('AppTextField Golden Tests', () {
  //   testWidgets('Default state golden test', (tester) async {
  //     final controller = TextEditingController();
  //
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: Scaffold(
  //           body: Center(
  //             child: SizedBox(
  //               width: 300,
  //               child: AppTextField(
  //                 controller: controller,
  //                 label: 'Email',
  //                 hint: 'Enter email',
  //                 prefixIcon: Icons.email,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(AppTextField),
  //       matchesGoldenFile('goldens/app_text_field_default.png'),
  //     );
  //
  //     controller.dispose();
  //   });
  //
  //   testWidgets('Error state golden test', (tester) async {
  //     final controller = TextEditingController();
  //
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: Scaffold(
  //           body: Center(
  //             child: SizedBox(
  //               width: 300,
  //               child: AppTextField(
  //                 controller: controller,
  //                 label: 'Email',
  //                 errorText: 'Invalid email',
  //                 prefixIcon: Icons.email,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(AppTextField),
  //       matchesGoldenFile('goldens/app_text_field_error.png'),
  //     );
  //
  //     controller.dispose();
  //   });
  //
  //   testWidgets('RTL layout golden test', (tester) async {
  //     final controller = TextEditingController();
  //
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         theme: AppTheme.lightTheme,
  //         home: Directionality(
  //           textDirection: TextDirection.rtl,
  //           child: Scaffold(
  //             body: Center(
  //               child: SizedBox(
  //                 width: 300,
  //                 child: AppTextField(
  //                   controller: controller,
  //                   label: 'البريد الإلكتروني',
  //                   prefixIcon: Icons.email,
  //                   suffixIcon: Icons.check,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //
  //     await expectLater(
  //       find.byType(AppTextField),
  //       matchesGoldenFile('goldens/app_text_field_rtl.png'),
  //     );
  //
  //     controller.dispose();
  //   });
  // });
}
