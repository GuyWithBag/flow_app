import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:flow_app/services/services.barrel.dart';

class BannerAdWidget extends HookWidget {
  const BannerAdWidget({super.key});

  static bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    if (!_isMobile) return const SizedBox.shrink();

    final AdService adService = context.watch<AdService>();
    if (adService.bAd == null) {
      return SizedBox(height: 80);
    }
    return SizedBox(
      width: adService.bAd!.size.width.toDouble(),
      height: adService.bAd!.size.height.toDouble(),
      child: AdWidget(ad: adService.bAd!),
    );
  }
}
