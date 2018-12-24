class Notification
  def initialize(json, safe, img)
    @id = json["id"]
    @type = json["type"]
    @created_at = json["created_at"]
    @account = User.new(json["account"])
    @status = if !json["status"].nil?
                Toot.new(json["status"])
              else
                ""
              end
    @safe = safe
    @img = img
  end

  def print_notification
    case @type
    when "reblog", "favourite", "mention" then
      case @type
      when "mention" then
        print "\e[37;0;1m"
        print "↩️  Reply \n"
      when "favourite" then
        print "\e[37;0;1m"
        print "🌠 Favourie "
        print "\e[33m"
        print "#{@account.display_name}"
        print "\e[32m"
        print " @#{@account.acct} \n"
      when "reblog" then
        print "\e[37;0;1m"
        print "🔄 Boost "
        print "\e[33m"
        print "#{@account.display_name}"
        print "\e[32m"
        print " @#{@account.acct} \n"
      end
      if @safe
        @status.to_safe
      end
      @status.parse_toot_body
      if @img
        @status.print_user_icon("32", false)
        @status.shortcode2emoji
      end
      @status.print_toot_info
      if @img
        print "\x1b[5C"
      end
      @status.print_toot_body
      if @img
        @status.printimg
        puts "\n"
      end
    when "follow" then
      print "\e[37;0;1m"
      print "📲 Follow "
      print "\e[33m"
      print "#{@account.display_name}"
      print "\e[32m "
      print "@#{@account.acct} \n"
    end
  end
end
