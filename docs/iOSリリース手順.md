# iOSリリース手順

App Store(iOS)に公開するときの手順と、決めたこと。**初回は2026-11-10に、1.0.0(ビルド6)と月額プランを審査へ提出した**。アップデートのときは「4. ビルドとアップロード」以降を繰り返す。
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
- [x] Appleでサインインを設定する(Firebaseの「Apple」の有効化・連携の解除用のキー。[環境構築手順 7-6](環境構築手順.md))。キーは Key ID `K497YXG2HX`(Sign in with Apple、Primary App ID `com.buraridate.burariDate`)。Firebaseの「OAuth コードフローの構成」は、サービスIDに**Bundle ID** `com.buraridate.burariDate`・チームID・キーID・秘密鍵を入れた(iOSのネイティブのログインだけなので、Web用のサービスIDは作っていない。TestFlightで、Appleで登録したアカウントの削除が通ることを確かめた)
- [x] App Check: Apple Developer → Keys で DeviceCheck のキー(Key ID `M4JU6TA74P`)を作り、Firebaseコンソール → App Check → iOSアプリ → DeviceCheck に、キー・Key ID・Team IDを登録する(トークンの有効期間は1時間。登録しないと、本番版のトークンが`INVALID`になる。サーバーが必須にするまでは、動きは止まらない)
- [x] 公開サイトをデプロイする(規約・ポリシーにApple・App Storeを書いた版): `firebase deploy --only hosting --project burari-date`
- [x] サブスクリプショングループ「プラン」の**表示名と説明**(ローカリゼーション)を作る: 日本語・表示名`ぶらりデートガチャ`・「App名を使用」。**ないと、提出のときに「自動更新サブスクリプションは、サブスクリプショングループとともに提出する必要があります」で止まる**
- [ ] サブスクの「ストリームライン購入」(App Storeのページから直接買える仕組み)をオフにする(推奨。登録してから購入する作りのため、アプリの外で買われると、登録していない状態の購入になる)
- 商品の購入オプションは「App Storeだけ・マルチシート購入なし」、ファミリー共有はオフ(一度オンにすると戻せない)

## 2. App Store Connect の掲載情報

### バージョンのページ

| 項目 | 値・注意 |
|---|---|
| プロモーション用テキスト | 170文字以内。審査なしで、いつでも変更できる |
| 概要 | 4000文字以内。課金は「App Storeの月額プラン」と書き、Google Playに触れない。**利用規約(`https://burari-date.web.app/terms.html`)とプライバシーポリシーのURLを、最後に書く**(サブスクのアプリの条件。ガイドライン3.1.2) |
| キーワード | 100文字以内・カンマ区切り・スペースなし。アプリ名・他社のアプリ名は入れない |
| サポートURL | `https://burari-date.web.app/` |
| バージョン | `pubspec.yaml`の`version`の前半と同じ(例: `1.0.0`。初期値の`1.0`のままにしない) |
| 著作権 | `2026 CenterRiverStudio` |

1.0.0で入れた文面:

- プロモーション用テキスト: 「行き先は、ガチャまかせ。出発駅と路線を選ぶだけで、ランダムに決まった駅の周辺から、グルメや観光スポットをAIの紹介文つきでご提案。ふたりの休日に、小さな冒険を。」
- キーワード: `駅,おでかけ,ランダム,グルメ,観光,カップル,休日,散歩,街歩き,行き先,ルーレット,スポット,電車,路線,AI,ふたり,記念日,週末,カフェ`(アプリ名の「デート」「ガチャ」「ぶらり」は、自動で検索の対象になるので入れない)
- 概要: 「いつものデート、行き先がマンネリに…」で始まり、こんな方におすすめ・使い方・主な機能・料金について(無料10回・月額300円・自動更新と24時間前までの解約・解約の場所)・ご注意(外部サービスの情報とAIの紹介文)・利用規約とプライバシーポリシーのURL、の順。変えるときは、App Store Connectの今の文面を写してから直す

### スクリーンショット

- 「Dynamic Island搭載iPhone(中型ディスプレイ)」に **1206×2622px**(iPhone 18 Proのシミュレーター)を7枚。iPadは不要
- Google Play用の画像は、Androidの画面(ステータスバー・ナビゲーション)が写っているので**そのまま使えない**(ガイドライン2.3.10)。Play用と同じ見出し・デザインで、中の画面だけiPhoneに差し替える
- 1.0.0の画像: `~/Downloads/burari_appstore_iphone_1206x2622/`(リポジトリの外)。**01(ホーム)を先頭に、01→07の順に並べる**(アップロードすると逆順になることがある)

