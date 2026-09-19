import 'dart:async';
import 'dart:typed_data';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/profile/profile_model.dart';
import 'package:user_app/features/profile/profile_provider.dart';
import 'package:user_app/features/profile/profile_service.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  XFile? _newPhoto;
  Uint8List? _previewBytes;
  bool _editing = false;
  bool _removePhoto = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _startEditing(CustomerProfile profile) {
    _name.text = profile.fullName;
    _phone.text = profile.phone ?? '';
    setState(() => _editing = true);
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      ProfilePhoto.fromBytes(bytes);
      if (!mounted) return;
      setState(() {
        _newPhoto = photo;
        _previewBytes = bytes;
        _removePhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر اختيار الصورة. اختر JPG أو PNG أو WebP بحجم حتى 2 ميجابايت.',
          ),
        ),
      );
    }
  }

  Future<void> _save(CustomerProfile profile) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileServiceProvider)
          .save(
            current: profile,
            fullName: _name.text,
            phone: _phone.text.trim().isEmpty ? null : _phone.text,
            newPhoto: _newPhoto,
            removePhoto: _removePhoto,
          );
      if (!mounted) return;
      ref.invalidate(profileProvider);
      setState(() {
        _editing = false;
        _newPhoto = null;
        _previewBytes = null;
        _removePhoto = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات الحساب.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_saveErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BikoSpace.md,
        BikoSpace.sm,
        BikoSpace.md,
        BikoSpace.xl,
      ),
      children: [
        profile.when(
          loading: () => const LoadingSkeleton(),
          error: (error, _) => UserErrorState(
            message: classifyReadError(error).message,
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (value) => _editing
              ? _ProfileEditor(
                  formKey: _formKey,
                  name: _name,
                  phone: _phone,
                  photoUrl: _removePhoto ? null : value.photoUrl,
                  previewBytes: _previewBytes,
                  hasNewPhoto: _newPhoto != null,
                  hasPhoto: value.photoPath != null,
                  saving: _saving,
                  onPickPhoto: _pickPhoto,
                  onRemovePhoto: () => setState(() {
                    _newPhoto = null;
                    _previewBytes = null;
                    _removePhoto = true;
                  }),
                  onCancel: () => setState(() {
                    _editing = false;
                    _newPhoto = null;
                    _previewBytes = null;
                    _removePhoto = false;
                  }),
                  onSave: () => _save(value),
                )
              : _ProfileSummary(
                  profile: value,
                  onEdit: () => _startEditing(value),
                ),
        ),
        const SizedBox(height: BikoSpace.lg),
        const SafeSignOutButton(),
      ],
    );
  }

  String _saveErrorMessage(Object error) => switch (error) {
    TimeoutException() => 'انتهت مهلة الحفظ. تحقق من اتصالك ثم حاول مرة أخرى.',
    ReadFailure(kind: ReadFailureKind.auth) =>
      'انتهت جلسة الحساب. سجّل الدخول ثم حاول مرة أخرى.',
    FormatException() => 'الصورة أو رقم الهاتف غير صالح.',
    _ => 'تعذر حفظ بيانات الحساب. حاول مرة أخرى.',
  };
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile, required this.onEdit});

  final CustomerProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ProfileAvatar(photoUrl: profile.photoUrl),
              const SizedBox(width: BikoSpace.md),
              Expanded(
                child: Text(
                  profile.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                key: const Key('edit-profile'),
                tooltip: 'تعديل الحساب',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: BikoSpace.md),
          _ProfileLine(icon: Icons.email_outlined, value: profile.email),
          if (profile.phone case final phone?) ...[
            const SizedBox(height: BikoSpace.gap),
            _ProfileLine(icon: Icons.phone_outlined, value: phone),
          ],
        ],
      ),
    ),
  );
}

class _ProfileEditor extends StatelessWidget {
  const _ProfileEditor({
    required this.formKey,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.previewBytes,
    required this.hasNewPhoto,
    required this.hasPhoto,
    required this.saving,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onCancel,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController phone;
  final String? photoUrl;
  final Uint8List? previewBytes;
  final bool hasNewPhoto;
  final bool hasPhoto;
  final bool saving;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ProfileAvatar(
                  photoUrl: photoUrl,
                  previewBytes: previewBytes,
                  hasNewPhoto: hasNewPhoto,
                ),
                const SizedBox(width: BikoSpace.md),
                Expanded(
                  child: Wrap(
                    spacing: BikoSpace.xs,
                    runSpacing: BikoSpace.xs,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('pick-profile-photo'),
                        onPressed: saving ? null : onPickPhoto,
                        icon: const Icon(Icons.photo_outlined),
                        label: Text(
                          hasNewPhoto ? 'تم اختيار صورة' : 'تغيير الصورة',
                        ),
                      ),
                      if (hasPhoto || hasNewPhoto)
                        TextButton(
                          onPressed: saving ? null : onRemovePhoto,
                          child: const Text('إزالة'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: BikoSpace.md),
            TextFormField(
              key: const Key('profile-name'),
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'أدخل الاسم الكامل.'
                  : value.trim().length > 100
                  ? 'الاسم طويل جدًا.'
                  : null,
            ),
            const SizedBox(height: BikoSpace.md),
            TextFormField(
              key: const Key('profile-phone'),
              controller: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
                helperText: 'للتواصل فقط، وليس لتسجيل الدخول.',
              ),
              validator: (value) => value != null && value.trim().length > 32
                  ? 'رقم الهاتف طويل جدًا.'
                  : value != null &&
                        value.trim().isNotEmpty &&
                        !ProfilePhone.isValid(value)
                  ? 'أدخل رقم هاتف صحيحًا.'
                  : null,
            ),
            const SizedBox(height: BikoSpace.lg),
            FilledButton(
              key: const Key('save-profile'),
              onPressed: saving ? null : onSave,
              child: Text(saving ? 'جارٍ الحفظ...' : 'حفظ التعديلات'),
            ),
            TextButton(
              onPressed: saving ? null : onCancel,
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    this.photoUrl,
    this.previewBytes,
    this.hasNewPhoto = false,
  });

  final String? photoUrl;
  final Uint8List? previewBytes;
  final bool hasNewPhoto;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 30,
    backgroundColor: UserColors.primarySoft,
    foregroundColor: UserColors.primary,
    foregroundImage: previewBytes != null
        ? MemoryImage(previewBytes!)
        : photoUrl == null
        ? null
        : NetworkImage(photoUrl!),
    onForegroundImageError: previewBytes != null || photoUrl != null
        ? (_, _) {}
        : null,
    child: Icon(
      hasNewPhoto ? Icons.photo_rounded : Icons.person_rounded,
      size: 30,
    ),
  );
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: UserColors.muted),
      const SizedBox(width: BikoSpace.gap),
      Expanded(
        child: Text(
          value,
          textDirection: TextDirection.ltr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
