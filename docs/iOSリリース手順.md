# iOSリリース手順

App Store(iOS)に公開するときの手順と、決めたこと。初回の審査提出に向けて書いたもの。アップデートのときは「4. ビルドとアップロード」以降を繰り返す。
Google Playは[ストア公開チェックリスト](ストア公開チェックリスト.md)、設定の手順は[環境構築手順](環境構築手順.md)(7-3 課金・7-5 App Check・7-6 ログイン)を参照。

## 固定値

| 項目 | 値 |
|---|---|
| Team ID | `4N5F9L6BC2`(`ios/Runner.xcodeproj`の`DEVELOPMENT_TEAM`) |
| Bundle ID | prod `com.buraridate.burariDate` / dev `.dev` / stg `.stg`(**App Store Connectでアプリを作ると、変えられない**。iOSはアンダースコアを使えないため、Androidの`com.buraridate.burari_date`とは違う) |
| App Store ID(アプリのApple ID) | `6832859521`(`https://apps.apple.com/jp/app/id6832859521`。公開されるまでは開けない) |
| SKU | `burari-date-ios` |
| サブスクの商品 | 製品ID `burari_date_monthly`(グループ「プラン」、1か月・¥300・日本のみ・ファミリー共有オフ)。RevenueCatでEntitlement `burari_date_pro`と、Offering `default`の`$rc_monthly`につないだ |
| RevenueCatのiOSの公開APIキー | `kRevenueCatIosApiKey`(`lib/core/config/revenuecat.dart`) |
| アプリ内課金キー | Key ID `M755UM4B3F`(RevenueCatに登録済み。`.p8`は手元の`~/Keys/app-store-connect/`に保管) |
| Firebase のiOSアプリ | `1:889357641434:ios:b58cd38ba9138f612d27e3`(prod のBundle IDで登録。dev・stgも同じプロジェクトにつながる) |
| 対応端末 | iPhone専用・縦固定・iOS 15.0以上(iPadのスクリーンショット・審査が不要) |
| Entitlement | `burari_date_pro`(Androidと共通) |

> `.p8`(アプリ内課金キー・Sign in with Appleのキー・DeviceCheckのキー)・審査用アカウントのパスワードは、**リポジトリに入れない**。

## 1. 初回だけ行う設定

- [x] App Store Connectでアプリを作成する(名前「ぶらりデートガチャ」、プライマリ言語は日本語、Bundle ID `com.buraridate.burariDate`、SKU `burari-date-ios`。EUのDSAは「トレーダーではない(EUで配信しない)」)
- [x] 有料アプリ契約(銀行口座・税務。W-8BENは日米租税条約12条1項・0%)を結ぶ
- [x] サブスクの商品を作り、RevenueCatにつなぎ、`kRevenueCatIosApiKey`を入れる([環境構築手順 7-3](環境構築手順.md))
- [x] Appleでサインインを設定する(Firebaseの「Apple」の有効化・連携の解除用のキー。[環境構築手順 7-6](環境構築手順.md))。キーは Key ID `K497YXG2HX`(Sign in with Apple、Primary App ID `com.buraridate.burariDate`)。Firebaseの「OAuth コードフローの構成」は、サービスIDに**Bundle ID** `com.buraridate.burariDate`・チームID・キーID・秘密鍵を入れた(iOSのネイティブのログインだけなので、Web用のサービスIDは作っていない。TestFlightで、Appleで登録したアカウントの削除が通るかを確かめる)
- [x] App Check: Apple Developer → Keys で DeviceCheck のキー(Key ID `M4JU6TA74P`)を作り、Firebaseコンソール → App Check → iOSアプリ → DeviceCheck に、キー・Key ID・Team IDを登録する(トークンの有効期間は1時間。登録しないと、本番版のトークンが`INVALID`になる。サーバーが必須にするまでは、動きは止まらない)
- [ ] 公開サイトをデプロイする(規約・ポリシーにApple・App Storeを書いた版): `firebase deploy --only hosting --project burari-date`

## 2. App Store Connect の掲載情報

### バージョンのページ

| 項目 | 値・注意 |
|---|---|
| プロモーション用テキスト | 170文字以内。審査なしで、いつでも変更できる |
| 概要 | 4000文字以内。課金は「App Storeの月額プラン」と書き、Google Playに触れない。**利用規約(`https://burari-date.web.app/terms.html`)とプライバシーポリシーのURLを、最後に書く**(サブスクのアプリの条件。ガイドライン3.1.2) |
| キーワード | 100文字以内・カンマ区切り・スペースなし。アプリ名・他社のアプリ名は入れない |
| サポートURL | `https://burari-date.web.app/` |
| バージョン | `pubspec.yaml`の`version`の前半と同じ(例: `1.0.0`) |
| 著作権 | `2026 CenterRiverStudio` |

### スクリーンショット

- 「Dynamic Island搭載iPhone(中型ディスプレイ)」に **1206×2622px** を最大10枚。iPadは不要
- Google Play用の画像は、サイズが合わず、Androidの画面(ナビゲーションバー・Google Playの案内)が写るので**使えない**(ガイドライン2.3.10)
- iPhone 18 Proのシミュレーターで撮る。`xcrun simctl io <UDID> screenshot`、ステータスバーは`xcrun simctl status_bar <UDID> override`で整える
- サブスクの商品にも、審査用のスクリーンショット(プランの画面)が1枚要る

