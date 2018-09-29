#!/usr/bin/env ruby

require 'optparse'
require 'net/http'
require 'uri'
require 'json'
require 'mime/types'

def load_account(file)
  begin
    file = File.open(file, "a+")
  rescue
    puts "Error"
    exit 1
  end

  file_str = []
  file.each_line do |line|
    file_str.push(line.chop)
  end

  file_str = file_str.join("\n")

  file.close

  begin
    ac = JSON.parse(file_str)
  rescue
    puts "Parse Error"
    exit 1
  end
  return ac
end

def posttoot (vis, cw, account, body, reply_id, media_id, sen)
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


def to_suddenly_death(toot)
  if system("which echo-sd >& /dev/null")
    str = `echo-sd #{toot}`
    return str
  else
    puts "There is no echo-ed command!"
    exit!
  end
end

config_path = if ENV["CT_CONFIG_PATH"].nil?
                "account.json"
              else
                ENV["CT_CONFIG_PATH"]
              end
account = load_account(config_path)
vis = "public"
cw = ""
reply_id = ""
media_id = []
sen = false
sd = false

OptionParser.new do |opt|
  opt.on('--public',             'Set visibility to public'  ) { vis = "public" }
  opt.on('--unlisted',           'Set visibility to unlisted') { vis = "unlisted" }
  opt.on('--private',            'Set visibility to private' ) { vis = "private" }
  opt.on('--direct',             'Set visibility to direct'  ) { vis = "direct" }
  opt.on('--cw [TEXT]',          'Set CW TEXT=warning text'  ) { |cw| cw = "#{cw}" }
  opt.on('--reply [Reply to ID]','Post reply'                ) { |re| reply_id = "#{re.to_i}"}
  opt.on('--media [path]',       'Post with images'          ) { |media| media_id.push(postmedia(account, media))}
  opt.on('--nsfw',               'Set NSFW flag'             ) { sen = true }
  opt.on('--sd',                 'To "totsuzen no shi"'      ) { sd = true }

  opt.parse!(ARGV)
end


if ARGV[0].nil? || ARGV[0].empty? then
  puts "Error: ARGV[0] is empty!"
  exit!
end

if sd
  body = to_suddenly_death(ARGV[0])
else
  body = ARGV[0]
end

posttoot(vis, cw, account, body, reply_id, media_id, sen)
