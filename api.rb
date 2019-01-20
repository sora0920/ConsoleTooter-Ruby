require 'net/http'
require 'uri'
require 'json'
require 'mime/types'
require "nokogiri"
require "thread"

# opts = sensitive, sd, visibility, spoiler_text, in_reply_to_id, media_ids

# ステータスを投稿する
# @param [Hash] account アカウント情報
# @param [String] body 投稿する文字列
# @param [Hash] opts オプション
# @return [nil]
def post_toot2 (account, body, opts)
  uri = URI.parse("https://" + account["host"] + "/api/v1/statuses")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)

  data = {
    status: body,
    visibility: opts["visibility"],
    spoiler_text: opts["spoiler_text"],
    in_reply_to_id: opts["in_reply_to_id"],
    media_ids: opts["media_ids"],
    sensitive: opts["sensitive"]
  }.to_json

  req["Content-Type"] = "application/json"
  req["Authorization"] = " Bearer " + account["token"]

  req.body = data

  res = https.request(req)

  puts res.code
  puts res.message
end

# ステータスを投稿(互換性用)
# この関数はエラーが起こらないようにするためのものであり廃止予定です
# @param [String] vis 公開範囲の指定
# @param [String] cw 警告文の指定
# @param [Hash] account アカウント情報
# @param [String] body 投稿する文字列
# @param [String] reply_id 他の投稿のリプライとして投稿する場合に付与するID
# @param [Array] media_id 添付するメディアのID
# @param [Boolean] sen NSFWかのフラグ
# @return [nil]
def post_toot (vis, cw, account, body, reply_id, media_id, sen)
  uri = URI.parse("https://" + account["host"] + "/api/v1/statuses")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)

  data = {
            status: body,
            visibility: vis,
            spoiler_text: cw,
            in_reply_to_id: reply_id,
            media_ids: media_id,
            sensitive: sen
  }.to_json

  req["Content-Type"] = "application/json"
  req["Authorization"] = " Bearer " + account["token"]

  req.body = data

  res = https.request(req)

  puts res.code
  puts res.message
end

# 画像をサーバにアップロードする
# @param [Hash] account アカウント情報
# @param [String] filename 画像のパス
# @return [String] アップロードされた画像に付与されたID
def postmedia(account, filename)
  begin
    file = File.open(filename, "a+")
  rescue
    puts "Failed to read file"
    exit 1
  end

  uri = URI.parse("https://" + account["host"] + "/api/v1/media")

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)

  data = [ ["file", file.read , { filename: File.basename(filename), content_type: MIME::Types.type_for(filename)[0].to_s }] ]

  req["Authorization"] = " Bearer " + account["token"]
  req["Content-Type"] = "multipart/form-data"

  req.set_form(data, "multipart/form-data")

  res = https.request(req)

  file.close

  if res.code != "200"
    puts "File upload failed: #{res.message}"
    exit 1
  end

  puts res.code
  puts res.message

  return JSON.parse(res.body)["id"]
end

# ストリームに接続する(互換性用)
# この関数はエラーが起こらないようにするためのものであり廃止予定です
# @param [Hash] account アカウント情報
# @param [String] tl 受信するタイムライン
# @param [Hash] param オプション
# @param [Boolean] img Sixelを使用するかどうか
# @param [Boolean] safe CW, NSFWを非表示にするかどうか
# @param [Boolean] notification_only 通知のみを受信するかどうか
# @return [nil]
def stream(account, tl, param, img, safe, notification_only)
  uri = URI.parse("https://#{account["host"]}/api/v1/streaming/#{tl}")

  uri.query = URI.encode_www_form(param)

  buffer = ""

  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |https|
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = " Bearer " + account["token"]
    req["Content-Type"] = "text/event-stream"

    https.request(req) do |res|
      if notification_only
        puts "Connect(Notification): #{res.code}"
      else
        puts "Connect(#{tl}): #{res.code}"
      end

      if res.code != "200"
        puts res.message
        puts res.body
      end
      res.read_body do |chunk|
        buffer += chunk
        while index = buffer.index(/\r\n\r\n|\n\n/)
          stream = buffer.slice!(0..index)
          json = sse_parse(stream)
          if json[:event] == "update" && !notification_only
            ary = []
            ary.push(JSON.parse(json[:body]))
            print_timeline(ary, false, param, img, true, safe)
          elsif json[:event] == "notification"
            n = Notification.new(JSON.parse(json[:body]), safe, img)
            n.print_notification
            print_screen_line
            # notify-send test
            n.send_notify_notification
          elsif json[:event] == "delete"
            print_delete(json[:body])
            print_screen_line
          end
        end
      end
    end
  end
end

