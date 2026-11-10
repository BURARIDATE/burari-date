import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:burari_date/core/config/subscription_store.dart';

void main() {
  test('iOSはApp Store、それ以外はGoogle Play', () {
    expect(
      SubscriptionStore.of(TargetPlatform.iOS),
      SubscriptionStore.appStore,
    );
    expect(
      SubscriptionStore.of(TargetPlatform.android),
      SubscriptionStore.googlePlay,
    );
  });

  test('App Storeの案内に、Google Playのことを混ぜない(審査ガイドライン3.1.1)', () {
    const store = SubscriptionStore.appStore;
    expect(store.manageUrl, startsWith('https://apps.apple.com/'));
    for (final text in [store.name, store.managePlace]) {
      expect(text, isNot(contains('Google')));
    }
  });
}
