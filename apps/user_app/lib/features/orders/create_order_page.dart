import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_rules.dart';
import 'package:user_app/features/maps/location_picker_page.dart';
import 'package:user_app/features/maps/route_preview_map.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({
    required this.service,
    this.prefill,
    this.onCreated,
    super.key,
  });

  final ServiceType service;
  final OrderDraft? prefill;
  final ValueChanged<CustomerOrder>? onCreated;

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _weight = TextEditingController();
  final _declaredValue = TextEditingController();
  late final MutationReconciler _reconciler;
  LocationSelection? _pickup;
  LocationSelection? _destination;
  RouteQuote? _quote;
  bool _quoteLoading = false;
  String? _quoteError;
  int _quoteGeneration = 0;
  String? _intentId;
  CustomerOrder? _createdOrder;
  String? _error;

  bool get _busy => _reconciler.blocksActions;

  @override
  void initState() {
    super.initState();
    _reconciler = MutationReconciler()..addListener(_changed);
    final prefill = widget.prefill;
    _pickup = prefill?.pickup;
    _destination = prefill?.destination;
    if (prefill != null) {
      if (prefill.proposedPrice > 0) {
        _price.text = formatAmount(prefill.proposedPrice);
      }
      _recipientName.text = prefill.delivery?.recipientName ?? '';
      _recipientPhone.text = prefill.delivery?.recipientPhone ?? '';
      _weight.text = prefill.delivery == null
          ? ''
          : formatAmount(prefill.delivery!.parcelWeightKg);
      _declaredValue.text = prefill.delivery == null
          ? ''
          : formatAmount(prefill.delivery!.declaredValue);
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQuote());
    }
    for (final controller in [
      _price,
      _recipientName,
      _recipientPhone,
      _weight,
      _declaredValue,
    ]) {
      controller.addListener(_payloadChanged);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _payloadChanged() {
    if (!_busy && _createdOrder == null) _intentId = null;
  }

  @override
  void dispose() {
    _reconciler.removeListener(_changed);
    _reconciler.dispose();
    _price.dispose();
    _recipientName.dispose();
    _recipientPhone.dispose();
    _weight.dispose();
    _declaredValue.dispose();
    super.dispose();
  }

  OrderDraft _draft() => OrderDraft(
    service: widget.service,
    pickup: _pickup!,
    destination: _destination!,
    proposedPrice: double.parse(_price.text.trim()),
    routeQuote: _quote,
    delivery: widget.service == ServiceType.delivery
        ? DeliveryDetails(
            recipientName: _recipientName.text.trim(),
            recipientPhone: _recipientPhone.text.trim(),
            parcelWeightKg: double.parse(_weight.text.trim()),
            declaredValue: double.parse(_declaredValue.text.trim()),
          )
        : null,
  );

  Future<void> _selectLocation(bool pickup) async {
    if (_busy) return;
    final value = await pickMapLocation(
      context,
      title: pickup ? 'اختر نقطة الاستلام' : 'اختر الوجهة',
      initial: pickup ? _pickup : _destination,
    );
    if (value == null || !mounted) return;
    setState(() {
      // A changed route invalidates pending quotes even when it is incomplete
      // or has identical endpoints and therefore cannot request a new quote.
      _quoteGeneration++;
      _quoteLoading = false;
      if (pickup) {
        _pickup = value;
      } else {
        _destination = value;
      }
      _quote = null;
      _quoteError = null;
      _intentId = null;
    });
    if (_pickup != null && _destination != null && _pickup != _destination) {
      await _refreshQuote();
    }
  }

  Future<void> _refreshQuote() async {
    final pickup = _pickup;
    final destination = _destination;
    if (pickup == null || destination == null || pickup == destination) return;
    final generation = ++_quoteGeneration;
    setState(() {
      _quoteLoading = true;
      _quoteError = null;
      _quote = null;
      _intentId = null;
    });
    try {
      final quote = await ref
          .read(orderServiceProvider)
          .createRouteQuote(widget.service, pickup, destination);
      if (!mounted || generation != _quoteGeneration) return;
      setState(() {
        _quote = quote;
        _pickup = LocationSelection(
          displayAddress: pickup.displayAddress,
          latitude: quote.pickup.latitude,
          longitude: quote.pickup.longitude,
        );
        _destination = LocationSelection(
          displayAddress: destination.displayAddress,
          latitude: quote.destination.latitude,
          longitude: quote.destination.longitude,
        );
        if (_price.text.trim().isEmpty) {
          _price.text = formatAmount(quote.suggestedPrice);
        }
      });
    } on BusinessFailure catch (error) {
      if (mounted && generation == _quoteGeneration) {
        setState(() => _quoteError = error.message);
      }
    } catch (_) {
      if (mounted && generation == _quoteGeneration) {
        setState(() => _quoteError = 'تعذر حساب المسار الآن.');
      }
    } finally {
      if (mounted && generation == _quoteGeneration) {
        setState(() => _quoteLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    if (_pickup == null || _destination == null) {
      setState(() => _error = 'اختر نقطة الاستلام والوجهة.');
      return;
    }
    if (_pickup == _destination) {
      setState(() => _error = 'اختر وجهة مختلفة عن نقطة الاستلام.');
      return;
    }
    if (_quote == null) {
      setState(() => _error = 'احسب المسار والسعر أولًا.');
      return;
    }
    if (!_quote!.expiresAt.isAfter(DateTime.now().toUtc())) {
      await _refreshQuote();
      if (mounted) {
        setState(
          () => _error = 'تم تحديث عرض المسار. راجع السعر ثم أرسل الطلب.',
        );
      }
      return;
    }
    setState(() {
      _error = null;
      _intentId ??= newCreationIntentId();
    });
    final intent = _intentId!;
    final service = ref.read(orderServiceProvider);
    await _reconciler.run(
      mutate: () async {
        _createdOrder = await service.createOrder(_draft(), intent);
      },
      refresh: () async {
        _createdOrder ??= await service.findByCreationIntent(intent);
        return _createdOrder != null;
      },
      revalidateAuth: ref.read(authServiceProvider).revalidateSession,
    );
    if (!mounted) return;
    if (_createdOrder != null) {
      _finish(_createdOrder!);
    } else if (_reconciler.outcome == MutationOutcome.businessFailure) {
      setState(() => _error = customerMutationMessage(_reconciler.error));
    }
  }

  Future<void> _retryRecovery() async {
    await _reconciler.retryRead();
    if (mounted && _createdOrder != null) _finish(_createdOrder!);
  }

  void _finish(CustomerOrder order) {
    ref.invalidate(activeOrderProvider);
    ref.invalidate(orderHistoryProvider);
    ref.invalidate(orderHistoryPageProvider);
    if (widget.onCreated != null) {
      widget.onCreated!(order);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.service == ServiceType.delivery;
    return Scaffold(
      appBar: AppTopBar(title: delivery ? 'طلب توصيل' : 'طلب رحلة'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              BikoSpace.md,
              BikoSpace.sm,
              BikoSpace.md,
              BikoSpace.xl,
            ),
            children: [
              Row(
                children: [
                  ServiceTypeBadge(code: widget.service.databaseValue),
                  const Spacer(),
                  Text(
                    'المسار والسعر',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: BikoSpace.md),
              Text(
                delivery ? 'أرسل طردك بسهولة' : 'إلى أين تريد الذهاب؟',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: BikoSpace.xs),
              Text(
                delivery
                    ? 'طرد واحد، بيانات واضحة، وسعر نقدي قبل الإرسال.'
                    : 'رحلة لشخص واحد. راجع السعر قبل عرضه على السائقين.',
              ),
              const SizedBox(height: BikoSpace.lg),
              Text('المسار', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: BikoSpace.sm),
              LocationField(
                fieldKey: const Key('pickup-location'),
                label: 'نقطة الاستلام',
                address: _pickup?.displayAddress,
                enabled: !_busy,
                onTap: () => _selectLocation(true),
              ),
              const SizedBox(height: BikoSpace.gap),
              LocationField(
                fieldKey: const Key('destination-location'),
                label: 'الوجهة',
                address: _destination?.displayAddress,
                enabled: !_busy,
                onTap: () => _selectLocation(false),
              ),
              if (_quoteLoading) ...[
                const SizedBox(height: BikoSpace.md),
                const InlineLoading(
                  label: 'جاري حساب المسار والسعر...',
                  icon: Icons.route_rounded,
                ),
              ],
              if (_quoteError != null) ...[
                const SizedBox(height: BikoSpace.md),
                UserInlineMessage(
                  message: _quoteError!,
                  icon: Icons.error_outline,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _quoteLoading ? null : _refreshQuote,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة حساب المسار'),
                  ),
                ),
              ],
              if (_quote case final quote?) ...[
                const SizedBox(height: BikoSpace.md),
                RoutePreviewMap(quote: quote),
                const SizedBox(height: BikoSpace.gap),
                _PricingSummary(quote: quote),
                const SizedBox(height: BikoSpace.gap),
                _ProposedPriceEditor(
                  controller: _price,
                  enabled: !_busy,
                  quote: quote,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              if (delivery) ...[
                const SizedBox(height: BikoSpace.section),
                Card(
                  color: UserColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(BikoSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'المستلم والطرد',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: BikoSpace.sm),
                        Text(
                          'طرد واحد، حتى 8 كجم وقيمة معلنة حتى 3000 ج.م.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: BikoSpace.md),
                        TextFormField(
                          key: const Key('recipient-name'),
                          controller: _recipientName,
                          enabled: !_busy,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستلم',
                          ),
                          validator: (value) =>
                              requiredText(value, 'اسم المستلم مطلوب.'),
                        ),
                        const SizedBox(height: BikoSpace.gap),
                        TextFormField(
                          key: const Key('recipient-phone'),
                          controller: _recipientPhone,
                          enabled: !_busy,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'هاتف المستلم',
                          ),
                          validator: (value) =>
                              requiredText(value, 'هاتف المستلم مطلوب.'),
                        ),
                        const SizedBox(height: BikoSpace.gap),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('parcel-weight'),
                                controller: _weight,
                                enabled: !_busy,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'الوزن (كجم)',
                                ),
                                validator: parcelWeight,
                              ),
                            ),
                            const SizedBox(width: BikoSpace.gap),
                            Expanded(
                              child: TextFormField(
                                key: const Key('declared-value'),
                                controller: _declaredValue,
                                enabled: !_busy,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'القيمة (ج.م)',
                                ),
                                validator: declaredValue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: BikoSpace.gap),
                        const Text(
                          'لا نقبل الأسلحة أو المواد الخطرة أو الحيوانات أو الأدوية المبردة.',
                          style: TextStyle(
                            color: UserColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_quote == null) ...[
                const SizedBox(height: BikoSpace.section),
                _ProposedPriceEditor(
                  controller: _price,
                  enabled: !_busy,
                  quote: null,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: BikoSpace.sm),
                UserInlineMessage(
                  message: _error!,
                  icon: Icons.error_outline_rounded,
                ),
              ],
              if (_reconciler.phase != RecoveryPhase.idle) ...[
                const SizedBox(height: BikoSpace.sm),
                ConnectionStateView(
                  phase: _reconciler.phase,
                  onRetry: _reconciler.phase == RecoveryPhase.unavailable
                      ? _retryRecovery
                      : null,
                ),
              ],
              const SizedBox(height: BikoSpace.lg),
              PrimaryButton(
                key: const Key('create-order'),
                onPressed: _busy || _quoteLoading || _quote == null
                    ? null
                    : _submit,
                icon: Icons.search_rounded,
                label: _busy ? 'جاري التحقق...' : 'عرض على السائقين',
                isLoading: _busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProposedPriceEditor extends StatelessWidget {
  const _ProposedPriceEditor({
    required this.controller,
    required this.enabled,
    required this.quote,
    required this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final RouteQuote? quote;
  final ValueChanged<String> onFieldSubmitted;

  @override
  Widget build(BuildContext context) => Card(
    color: UserColors.primarySoft,
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('سعرك المقترح', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: BikoSpace.xs),
          const Text('هذا هو السعر الذي يراه السائقون.'),
          const SizedBox(height: BikoSpace.sm),
          PriceInput(
            fieldKey: const Key('proposed-price'),
            controller: controller,
            label: 'سعرك',
            supportingText: quote == null
                ? 'احسب المسار أولًا لمعرفة الحد الأدنى.'
                : 'الحد الأدنى ${formatAmount(quote!.minimumCustomerPrice)} ج.م',
            enabled: enabled,
            validator: (value) => proposedPriceForQuote(value, quote),
            onFieldSubmitted: onFieldSubmitted,
          ),
        ],
      ),
    ),
  );
}

class _PricingSummary extends StatelessWidget {
  const _PricingSummary({required this.quote});
  final RouteQuote quote;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('المسار', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: BikoSpace.sm),
          Text(
            '${(quote.distanceMeters / 1000).toStringAsFixed(1)} كم • '
            '${(quote.durationSeconds / 60).ceil()} دقيقة تقريبًا',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: BikoSpace.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: UserColors.primarySoft,
              borderRadius: BorderRadius.circular(BikoRadius.medium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(BikoSpace.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'السعر المقترح من بيكو',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${formatAmount(quote.suggestedPrice)} ج.م',
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BikoSpace.sm),
          Text(
            'الحد الأدنى: ${formatAmount(quote.minimumCustomerPrice)} ج.م. اختر سعرك قبل الإرسال.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}
