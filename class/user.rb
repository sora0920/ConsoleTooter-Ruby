class User
  attr_reader :acct, :emojis, :display_name, :avatar
  attr_writer :display_name

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

  def emojis?
    return !@emojis.nil?
  end
end
