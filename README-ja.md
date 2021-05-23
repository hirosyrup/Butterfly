<p align="center">
<img src="https://user-images.githubusercontent.com/24717967/118624685-5297eb80-b804-11eb-9555-736bdc311e1b.png" alt="app_icon" title="app_icon">
</p>
<p align="center">
<a href="https://github.com/hirosyrup/Butterfly/blob/master/README.md">🇺🇸English</a> / <a href="https://github.com/hirosyrup/Butterfly/blob/master/README-ja.md">🇯🇵Japanese</a>
</p>

# Butterfly

Butterflyは議事録作成の補助ツールです。以下のような特徴を持っています。

* 音声を文字へ話者ごとに書き起こし
* 書き起こした文章はクリップボードへのコピーやCSVでのエクスポートができる
* 同時に録音データも保存
* 書き起こした文章をもとに任意の箇所から音声再生ができるプレビュー機能

https://user-images.githubusercontent.com/24717967/118831907-198e7280-b8fb-11eb-86ea-b453e61b1859.mp4

# 動作環境

macOS 10.15以上

iOS版は開発中！

# インストール方法

## 前準備

動作インフラとしてFirebaseを使用します。その環境は利用者が用意する必要があります。したがって以下を準備してください。

* Firebaseの登録を行うためのGoogleアカウント
* [Firebase CLI](https://firebase.google.com/docs/cli?hl=ja)のインストール

## Firebaseでプロジェクトの作成

[こちら](https://firebase.google.com/docs/ios/setup?hl=ja)のステップ1〜ステップ3までを行いGoogleService-Info.plistを取得してください。

以下注意事項です。

* プロジェクト名はなんでもOKです。
* Googleアナリティクスは使わないので有効でも無効でもかまいません。
* iOSアプリを追加する際のバンドルIDにはcom.koalab.Butterflyを入力してください。ニックネームとAppStoreIDについては入力不要です。
* iOSアプリの追加画面でplistファイルをダウンロードしたら、後は全て「次へ」をクリックしてスキップしてください。

## プロジェクトの設定

## Authentication設定

Firebaseダッシュボードの左メニューから「Authentication」をクリックし、表示された画面の「始める」をクリックしてください。

「Sign-in method」タブを開いてプロバイダの中から「メール/パスワード」を開いて有効にしてください。メールリンクは無効のままにします。

## Firestore設定

Firebaseダッシュボードの左メニューから「Firestore」をクリックし、表示された画面の「データベースの作成」をクリックしてください。

「本番環境モードで開始する」を選んで次へ、ロケーションはasia-northeast1(東京)かasia-northeast2(大阪)で、近い方を選択してください。

## セキュリティルールとインデックスのデプロイ

gitでソースコードをcloneするか、[Release](https://github.com/hirosyrup/Butterfly/releases)からダウンロードして、ターミナルでルートディレクトリに移動します。

次にfirebaseにログインします。

```
firebase login
```

最後に以下のコマンドを叩いて完了するまで待ちます。設定が反映されるまで数分かかる場合があります。

```
cd deploy
./deploy.sh your-project-id
```

※your-project-idについては、プロジェクトの設定画面に出ているので置き換えてください。

<img width="689" alt="" src="https://user-images.githubusercontent.com/24717967/118674536-cf42be00-b834-11eb-9fd0-05ae56b5c4ed.png">

これでプロジェクトの設定は完了です。
しばらくは無料枠で使用できますが、それを超えそうになったら有料プラン(Blaze)の登録をしてください。
料金については[こちら](https://firebase.google.com/pricing?hl=ja)から確認できます。

## アプリのインストール

[こちら](https://github.com/hirosyrup/Butterfly/releases)より最新版をダウンロードしてください。

zipファイルを解凍し、アプリを起動します。
**Butterflyはステータスバー常駐型アプリです。**Dockには表示されません。

※開発元が不明で開けない、という警告が出たら、「システム環境設定」を開き、「セキュリティとプライバシー」の「一般」タブの実行許可欄に「そのまま開く」ボタンが表示されていると思いますのでそちらをクリックしてください。

# アプリの使い方

## メイン画面

<img width="320" alt="" src="https://user-images.githubusercontent.com/24717967/118834264-0da3b000-b8fd-11eb-8dd1-e7da4f1277bc.png">

1. メニュー
2. ワークスペースの切り替え
3. 新規ミーティング追加
4. タイトルでの絞り込み検索
5. 日付での絞り込み検索
6. ミーティング編集
7. ミーティングアーカイブ
   アーカイブするとデータ自体は残りますが一覧から非表示になります。

## ユーザー設定

メニューから設定画面を開くことができます。

<img width="480" alt="" src="https://user-images.githubusercontent.com/24717967/118833719-a259de00-b8fc-11eb-8391-f1aae7d0aeda.png">

1. アイコン画像設定。必ず正方形の画像を使用してください。
2. ユーザー名。えんぴつアイコンを押すと編集、チェックアイコンに変わるのでそれをクリックで保存。
3. 言語設定。Appleの音声認識エンジンを使って書き起こしする時に適用されます。
4. [話者認識](#話者認識)で使用する声紋を取る機能です。

## ワークスペース設定

<img width="480" alt="" src="https://user-images.githubusercontent.com/24717967/118834176-fd8bd080-b8fc-11eb-8341-83218cc817da.png">

1. ワークスペース名
2. ワークスペースに所属するメンバーの選択。ここで選択されたメンバーのみが、このワークスペースのミーティングに参加できます。
3. [話者認識](#話者認識)の有効/無効の切り替えスイッチ。

## 書き起こし画面

<img width="320" alt="" src="https://user-images.githubusercontent.com/24717967/118834370-244a0700-b8fd-11eb-8d6d-83dbd2813314.png">

1. ミーティングの参加者が表示されます。ミーティングウィンドウを開いているユーザーには赤丸印が付き、マイク入力を受け付けるのはそのユーザーのみです。
   各々の端末のマイクを使用するため、複数人が同室にいる状態でのミーティングを行う際には、全員がウィンドウを開くと、それら複数の端末のマイクから音声を拾い、書き起こし内容が重複する可能性が高くなります。そのため、その状況下では、ウィンドウを開くユーザーを1人とし、[話者認識](#話者認識)機能を使うことをおすすめします。
   逆にリモート会議のような別々の場所でミーティングを行う場合には、場所が離れているユーザーは必ずウィンドウを開いてマイク入力を有効にする必要があります。
2. 書き起こし内容のエクスポートや音声ファイルのエクスポートをするボタンです。
3. 書き起こし結果の表示部分を開閉するボタンです。
4. ミーティング開始ボタンです。開始すると書き起こしと録音が始まります。開始ボタンを押したユーザーがホストとなり、ホストのみがミーティングを終了させられます。終了時に開始から終了までの時間分が録音ファイルとしてFirebaseのストレージにアップロードされます。そのためホストユーザーは終了することを必ず忘れないように注意してください。

# 高度な機能

ここではより書き起こしの精度を上げるためのオプション機能について記載します。

## 話者認識

複数人が同室にいる状態でのミーティングを行う際には、複数のマイクで話者の音声を拾わないように、誰か1人がミーティングウィンドウを開きマイク入力を1つとする必要があります。
ただし、入力された音声はその端末のユーザと認識されるため誰が喋ったものなのかが判別できなくなります。
話者認識機能を使うことで、その判別が可能になります。話者認識機能を使うには、「ワークスペース内のユーザーの声紋を取る」ことと「話者認識モデルの作成」が必要になります。

### 前準備

話者認識モデルの作成には、Xcodeに同梱されている「Create ML」アプリを使用します。事前にXcodeのインストールを行ってください。

### 声紋の取得

メニューのPreferencesよりユーザー設定を開き「Create voiceprint」をクリックします。
開始ボタンを押すとそのまま録音が始まりますので、内容はなんでもいいので**20秒間途切れず何か喋り続けてください。**
開始ボタンを押すと20秒間のカウントダウンが始まり、0になると録音をやめ、録音ファイルがストレージに自動的にアップロードされます。

話者認識の精度を上げるには以下のようなポイントを意識してください。要は、録音環境とミーティングの実環境に差異がない方が精度が上がりやすくなります。

* いつも会議する場所があればそこで録音をする。
* いつも使っているマイクを使って録音する。
* いつも話している時の自然な声で録音する。

### 話者認識モデルの作成

1. メニューのPreferencesよりワークスペース設定を開き、ワークスペースの新規追加または編集画面で「Enable speaker recognition」を有効にします。
2. 「Export a learning data set」ボタンを押して任意の場所に学習用の音声ファイルを出力します。
3. 



## 音声認識エンジンAmiVoiceの使用(日本語向け機能)



# ライセンス

ButterflyのソースコードはMITライセンスです。

使用ライブラリのライセンスは以下を参照ください。

[Firebase](https://github.com/firebase/firebase-ios-sdk/blob/master/LICENSE)

[Hydra](https://github.com/malcommac/Hydra/blob/master/LICENSE)

[SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver/blob/master/LICENSE)

[Starscream](https://github.com/daltoniam/Starscream/blob/master/LICENSE)