import 'dart:ui';

import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/onboarding/data/onboarding_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single onboarding slide — illustration with decorative blur blob,
/// headline with highlighted word in primary color, and description
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({required this.slide, super.key});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final titleText = slide.title.tr;
    final highlightText = slide.highlightWord.tr;
    final descText = slide.description.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration with decorative blur blob
          SizedBox(
            width: double.infinity,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Decorative blurred background blob
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                // Main illustration
                Image.asset(
                  slide.illustration,
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Headline with highlighted word
          _buildTitle(context, titleText, highlightText),
          const SizedBox(height: 16),
          // Description
          Text(
            descText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String fullTitle, String highlight) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.2,
    );

    // Split title around the highlight word
    final parts = fullTitle.split(highlight);
    if (parts.length < 2) {
      // Highlight word not found — render plain
      return Text(fullTitle, style: style, textAlign: TextAlign.center);
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: highlight,
            style: const TextStyle(color: AppTheme.primary),
          ),
          TextSpan(text: parts.sublist(1).join(highlight)),
        ],
      ),
    );
  }
}
