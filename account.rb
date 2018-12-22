require "json"

def load_account
  config_path = if ENV["CT_CONFIG_PATH"].nil?
                  "account.json"
                else
                  ENV["CT_CONFIG_PATH"]
                end

  begin
    file = File.open(config_path, "a+")
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
