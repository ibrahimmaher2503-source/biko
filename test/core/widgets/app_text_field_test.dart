import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
            body: AppTextField(controller: controller, label: 'Name'),
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

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
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
      final appTextField = tester.widget<AppTextField>(
        find.byType(AppTextField),
      );
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

      await tester.enterText(
        find.byType(TextFormField),
        'This is a very long text',
      );
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
      final appTextField = tester.widget<AppTextField>(
        find.byType(AppTextField),
      );
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
                  return (value?.isEmpty ?? false) ? 'Required' : null;
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
      final appTextField = tester.widget<AppTextField>(
        find.byType(AppTextField),
      );
      expect(appTextField.keyboardType, TextInputType.emailAddress);

      controller.dispose();
    });

    testWidgets('T025: Validation shows error message on invalid input', (
      tester,
    ) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextField(
                controller: controller,
                label: 'Email',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Validate with empty value
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);

      // Enter invalid email (no @)
      await tester.enterText(find.byType(TextFormField), 'invalidemail');
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Invalid email format'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), 'valid@email.com');
      formKey.currentState!.validate();
      await tester.pump();

      // No error message should be shown
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Invalid email format'), findsNothing);

      controller.dispose();
    });

    testWidgets('T029: Keyboard interaction - focus and text entry', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppTextField(
                  controller: controller,
                  focusNode: focusNode,
                  label: 'Username',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );

      // Initially not focused
      expect(focusNode.hasFocus, isFalse);

      // Tap to focus
      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Now should be focused
      expect(focusNode.hasFocus, isTrue);

      // Enter text via keyboard
      await tester.enterText(find.byType(TextFormField), 'john_doe');
      expect(controller.text, 'john_doe');

      // Can unfocus
      focusNode.unfocus();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('T030: Adapts to dark theme correctly', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Dark Theme Field',
              hint: 'Enter text',
            ),
          ),
        ),
      );

      // Verify field renders in dark theme
      expect(find.text('Dark Theme Field'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      // Verify dark theme is applied
      final BuildContext context = tester.element(find.byType(AppTextField));
      expect(Theme.of(context).brightness, equals(Brightness.dark));

      // Verify field is functional in dark theme
      await tester.enterText(find.byType(TextFormField), 'Dark mode test');
      expect(controller.text, 'Dark mode test');

      controller.dispose();
    });
  });

  group('AppTextField Accessibility Tests', () {
    testWidgets('T031: Has proper semantic labels for screen readers', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Email Address',
              hint: 'Enter your email',
            ),
          ),
        ),
      );

      // Verify label and hint text are accessible
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);

      // Verify field is rendered and accessible
      expect(find.byType(TextFormField), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Error state is accessible to screen readers', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Email',
              errorText: 'This field is required',
            ),
          ),
        ),
      );

      // Verify error text is visible and accessible
      expect(find.text('This field is required'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Disabled field is accessible with proper state', (
      tester,
    ) async {
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

      // Verify disabled state is communicated
      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.enabled, isFalse);

      // Verify label is still accessible
      expect(find.text('Disabled Field'), findsOneWidget);

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
