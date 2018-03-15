require "ncurses.rb"
require "json"
require "net/http"
require "uri"
require "thread"
require "nokogiri"
require "optparse"

def timeline_create(account, tl, tl_name)
  uri = URI.parse("https://#{host}/api/v1/timelines/#{tl}limit=40")

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri.path)
  req["Authorization"] = token

  res = https.request(req)

  toots = JSON.parse(res.body)

  toots.each{ |toot|
    Plugin.call :extract_receive_message, tl_name, create_toot(toot)
  }
end

