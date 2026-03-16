import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Interactive 5-star rating widget with tinted background container
class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({
    required this.rating,
    required this.onRatingChanged,
    this.size = 36,
    this.spacing = 8,
    super.key,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ext.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: ext.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final starIndex = index + 1;
          final isActive = starIndex <= rating;
          return GestureDetector(
            onTap: () => onRatingChanged(starIndex),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Icon(
                isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: isActive ? AppTheme.orange : ext.borderSubtle,
              ),
            ),
          );
        }),
      ),
    );
  }
}
