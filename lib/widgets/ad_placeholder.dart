import 'package:flutter/material.dart';

/// Placeholder widget for banner ads while the ad account is being set up.
/// This shows a visual representation of where ads will appear.
///
/// TODO: REPLACE WITH REAL ADS - See AD_IMPLEMENTATION.md for instructions
/// Replace this entire widget with your banner ad widget (e.g., AdMob's BannerAd)
class AdPlaceholder extends StatelessWidget {
  const AdPlaceholder({super.key, this.height = 50, this.showLabel = true});

  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
      ),
      child: showLabel
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ad_units,
                    size: 16,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ad Placeholder',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
