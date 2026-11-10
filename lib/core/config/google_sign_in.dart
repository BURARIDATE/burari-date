/// Googleログインの「ウェブ クライアントID」(Issue #130)。
///
/// FirebaseコンソールでGoogleログインを有効にすると作られる、ウェブ用のOAuth
/// クライアントのID(`...apps.googleusercontent.com`)。秘密の値ではなく、公開
/// してよい識別子。Firebase Authentication の「ログイン方法」→ Google →
/// 「ウェブ SDK の構成」で確認できる。
///
/// 空の間は、Googleでの登録を、「設定が、まだ済んでいません」と案内して使えなくする。
const kGoogleServerClientId =
    '889357641434-bf9kb7e5hmouu1t9iag2pa0qojj3ge8e.apps.googleusercontent.com';

/// Googleログインの「iOS クライアントID」(iOSのみ)。
///
/// FirebaseにiOSアプリ(`com.buraridate.burariDate`)を登録したときに作られる、iOS用の
/// OAuthクライアントのID。`GoogleService-Info.plist`の`CLIENT_ID`と同じ値で、秘密では
/// ない。`ios/Runner/Info.plist`のURLスキームには、これを逆順にした
/// `REVERSED_CLIENT_ID`を登録している(ログインのあと、アプリに戻るため)。
const kGoogleIosClientId =
    '889357641434-cb85nn6uaht87kkle67oe3m5k4h827p9.apps.googleusercontent.com';
