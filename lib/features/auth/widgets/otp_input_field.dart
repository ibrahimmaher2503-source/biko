import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 4-digit OTP input — 4 individual TextFields with auto-advance focus
class OtpInputField extends StatefulWidget {
  const OtpInputField({required this.onCompleted, super.key});

  final ValueChanged<String> onCompleted;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      // Advance to next field
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 4 filled
    if (_otp.length == 4) {
      widget.onCompleted(_otp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    // Handle backspace — move focus to previous field if current is empty
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Padding(
          padding: EdgeInsets.only(left: index > 0 ? 16 : 0),
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _onKeyEvent(index, event),
            child: SizedBox(
              width: 56,
              height: 64,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _onChanged(index, value),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: ext.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    borderSide: BorderSide(color: ext.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    borderSide: BorderSide(color: ext.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
