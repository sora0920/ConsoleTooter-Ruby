require "ncurses.rb"
require "json"
require "net/http"
require "uri"
require "thread"
require "nokogiri"
require "optparse"

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
  puts res.body
  return toots = JSON.parse(res.body)
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
  opt.on('--local',           'Display local timeline'                     ) { tl = "?local=true&" }
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



puts timeline_load(account, tl, limit)

