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



# ライセンス

ButterflyのソースコードはMITライセンスです。

使用ライブラリのライセンスは以下を参照ください。

[Firebase](https://github.com/firebase/firebase-ios-sdk/blob/master/LICENSE)

[Hydra](https://github.com/malcommac/Hydra/blob/master/LICENSE)

[SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver/blob/master/LICENSE)

[Starscream](https://github.com/daltoniam/Starscream/blob/master/LICENSE)