# ストリームに接続する
# @param [Hash] account アカウント情報
# @param [Hash] opts オプション
# @param [Boolean] notification_only 通知のみのストリームかのフラグ
# @return [nil]
def stream2(account, opts, notification_only)# tl, param, img, safe, notification_only)
  if notification_only
    uri = URI.parse("https://#{account["host"]}/api/v1/streaming/user")
  else
    uri = URI.parse("https://#{account["host"]}/api/v1/streaming/#{opts["tl"]}")
  end

  uri.query = URI.encode_www_form(opts["param"])

  buffer = ""

  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |https|
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = " Bearer " + account["token"]
    req["Content-Type"] = "text/event-stream"

    https.request(req) do |res|
      if notification_only
        puts "Connect(Notification): #{res.code}"
      else
        puts "Connect(#{opts["tl"]}): #{res.code}"
      end

      if res.code != "200"
        puts res.message
        puts res.body
      end
      res.read_body do |chunk|
        buffer += chunk
        while index = buffer.index(/\r\n\r\n|\n\n/)
          stream = buffer.slice!(0..index)
          json = sse_parse(stream)
          if json[:event] == "update" && !notification_only
            ary = []
            ary.push(JSON.parse(json[:body]))
            print_timeline(ary, false, opts["param"], opts["img"], true, opts["safe"])
          elsif json[:event] == "notification"
            n = Notification.new(JSON.parse(json[:body]), opts["safe"], opts["img"])
            n.print_notification
            print_screen_line
            # notify-send test
            if opts["notify_x"]
              n.send_notify_notification
            end
          elsif json[:event] == "delete"
            print_delete(json[:body])
            print_screen_line
          end
        end
      end
    end
  end
end

# タイムラインを取得する
# @param [Hash] account アカウント情報
# @param [String] tl 取得するタイムライン
# @param [Hash] param オプション
# @return [Hash] 指定した件数分のステータスのHash
def timeline_load(account, tl, param)
  uri = URI.parse("https://#{account["host"]}/api/v1/timelines/#{tl}")

  uri.query = URI.encode_www_form(param)

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri.request_uri)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  if res.code != "200"
    puts res.code
    puts res.message
    puts res.body
  end

  return JSON.parse(res.body)
end

# タイムラインを取得する
# @param [Hash] account アカウント情報
# @param [Hash] opts オプション
# @return [Hash] 指定した件数分のステータスのHash
def timeline_load2(account, opts)
  uri = URI.parse("https://#{account["host"]}/api/v1/timelines/#{opts["tl"]}")

  uri.query = URI.encode_www_form(opts["param"])

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri.request_uri)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  if res.code != "200"
    puts res.code
    puts res.message
    puts res.body
  end

  return JSON.parse(res.body)
end

# リストのリストを取得して表示する
# @param [Hash] account アカウント情報
# @return [nil]
def listlist(account)
  uri = URI.parse("https://#{account["host"]}/api/v1/lists")

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri.path)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  lists = JSON.parse(res.body)

  puts "ID  Title\n\n"
  lists.each{ |list|
    li = list
    puts "#{li["id"]}  #{li["title"]}"
  }
end

# フォロー
# @param [Hash] account アカウント情報
# @param [String] id フォローされるアカウントのID
# @return [nil]
def follow (account, id)
  if /^\w+$/ === id
    id += "@#{account["host"]}"
  end

  uri = URI.parse("https://" + account["host"] + "/api/v1/follows")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)

  data = {
            uri: id
  }.to_json

  req["Content-Type"] = "application/json"
  req["Authorization"] = " Bearer " + account["token"]

  req.body = data

  res = https.request(req)

  puts res.code
  puts res.message
end

# ふぁぼる
# @param [Hash] account アカウント情報
# @param [String] id ふぁぼられるステータスのID
# @return [nil]
def favourite(account, id)
  uri = URI.parse("https://" + account["host"] + "/api/v1/statuses/#{id}/favourite")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  puts res.code
  puts res.message
end

# ふぁぼを外す
# @param [Hash] account アカウント情報
# @param [String] id ふぁぼを外されるステータスのID
# @return [nil]
def unfavourite(account, id)
  uri = URI.parse("https://" + account["host"] + "/api/v1/statuses/#{id}/unfavourite")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  puts res.code
  puts res.message
end

# ユーザからのフォローリクエスト扱いをサーバに送信する
# @param [Hash] account アカウント情報
# @param [String] id フォローリクエスト元のアカウントID
# @param [String] reply ユーザの入力した処理
# @return [nil]
def follow_request_reply(account, id, reply)
  uri = URI.parse("https://" + account["host"] + "/api/v1/follow_requests/#{id}/#{reply}")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  puts res.code
  puts res.message
end

# フォローリクエストを取得する
# @param [Hash] account アカウント情報
# @return [Hash] フォローリクエストを送信してきたアカウント情報
def get_follow_requests(account)
  uri = URI.parse("https://#{account["host"]}/api/v1/follow_requests")

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri.path)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  requests = JSON.parse(res.body)

  print "#{res.code} #{res.message}\n"
  return requests
end

# ステータスを取得する
# @param [Hash] account アカウント情報
# @oaram [String] id ステータスのID
# @return [Hash] Hash化されたステータス情報
def get_status(account, id)
  uri = URI.parse("https://#{account["host"]}/api/v1/statuses/#{id}")

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri.path)
  req["Authorization"] = "Bearer #{account["token"]}"

  res = https.request(req)

  puts res.code
  puts res.message
  return JSON.parse(res.body)
end
