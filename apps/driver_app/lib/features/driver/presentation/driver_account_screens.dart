part of '../driver_screens.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(driverAccountProvider);
    final email = ref.read(driverServiceProvider).currentEmail ?? 'غير متاح';
    return DriverShell(
      selectedIndex: 3,
      title: 'الحساب',
      child: ListView(
        padding: const EdgeInsets.all(DriverSpace.md),
        children: [
          DriverCard(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  child: Icon(Icons.person_rounded, size: 38),
                ),
                const SizedBox(height: DriverSpace.md),
                Text(
                  email,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DriverSpace.md),
          account.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => DriverErrorState(
              message: driverErrorMessage(error),
              onRetry: () => ref.invalidate(driverAccountProvider),
            ),
            data: (value) => value == null
                ? const DriverCard(
                    child: Text(
                      'لا يوجد سجل سائق لهذا الحساب. إنشاء سجل السائق يتم من جهة موثوقة.',
                    ),
                  )
                : DriverCard(
                    child: Column(
                      children: [
                        _ProfileRow(
                          label: 'حالة السائق',
                          value: driverStatusLabel(value.status),
                        ),
                        const Divider(height: DriverSpace.lg),
                        _ProfileRow(
                          label: 'نوع الحساب',
                          value: driverTypeLabel(value.type),
                        ),
                        const Divider(height: DriverSpace.lg),
                        _ProfileRow(
                          label: 'الجهة',
                          value: value.officeId == null
                              ? 'مستقل'
                              : 'مرتبط بمكتب',
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: DriverSpace.lg),
          DriverCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('التحقق والمستندات'),
              subtitle: const Text('حالة الحساب والدراجة وتجديد المستندات'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => context.push('/verification'),
            ),
          ),
          const SizedBox(height: DriverSpace.lg),
          const SafeSignOutButton(),
        ],
      ),
    );
  }
}

