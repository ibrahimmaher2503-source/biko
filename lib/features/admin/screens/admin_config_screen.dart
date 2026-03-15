import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/admin/controllers/admin_auth_controller.dart';
import 'package:biko/features/admin/controllers/admin_config_controller.dart';
import 'package:biko/features/admin/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  late final AdminConfigController controller;

  // Number field controllers
  late final TextEditingController _baseFareCtrl;
  late final TextEditingController _pricePerKmCtrl;
  late final TextEditingController _pricePerMinCtrl;
  late final TextEditingController _surgeMultiplierCtrl;
  late final TextEditingController _commissionRideCtrl;
  late final TextEditingController _commissionC2cCtrl;
  late final TextEditingController _commissionB2bCtrl;
  late final TextEditingController _minBidRadiusCtrl;
  late final TextEditingController _bidTimeoutCtrl;
  late final TextEditingController _referrerRewardCtrl;
  late final TextEditingController _refereeRewardCtrl;

  // Text field controllers
  late final TextEditingController _supportPhoneCtrl;
  late final TextEditingController _supportEmailCtrl;

  /// Workers to sync controller Rx values → text field text.
  final List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    controller = Get.find<AdminConfigController>();

    _baseFareCtrl = TextEditingController(
      text: controller.baseFare.value.toStringAsFixed(2),
    );
    _pricePerKmCtrl = TextEditingController(
      text: controller.pricePerKm.value.toStringAsFixed(2),
    );
    _pricePerMinCtrl = TextEditingController(
      text: controller.pricePerMin.value.toStringAsFixed(2),
    );
    _surgeMultiplierCtrl = TextEditingController(
      text: controller.surgeMultiplier.value.toStringAsFixed(2),
    );
    _commissionRideCtrl = TextEditingController(
      text: (controller.commissionRide.value * 100).toStringAsFixed(1),
    );
    _commissionC2cCtrl = TextEditingController(
      text: (controller.commissionC2c.value * 100).toStringAsFixed(1),
    );
    _commissionB2bCtrl = TextEditingController(
      text: (controller.commissionB2b.value * 100).toStringAsFixed(1),
    );
    _minBidRadiusCtrl = TextEditingController(
      text: controller.minBidRadius.value.toStringAsFixed(2),
    );
    _bidTimeoutCtrl = TextEditingController(
      text: controller.bidTimeout.value.toStringAsFixed(2),
    );
    _referrerRewardCtrl = TextEditingController(
      text: controller.referrerReward.value.toStringAsFixed(2),
    );
    _refereeRewardCtrl = TextEditingController(
      text: controller.refereeReward.value.toStringAsFixed(2),
    );
    _supportPhoneCtrl = TextEditingController(
      text: controller.supportPhone.value,
    );
    _supportEmailCtrl = TextEditingController(
      text: controller.supportEmail.value,
    );

    // Workers sync Rx → text when config reloads or resets
    _workers.addAll([
      ever(controller.baseFare, (v) => _sync(_baseFareCtrl, v.toStringAsFixed(2))),
      ever(controller.pricePerKm, (v) => _sync(_pricePerKmCtrl, v.toStringAsFixed(2))),
      ever(controller.pricePerMin, (v) => _sync(_pricePerMinCtrl, v.toStringAsFixed(2))),
      ever(controller.surgeMultiplier, (v) => _sync(_surgeMultiplierCtrl, v.toStringAsFixed(2))),
      ever(controller.commissionRide, (v) => _sync(_commissionRideCtrl, (v * 100).toStringAsFixed(1))),
      ever(controller.commissionC2c, (v) => _sync(_commissionC2cCtrl, (v * 100).toStringAsFixed(1))),
      ever(controller.commissionB2b, (v) => _sync(_commissionB2bCtrl, (v * 100).toStringAsFixed(1))),
      ever(controller.minBidRadius, (v) => _sync(_minBidRadiusCtrl, v.toStringAsFixed(2))),
      ever(controller.bidTimeout, (v) => _sync(_bidTimeoutCtrl, v.toStringAsFixed(2))),
      ever(controller.referrerReward, (v) => _sync(_referrerRewardCtrl, v.toStringAsFixed(2))),
      ever(controller.refereeReward, (v) => _sync(_refereeRewardCtrl, v.toStringAsFixed(2))),
      ever(controller.supportPhone, (v) => _sync(_supportPhoneCtrl, v)),
      ever(controller.supportEmail, (v) => _sync(_supportEmailCtrl, v)),
    ]);
  }

  void _sync(TextEditingController ctrl, String text) {
    if (ctrl.text != text) {
      ctrl.text = text;
    }
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    _baseFareCtrl.dispose();
    _pricePerKmCtrl.dispose();
    _pricePerMinCtrl.dispose();
    _surgeMultiplierCtrl.dispose();
    _commissionRideCtrl.dispose();
    _commissionC2cCtrl.dispose();
    _commissionB2bCtrl.dispose();
    _minBidRadiusCtrl.dispose();
    _bidTimeoutCtrl.dispose();
    _referrerRewardCtrl.dispose();
    _refereeRewardCtrl.dispose();
    _supportPhoneCtrl.dispose();
    _supportEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final authController = Get.find<AdminAuthController>();

    if (!authController.isSuperAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: colors.textMuted),
              const SizedBox(height: 16),
              Text(
                'admin.config.super_admin_only'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'admin.config.super_admin_only_description'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppLoading());
        }

        return Column(
          children: [
            // Unsaved changes banner
            if (controller.hasUnsavedChanges)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: colors.warning.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: colors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'admin.config.unsaved_changes'.tr,
                        style: TextStyle(
                          color: colors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AppButton(
                      text: 'admin.config.save'.tr,
                      onPressed: controller.saveConfig,
                      isLoading: controller.isSaving.value,
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      text: 'admin.config.reset'.tr,
                      onPressed: controller.resetToSaved,
                      variant: ButtonVariant.text,
                    ),
                  ],
                ),
              ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.config.title'.tr,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'admin.config.description'.tr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Maintenance Mode Toggle
                    _buildMaintenanceCard(context, colors),
                    const SizedBox(height: 24),

                    // Pricing
                    _buildSection(
                      context,
                      title: 'admin.config.pricing'.tr,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.base_fare'.tr,
                                ctrl: _baseFareCtrl,
                                rxValue: controller.baseFare,
                                suffix: 'currency.egp'.tr,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.price_per_km'.tr,
                                ctrl: _pricePerKmCtrl,
                                rxValue: controller.pricePerKm,
                                suffix: '${'currency.egp'.tr}/km',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.price_per_min'.tr,
                                ctrl: _pricePerMinCtrl,
                                rxValue: controller.pricePerMin,
                                suffix: '${'currency.egp'.tr}/min',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.surge_multiplier'.tr,
                                ctrl: _surgeMultiplierCtrl,
                                rxValue: controller.surgeMultiplier,
                                suffix: 'x',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Commission Rates
                    _buildSection(
                      context,
                      title: 'admin.config.commission_rates'.tr,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.commission_ride'.tr,
                                ctrl: _commissionRideCtrl,
                                rxValue: controller.commissionRide,
                                suffix: '%',
                                isPercentage: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.commission_c2c'.tr,
                                ctrl: _commissionC2cCtrl,
                                rxValue: controller.commissionC2c,
                                suffix: '%',
                                isPercentage: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.commission_b2b'.tr,
                                ctrl: _commissionB2bCtrl,
                                rxValue: controller.commissionB2b,
                                suffix: '%',
                                isPercentage: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bidding Settings
                    _buildSection(
                      context,
                      title: 'admin.config.bidding_settings'.tr,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.min_bid_radius'.tr,
                                ctrl: _minBidRadiusCtrl,
                                rxValue: controller.minBidRadius,
                                suffix: 'km',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.bid_timeout'.tr,
                                ctrl: _bidTimeoutCtrl,
                                rxValue: controller.bidTimeout,
                                suffix: 'seconds',
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Referral Rewards
                    _buildSection(
                      context,
                      title: 'admin.config.referral_rewards'.tr,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.referrer_reward'.tr,
                                ctrl: _referrerRewardCtrl,
                                rxValue: controller.referrerReward,
                                suffix: 'currency.egp'.tr,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumField(
                                context,
                                label: 'admin.config.referee_reward'.tr,
                                ctrl: _refereeRewardCtrl,
                                rxValue: controller.refereeReward,
                                suffix: 'currency.egp'.tr,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Support Contact
                    _buildSection(
                      context,
                      title: 'admin.config.support_contact'.tr,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTxtField(
                                context,
                                label: 'admin.config.support_phone'.tr,
                                ctrl: _supportPhoneCtrl,
                                rxValue: controller.supportPhone,
                                hint: '+201000000000',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTxtField(
                                context,
                                label: 'admin.config.support_email'.tr,
                                ctrl: _supportEmailCtrl,
                                rxValue: controller.supportEmail,
                                hint: 'support@bikeride.eg',
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          text: 'admin.config.reset'.tr,
                          onPressed: controller.resetToSaved,
                          variant: ButtonVariant.outline,
                        ),
                        const SizedBox(width: 16),
                        AppButton(
                          text: 'admin.config.save'.tr,
                          onPressed: controller.saveConfig,
                          isLoading: controller.isSaving.value,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ==================== Helper Builders ====================

  Widget _buildMaintenanceCard(
    BuildContext context,
    AppColorsExtension colors,
  ) {
    return AppCard(
      padding: 24,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.config.maintenance_mode'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'admin.config.maintenance_mode_description'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: controller.maintenanceMode.value,
              onChanged: (value) async {
                if (value) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => ConfirmDialog(
                      title: 'admin.config.enable_maintenance_mode'.tr,
                      message:
                          'admin.config.enable_maintenance_mode_warning'.tr,
                      confirmLabel: 'admin.config.enable'.tr,
                      cancelLabel: 'admin.config.cancel'.tr,
                      isDestructive: true,
                    ),
                  );
                  if (confirmed ?? false) {
                    controller.toggleMaintenanceMode(value);
                  }
                } else {
                  controller.toggleMaintenanceMode(value);
                }
              },
              activeThumbColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return AppCard(
      padding: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumField(
    BuildContext context, {
    required String label,
    required TextEditingController ctrl,
    required RxDouble rxValue,
    required String suffix,
    bool isPercentage = false,
  }) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colors.surfaceContainer,
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          rxValue.value = isPercentage ? parsed / 100 : parsed;
        }
      },
    );
  }

  Widget _buildTxtField(
    BuildContext context, {
    required String label,
    required TextEditingController ctrl,
    required RxString rxValue,
    required TextInputType keyboardType,
    String? hint,
  }) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colors.surfaceContainer,
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      onChanged: (text) {
        rxValue.value = text;
      },
    );
  }
}
