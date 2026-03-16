import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/features/admin/models/finance/commission_rates_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Editor form for ride, c2c, and b2b commission rates
/// with Save and Reset buttons.
class CommissionRatesEditor extends StatefulWidget {
  const CommissionRatesEditor({
    required this.onSave,
    super.key,
    this.currentRates,
  });

  final CommissionRatesModel? currentRates;
  final Function(CommissionRatesModel) onSave;

  @override
  State<CommissionRatesEditor> createState() => _CommissionRatesEditorState();
}

class _CommissionRatesEditorState extends State<CommissionRatesEditor> {
  late final TextEditingController _rideController;
  late final TextEditingController _c2cController;
  late final TextEditingController _b2bController;

  @override
  void initState() {
    super.initState();
    _rideController = TextEditingController(
      text: widget.currentRates?.rideRate.toString() ?? '0',
    );
    _c2cController = TextEditingController(
      text: widget.currentRates?.c2cRate.toString() ?? '0',
    );
    _b2bController = TextEditingController(
      text: widget.currentRates?.b2bDefaultRate.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _rideController.dispose();
    _c2cController.dispose();
    _b2bController.dispose();
    super.dispose();
  }

  void _reset() {
    _rideController.text =
        widget.currentRates?.rideRate.toString() ?? '0';
    _c2cController.text =
        widget.currentRates?.c2cRate.toString() ?? '0';
    _b2bController.text =
        widget.currentRates?.b2bDefaultRate.toString() ?? '0';
  }

  void _save() {
    final rideRate =
        double.tryParse(_rideController.text) ?? 0;
    final c2cRate =
        double.tryParse(_c2cController.text) ?? 0;
    final b2bRate =
        double.tryParse(_b2bController.text) ?? 0;

    widget.onSave(
      CommissionRatesModel(
        rideRate: rideRate,
        c2cRate: c2cRate,
        b2bDefaultRate: b2bRate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _rideController,
          label: 'admin.finance.ride_commission_rate'.tr,
          hint: 'admin.finance.enter_percentage'.tr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixIcon: Icons.percent,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _c2cController,
          label: 'admin.finance.c2c_commission_rate'.tr,
          hint: 'admin.finance.enter_percentage'.tr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixIcon: Icons.percent,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _b2bController,
          label: 'admin.finance.b2b_commission_rate'.tr,
          hint: 'admin.finance.enter_percentage'.tr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixIcon: Icons.percent,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'common.reset'.tr,
                variant: ButtonVariant.outline,
                onPressed: _reset,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'common.save'.tr,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
