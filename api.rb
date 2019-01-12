require 'net/http'
require 'uri'
require 'json'
require 'mime/types'
require "nokogiri"
require "thread"

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