撮り方(本番のサーバーにつながる。ガチャを1回使う):

```bash
# 1. シミュレーターで画面を進め、7枚を撮る(ホーム・出発駅・ガチャ・到着駅・グルメ・詳細・観光)
tool/ios_screenshots/shoot.sh <iPhone 18 ProのUDID> /tmp/ios_raw
# 2. Play用の合成画像(01〜07、1080x1920)の見出しを使って、1206x2622に合成する
swift tool/ios_screenshots/compose.swift play/05.png /tmp/ios_raw/05_food.png out/05_food.jpg 448
```

- 到着駅はPlay用と同じ**目黒駅**にそろえている(渋谷駅・JR山手線・品川駅方面・ちょうど2駅隣)。候補(グルメ・観光)は、その日の検索結果で変わる
- 合成の最後の引数は、Play用の画像のスマホの枠の上端より少し上の高さ(01:461、02:446、03:461、04:458、05:448、06:455、07:456)
- iOSでは、アプリを入れ直しても**無料の回数はリセットされない**(Firebaseの匿名ログインがキーチェーンに残る)。上限に達したら、別のシミュレーターで撮る
- 全画面の通しの確認は `tool/ios_screenshots/shoot.sh <UDID> /tmp/walk integration_test/full_walkthrough_test.dart`(ガチャを2回使う。エラーの文言が出た画面を「CHECK-NG:」で出す)

### App Review に関する情報

- **連絡先情報**(姓・名・電話番号・メール)は必須。電話番号は`+81`から(先頭の0を取る)。公開されない
- **サインイン情報**: 「サインインが必要」の**チェックを外す**(初期値はチェックあり)。ログインしなくても主な機能が使え(ゲストで無料10回)、登録(Appleでサインイン)・購入は、審査担当者が自分のApple Accountとサンドボックスで試せるため、審査用のアカウントは用意しない
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
| 年齢制限 | アプリ内コントロール・機能(ペアレンタルコントロール・年齢確認・無制限のウェブアクセス・ユーザ生成コンテンツ・ソーシャルメディア・メッセージ・広告)はすべて「いいえ」。暴力・疑似ギャンブル・コンテストは「なし」、ギャンブル・ルートボックスは「いいえ」(ガチャは駅をランダムに選ぶだけで、アイテムの抽選・有料の抽選ではない)。「アルコール・タバコ・ドラッグ」は、候補に居酒屋が出てお酒の写真・紹介文が出るため「まれ」。年齢カテゴリの上書きは「該当なし」(利用規約に最低年齢はない) |
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
| ユーザコンテンツ | カスタマーサポート | お問い合わせの内容(App Store Connectでは「ユーザコンテンツ」の中にある) |

- 各項目: 用途「アプリの機能」のみ/ユーザに関連付け「はい」/トラッキング「いいえ」
- 位置情報・診断・分析は**収集しない**(Analytics・Crashlyticsは未導入。入れたら申告を足す)
- 最後に右上の「**公開**」を押す

### 価格および配信状況

- 価格: 「価格スケジュール」で、基準を日本・**¥0(無料)**(アプリ内課金あり)。未設定だと「価格帯を選択する必要があります」で提出できない
- **アプリの配信状況**: 「配信状況の設定」で**日本**を選んで保存する(価格の設定とは別。**選ばないと、承認されても「App Storeから削除済み」になり、どこにも出ない**。1.0.0は、承認のあとに気づいて設定した)
- 「Appleシリコン搭載のMac」「Apple Vision Pro」での配信は、確かめていないので、チェックを外す(推奨)

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

1. 配信タブ → バージョンのページ → 「ビルド」でビルドを選ぶ(1.0.0は**ビルド6**。ビルド5は履歴の表示の修正の前)
2. 初回は、サブスクの**商品**(月額プラン)と**グループ**(プラン)も、同じ提出に含める(それぞれのページの「審査用に追加」)
3. 「審査用に追加」→ 提出物の下書きに「iOSアプリ 1.0.0・月額プラン・プラン」がそろったら「審査へ提出」
   - 足りない項目は、一覧で出る(初回は: 連絡先情報・プライバシーポリシーURL・アプリのプライバシーの公開・年齢制限・コンテンツ配信権・カテゴリ・価格)
4. 結果は24〜48時間が目安。質問は App Review のメッセージに届く

## 6. 承認後

承認されると、状態が「**配信準備完了**」(緑)になる。1.0.0は、提出した日のうちに承認された。

1. 「このバージョンをリリース」で公開する
2. App Storeから入れて、起動・購入(本番)・App Check(Firebaseのログの`verifications.app`が`VALID`)を確かめる
