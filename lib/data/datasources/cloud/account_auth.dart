import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/google_sign_in.dart';
import '../../../domain/entities/account_status.dart';
import '../../../domain/repositories/account_repository.dart';

/// アカウントの登録・ログアウトに使う認証の操作(Issue #130)。
///
/// 本物([FirebaseAccountAuth])は、FirebaseとGoogle・Appleの認証を使う。テストでは偽物に
/// 差し替え、実際のログインを行わずに、流れと、失敗の扱いを確かめる。
abstract class AccountAuth {
  /// いまのアカウントの状態。
  AccountStatus currentStatus();

  /// Googleでログインし、いまの(匿名の)アカウントに紐づけて、登録済みにする。
  Future<void> linkWithGoogle();

  /// Googleでログインし、そのGoogleアカウントのアカウントに切り替える(Issue #136)。
  /// いまの(匿名の)アカウントは、使われなくなる。
  Future<void> signInWithGoogle();

  /// Appleでサインインし、いまの(匿名の)アカウントに紐づけて、登録済みにする(iOSのみ)。
  Future<void> linkWithApple();

  /// Appleでサインインし、そのApple IDのアカウントに切り替える(iOSのみ)。
  Future<void> signInWithApple();

  /// いまのアカウントがAppleで登録されていれば、Appleでの確認のあと、Appleとの連携を
  /// 解除する(トークンを無効にする)。アカウントの削除の前に呼ぶ(App Storeの審査
  /// ガイドライン5.1.1(v))。Appleで登録していなければ、何もしない。
  Future<void> revokeAppleIfLinked();

  /// ログアウトする。
  Future<void> signOut();
}

/// 認証の失敗を、利用者向けの文言の例外にする。内部の表記(エラーコードなど)は、
/// 画面に出さない。[method]は、文言に出すログイン方法。
AccountException accountExceptionFrom(
  Object error, {
  LoginMethod method = LoginMethod.google,
}) {
  if (error is AccountException) return error;

  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return const AccountCancelledException();
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return const AccountException('Googleのログイン画面を開けませんでした。もう一度お試しください。');
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return const AccountException('Googleでのログインの設定に問題があります。');
      default:
        return const AccountException(
          'Googleでログインできませんでした。時間をおいて、もう一度お試しください。',
        );
    }
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      // Appleのサインインの画面を、利用者が閉じた(iOSのプラグインが返すコード)。
      case 'canceled':
      case 'web-context-canceled':
      case 'web-context-cancelled':
        return const AccountCancelledException();
      case 'credential-already-in-use':
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        // 別の端末などで、すでに登録されているアカウント。登録(紐づけ)では
        // 切り替えず、「ログイン」から入るよう、案内する(Issue #136)。
        return AccountAlreadyRegisteredException(method);
      case 'provider-already-linked':
        return AccountException('すでに${method.label}で登録済みです。');
      case 'network-request-failed':
        return const AccountException('通信できませんでした。通信状況を確認して、もう一度お試しください。');
      case 'user-disabled':
        return const AccountException('このアカウントは、利用できません。');
      case 'invalid-response':
      case 'not-handled':
      case 'failed':
        return AccountException('${method.label}でサインインできませんでした。もう一度お試しください。');
    }
  }

  return const AccountException('時間をおいて、もう一度お試しください。');
}

/// FirebaseとGoogle・Appleの認証を使う、本物の[AccountAuth]。
///
/// 匿名のアカウントに、GoogleやAppleの認証情報を紐づけて登録する。ユーザーID(UID)が
/// 変わらないため、履歴・お気に入り・無料枠の回数は、そのまま引き継がれる。
class FirebaseAccountAuth implements AccountAuth {
  FirebaseAccountAuth({
    this.serverClientId = kGoogleServerClientId,
    this.iosClientId = kGoogleIosClientId,
  });

  /// Googleログインの「ウェブ クライアントID」。
  final String serverClientId;

  /// Googleログインの「iOS クライアントID」。iOSでだけ使う。
  final String iosClientId;

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    await GoogleSignIn.instance.initialize(
      clientId: isIos && iosClientId.isNotEmpty ? iosClientId : null,
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _isInitialized = true;
  }

  /// Appleでサインインするときの設定。メールアドレスは、アカウント画面に出すため。
  /// 名前は、使わないので、求めない。
  static AppleAuthProvider _appleProvider() =>
      AppleAuthProvider()..addScope('email');

  @override
  AccountStatus currentStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return const AccountStatus.guest();
    for (final info in user.providerData) {
      final method = switch (info.providerId) {
        'apple.com' => LoginMethod.apple,
        'google.com' => LoginMethod.google,
        _ => null,
      };
      if (method != null) {
        return AccountStatus.registered(
          method: method,
          email: info.email ?? user.email,
        );
      }
    }
    // 対応しているログイン方法で登録されていないものは、ゲストとして扱う。
    return const AccountStatus.guest();
  }

  @override
  Future<void> linkWithGoogle() async {
    if (serverClientId.isEmpty) {
      throw const AccountException('Googleでのログインの設定が、まだ済んでいません。');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AccountException('サインインできていません。通信状況を確認して、もう一度お試しください。');
    }
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AccountException('Googleのログイン情報を取得できませんでした。');
    }
    await user.linkWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    // 紐づけの結果(プロバイダの情報)を、いまのユーザーに反映する。
    await user.reload();
  }

  @override
  Future<void> signInWithGoogle() async {
    if (serverClientId.isEmpty) {
      throw const AccountException('Googleでのログインの設定が、まだ済んでいません。');
    }
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AccountException('Googleのログイン情報を取得できませんでした。');
    }
    // いまのゲストではなく、そのGoogleアカウントのアカウントに、切り替わる。
    await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Future<void> linkWithApple() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AccountException('サインインできていません。通信状況を確認して、もう一度お試しください。');
    }
    await user.linkWithProvider(_appleProvider());
    await user.reload();
  }

  @override
  Future<void> signInWithApple() async {
    // いまのゲストではなく、そのApple IDのアカウントに、切り替わる。
    await FirebaseAuth.instance.signInWithProvider(_appleProvider());
  }

  @override
  Future<void> revokeAppleIfLinked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final isApple = user.providerData.any((i) => i.providerId == 'apple.com');
    if (!isApple) return;
    // 連携の解除には、Appleでの確認で、新しく受け取る「認可コード」が要る。
    final credential = await user.reauthenticateWithProvider(_appleProvider());
    final code = credential.additionalUserInfo?.authorizationCode;
    if (code == null || code.isEmpty) {
      throw const AccountException('Appleでの確認ができませんでした。もう一度お試しください。');
    }
    await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(code);
  }

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google側のログアウトに失敗しても、Firebaseからは、ログアウト済み。
    }
  }
}
