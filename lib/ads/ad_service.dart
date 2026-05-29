import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_constants.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  final ValueNotifier<bool> homeBannerReady = ValueNotifier(false);
  final ValueNotifier<String?> lastAdError = ValueNotifier(null);

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  bool _mobileAdsReady = false;

  BannerAd? _homeBannerAd;
  bool _isLoadingHomeBanner = false;
  int _bannerRetryCount = 0;
  static const _maxBannerRetries = 5;

  BannerAd? get homeBannerAd => _homeBannerAd;

  Future<void> initialize() async {
    // Real ads only — no test device ID (test mode shows "Test Ad" text)
    final status = await MobileAds.instance.initialize();
    _mobileAdsReady = true;
    debugPrint('AdMob initialized: ${status.adapterStatuses}');

    // Brief delay so WebView/JS engine is ready before first ad request
    await Future.delayed(const Duration(milliseconds: 500));
    loadInterstitial();
  }

  Future<void> loadHomeBanner(int width) async {
    if (!_mobileAdsReady) {
      await initialize();
    }
    if (width <= 0) {
      debugPrint('Banner skipped: invalid width ($width)');
      return;
    }
    if (_isLoadingHomeBanner) return;
    if (_homeBannerAd != null && homeBannerReady.value) return;

    _disposeHomeBanner();
    _isLoadingHomeBanner = true;
    lastAdError.value = null;

    final adSize =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
              Orientation.portrait,
              width,
            ) ??
            AdSize.banner;

    final banner = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isLoadingHomeBanner = false;
          _bannerRetryCount = 0;
          homeBannerReady.value = true;
          lastAdError.value = null;
          debugPrint('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _homeBannerAd = null;
          _isLoadingHomeBanner = false;
          homeBannerReady.value = false;
          lastAdError.value = '${error.code}: ${error.message}';
          debugPrint('Banner ad FAILED — ${error.code}: ${error.message}');
          _scheduleBannerRetry(width);
        },
      ),
    );

    _homeBannerAd = banner;
    await banner.load();
  }

  void _scheduleBannerRetry(int width) {
    if (_bannerRetryCount >= _maxBannerRetries) {
      debugPrint('Banner ad: max retries reached');
      return;
    }
    _bannerRetryCount++;
    final delay = Duration(seconds: 3 * _bannerRetryCount);
    Future.delayed(delay, () => loadHomeBanner(width));
  }

  void _disposeHomeBanner() {
    _homeBannerAd?.dispose();
    _homeBannerAd = null;
    homeBannerReady.value = false;
  }

  void reloadHomeBanner(int width) {
    _bannerRetryCount = 0;
    _disposeHomeBanner();
    _isLoadingHomeBanner = false;
    loadHomeBanner(width);
  }

  void loadInterstitial() {
    if (!_mobileAdsReady) return;
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: AdConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitialAd = ad;
          debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
          debugPrint(
            'Interstitial ad FAILED — ${error.code}: ${error.message}',
          );
          Future.delayed(const Duration(seconds: 10), loadInterstitial);
        },
      ),
    );
  }

  Future<void> showInterstitial({required VoidCallback onComplete}) async {
    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('Interstitial not ready yet — skipping');
      loadInterstitial();
      onComplete();
      return;
    }

    _interstitialAd = null;
    final completer = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissedAd) {
        dismissedAd.dispose();
        loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        loadInterstitial();
        debugPrint('Interstitial show failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    ad.show();
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
    onComplete();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _disposeHomeBanner();
    homeBannerReady.dispose();
    lastAdError.dispose();
  }
}
