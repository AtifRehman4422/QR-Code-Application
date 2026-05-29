import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  double? _lastWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestBanner());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _requestBanner();
  }

  void _requestBanner() {
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _requestBanner();
      });
      return;
    }
    if (width == _lastWidth && AdService.instance.homeBannerReady.value) {
      return;
    }
    _lastWidth = width.toDouble();
    AdService.instance.loadHomeBanner(width);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.homeBannerReady,
      builder: (context, isReady, _) {
        final banner = AdService.instance.homeBannerAd;
        if (isReady && banner != null) {
          return SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: banner.size.height.toDouble(),
              child: Center(
                child: SizedBox(
                  width: banner.size.width.toDouble(),
                  height: banner.size.height.toDouble(),
                  child: AdWidget(ad: banner),
                ),
              ),
            ),
          );
        }

        return ValueListenableBuilder<String?>(
          valueListenable: AdService.instance.lastAdError,
          builder: (context, error, _) {
            if (kDebugMode && error != null) {
              return Container(
                width: double.infinity,
                height: 50,
                color: Colors.orange.shade100,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Ad error: $error',
                  style: const TextStyle(fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const SizedBox(width: double.infinity, height: 50);
          },
        );
      },
    );
  }
}
