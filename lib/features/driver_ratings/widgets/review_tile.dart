import 'package:biko/core/models/rating_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tile showing a single customer review.
///
/// Matches stitch design: avatar placeholder, star row,
/// comment text, and chip tags in bordered container.
class ReviewTile extends StatelessWidget {
  const ReviewTile({required this.rating, super.key});

  final RatingModel rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ext.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: ext.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + stars + date
            Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ext.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: ext.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                // Stars
                Expanded(
                  child: Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating.score
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: ext.warning,
                        size: 18,
                      );
                    }),
                  ),
                ),
                Text(
                  dateFormat.format(rating.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ext.textMuted,
                  ),
                ),
              ],
            ),
            // Comment
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                rating.comment!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            // Chips
            if (rating.chips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: rating.chips.map((chip) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ext.surfaceContainer,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusFull,
                      ),
                    ),
                    child: Text(
                      chip,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
