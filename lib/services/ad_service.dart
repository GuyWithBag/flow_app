import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  InterstitialAd? iAd;
  BannerAd? bAd;
  final Map<String, int> _interstitialCallCounts = {};

  static bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static String get _bannerAdUnitId => kDebugMode
      ? "ca-app-pub-3940256099942544/9214589741"
      : "ca-app-pub-7340092341275453/7352345203";

  static String get _interstitialAdUnitId => kDebugMode
      ? "ca-app-pub-3940256099942544/1033173712"
      : "ca-app-pub-7340092341275453/5646405502";

  /// Shows the interstitial ad based on frequency, tracked per [id].
  /// [id] — unique identifier for the call site (e.g. 'presets', 'settings').
  /// [showAtFirst] — if true, shows on the first call; otherwise skips it.
  /// [frequency] — show the ad every N calls.
  void maybeShowInterstitial({
    required String id,
    bool showAtFirst = false,
    int frequency = 1,
  }) async {
    final count = (_interstitialCallCounts[id] ?? 0) + 1;
    _interstitialCallCounts[id] = count;
    final bool shouldShow = showAtFirst
        ? (count - 1) % frequency == 0
        : count % frequency == 0;
    if (shouldShow) {
      await iAd?.show();
      loadInterstitial();
    }
  }

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
      adUnitId: _bannerAdUnitId,
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
      adUnitId: _interstitialAdUnitId,
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
