require "net/http"
require "nokogiri"
require_relative "./account.rb"
require_relative "./class/user.rb"
require_relative "./api.rb"

account = load_account

def print_screen_line
  term_cols = `tput cols`
  lines = ""
  while lines.length < term_cols.to_i do
    lines += "-"
  end
  puts lines
end

def requests_operation(account)
  requests = get_follow_requests(account)
  requests.each {|request|
    req_user = User.new(request)

    print "\e[33m"
    print "#{req_user.display_name} "
    print "\e[32m"
    print "#{req_user.acct}#{req_user.lock_status}"
    print "\e[0m\n"
    note_raw = Nokogiri::HTML.parse(req_user.note,nil,"UTF-8")

    note_raw.search('br').each do |br|
      br.replace("\n")
    end

    note = note_raw.text
    print "#{note}\n\n"
    print "Web: #{req_user.url}\n"

    print "Accept? [Y/N/(S)kip]\n"
    print "> "
    user_input = gets

    case user_input.chomp
    when "Yes", "yes", "Y", "y" then
      follow_request_reply(account, req_user.id, "authorize")
    when "No", "no", "N", "n" then
      follow_request_reply(account, req_user.id, "reject")
    when "Skip", "skip", "S", "s" then
      puts "Skipped."
    end
    print_screen_line
  }
end

requests_operation(account)
