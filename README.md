# ConsoleTooter-Ruby
Toooooooooooooooooot!!!!!!!!!!!!!!!!!!!!
# これなに
CLIでMastodonできるやつ
# なにいる？
## 必須
- Ruby
- Gem
## 任意
- libsixel(```img2sixel```コマンド)
- curl
- Sixel Graphicsに対応した端末エミュレータ
  - 上記3つの組み合わせでアイコン表示、画像表示、カスタム絵文字表示ができます。
- bash
  - ターミナルがSixelに対応しているかの判定に使われているコードが```/bin/sh```がbashじゃないと正常に動作しないため。```/bin/sh```がbashじゃない場合は判定が常にTrueになります。
- ```echo-sd```コマンド
  - 投稿時に
```
＿人人人人人人＿
＞　突然の死　＜
￣Y^Y^Y^Y^Y^Y￣
```
ができます

# できる!
1. テキスト投稿
2. 画像投稿
3. CW投稿
4. 公開範囲指定投稿
5. リプライへの返信
6. 突然の死の投稿
7. ホームタイムラインの取得
8. ローカルタイムラインの取得
9. 連合タイムラインの取得
10. リストタイムラインの取得
11. Hashtagタイムラインの取得
12. アイコン表示
13. 画像表示
14. カスタム絵文字表示
15. タイムラインすべてのストリーミング
16. ストリーミング時の通知の表示
17. フォロー

# 準備
- ```./account.json```にhostとtokenをつっこむ

または

- 環境変数``CT_CONFIG_PATH``に任意のコンフィグファイルを指定する

# Usage

```command --help```
