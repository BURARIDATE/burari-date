// ストア(App Store・Google Play)のスクリーンショットを撮るための操作。
//
// 本物のアプリ(本番のFirebase・API)を起動し、ホーム → 出発駅 → ガチャ → 到着駅 →
// 候補(グルメ・詳細・観光)の順に、画面を進める。各画面で「SNAP:<名前>」を出力して
// 数秒止まるので、そのあいだに、外から`xcrun simctl io <UDID> screenshot`で撮る。
// 撮影の手順は docs/iOSリリース手順.md の「スクリーンショット」を参照。
//
// ガチャを1回使う(無料の回数が減る)。到着駅はランダム。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:burari_date/bootstrap.dart';
import 'package:burari_date/core/config/flavor.dart';

/// 撮影のあいだ、止まる時間。
const _snapPause = Duration(seconds: 4);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 実際の時間で待つ(アニメーションが続く画面では、pumpAndSettleが終わらないため)。
  Future<void> wait(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// [finder]が見つかるまで待つ。
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        // 原因を見られるよう、止まった画面を撮ってから、失敗にする。
        // ignore: avoid_print
        print('SNAP:zz_failed');
        await wait(tester, _snapPause);
        throw TestFailure('見つかりませんでした: $finder');
      }
      await wait(tester, const Duration(milliseconds: 300));
    }
  }

  Future<void> snap(WidgetTester tester, String name) async {
    await wait(tester, const Duration(milliseconds: 800));
    // ignore: avoid_print
    print('SNAP:$name');
    await wait(tester, _snapPause);
  }

  testWidgets('ストアのスクリーンショット', (tester) async {
    await bootstrap(Flavor.prod);

    // 初回は、利用規約の同意。最後までスクロールして、同意する。
    final accept = find.text('同意して始める');
    final start = find.text('ガチャを始める');
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (accept.evaluate().isEmpty && start.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) throw TestFailure('起動しませんでした');
      await wait(tester, const Duration(milliseconds: 300));
    }
    if (accept.evaluate().isNotEmpty) {
      for (var i = 0; i < 10; i++) {
        for (final element in find.byType(Scrollable).evaluate()) {
          final position =
              (element as StatefulElement).state as ScrollableState;
          position.position.jumpTo(position.position.maxScrollExtent);
        }
        await wait(tester, const Duration(milliseconds: 300));
      }
      await tester.tap(accept);
      await wait(tester, const Duration(seconds: 2));
    }

    // 01 ホーム
    await waitFor(tester, find.text('ガチャを始める'));
    await snap(tester, '01_home');

    // 02 出発駅・路線(渋谷駅・JR山手線)
    await tester.tap(find.text('ガチャを始める'));
    await wait(tester, const Duration(seconds: 1));
    await tester.tap(find.text('駅名を入力(サジェスト表示)'));
    await wait(tester, const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).last, '渋谷');
    final yamanote = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('JR山手線'),
    );
    await waitFor(tester, yamanote);
    await tester.tap(yamanote.first);
    await wait(tester, const Duration(seconds: 1));
    await waitFor(tester, find.text('JR山手線'));
    FocusManager.instance.primaryFocus?.unfocus();
    await snap(tester, '02_departure');

    // 到着駅を、Google Play用と同じ目黒駅にそろえる(渋谷駅から品川駅方面に、ちょうど2駅隣)。
    await tester.tap(find.text('品川駅'));
    await wait(tester, const Duration(milliseconds: 500));
    final maxMinus = find.byIcon(Icons.remove_circle_outline).last;
    for (var i = 0; i < 5; i++) {
      await tester.tap(maxMinus);
      await wait(tester, const Duration(milliseconds: 200));
    }
    await waitFor(tester, find.text('駅数範囲: 2〜2駅隣'));

    // 03 ガチャの演出(2段が決まった瞬間)
    await tester.tap(find.text('ガチャをする'));
    await waitFor(tester, find.text('ガチャる'));
    await wait(tester, const Duration(seconds: 1));
    await tester.tap(find.text('ガチャる'));
    // 2段(〇駅隣・到着駅)が決まった瞬間。1秒後に駅名標へ切り替わるので、すぐ撮る。
    final decided = find.textContaining('到着駅：');
    while (decided.evaluate().isEmpty) {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    // 到着駅の段が、めくれ終わるのを待つ。
    final settle = DateTime.now().add(const Duration(milliseconds: 300));
    while (DateTime.now().isBefore(settle)) {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    // ignore: avoid_print
    print('SNAP:03_gacha');

    // 04 到着駅
    await waitFor(tester, find.text('この駅に行く'));
    await snap(tester, '04_arrival');

    // 05 候補の一覧(グルメ)
    await tester.tap(find.text('この駅に行く'));
    await waitFor(
      tester,
      find.text('AI紹介'),
      timeout: const Duration(seconds: 120),
    );
    await snap(tester, '05_food');

    // 06 候補の詳細(地図・写真の読み込みを待つ)
    // 1件目はチェーン店(ロゴが大きく写る)のことが多いので、2件目を開く。
    await tester.tap(find.text('AI紹介').at(1));
    await waitFor(tester, find.text('候補詳細'));
    await wait(tester, const Duration(seconds: 6));
    await snap(tester, '06_detail');

    // 07 候補の一覧(観光)
    await tester.pageBack();
    await wait(tester, const Duration(seconds: 1));
    await tester.tap(find.text('観光'));
    await wait(tester, const Duration(seconds: 3));
    await snap(tester, '07_sights');
  });
}
