part of '../driver_screens.dart';

/// The presentation-to-service seam for the independent application flow.
class DriverOnboardingApplication {
  const DriverOnboardingApplication({
    required this.fullName,
    required this.phone,
    required this.dateOfBirth,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.color,
    this.modelYear,
  });

  final String fullName;
  final String phone;
  final DateTime dateOfBirth;
  final String plateNumber;
  final String brand;
  final String model;
  final String color;
  final int? modelYear;
}

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({
    required this.onSubmit,
    this.onSubmitted,
    this.initialDateOfBirth,
    super.key,
  });

  final Future<void> Function(DriverOnboardingApplication application) onSubmit;
  final VoidCallback? onSubmitted;

  /// Allows a trusted route/restoration layer to repopulate a selected date.
  final DateTime? initialDateOfBirth;

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _plateNumber = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  final _modelYear = TextEditingController();
  DateTime? _dateOfBirth;
  String? _dateError;
  String? _message;
  bool _busy = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _dateOfBirth = widget.initialDateOfBirth;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _plateNumber.dispose();
    _brand.dispose();
    _model.dispose();
    _color.dispose();
    _modelYear.dispose();
    super.dispose();
  }

  Future<void> _chooseDateOfBirth() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final latest = DateTime(today.year - 21, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: latest,
      initialDate:
          _dateOfBirth ?? DateTime(today.year - 25, today.month, today.day),
      helpText: 'تاريخ الميلاد',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _dateOfBirth = picked;
      _dateError = null;
      _message = null;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    final today = DateUtils.dateOnly(DateTime.now());
    final latestBirthDate = DateTime(today.year - 21, today.month, today.day);
    if (_dateOfBirth == null) {
      setState(() => _dateError = 'اختر تاريخ الميلاد.');
    } else if (_dateOfBirth!.isAfter(latestBirthDate)) {
      setState(() => _dateError = 'يجب أن يكون العمر 21 عامًا على الأقل.');
    }
    if (!valid ||
        _dateOfBirth == null ||
        _dateOfBirth!.isAfter(latestBirthDate) ||
        _busy) {
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.onSubmit(
        DriverOnboardingApplication(
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim(),
          dateOfBirth: _dateOfBirth!,
          plateNumber: _plateNumber.text.trim(),
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          color: _color.text.trim(),
          modelYear: int.tryParse(_modelYear.text.trim()),
        ),
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _message = null;
      });
    } catch (error) {
      if (mounted) setState(() => _message = driverErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('طلب الانضمام كسائق')),
    body: SafeArea(
      top: false,
      child: _submitted
          ? _SubmittedView(onContinue: widget.onSubmitted)
          : _form(),
    ),
  );

  Widget _form() => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(DriverSpace.md),
      children: [
        DriverCard(
          color: DriverColors.primary.withValues(alpha: .06),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.two_wheeler_rounded,
                color: DriverColors.primary,
              ),
              const SizedBox(width: DriverSpace.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سائق مستقل',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: DriverSpace.xs),
                    Text(
                      'أرسل بياناتك للمراجعة. لا يصبح الحساب نشطًا قبل الاعتماد.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DriverSpace.lg),
        const _OnboardingSectionTitle('البيانات الشخصية'),
        const SizedBox(height: DriverSpace.sm),
        _field(
          key: const Key('driver-full-name-field'),
          controller: _fullName,
          label: 'الاسم بالكامل',
          validator: (value) => _required(value, 'اكتب الاسم بالكامل.'),
        ),
        const SizedBox(height: DriverSpace.sm),
        _field(
          key: const Key('driver-phone-field'),
          controller: _phone,
          label: 'رقم الهاتف (اختياري)',
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          validator: _phoneValidator,
        ),
        const SizedBox(height: DriverSpace.sm),
        _dateField(),
        const SizedBox(height: DriverSpace.lg),
        const _OnboardingSectionTitle('بيانات الدراجة'),
        const SizedBox(height: DriverSpace.sm),
        _field(
          key: const Key('driver-plate-number-field'),
          controller: _plateNumber,
          label: 'رقم اللوحة',
          textDirection: TextDirection.ltr,
          validator: (value) => _required(value, 'اكتب رقم اللوحة.'),
        ),
        const SizedBox(height: DriverSpace.sm),
        Row(
          children: [
            Expanded(
              child: _field(
                key: const Key('driver-brand-field'),
                controller: _brand,
                label: 'الماركة',
                validator: (value) => _required(value, 'اكتب ماركة الدراجة.'),
              ),
            ),
            const SizedBox(width: DriverSpace.sm),
            Expanded(
              child: _field(
                key: const Key('driver-model-field'),
                controller: _model,
                label: 'الموديل',
                validator: (value) => _required(value, 'اكتب موديل الدراجة.'),
              ),
            ),
          ],
        ),
        const SizedBox(height: DriverSpace.sm),
        Row(
          children: [
            Expanded(
              child: _field(
                key: const Key('driver-color-field'),
                controller: _color,
                label: 'اللون',
                validator: (value) => _required(value, 'اكتب لون الدراجة.'),
              ),
            ),
            const SizedBox(width: DriverSpace.sm),
            Expanded(
              child: _field(
                key: const Key('driver-model-year-field'),
                controller: _modelYear,
                label: 'سنة الموديل (اختياري)',
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                validator: _modelYearValidator,
              ),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: DriverSpace.md),
          Text(
            _message!,
            key: const Key('driver-onboarding-message'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: DriverColors.error),
          ),
        ],
        const SizedBox(height: DriverSpace.lg),
        FilledButton(
          key: const Key('driver-onboarding-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'جاري إرسال الطلب...' : 'إرسال الطلب للمراجعة'),
        ),
        const SizedBox(height: DriverSpace.sm),
        const Text(
          'سيظل الحساب قيد المراجعة حتى تنتهي جهة التحقق من فحص البيانات والمستندات.',
          textAlign: TextAlign.center,
          style: TextStyle(color: DriverColors.muted, height: 1.4),
        ),
      ],
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    Key? key,
    TextInputType? keyboardType,
    TextDirection? textDirection,
  }) => TextFormField(
    key: key,
    controller: controller,
    keyboardType: keyboardType,
    textDirection: textDirection,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );

  Widget _dateField() => InkWell(
    key: const Key('driver-date-of-birth-field'),
    onTap: _busy ? null : _chooseDateOfBirth,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'تاريخ الميلاد',
        errorText: _dateError,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      child: Text(
        _dateOfBirth == null ? 'اختر تاريخ الميلاد' : _dateLabel(_dateOfBirth!),
        style: TextStyle(
          color: _dateOfBirth == null ? DriverColors.muted : DriverColors.text,
        ),
      ),
    ),
  );

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return null;
    if (!RegExp(r'^[+]?[0-9][0-9 ()-]*$').hasMatch(phone)) {
      return 'اكتب رقم هاتف صحيحًا.';
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length < 6 || digits.length > 32
        ? 'يجب أن يحتوي الهاتف على 6 إلى 32 رقمًا.'
        : null;
  }

  String? _modelYearValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final year = int.tryParse(text);
    return year == null || year < 1950 || year > 2100
        ? 'اكتب سنة بين 1950 و2100.'
        : null;
  }

  static String? _required(String? value, String message) =>
      value?.trim().isEmpty != false ? message : null;

  static String _dateLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _OnboardingSectionTitle extends StatelessWidget {
  const _OnboardingSectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
  );
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({this.onContinue});
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(DriverSpace.md),
    children: [
      DriverCard(
        color: DriverColors.success.withValues(alpha: .08),
        child: Column(
          children: [
            const Icon(
              Icons.pending_actions_rounded,
              size: 48,
              color: DriverColors.warning,
            ),
            const SizedBox(height: DriverSpace.md),
            const Text(
              'تم إرسال طلبك للمراجعة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: DriverSpace.sm),
            const Text(
              'حالة السائق والدراجة الآن: قيد المراجعة.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      if (onContinue != null) ...[
        const SizedBox(height: DriverSpace.lg),
        FilledButton(onPressed: onContinue, child: const Text('متابعة')),
      ],
    ],
  );
}
