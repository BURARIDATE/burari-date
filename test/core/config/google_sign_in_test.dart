import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:burari_date/core/config/google_sign_in.dart';

void main() {
  test('ウェブ クライアントIDは、設定済みで、Googleのクライアントの形(…apps.googleusercontent.com)', () {
    // 空だと、Googleでの登録が「設定が、まだ済んでいません」となり、使えない(Issue #149)。
    expect(kGoogleServerClientId, isNotEmpty);
    expect(kGoogleServerClientId, endsWith('.apps.googleusercontent.com'));
  });

  test('FirebaseのプロジェクトID番号(burari-date: 889357641434)で始まる', () {
    // 別のプロジェクトのIDを、入れてしまうことを防ぐ。
    expect(kGoogleServerClientId, startsWith('889357641434-'));
  });

  group('iOS クライアントID', () {
    test('設定済みで、同じFirebaseのプロジェクトの、Googleのクライアントの形', () {
      expect(kGoogleIosClientId, startsWith('889357641434-'));
      expect(kGoogleIosClientId, endsWith('.apps.googleusercontent.com'));
      expect(kGoogleIosClientId, isNot(kGoogleServerClientId));
    });

    test('Info.plistに、逆順にしたURLスキームがある(無いと、ログイン後にアプリへ戻れない)', () {
      final reversed =
          'com.googleusercontent.apps.'
          '${kGoogleIosClientId.replaceAll('.apps.googleusercontent.com', '')}';
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('<string>$reversed</string>'));
    });
  });
}