### App Review に関する情報

- **サインイン情報**: ログインしなくても使える(ゲストで無料10回)。購読中の状態を見てもらうため、審査用のアカウントを用意し、RevenueCatで**プロモーションの権利**(`burari_date_pro`)を付けておくと確実
- **メモ**(英語)の基本:

```
Thank you for reviewing Burari Date Gacha.

[What the app does]
Pick a departure station and a train line, then spin the gacha. The app picks a random arrival station and suggests restaurants and sightseeing spots around it, with short AI-written introductions.

[Sign in]
No sign-in is needed. On first launch the app uses an anonymous account, and 10 gacha spins are free.
Registering an account is optional (Settings > アカウント). It supports Sign in with Apple and Google.

[Subscription]
After the 10 free spins, a monthly auto-renewable subscription (App Store in-app purchase) is required to continue.
Settings > プラン shows the price, the renewal terms, and links to the Terms of Use and Privacy Policy. Purchases can be restored from the same screen.

[Account deletion]
Settings > アカウント > アカウントを削除 deletes the account and its data. For accounts registered with Sign in with Apple, the app also revokes the Apple token.

[Location]
The app does not use the device location. Locations are only the station the user picks.
```

- **リリース方法**: 「このバージョンを手動でリリースする」

### アプリ情報

| 項目 | 値 |
|---|---|
| カテゴリ | プライマリ: 旅行(セカンダリ: ライフスタイル) |
| コンテンツ配信権 | **はい**(OpenStreetMapの地図タイル・ホットペッパーグルメ・Foursquareの情報を、各サービスの規約に沿って表示) |
| 年齢制限 | 機能(ペアレンタルコントロール・年齢確認・ウェブアクセス・ユーザ生成コンテンツ・メッセージ・広告)はすべて「いいえ」。内容は、飲食店の情報にお酒が含まれうるため「アルコール・タバコ・ドラッグへの言及」を確認して選ぶ。ガチャは駅をランダムに選ぶだけで、有料の抽選ではない(ルートボックスではない) |
| 暗号化 | `Info.plist`の`ITSAppUsesNonExemptEncryption=false`で申告済み |

### アプリのプライバシー

- プライバシーポリシーURL: `https://burari-date.web.app/privacy.html`
- 収集するデータ(`ios/Runner/PrivacyInfo.xcprivacy`と揃える)

| 分類 | 項目 | 内容 |
|---|---|---|
| 連絡先情報 | 名前 | Google・Appleの表示名(Firebase認証に保存されることがある) |
| 連絡先情報 | メールアドレス | アカウント登録・お問い合わせの返信先 |
| ID | ユーザID | Firebaseの識別子 |
| ID | デバイスID | 無料の回数を数える、ランダムな端末の識別子 |
| 購入 | 購入履歴 | 購読の状態(RevenueCat) |
| 使用状況データ | 製品の操作 | ガチャの履歴・お気に入り・利用回数 |
| その他のデータ | カスタマーサポート | お問い合わせの内容 |

- 各項目: 用途「アプリの機能」のみ/ユーザに関連付け「はい」/トラッキング「いいえ」
- 位置情報・診断・分析は**収集しない**(Analytics・Crashlyticsは未導入。入れたら申告を足す)
- 最後に右上の「**公開**」を押す

### 価格および配信状況

- 価格: 無料(アプリ内課金あり)、配信地域: 日本

## 3. 提出前の確認

- [ ] `kRevenueCatIosApiKey`が入っている(空だと購入できず、却下される)
- [ ] `pubspec.yaml`の`version`のビルド番号が、App Store Connectにアップロード済みのものより大きい
- [ ] TestFlightで、本番版を実機で確かめる: 起動・同意・ガチャ、Appleで登録・ログイン・削除、Googleで登録・ログイン、サンドボックスでの購入・復元・解約の案内

## 4. ビルドとアップロード

```bash
flutter build ipa --flavor prod -t lib/main_prod.dart
```

- 出力: `build/ios/archive/Runner.xcarchive`、`build/ios/ipa/burari_date.ipa`(App Store配布用の証明書で署名済み)
- アップロードは、どちらか
  1. **Xcode の Organizer**: `open build/ios/archive/Runner.xcarchive` → Distribute App → App Store Connect → Upload(Xcode 27.2では、先に Validate App を実行しないと、押せないことがある)
  2. **Transporter**(Mac App Store): `build/ios/ipa/burari_date.ipa`をドラッグして「配信」
- 10〜30分で、TestFlightのビルドが「提出準備完了」になる

## 5. 審査への提出

1. 配信タブ → バージョンのページ → 「ビルド」でビルドを選ぶ
2. 初回は、サブスクの商品も、同じ提出に含める(App内課金とサブスクリプション → 商品を選ぶ)
3. 「審査用に追加」→「審査へ提出」
4. 結果は24〜48時間が目安。質問は App Review のメッセージに届く

## 6. 承認後

1. 「このバージョンをリリース」で公開する
2. App Storeから入れて、起動・購入(本番)・App Check(Firebaseのログの`verifications.app`が`VALID`)を確かめる
