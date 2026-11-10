import 'package:flutter/foundation.dart';

/// 定期購読を販売するストア。OSで決まる(AndroidはGoogle Play、iOSはApp Store)。
///
/// 解約のしかたの案内・購読の管理の画面を、ストアごとに出し分けるために使う。
/// iOSで、Google Playへ案内すると、App Storeの審査に通らない(ガイドライン3.1.1)。
enum SubscriptionStore {
  googlePlay(
    name: 'Google Play',
    manageUrl: 'https://play.google.com/store/account/subscriptions',
    managePlace: 'Google Playの「定期購入」',
  ),
  appStore(
    name: 'App Store',
    manageUrl: 'https://apps.apple.com/account/subscriptions',
    managePlace: '「設定」アプリの、ご自身の名前→「サブスクリプション」',
  );

  const SubscriptionStore({
    required this.name,
    required this.manageUrl,
    required this.managePlace,
  });

  /// 画面に出す、ストアの名前。
  final String name;

  /// 購読の管理(解約・支払い方法の変更)の画面のURL。
  final String manageUrl;

  /// 解約できる場所の案内(「〇〇から、解約できます」の〇〇)。
  final String managePlace;

  /// [platform]で使うストア。iOS以外は、Google Play。
  static SubscriptionStore of(TargetPlatform platform) =>
      platform == TargetPlatform.iOS ? appStore : googlePlay;
}
