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

  RewardedAd? _rewardedAd;
  bool _loadingRewarded = false;

  bool get rewardedReady => _rewardedAd != null;

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
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _loadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<bool> showRewarded() async {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewarded();
      return false;
    }

    _rewardedAd = null;
    var earned = false;
    ad.show(
      onUserEarnedReward: (_, __) {
        earned = true;
      },
    );

    while (ad.responseInfo != null && !earned) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_rewardedAd != null) break;
    }
    return earned;
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
}
