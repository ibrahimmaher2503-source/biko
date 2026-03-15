import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/admin/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Grid of document cards with status badges (pending/approved/rejected).
///
/// Each card shows a thumbnail, document type label, status badge, and
/// action buttons for approve/reject/view.
class DocumentReviewGrid extends StatelessWidget {
  const DocumentReviewGrid({
    required this.documents,
    required this.onApprove,
    required this.onReject,
    required this.onViewFull,
    super.key,
  });

  /// List of documents to display in the grid.
  final List<DocumentModel> documents;

  /// Called when admin approves a document.
  final Function(String docId) onApprove;

  /// Called when admin rejects a document with a reason.
  final Function(String docId, String reason) onReject;

  /// Called when admin taps a document to view full size.
  final Function(String url) onViewFull;

  String _documentTypeLabel(DocumentModel doc) {
    switch (doc.type.toJson()) {
      case 'national_id':
        return 'admin.documents.national_id'.tr;
      case 'license':
        return 'admin.documents.license'.tr;
      case 'vehicle_registration':
        return 'admin.documents.vehicle_registration'.tr;
      case 'criminal_record':
        return 'admin.documents.criminal_record'.tr;
      default:
        return doc.type.toJson();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: Text(
          'admin.widgets.no_documents'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).extension<AppColorsExtension>()!.textMuted,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _DocumentCard(
          document: doc,
          typeLabel: _documentTypeLabel(doc),
          onApprove: () => onApprove(doc.id),
          onReject: (reason) => onReject(doc.id, reason),
          onViewFull: () => onViewFull(doc.fileUrl),
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.typeLabel,
    required this.onApprove,
    required this.onReject,
    required this.onViewFull,
  });

  final DocumentModel document;
  final String typeLabel;
  final VoidCallback onApprove;
  final Function(String) onReject;
  final VoidCallback onViewFull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail area
          Expanded(
            child: GestureDetector(
              onTap: onViewFull,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLarge),
                  ),
                  color: colors.surfaceContainer,
                  image: document.fileUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(document.fileUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: document.fileUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.description_outlined,
                          size: 40,
                          color: colors.textMuted,
                        ),
                      )
                    : Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.zoom_in,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Info & actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type label + status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        typeLabel,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge.fromDocumentStatus(document.status),
                  ],
                ),
                const SizedBox(height: 8),

                // Admin note if rejected
                if (document.adminNote != null &&
                    document.adminNote!.isNotEmpty) ...[
                  Text(
                    document.adminNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Action buttons for pending documents
                if (document.status.toJson() == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () => onReject(''),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusDefault,
                                ),
                              ),
                            ),
                            child: Text(
                              'admin.users.reject'.tr,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: FilledButton(
                            onPressed: onApprove,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusDefault,
                                ),
                              ),
                            ),
                            child: Text(
                              'admin.users.approve'.tr,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
