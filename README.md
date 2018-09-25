# ConsoleTooter-Ruby
Rubyで作ったConsoleTooterだよぉ
# これなに
ターミナルでMastodonできるやつ
# なにできる
1. 投稿(画像投稿、CW、公開範囲指定、リプライへの返信、echo-sdによる突然の死)
2. タイムラインの取得(ホーム、ローカル、連合、リスト、Hashtag、Sixelによる画像表示、Sixelによるカスタム絵文字表示, ストリーミング)
3. 通知の表示(ストリーミングしている場合のみ)
4. フォロー (リモートフォロー、ローカルでのフォロー)

# 下拵え
- account.jsonにhostとtokenをつっこむ

または

- 環境変数``CT_CONFIG_PATH``に任意のコンフィグファイルを指定する
