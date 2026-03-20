import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flow_app/services/services.barrel.dart';

class BannerAdWidget extends HookWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // final _bannerAd = useState<BannerAd?>();

    return FutureBuilder(
      future: AdService.loadBannerAd(context),
      builder: (context, asyncSnapshot) {
        // if (!asyncSnapshot.hasData) {

        // }
        return Skeletonizer(
          enabled: asyncSnapshot.hasData,
          child: SizedBox(
            width: asyncSnapshot.data!.size.width.toDouble(),
            height: asyncSnapshot.data!.size.height.toDouble(),
            child: AdWidget(ad: asyncSnapshot.data!),
          ),
        );
      },
    );
  }
}
