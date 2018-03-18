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
    puts "未実装"
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


  def reload
    puts "未実装"
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

def timeline_load(account, tl, limit)
  uri = URI.parse("https://#{account["host"]}/api/v1/timelines/#{tl}limit=#{limit}")

  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Get.new(uri.path)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  puts res.code
  
  toots = JSON.parse(res.body)
  toots.each{|toot|
    t = Toot.new(toot)
    t.print
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

def timeline_parse(json)
  puts "未実装" 
end

account = load_account("account.json")
tl = "home?"
limit = `tput lines`
stream = false
mediaonly = false

OptionParser.new do |opt|
  opt.on('--home',            'Display home timeline'                      ) { tl = "home?" }
  opt.on('--local',           'Display local timeline'                     ) { tl = "public?local=true&" }
  opt.on('--public',          'Display public timeline'                    ) { tl = "public?" }
  opt.on('--stream',          'Start up in streaming mode'                 ) { stream = true }
  opt.on('--mediaonly',       'Retrieve only posts that include media'     ) { mediaonly = true }
  opt.on('--list [ID]',       'Display list timeline'                      ) { |id| tl = "list/#{id}?" }
  opt.on('--limit [1-40]',    'Specify the number of Toot to acquire'      ) { |lim| limit = lim }
  opt.on('--lists',           'Retrieving lists'                           ) { 
                                                                               listlist(account) 
                                                                               exit 0
                                                                             }
  
  opt.parse!(ARGV)
end



timeline_load(account, tl, limit)