class DriverVerificationScreen extends ConsumerStatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  ConsumerState<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState
    extends ConsumerState<DriverVerificationScreen> {
  String? _busyType;
  String? _message;

  static const _driverTypes = [
    'NATIONAL_ID',
    'DRIVING_LICENSE',
    'DRIVER_SELFIE',
  ];
  static const _motorcycleTypes = [
    'MOTORCYCLE_REGISTRATION',
    'OWNERSHIP_AUTHORIZATION',
    'MOTORCYCLE_PHOTO',
    'INSURANCE',
    'INSPECTION',
  ];

  Future<void> _confirmSafetyEquipment() async {
    if (_busyType != null) return;
    setState(() {
      _busyType = 'HELMET';
      _message = null;
    });
    try {
      await ref.read(driverServiceProvider).confirmRideSafetyEquipment();
      ref.invalidate(driverVerificationProvider);
      await ref.read(driverVerificationProvider.future);
      if (mounted) setState(() => _message = 'تم حفظ إقرار معدات الأمان.');
    } catch (error) {
      if (mounted) setState(() => _message = driverErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busyType = null);
    }
  }

  Future<void> _upload(
    String type, {
    required DriverVerificationOverview overview,
    required bool motorcycle,
  }) async {
    if (_busyType != null) return;
    DateTime? expiryDate;
    if (type == 'DRIVING_LICENSE') {
      expiryDate = await showDatePicker(
        context: context,
        firstDate: DateUtils.dateOnly(
          DateTime.now().add(const Duration(days: 1)),
        ),
        lastDate: DateTime(DateTime.now().year + 10, 12, 31),
        initialDate: DateTime.now().add(const Duration(days: 365)),
        helpText: 'تاريخ انتهاء رخصة القيادة',
      );
      if (expiryDate == null || !mounted) return;
    }
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (!mounted || picked.isEmpty) return;
    final file = picked.single;
    final bytes = await file.readAsBytes();
    final extension = file.extension?.toLowerCase();
    if (extension == null ||
        !const {'jpg', 'jpeg', 'png', 'pdf'}.contains(extension)) {
      setState(() => _message = 'تعذر قراءة الملف المختار.');
      return;
    }
    setState(() {
      _busyType = type;
      _message = null;
    });
    try {
      final service = ref.read(driverServiceProvider);
      final account = await ref.read(driverAccountProvider.future);
      if (account == null) {
        throw const DriverAppException('لا يوجد حساب سائق لهذا المستخدم.');
      }
      if (motorcycle) {
        final bike = overview.motorcycle;
        if (bike == null) {
          throw const DriverAppException('لا توجد دراجة مسجلة لهذا السائق.');
        }
        await service.submitMotorcycleDocument(
          driverId: account.id,
          motorcycleId: bike.id,
          type: type,
          bytes: bytes,
          extension: extension,
          expiryDate: expiryDate,
        );
      } else {
        await service.submitDriverDocument(
          driverId: account.id,
          type: type,
          bytes: bytes,
          extension: extension,
          expiryDate: expiryDate,
        );
      }
      ref.invalidate(driverVerificationProvider);
      await ref.read(driverVerificationProvider.future);
      if (mounted) {
        setState(() => _message = 'تم رفع المستند وإرساله للمراجعة.');
      }
    } catch (error) {
      if (mounted) setState(() => _message = driverErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busyType = null);
    }
  }

  VerificationDocument? _find(
    List<VerificationDocument> documents,
    String type,
  ) {
    for (final document in documents) {
      if (document.type == type) return document;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final verification = ref.watch(driverVerificationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق والمستندات'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => ref.invalidate(driverVerificationProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: verification.when(
          loading: () => const DriverLoadingState(),
          error: (error, _) => DriverErrorState(
            message: driverErrorMessage(error),
            onRetry: () => ref.invalidate(driverVerificationProvider),
          ),
          data: (overview) => ListView(
            padding: const EdgeInsets.all(DriverSpace.md),
            children: [
              DriverCard(
                color:
                    (overview.readyForNewWork
                            ? DriverColors.success
                            : DriverColors.warning)
                        .withValues(alpha: .08),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      overview.readyForNewWork
                          ? Icons.verified_rounded
                          : Icons.pending_actions_rounded,
                      color: overview.readyForNewWork
                          ? DriverColors.success
                          : DriverColors.warning,
                    ),
                    const SizedBox(width: DriverSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            overview.readyForNewWork
                                ? 'جاهز لاستقبال طلبات جديدة'
                                : 'غير جاهز لطلبات جديدة',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          if (overview.safetyReason != null) ...[
                            const SizedBox(height: DriverSpace.xs),
                            Text(overview.safetyReason!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DriverSpace.md),
              if (!overview.safetyEquipmentConfirmed) ...[
                DriverCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'معدات أمان الرحلات',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: DriverSpace.xs),
                      const Text(
                        'أقر بتوفر خوذة للسائق وخوذة إضافية للراكب عند تنفيذ الرحلات.',
                      ),
                      const SizedBox(height: DriverSpace.sm),
                      FilledButton(
                        onPressed: _busyType == null
                            ? _confirmSafetyEquipment
                            : null,
                        child: const Text('تأكيد توفر معدات الأمان'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DriverSpace.md),
              ],
              _VerificationSection(
                title: 'مستندات السائق المطلوبة',
                children: [
                  for (final type in _driverTypes)
                    _VerificationDocumentTile(
                      type: type,
                      document: _find(overview.driverDocuments, type),
                      busy: _busyType == type,
                      onUpload: () =>
                          _upload(type, overview: overview, motorcycle: false),
                    ),
                ],
              ),
              const SizedBox(height: DriverSpace.md),
              _VerificationSection(
                title: 'الدراجة والمستندات التشغيلية',
                subtitle: overview.motorcycle == null
                    ? 'لا توجد دراجة مسجلة.'
                    : '${overview.motorcycle!.brand} ${overview.motorcycle!.model} • ${overview.motorcycle!.plateNumber}',
                children: [
                  if (overview.motorcycle != null)
                    _VerificationStatusLine(
                      label: 'اعتماد الدراجة',
                      status: overview.motorcycle!.verificationStatus,
                      reason: overview.motorcycle!.rejectionReason,
                    ),
                  for (final type in _motorcycleTypes)
                    _VerificationDocumentTile(
                      type: type,
                      document: _find(overview.motorcycleDocuments, type),
                      busy: _busyType == type,
                      onUpload: overview.motorcycle == null
                          ? null
                          : () => _upload(
                              type,
                              overview: overview,
                              motorcycle: true,
                            ),
                    ),
                ],
              ),
              if (_message != null) ...[
                const SizedBox(height: DriverSpace.md),
                Text(_message!, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.title,
    required this.children,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DriverCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        if (subtitle != null) ...[
          const SizedBox(height: DriverSpace.xs),
          Text(subtitle!, style: const TextStyle(color: DriverColors.muted)),
        ],
        const SizedBox(height: DriverSpace.sm),
        ...children,
      ],
    ),
  );
}

class _VerificationDocumentTile extends StatelessWidget {
  const _VerificationDocumentTile({
    required this.type,
    required this.document,
    required this.busy,
    required this.onUpload,
  });
  final String type;
  final VerificationDocument? document;
  final bool busy;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Divider(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_documentLabel(type)),
                const SizedBox(height: 2),
                Text(
                  document == null
                      ? 'غير مرفوع'
                      : _documentStatusLabel(document!.status),
                  style: TextStyle(
                    color: _documentStatusColor(document?.status),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (document?.expiryDate != null)
                  Text('ينتهي: ${_shortDate(document!.expiryDate!)}'),
                if (document?.rejectionReason != null)
                  Text(
                    document!.rejectionReason!,
                    style: const TextStyle(color: DriverColors.error),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : onUpload,
            child: Text(busy ? 'جاري الرفع...' : 'رفع/تجديد'),
          ),
        ],
      ),
    ],
  );
}

class _VerificationStatusLine extends StatelessWidget {
  const _VerificationStatusLine({
    required this.label,
    required this.status,
    this.reason,
  });
  final String label;
  final DocumentStatus status;
  final String? reason;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: reason == null ? null : Text(reason!),
    trailing: Text(
      _documentStatusLabel(status),
      style: TextStyle(
        color: _documentStatusColor(status),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String _documentLabel(String type) => switch (type) {
  'NATIONAL_ID' => 'بطاقة الرقم القومي',
  'DRIVING_LICENSE' => 'رخصة القيادة',
  'DRIVER_SELFIE' => 'صورة السائق',
  'MOTORCYCLE_REGISTRATION' => 'رخصة الدراجة',
  'OWNERSHIP_AUTHORIZATION' => 'الملكية أو التفويض',
  'MOTORCYCLE_PHOTO' => 'صورة الدراجة',
  'INSURANCE' => 'التأمين',
  'INSPECTION' => 'الفحص',
  _ => type,
};

String _documentStatusLabel(DocumentStatus status) => switch (status) {
  DocumentStatus.pending => 'قيد المراجعة',
  DocumentStatus.approved => 'معتمد',
  DocumentStatus.rejected => 'مرفوض',
  DocumentStatus.expired => 'منتهي',
};

Color _documentStatusColor(DocumentStatus? status) => switch (status) {
  DocumentStatus.approved => DriverColors.success,
  DocumentStatus.rejected || DocumentStatus.expired => DriverColors.error,
  _ => DriverColors.warning,
};

String _shortDate(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: const TextStyle(color: DriverColors.muted)),
      const SizedBox(width: DriverSpace.md),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}
