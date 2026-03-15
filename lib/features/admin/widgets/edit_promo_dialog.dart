import 'package:biko/core/models/promo_code_model.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

enum DiscountType { percentage, fixed }

class EditPromoDialog extends StatefulWidget {
  const EditPromoDialog({
    this.promo,
    super.key,
  });

  final PromoCodeModel? promo;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    PromoCodeModel? promo,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EditPromoDialog(promo: promo),
    );
  }

  @override
  State<EditPromoDialog> createState() => _EditPromoDialogState();
}

class _EditPromoDialogState extends State<EditPromoDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _amountController;
  late final TextEditingController _maxDiscountController;
  late final TextEditingController _maxUsesController;
  final _formKey = GlobalKey<FormState>();
  DiscountType _discountType = DiscountType.percentage;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final promo = widget.promo;
    _codeController = TextEditingController(text: promo?.code ?? '');
    _amountController = TextEditingController(
      text: promo?.discountPercent.toStringAsFixed(0) ?? '',
    );
    _maxDiscountController = TextEditingController(
      text: promo?.maxDiscount.toStringAsFixed(0) ?? '',
    );
    _maxUsesController = TextEditingController();
    if (promo != null) {
      _endDate = promo.expiresAt;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _maxDiscountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final isEditing = widget.promo != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? 'admin.promos.edit'.tr
                        : 'admin.promos.create'.tr,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'admin.promos.code'.tr,
                    controller: _codeController,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'admin.promos.code_required'.tr
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DiscountType>(
                    initialValue: _discountType,
                    decoration: InputDecoration(
                      labelText: 'admin.promos.discount_type'.tr,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: DiscountType.percentage,
                        child: Text('admin.promos.percentage'.tr),
                      ),
                      DropdownMenuItem(
                        value: DiscountType.fixed,
                        child: Text('admin.promos.fixed_amount'.tr),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _discountType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: _discountType == DiscountType.percentage
                        ? 'admin.promos.discount_percent'.tr
                        : 'admin.promos.discount_amount'.tr,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'admin.promos.amount_required'.tr;
                      }
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) {
                        return 'admin.promos.invalid_amount'.tr;
                      }
                      if (_discountType == DiscountType.percentage &&
                          val > 100) {
                        return 'admin.promos.max_percentage'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'admin.promos.max_discount'.tr,
                    controller: _maxDiscountController,
                    keyboardType: TextInputType.number,
                    hint: 'admin.promos.max_discount_hint'.tr,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'admin.promos.max_uses'.tr,
                    controller: _maxUsesController,
                    keyboardType: TextInputType.number,
                    hint: 'admin.promos.max_uses_hint'.tr,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(context, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'admin.promos.start_date'.tr,
                            ),
                            child: Text(
                              _startDate != null
                                  ? fmt.format(_startDate!)
                                  : 'admin.promos.select_date'.tr,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(context, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'admin.promos.end_date'.tr,
                            ),
                            child: Text(
                              _endDate != null
                                  ? fmt.format(_endDate!)
                                  : 'admin.promos.select_date'.tr,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 120,
                        child: AppButton(
                          text: 'common.cancel'.tr,
                          variant: ButtonVariant.outline,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: AppButton(
                          text: 'common.save'.tr,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context, {
                                if (widget.promo != null)
                                  'id': widget.promo!.id,
                                'code': _codeController.text.trim(),
                                'discount_type': _discountType.name,
                                'amount': double.tryParse(
                                      _amountController.text.trim(),
                                    ) ??
                                    0,
                                'max_discount': double.tryParse(
                                      _maxDiscountController.text.trim(),
                                    ) ??
                                    0,
                                'max_uses': int.tryParse(
                                      _maxUsesController.text.trim(),
                                    ) ??
                                    0,
                                if (_startDate != null)
                                  'start_date': _startDate!.toIso8601String(),
                                if (_endDate != null)
                                  'end_date': _endDate!.toIso8601String(),
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
