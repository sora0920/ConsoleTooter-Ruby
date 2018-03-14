#!/usr/bin/env ruby

require 'optparse'
require 'net/http'
require 'uri'
require 'json'
require 'mime/types'

def PostToot (vis, cw, account, body, reply_id, media_id)
  uri = URI.parse("https://" + account["host"] + "/api/v1/statuses")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)

  data = {
            status: body,
            visibility: vis,
            spoiler_text: cw,
            in_reply_to_id: reply_id,
            media_ids: media_id
  }.to_json


  token = " Bearer " + account["token"]

  req["Content-Type"] = "application/json"
  req["Authorization"] = token

  req.body = data

  res = https.request(req)

  $http_status_code = "code -> #{res.code}"
  $http_msg = "msg -> #{res.message}"
  $http_body = "body -> #{JSON.parse(res.body)}"
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

  token = " Bearer " + account["token"]

  req["Authorization"] = token
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
  
  begin 
    ac = JSON.parse(file_str)
  rescue
    puts "Parse Error"
    exit 1
  end
  return ac
end

vis = "public"
cw = ""
reply_id = ""
media_id = []
account = {}

OptionParser.new do |opt|
  opt.on('--pb',              'Specify visibility as public'                      ) { vis = "public" }
  opt.on('--ul',              'Specify visibility as unlisted'                    ) { vis = "unlisted" }
  opt.on('--pv',              'Specify visibility as private'                     ) { vis = "private" }
  opt.on('--di',              'Specify visibility as direct'                      ) { vis = "direct" }
  opt.on('--cw [TEXT]',       'Use CW. Please Input CW Text for After this option') { |cw| cw = "#{cw}" }
  opt.on('--re [Reply to ID]','Post as a reply'                                   ) { |re| reply_id = "#{re.to_i}"}
  opt.on('--media [path]',    'Post with images'                                  ) { |media| media_id.push(postmedia(account, media))}
  
  opt.parse!(ARGV)
end


if ARGV[0].nil? || ARGV[0].empty? then
  puts "Error: ARGV[0] is empty!"
  exit!
end 

body = ARGV[0]

account = load_account("account.json")
PostToot(vis, cw, account, body, reply_id, media_id)

puts $http_status_code
puts $http_msg







