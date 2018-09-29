#!/usr/bin/env ruby

require "ncurses.rb"
require "json"
require "net/http"
require "uri"
require "thread"
require "nokogiri"
require "optparse"
require "time"

class User
  def initialize(account)
    @id = account["id"]
    @username = account["username"]
    @display_name = if account["display_name"] == ""
                      account["username"]
                    else
                      account["display_name"]
                    end
    @acct = account["acct"]
    @created_at = account["created_at"]
    @locked = account["locked"]
    @followers_count = account["followers_count"]
    @following_count = account["following_count"]
    @statuses_count = account["statuses_count"]
    @note = account["note"]
    @url = account["url"]
    @avatar = account["avatar_static"]
    @header = account["header"]
    @moved = account["moved"]
    @emojis = account["emojis"]
  end

  def name
    @display_name
  end

  def name=(name)
    @display_name = name
  end

  def acct
    @acct
  end

  def icon
    @avatar
  end

  def emojis
    @emojis
  end

  def emojis?
    return !@emojis.nil?
  end
end

class Toot
  def initialize(toot)
    @id = toot["id"]
    @url = toot["url"]
    @account = User.new(toot["account"])
    @in_reply_to_id = toot["in_reply_to_id"]
    @in_reply_to_account_id = toot["in_reply_to_account_id"]
    @reblog = toot["reblog"]
    @content = toot["content"]
    @created_at = toot["created_at"]
    @emojis = toot["emojis"]
    @reblogs_count = toot["reblogs_count"]
    @favourites_count = toot["favourites_count"]
    @reblogged = toot["reblogged"]
    @favourited = toot["favourited"]
    @muted = toot["muted"]
    @sensitive = toot["sensitive"]
    @spoiler_text = toot["spoiler_text"]
    @visibility = toot["visibility"]
    @media_attachments = toot["media_attachments"]
    @mentions = toot["mentions"]
    @tags = toot["tags"]
    @application = toot["application"]
    @language = toot["language"]
    @pinned = toot["pinned"]
    if !toot["reblog"].to_s.empty?
      @rebloger = User.new(toot["account"])
    end
  end

  def id
    @id
  end

  def reblog_parse
    @id = @reblog["id"]
    @url = @reblog["url"]
    @account = User.new(@reblog["account"])
    @in_reply_to_id = @reblog["in_reply_to_id"]
    @in_reply_to_account_id = @reblog["in_reply_to_account_id"]
    @content = @reblog["content"]
    @created_at = @reblog["created_at"]
    @emojis = @reblog["emojis"]
    @reblogs_count = @reblog["reblogs_count"]
    @favourites_count = @reblog["favourites_count"]
    @reblogged = @reblog["reblogged"]
    @favourited = @reblog["favourited"]
    @muted = @reblog["muted"]
    @sensitive = @reblog["sensitive"]
    @spoiler_text = @reblog["spoiler_text"]
    @visibility = @reblog["visibility"]
    @media_attachments = @reblog["media_attachments"]
    @mentions = @reblog["mentions"]
    @tags = @reblog["tags"]
    @application = @reblog["application"]
    @language = @reblog["language"]
    @pinned = @reblog["pinned"]
  end

  def img
    @media_attachments
  end

  def reblog?
    return !@reblog.to_s.empty?
  end

  def images?
    return @media_attachments.length >= 1
  end

  def emojis?
    return !@emojis.nil?
  end

  def emojis
    @emojis
  end

  def to_safe
    if @sensitive
      @media_attachments = {}
    end
    if !@spoiler_text.empty?
      @content = "<p>🔞In Safe Mode, This Content Can't be Displayd.🔞</p>"
    end
  end

  def shortcode2emoji
    if @account.emojis?
      @account.emojis.each{ |emoji|
        code = Regexp.new(":#{emoji["shortcode"]}:")
        @account.name =  @account.name.gsub(code, "#{`img2sixel -w 15 -h 15 #{emoji["static_url"]}`} \x1b[1A\x1b[1C")
      }
    end

    if self.emojis?
      @emojis.each{ |emoji|
        code = Regexp.new(":#{emoji["shortcode"]}:")
        @spoiler_text = @spoiler_text.gsub(code, "#{`img2sixel -w 15 -h 15 #{emoji["static_url"]}`} \x1b[1A\x1b[1C")
        @content = @content.gsub(code, "#{`img2sixel -w 15 -h 15 #{emoji["static_url"]}`} \x1b[1A\x1b[1C")
      }
    end
  end

  def print_toot_info
    vi = case @visibility
        when "public" then
          ""
        when "unlisted" then
          "🔓 "
        when "private" then
          "🔒 "
        when "direct" then
          "✉ "
        else
          ""
      end
    print "#{vi}\e[33m#{@account.name}\e[32m @#{@account.acct} "
    print "\e[0m#{Time.parse(@created_at).localtime.strftime("%Y/%m/%d %H:%M")} \n"
  end

  def print_reblog
    print "\e[32mRT "
    print_user_icon("32", true)
  end

  def print_reblog_no_sixel
    print "\e[32mRT \e[33m#{@rebloger.name}\e[32m @#{@rebloger.acct} \n"
  end

  def parse_toot_body
    if !@spoiler_text.empty?
      s = Nokogiri::HTML.parse(@spoiler_text,nil,"UTF-8")
      s.search('br').each do |br|
        br.replace("\n")
      end

      @spoiler_text = s.text
    end

    t = Nokogiri::HTML.parse(@content,nil,"UTF-8")

    t.search('br').each do |br|
      br.replace("\n")
    end

    @content = t.text
  end

  def print_toot_body
    if !@spoiler_text.empty?
      print "#{@spoiler_text}"
      puts "\n"
    end

    print "#{@content}"
    puts "\n\n"
  end

  def printimg
    self.img.each do |img|
      if img["type"] == "image"
        system("img2sixel #{img["preview_url"]}")
      end
    end
  end

  def print_user_icon(size, reblog)
    icon = if reblog
             @rebloger.icon
           else
             @account.icon
           end
    print `curl -L -k -s #{icon} | img2sixel -w #{size} -h #{size}`
    print "\x1b[2A\x1b[5C"
  end
