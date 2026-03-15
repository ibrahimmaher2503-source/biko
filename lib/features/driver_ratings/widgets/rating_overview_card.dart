import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Card showing average rating, total count, and star distribution.
///
/// Matches stitch design: large rating number with star icons,
/// smooth progress bars for distribution, and clean layout.
class RatingOverviewCard extends StatelessWidget {
  const RatingOverviewCard({
    required this.averageRating,
    required this.totalRatings,
    required this.distribution,
    super.key,
  });

  final double averageRating;
  final int totalRatings;
  final Map<int, int> distribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Average rating section
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Large score with star icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Icon(
                              Icons.star_rounded,
                              color: ext.warning,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Star row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: ext.warning,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      // Total count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ext.warningBg,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          '$totalRatings ${'ratings.total_reviews'.tr}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ext.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Star distribution
                Expanded(
                  flex: 3,
                  child: Column(
                    children: List.generate(5, (index) {
                      final star = 5 - index;
                      final count = distribution[star] ?? 0;
                      final percentage =
                          totalRatings > 0 ? count / totalRatings : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              child: Text(
                                '$star',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star_rounded,
                              color: ext.warning,
                              size: 12,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: ext.surfaceContainer,
                                  color: ext.warning,
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '$count',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: ext.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
