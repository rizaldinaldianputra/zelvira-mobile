import 'package:flutter/material.dart';
import 'package:feature_discovery/feature_discovery.dart';
import '../../config/app_style.dart';

class FeatureOverlayPrompt extends StatelessWidget {
  final String description;
  final int step;
  final int totalSteps;
  final bool isLast;

  const FeatureOverlayPrompt({
    super.key,
    required this.description,
    required this.step,
    required this.totalSteps,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Langkah $step/$totalSteps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Row(
              children: [
                if (!isLast)
                  TextButton(
                    onPressed: () => FeatureDiscovery.dismissAll(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Lewati'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async =>
                      FeatureDiscovery.completeCurrentStep(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Selesai' : 'Lanjut',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ZelixaFeatureOverlay extends StatelessWidget {
  final String featureId;
  final Widget tapTarget;
  final String title;
  final String description;
  final int step;
  final int totalSteps;
  final bool isLast;
  final ContentLocation contentLocation;
  final Widget child;

  const ZelixaFeatureOverlay({
    super.key,
    required this.featureId,
    required this.tapTarget,
    required this.title,
    required this.description,
    required this.step,
    this.totalSteps = 5,
    this.isLast = false,
    this.contentLocation = ContentLocation.below,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DescribedFeatureOverlay(
      featureId: featureId,
      tapTarget: tapTarget,
      backgroundColor: AppColors.primary,
      targetColor: Colors.white,
      textColor: Colors.white,
      contentLocation: contentLocation,
      overflowMode: OverflowMode.clipContent,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      description: FeatureOverlayPrompt(
        description: description,
        step: step,
        totalSteps: totalSteps,
        isLast: isLast,
      ),
      child: child,
    );
  }
}
