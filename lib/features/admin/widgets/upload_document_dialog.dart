import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadDocumentDialog extends StatefulWidget {
  const UploadDocumentDialog({
    required this.driverUid,
    super.key,
  });

  final String driverUid;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String driverUid,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => UploadDocumentDialog(driverUid: driverUid),
    );
  }

  @override
  State<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<UploadDocumentDialog> {
  DocumentType _documentType = DocumentType.nationalId;
  String? _selectedFileName;

  void _pickFile() {
    // File picker placeholder -- actual implementation depends on
    // file_picker or similar package being available.
    setState(() {
      _selectedFileName = 'selected_file.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.documents.upload_title'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DocumentType>(
                initialValue: _documentType,
                decoration: InputDecoration(
                  labelText: 'admin.documents.type'.tr,
                ),
                items: DocumentType.values
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          'admin.documents.type_${d.name}'.tr,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _documentType = v);
                  }
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFileName != null
                            ? Icons.insert_drive_file
                            : Icons.cloud_upload_outlined,
                        size: 40,
                        color: _selectedFileName != null
                            ? colors.success
                            : colors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFileName ??
                            'admin.documents.tap_to_select'.tr,
                        style: TextStyle(
                          color: _selectedFileName != null
                              ? null
                              : colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
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
                      text: 'admin.documents.upload'.tr,
                      onPressed: _selectedFileName == null
                          ? null
                          : () {
                              Navigator.pop(context, {
                                'driver_uid': widget.driverUid,
                                'document_type': _documentType.toJson(),
                                'file_name': _selectedFileName,
                              });
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
