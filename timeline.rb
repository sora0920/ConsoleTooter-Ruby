#!/usr/bin/env ruby

require "ncurses.rb"
require "json"
require "net/http"
require "uri"
require "thread"
require "nokogiri"
require "optparse"

class User
  def initialize(account)
    @id = account["id"]
    @username = account["username"]
    @display_name = if account["display_name"].empty?
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
    @avatar = account["avatar"]
    @header = account["header"]
    @moved = account["moved"]
  end

  def get
    {
      "acct": @acct,
      "display_name": @display_name,
      "locked": @locked,
      "followers_count": @followers_count,
      "following_count": @following_count,
      "statuses_count": @statuses_count,
      "note": @note,
      "url": @url,
      "avatar": @avatar,
      "header": @header,
      "moved": @moved
    }
  end


  def name
    @display_name
  end

  def acct
    @acct
  end

  def reload
    uri = URI.parse("https://#{account["host"]}/api/v1/accounts/#{@id}")
    
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    
    req = Net::HTTP::Get.new(uri.path)
    req["Authorization"] = " Bearer " + account["token"]

    res = https.request(req)

    self.initialize(JSON.parse(res.body))
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
  end

  def id
    @id
  end

  def get
    {
      "id": @id,
      "url": @url,
      "account": @account,
      "in_reply_to_id": @in_reply_to_id,
      "in_reply_to_account_id": @in_reply_to_account_id,
      "reblog": @reblog,
      "content": @content,
      "created_at": @created_at,
      "emojis": @emojis,
      "reblogs_count": @reblogs_count,
      "favourites_count": @favourites_count,
      "reblogged": @reblogged,
      "favourited": @favourited,
      "muted": @muted,
      "sensitive": @sensitive,
      "spoiler_text": @spoiler_text,
      "visibility": @visibility,
      "media_attachments": @media_attachments,
      "mentions": @mentions,
      "tags": @tags,
      "application": @application,
      "language": @language,
      "pinned": @pinned
    }
  end

  def img
    @media_attachments
  end

  def print
    puts "#{@account.name} @#{@account.acct}"
    if !@spoiler_text.empty?
      s = Nokogiri::HTML.parse(@spoiler_text,nil,"UTF-8")
      s.search('br').each do |br| 
        br.replace("\n")
      end

      puts s.text
      puts "\n"
    end

    t = Nokogiri::HTML.parse(@content,nil,"UTF-8")
    t.search('br').each do |br| 
      br.replace("\n")
    end

    puts t.text
    puts "\n"
  end

  def printimg
    imgs = self.img

    imgs.each do |img|
      if img["type"] == "image"
        system("img2sixel #{img["preview_url"]}")
      end
    end
  end


  def reload(account)
    uri = URI.parse("https://#{account["host"]}/api/v1/statuses/#{@id}")
    
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    
    req = Net::HTTP::Get.new(uri.path)
    req["Authorization"] = " Bearer " + account["token"]

    res = https.request(req)

    self.initialize(JSON.parse(res.body))
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

def timeline_load(account, tl, param, img, rev)
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
  
  
  toots = JSON.parse(res.body)
  
  i = 0
  if rev
    toots.each{|toot|
      if i > param["limit"].to_i - 1
        exit 0
      end
      t = Toot.new(toot)
      t.print
      if img
        t.printimg
        puts "\n"
      end
      i += 1
    }
  else
    _toots = []

    toots.each{|toot|
      if i > param["limit"].to_i - 1
        puts "break!"
        break
      end
      _toots.unshift(toot)
      i += 1
    }
    _toots.each{|toot|
      t = Toot.new(toot)
      t.print
      if img
        t.printimg
        puts "\n"
      end
    }
  end
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


account = load_account("account.json")
tl = "home"
limit = `tput lines`
stream = false
param = Hash.new
img = false
rev = false

OptionParser.new do |opt|
  opt.on('--home',            'Display home timeline'                      ) { tl = "home" }
  opt.on('--local',           'Display local timeline'                     ) { 
                                                                                tl = "public"
                                                                                param.store("local","1")
                                                                             }
  opt.on('--public',          'Display public timeline'                    ) { tl = "public" }
  opt.on('--stream',          'Start up in streaming mode'                 ) { stream = true }
  opt.on('--onlymedia',       'Retrieve only posts that include media'     ) { param.store("only_media", "1") }
  opt.on('--list [ID]',       'Display list timeline'                      ) { |id| tl = "list/#{id}?" }
  opt.on('--limit [1-40]',    'Specify the number of Toot to acquire'      ) { |lim| limit = lim }
  opt.on('--lists',           'Retrieving lists'                           ) { 
                                                                               listlist(account) 
                                                                               exit 0
                                                                             }
  opt.on('--rev',             'Inversion of order'                         ) { rev = true }
  
  opt.parse!(ARGV)
end


if system("img2sixel https://upload.wikimedia.org/wikipedia/en/a/a9/Example.jpg >& /dev/null")
  img = true
end

param.store("limit", "#{limit}")
timeline_load(account, tl, param, img, rev)

