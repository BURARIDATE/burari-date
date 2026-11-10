// アプリの全画面を通しで動かし、エラーの表示が出ないかを確かめる(リリース前の確認用)。
//
// 本物のアプリ(本番のFirebase・API)を使う。ガチャを2回使い、お気に入りを1件保存して消す。
// お問い合わせの送信・ログイン・購入は、しない(本番に影響するため)。
// 各画面で「SNAP:<名前>」を出力して止まるので、外から撮れば、画面も目で確かめられる。
// 問題は「CHECK-NG:」で出力し、最後にまとめて失敗にする。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:burari_date/bootstrap.dart';
import 'package:burari_date/core/config/flavor.dart';

/// 画面に出ていたら、問題とみなす文言(読み込みの失敗・取り直しの案内など)。
const _errorTexts = ['再読み込み', 'できませんでした', '失敗', '取得し直す', 'エラー'];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final problems = <String>[];

  Future<void> wait(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 60),
    required String what,
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        problems.add('$what が出ない');
        // ignore: avoid_print
        print('CHECK-NG: $what が出ない');
        return false;
      }
      await wait(tester, const Duration(milliseconds: 300));
    }
    return true;
  }

  /// いまの画面を撮り(外から)、エラーの文言がないかを確かめる。
  Future<void> check(WidgetTester tester, String name) async {
    await wait(tester, const Duration(milliseconds: 1200));
    for (final text in _errorTexts) {
      final found = find.textContaining(text).evaluate();
      if (found.isNotEmpty) {
        final shown = found
            .map((e) => (e.widget as Text).data ?? '')
            .take(2)
            .join(' / ');
        problems.add('$name: 「$shown」');
        // ignore: avoid_print
        print('CHECK-NG: $name: 「$shown」');
      }
    }
    // ignore: avoid_print
    print('SNAP:$name');
    await wait(tester, const Duration(seconds: 3));
  }

  Future<void> backToRoot(WidgetTester tester) async {
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil((route) => route.isFirst);
    await wait(tester, const Duration(seconds: 1));
  }

  testWidgets('全画面の通し', (tester) async {
    await bootstrap(Flavor.prod);

    // 同意
    final accept = find.text('同意して始める');
    final start = find.text('ガチャを始める');
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (accept.evaluate().isEmpty && start.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) throw TestFailure('起動しませんでした');
      await wait(tester, const Duration(milliseconds: 300));
    }
    if (accept.evaluate().isNotEmpty) {
      await check(tester, 'a01_consent');
      for (var i = 0; i < 10; i++) {
        for (final element in find.byType(Scrollable).evaluate()) {
          final state = (element as StatefulElement).state as ScrollableState;
          state.position.jumpTo(state.position.maxScrollExtent);
        }
        await wait(tester, const Duration(milliseconds: 300));
      }
      await tester.tap(accept);
      await wait(tester, const Duration(seconds: 2));
    }
    await waitFor(tester, start, what: 'ホーム');
    await check(tester, 'a02_home');

    // 出発駅の検索(駅名で探す)
    await tester.tap(start);
    await wait(tester, const Duration(seconds: 1));
    await check(tester, 'a03_select_empty');
    await tester.tap(find.text('駅名を入力(サジェスト表示)'));
    await wait(tester, const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).last, '吉祥寺');
    // 検索結果の「吉祥寺駅 / JR中央線」(後ろの「路線を選択」の欄と取り違えない)。
    final line = find.text('JR中央線');
    if (await waitFor(tester, line, what: '駅の検索結果')) {
      await check(tester, 'a04_search');
      await tester.tap(line.first);
      await wait(tester, const Duration(seconds: 1));
      FocusManager.instance.primaryFocus?.unfocus();
      await waitFor(tester, find.text('ガチャをする'), what: '出発駅を選んだ画面');
      await wait(tester, const Duration(seconds: 2));
      await check(tester, 'a05_select_filled');
    }

    // ガチャ → もう一度ガチャ → この駅に行く
    await tester.tap(find.text('ガチャをする'));
    await waitFor(tester, find.text('ガチャる'), what: 'ガチャる');
    await tester.tap(find.text('ガチャる'));
    await waitFor(tester, find.text('この駅に行く'), what: '到着駅');
    await check(tester, 'a06_arrival');
    await tester.tap(find.text('もう一度ガチャ'));
    await waitFor(tester, find.text('この駅に行く'), what: 'もう一度ガチャの到着駅');
    await check(tester, 'a07_arrival_again');
    await tester.tap(find.text('この駅に行く'));
    await waitFor(
      tester,
      find.text('AI紹介'),
      timeout: const Duration(seconds: 120),
      what: 'グルメのAIの紹介文',
    );
    await check(tester, 'a08_food');

    // 詳細 → お気に入りに保存
    await tester.tap(find.text('AI紹介').first);
    await waitFor(tester, find.text('候補詳細'), what: '候補の詳細');
    await wait(tester, const Duration(seconds: 4));
    await check(tester, 'a09_detail');
    final save = find.text('保存する');
    if (await waitFor(tester, save, what: '保存するボタン')) {
      await tester.ensureVisible(save);
      await tester.tap(save);
      await wait(tester, const Duration(seconds: 2));
      await check(tester, 'a10_detail_saved');
    }
    await tester.pageBack();
    await wait(tester, const Duration(seconds: 1));
    await tester.tap(find.text('観光'));
    await waitFor(
      tester,
      find.text('AI紹介'),
      timeout: const Duration(seconds: 120),
      what: '観光のAIの紹介文',
    );
    await check(tester, 'a11_sights');

    // 履歴 → お気に入り(保存したものがある)→ 削除
    await backToRoot(tester);
    await tester.tap(find.text('履歴'));
    await wait(tester, const Duration(seconds: 3));
    await check(tester, 'a12_history');
    await tester.tap(find.byTooltip('お気に入り'));
    await wait(tester, const Duration(seconds: 3));
    await check(tester, 'a13_favorites');

    // 設定の各画面
    await backToRoot(tester);
    await tester.tap(find.text('設定'));
    await wait(tester, const Duration(seconds: 1));
    await check(tester, 'a14_settings');
    for (final (index, item) in [
      '効果音',
      '好み設定',
      'アカウント',
      'プラン',
      '利用規約',
      'お問い合わせ',
    ].indexed) {
      await tester.tap(find.text(item).first);
      await wait(tester, const Duration(seconds: 4));
      await check(tester, 'a${15 + index}_settings_$index');
      await tester.pageBack();
      await wait(tester, const Duration(seconds: 1));
    }

    // ignore: avoid_print
    print('CHECK-DONE: ${problems.length}件');
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
