#!/usr/bin/env ruby

#require "ncurses.rb"
require "optparse"
require "time"
require_relative "./account.rb"
require_relative "./class/user.rb"
require_relative "./class/toot.rb"
require_relative "./class/notification.rb"
require_relative "./api.rb"

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

def print_screen_line
  term_cols = `tput cols`
  lines = ""
  while lines.length < term_cols.to_i do
    lines += "-"
  end
  puts lines
end

def print_delete(id)
  print "\e[m"
  print "💥 Delete #{Time.new.localtime.strftime("%Y/%m/%d %H:%M")}\n"
  print "ID: #{id}"
  print "\n"
end

# img rev safeはoptsに置き換え。 できればstreamも置き換えたいなぁ...
# なんでstreamとかいう使ってない物まで入ってたんですかねぇ...
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

    print "ID: "
    t.print_post_id

    print_screen_line
  }
end

# rev, param, img, safe
def print_timeline2(toots, opts)
  if !opts["rev"]
    _toots = toots
    toots = []

    _toots.each{|toot|
      toots.unshift(toot)
    }
  end
  toots.each{|toot|
    t = Toot.new(toot)
    if opts["safe"]
      t.to_safe
    end
    if t.reblog?
      t.reblog_parse
    end
      t.parse_toot_body
    if opts["img"]
      t.print_user_icon("32", false)
      t.shortcode2emoji
    end

    t.print_toot_info
    if opts["img"]
      print "\x1b[5C"
    end
    t.print_toot_body
    if t.reblog?
      if opts["img"]
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
    if opts["img"]
      t.printimg
      puts "\n"
    end

    print "ID: "
    t.print_post_id

    print_screen_line
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

def test_notify_send
  return system("which notify-send > /dev/null 2>&1")
end

account = load_account
# tlとかもできれば置き換えたい
#tl = "home"
#tl_id = nil
#limit = 20
#stream = false
#param = Hash.new
#img = test_sixel
#rev = false
#safe = false

# お前にこのコードの未来がかかってるんだよ!!!!!!!
opts = {
  "stream" => false,
  "img" => test_sixel,
  "rev" => false,
  "safe" => false,
  "notify_x" => test_notify_send,
  "tl" => "home",
  "tl_id" => nil,
  "limit" => 20,
  "param" => Hash.new
}

OptionParser.new do |opt|
  opt.on('--home',          'Get the home timeline'                                 ) { opts["tl"] = "home" }
  opt.on('--local',         'Get the local timeline'                                ) { opts["tl"] = "local" }
  opt.on('--public',        'Get the public timeline'                               ) { opts["tl"] = "public" }
  opt.on('--list [ID]',     'Get the list timeline'                                 ) { |id|
                                                                                         opts["tl"] = "list"
                                                                                         opts["tl_id"] = id
                                                                                      }
  opt.on('--hashtag [tag]', 'Get the hashtag timeline'                              ) { |tag|
                                                                                         opts["tl"] = "hashtag"
                                                                                         opts["tl_id"] = tag
                                                                                      }
  opt.on('--stream',        'Use streaming'                                         ) { opts["stream"] = true }
  opt.on('--onlymedia',     'Get posts only included images'                        ) { opts["param"].store("only_media", "1") }
  opt.on('--noimg',         "Don't be displayd image"                               ) { opts["img"] = false }
  opt.on('--safe',          "Don't be displayd NSFW images and CW contents"         ) { opts["safe"] = true }
  opt.on('--limit [1-40]',  "Displayd limit number (Don't work, if using streaming)") { |lim| opts["limit"] = lim }
  opt.on('--lists',         'Get your lists'                                        ) {
                                                                                         listlist(account)
                                                                                         exit 0
                                                                                      }
  opt.on('--rev',           "Reverse the output (Don't work, if using streaming)"   ) { opts["rev"] = true }

  opt.parse!(ARGV)
end

if opts["stream"]
  case opts["tl"]
  when "home" then
    opts["tl"] = "user"
  when "local" then
    opts["tl"] = "public/local"
  when "list" then
    opts["param"].store("list", "#{opts["tl_id"]}")
  when "hashtag" then
    opts["param"].store("tag", "#{opts["tl_id"]}")
  end

  begin
    if opts["tl"] == "user"
      stream2(account, opts, false)
    else
      Thread.new{
        stream2(account, opts, false)
      }
      stream2(account, opts, true)
    end
  rescue Interrupt
    puts "\nBye👋"
    print "\e[m"
    exit 0
  end
else
  case opts["tl"]
  when "local" then
    opts["tl"] = "public"
    opts["param"].store("local","1")
  when "list" then
    opts["tl"] += "/#{opts["tl_id"]}?"
  when "hashtag" then
    opts["tl"] = "tag/#{opts["tl_id"]}?"
  end

  opts["param"].store("limit", "#{opts["limit"]}")
  print_timeline2(timeline_load2(account, opts), opts)

  print "\e[m"
end
