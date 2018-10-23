class Toot
  attr_reader :id, :emojis

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

  def reblog?
    return !@reblog.to_s.empty?
  end

  def images?
    return @media_attachments.length >= 1
  end

  def emojis?
    return !@emojis.nil?
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
        @account.display_name =  @account.display_name.gsub(code, "#{`curl -L -k -s #{emoji["static_url"]} | img2sixel -w 15 -h 15`} \x1b[1A\x1b[1C")
      }
    end

    if self.emojis?
      @emojis.each{ |emoji|
        code = Regexp.new(":#{emoji["shortcode"]}:")
        @spoiler_text = @spoiler_text.gsub(code, "#{`curl -L -k -s #{emoji["static_url"]} | img2sixel -w 15 -h 15`} \x1b[1A\x1b[1C")
        @content = @content.gsub(code, "#{`curl -L -k -s #{emoji["static_url"]} | img2sixel -w 15 -h 15`} \x1b[1A\x1b[1C")
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
    print "#{vi}"
    print "\e[33m"
    print "#{@account.display_name}"
    print "\e[32m"
    print " @#{@account.acct} "

    print "\e[0m#{Time.parse(@created_at).localtime.strftime("%Y/%m/%d %H:%M")} \n"
  end

  def print_reblog
    print "\e[32m"
    print "RT "
    print_user_icon("32", true)
  end

  def print_reblog_no_sixel
    print "\e[32m"
    print "RT "
    print "\e[33m"
    print "#{@rebloger.display_name}"
    print "\e[32m"
    print " @#{@rebloger.acct} \n"
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
    @media_attachments.each do |img|
      if img["type"] == "image"
        system("curl -L -k -s #{img["preview_url"]} | img2sixel")
      end
    end
  end

  def print_user_icon(size, reblog)
    icon = if reblog
             @rebloger.avatar
           else
             @account.avatar
           end
    print `curl -L -k -s #{icon} | img2sixel -w #{size} -h #{size}`
    print "\x1b[2A\x1b[5C"
  end
end
