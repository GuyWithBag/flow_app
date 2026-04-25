import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  InterstitialAd? iAd;
  BannerAd? bAd;
  int _interstitialCallCount = 0;

  /// Shows the interstitial ad based on frequency.
  /// [showAtFirst] — if true, shows on the first call; otherwise skips it.
  /// [frequency] — show the ad every N calls.
  void maybeShowInterstitial({bool showAtFirst = false, int frequency = 1}) {
    _interstitialCallCount++;
    final bool shouldShow = showAtFirst
        ? (_interstitialCallCount - 1) % frequency == 0
        : _interstitialCallCount % frequency == 0;
    if (shouldShow) iAd?.show();
  }

  static bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void loadBannerAd(BuildContext context) async {
    if (!_isMobile) return;
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );

    if (size == null) {
      // Unable to get width of anchored banner.
      return null;
    }

    await BannerAd(
      adUnitId: "ca-app-pub-7340092341275453/7352345203",
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Called when an ad is successfully received.
          debugPrint("Banner Ad was loaded.");
          bAd = ad as BannerAd;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, err) {
          // Called when an ad request failed.
          debugPrint("Banner Ad failed to load with error: $err");
          ad.dispose();
          notifyListeners();
        },
      ),
    ).load();
  }

  void loadInterstitial({Function(LoadAdError)? onAdFailedToLoad}) {
    if (!_isMobile) return;
    InterstitialAd.load(
      adUnitId: "ca-app-pub-7340092341275453/5646405502",
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          // Called when an ad is successfully received.
          debugPrint('Ad was loaded.');
          // Keep a reference to the ad so you can show it later.
          iAd = ad;
          iAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => {
              ad.dispose(),
              debugPrint('Ad: Failed to show full screen content: $error'),
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          // Called when an ad request failed.
          debugPrint('Ad failed to load with error: $error');
          if (onAdFailedToLoad != null) onAdFailedToLoad(error);
        },
      ),
    );
  }
}
