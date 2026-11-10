/// ログイン方法。アカウント登録に使える方法を、ここに足していく。
///
/// 端末で使える方法は、OSで異なる(iOSはAppleとGoogle、AndroidはGoogleだけ)。画面は、
/// `loginMethodsProvider`の一覧を使う。
enum LoginMethod {
  /// Appleでサインイン(iOSのみ)。Googleなどの外部のログインを出すアプリは、Appleでの
  /// ログインも出す必要がある(App Storeの審査ガイドライン4.8)。
  apple('Apple'),
  google('Google');

  const LoginMethod(this.label);

  /// 画面に出す名前。
  final String label;
}

/// アカウントの状態(Issue #129)。
///
/// 起動時は、匿名認証で入るため、登録はしていない(ゲスト)。登録すると、匿名の
/// アカウントが、登録済みのアカウントに変わる(履歴・お気に入りは引き継ぐ)。
class AccountStatus {
  /// アカウントを登録していない状態(匿名のまま利用中)。
  const AccountStatus.guest()
    : isRegistered = false,
      method = null,
      email = null;

  /// アカウントを登録済みの状態。
  const AccountStatus.registered({required LoginMethod this.method, this.email})
    : isRegistered = true;

  final bool isRegistered;

  /// 登録に使ったログイン方法。登録していないときはnull。
  final LoginMethod? method;

  /// 登録したメールアドレス。分からないときはnull。
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AccountStatus &&
      other.isRegistered == isRegistered &&
      other.method == method &&
      other.email == email;

  @override
  int get hashCode => Object.hash(isRegistered, method, email);
}
