#!/usr/bin/env ruby

require 'optparse'
require_relative "./api.rb"
require_relative "./account.rb"


def to_suddenly_death(toot)
  if system("which echo-sd >& /dev/null")
    str = `echo-sd #{toot}`
    return str
  else
    puts "There is no echo-ed command!"
    exit!
  end
end

account = load_account

vis = "public"
cw = ""
reply_id = ""
media_id = []
sen = false
sd = false

opts = {
  "sensitive" = false,
  "sd" = false,
  "visibility" = "public", 
  "spoiler_text" = "",
  "in_reply_to_id" = "",
  "media_ids" = []
}

OptionParser.new do |opt|
  opt.on('--public',             'Set visibility to public'  ) { vis = "public" }
  opt.on('--unlisted',           'Set visibility to unlisted') { vis = "unlisted" }
  opt.on('--private',            'Set visibility to private' ) { vis = "private" }
  opt.on('--direct',             'Set visibility to direct'  ) { vis = "direct" }
  opt.on('--cw [TEXT]',          'Set CW TEXT=warning text'  ) { |cw_txt| cw = "#{cw_txt}" }
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

post_toot(vis, cw, account, body, reply_id, media_id, sen)
