require "net/http"
require "json"
require "optparse"
require_relative "./api.rb"
require_relative "./account.rb"
require_relative "./class/toot.rb"
require_relative "./class/user.rb"
# 入力されたIDの投稿をパクる
# ふぁぼはオプションで実装
# 最終的にはtoot.rbのオプションにしようかななどと

account = load_account

def copy_to_toot(account, id, opts)
  # return array
  status = get_posting_status(get_status(account, id))

  if opts["fav"]
    favourite(account, id)
  end
  if opts["vis"].empty?
    post_toot(status["visibility"], status["spoiler_text"], account, status["status"], status["in_reply_to_id"], "", status["sensitive"])
  else
    post_toot(opts["vis"], status["spoiler_text"], account, status["status"], status["in_reply_to_id"], "", status["sensitive"])
  end
end

def get_posting_status(json)
  status = Toot.new(json)
  status_raw = Nokogiri::HTML.parse(status.content,nil,"UTF-8")

  status_raw.search('br').each do |br|
    br.replace("\n")
  end

  status_text = status_raw.text

  spoiler_raw = Nokogiri::HTML.parse(status.spoiler_text,nil,"UTF-8")
  spoiler_raw.search('br').each do |br|
    br.replace("\n")
  end

  spoiler_text = spoiler_raw.text

  # メディアは後回し
  result = {
    "status" => status_text,
    "in_reply_to_id" => status.in_reply_to_id,
    "sensitive" => status.sensitive,
    "spoiler_text" => spoiler_text,
    "visibility" => status.visibility,
    "language" => status.language
  }

  return result
end

opts = {
  "vis" => "",
  "fav" => false
}
OptionParser.new do |opt|
  opt.on('--public',   'Set visibility to public'  ) { opts["vis"] = "public" }
  opt.on('--unlisted', 'Set visibility to unlisted') { opts["vis"] = "unlisted" }
  opt.on('--private',  'Set visibility to private' ) { opts["vis"] = "private" }
  opt.on('--direct',   'Set visibility to direct'  ) { opts["vis"] = "direct" }
  opt.on('--fav',      'Favourited to copy'        ) { opts["fav"] = true }

  opt.parse!(ARGV)
end

copy_to_toot(account, ARGV[0], opts)
