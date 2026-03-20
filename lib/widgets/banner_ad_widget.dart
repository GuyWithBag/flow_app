import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flow_app/services/services.barrel.dart';

class BannerAdWidget extends HookWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // final _bannerAd = useState<BannerAd?>();
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
