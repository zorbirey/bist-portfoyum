import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Desteklenmeyen platform');
  }

  static String get rewardedUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Desteklenmeyen platform');
  }

  static String get interstitialUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Desteklenmeyen platform');
  }

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;

  bool get rewardedReady => _rewardedAd != null;
  bool get interstitialReady => _interstitialAd != null;

  void preload() {
    loadRewarded();
    loadInterstitial();
  }

  void loadRewarded() {
    if (_loadingRewarded || _rewardedAd != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (_) {
          _loadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  void loadInterstitial() {
    if (_loadingInterstitial || _interstitialAd != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<bool> showRewarded() {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewarded();
      return Future.value(false);
    }

    _rewardedAd = null;
    final completer = Completer<bool>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earned);
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        loadRewarded();
      },
    );

    ad.show(
      onUserEarnedReward: (_, __) {
        earned = true;
      },
    );
    return completer.future;
  }

  Future<bool> showInterstitial() {
    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitial();
      return Future.value(false);
    }

    _interstitialAd = null;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(true);
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        loadInterstitial();
      },
    );

    ad.show();
    return completer.future;
  }

  BannerAd createBanner({required void Function() onLoaded}) {
    return BannerAd(
      adUnitId: bannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
