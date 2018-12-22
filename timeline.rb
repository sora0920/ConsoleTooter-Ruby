#!/usr/bin/env ruby

#require "ncurses.rb"
require "json"
require "net/http"
require "uri"
require "thread"
require "nokogiri"
require "optparse"
require "time"
require_relative "./account.rb"
require_relative "./class/user.rb"
require_relative "./class/toot.rb"
require_relative "./class/notification.rb"

def sse_parse(stream)
  data = ""
  name = nil

  stream.split(/\r?\n/).each do |part|
    /^data:(.+)$/.match(part) do |m|
      data += m[1].strip
      data += "\n"
    end
    /^event:(.+)$/.match(part) do |m|
      name = m[1].strip
    end
  end

  return {
    event: name,
    body: data.chomp!
  }
end

def stream(account, tl, param, img, safe, notification_only)
  uri = URI.parse("https://#{account["host"]}/api/v1/streaming/#{tl}")

  uri.query = URI.encode_www_form(param)

  buffer = ""

  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |https|
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = " Bearer " + account["token"]

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

def print_screen_line
  term_cols = `tput cols`
  lines = ""
  while lines.length < term_cols.to_i do
    lines += "-"
  end
  puts lines
end

def print_timeline(toots, rev, param, img, stream, safe)
  if !rev
    _toots = toots
    toots = []

    _toots.each{|toot|
      toots.unshift(toot)
    }
  end
    toots.each{|toot|
      t = Toot.new(toot)
      if safe
        t.to_safe
      end
      if t.reblog?
        t.reblog_parse
      end
        t.parse_toot_body
      if img
        t.print_user_icon("32", false)
        t.shortcode2emoji
      end

      t.print_toot_info
      if img
        print "\x1b[5C"
      end
      t.print_toot_body
      if t.reblog?
        if img
          print "\x1b[5C"
          t.print_reblog
          print "\n\n"
          if t.images?
            puts ""
          end
        else
          t.print_reblog_no_sixel
          print "\e[0m"
        end
      end
      if img
        t.printimg
        puts "\n"
      end
      print_screen_line
    }
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

def test_sixel
  if system("ls -la /bin/sh | grep bash > /dev/null 2>&1")
    sixel_term = system('stty -echo; echo -en "\e[c"; read -d c da1 <&1; stty echo; echo -E "${da1#*\?}" | grep "4;" >& /dev/null')
  else
    sixel_term = true
  end
  sixel_com = system("which img2sixel > /dev/null 2>&1")

  puts "Use Sixel: #{sixel_term && sixel_com}"

  return sixel_term && sixel_com
end


account = load_account
tl = "home"
tl_id = nil
limit = 20
stream = false
param = Hash.new
img = test_sixel
rev = false
safe = false

#flags = {stream:false, img:false, rev:false, safe:false}

OptionParser.new do |opt|
  opt.on('--home',          'Get the home timeline'                                 ) { tl = "home" }
  opt.on('--local',         'Get the local timeline'                                ) { tl = "local" }
  opt.on('--public',        'Get the public timeline'                               ) { tl = "public" }
  opt.on('--list [ID]',     'Get the list timeline'                                 ) { |id|
                                                                                         tl = "list"
                                                                                         tl_id = id
                                                                                      }
  opt.on('--hashtag [tag]', 'Get the hashtag timeline'                              ) { |tag|
                                                                                         tl = "hashtag"
                                                                                         tl_id = tag
                                                                                      }
  opt.on('--stream',        'Use streaming'                                         ) { stream = true }
  opt.on('--onlymedia',     'Get posts only included images'                        ) { param.store("only_media", "1") }
  opt.on('--noimg',         "Don't be displayd image"                               ) { img = false }
  opt.on('--safe',          "Don't be displayd NSFW images and CW contents"         ) { safe = true }
  opt.on('--limit [1-40]',  "Displayd limit number (Don't work, if using streaming)") { |lim| limit = lim }
  opt.on('--lists',         'Get your lists'                                        ) {
                                                                                         listlist(account)
                                                                                         exit 0
                                                                                      }
  opt.on('--rev',           "Reverse the output (Don't work, if using streaming)"   ) { rev = true }

  opt.parse!(ARGV)
end

if stream
  case tl
  when "home" then
    tl = "user"
  when "local" then
    tl = "public/local"
  when "list" then
    param.store("list", "#{tl_id}")
  when "hashtag" then
    param.store("tag", "#{tl_id}")
  end

  begin
    if tl == "user"
      stream(account, tl, param, img, safe, false)
    else
      Thread.new{
        stream(account, tl, param, img, safe, false)
      }
      stream(account, "user", param, img, safe, true)
    end
  rescue Interrupt
    puts "\nBye👋"
    print "\e[m"
    exit 0
  end
else
  case tl
  when "local" then
    tl = "public"
    param.store("local","1")
  when "list" then
    tl += "/#{tl_id}?"
  when "hashtag" then
    tl = "tag/#{tl_id}?"
  end

  param.store("limit", "#{limit}")
  print_timeline(timeline_load(account, tl, param), rev, param, img, false, safe)
  print "\e[m"
end