end

class Notification
  def initialize(json)
    @id = json["id"]
    @type = json["type"]
    @created_at = json["created_at"]
    @account = User.new(json["account"])
    @status = if !json["status"].nil?
                Toot.new(json["status"])
              else
                ""
              end
  end

  def print_notification
    case @type
    when "reblog", "favourite", "mention" then
      case @type
      when "mention" then
        print "\e[37;0;1m↩️  Reply "
      when "favourite" then
        print "\e[37;0;1m🌠 Favourite \e[33m#{@account.name}\e[32m @#{@account.acct} \n"
      when "reblog" then
        print "\e[37;0;1m🔄 Boost \e[33m#{@account.name}\e[32m @#{@account.acct} \n"
      end
      @status.print_toot
    when "follow" then
      print "\e[37;0;1m📲 Follow \e[33m#{@account.name}\e[32m @#{@account.acct} \n"
    end
  end
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

  file.close

  begin
    ac = JSON.parse(file_str)
  rescue
    puts "Parse Error"
    exit 1
  end
  return ac
end

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

def stream(account, tl, param, img, safe)
  uri = URI.parse("https://#{account["host"]}/api/v1/streaming/#{tl}")

  uri.query = URI.encode_www_form(param)

  buffer = ""

  Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |https|
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = " Bearer " + account["token"]

    https.request(req) do |res|
      puts "Connect: #{res.code}"
      if res.code != "200"
        puts res.message
        puts res.body
      end
      res.read_body do |chunk|
        buffer += chunk
        while index = buffer.index(/\r\n\r\n|\n\n/)
          stream = buffer.slice!(0..index)
          json = sse_parse(stream)
          if json[:event] == "update"
            ary = []
            ary.push(JSON.parse(json[:body]))
            print_timeline(ary, false, param, img, true, safe)
          elsif json[:event] == "notification"
            n = Notification.new(JSON.parse(json[:body]))
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
          print "\n\n"
        end
      end
      if img
        t.printimg
        puts "\n"
      end
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
  sixel_term = system('stty -echo; echo -en "\e[c"; read -d c da1 <&1; stty echo; echo -E "${da1#*\?}" | grep "4;" >& /dev/null')
  sixel_com = system("which img2sixel >& /dev/null")

  return sixel_term && sixel_com
end

config_path = if ENV["CT_CONFIG_PATH"].nil?
                "account.json"
              else
                ENV["CT_CONFIG_PATH"]
              end
account = load_account(config_path)
tl = "home"
tl_id = nil
limit = 20
stream = false
param = Hash.new
img = test_sixel
rev = false
safe = false

flags = {stream:false, img:false, rev:false, safe:false}

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
    stream(account, tl, param, img, safe)
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
