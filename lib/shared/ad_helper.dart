import 'dart:math';

import 'package:flutter/material.dart';

/// Helper class for managing ad display logic.
///
/// TODO: REPLACE WITH REAL ADS - See AD_IMPLEMENTATION.md for instructions
/// When ad account is ready:
/// 1. Replace _showInterstitialAdPlaceholder() with real ad loading logic
/// 2. Add dependency: google_mobile_ads or facebook_audience_network
/// 3. Add check for in-app purchase (ad-free status)
class AdHelper {
  static final Random _random = Random();

  /// Determines if an ad should be shown based on a probability.
  /// Default probability is 50% (0.5).
  static bool shouldShowAd({double probability = 0.5}) {
    return _random.nextDouble() < probability;
  }

  /// Shows an interstitial ad with a given probability, then navigates.
  /// If the ad is not shown (based on probability), navigates immediately.
  static Future<void> maybeShowAdAndNavigate(
    BuildContext context, {
    required VoidCallback onNavigate,
    double adProbability = 0.5,
  }) async {
    if (shouldShowAd(probability: adProbability)) {
      // Show the ad first
      await _showInterstitialAdPlaceholder(context);
    }
    // Then navigate
    if (context.mounted) {
      onNavigate();
    }
  }

  /// Shows a simulated interstitial ad dialog.
  static Future<void> _showInterstitialAdPlaceholder(
    BuildContext context,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.ad_units,
                size: 48,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Interstitial Ad Placeholder',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ad will appear here once configured',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
