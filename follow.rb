#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require_relative "./account.rb"

def follow (account, id)
  if /^\w+$/ === id
    id += "@#{account["host"]}"
  end

  uri = URI.parse("https://" + account["host"] + "/api/v1/follows")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)

  data = {
            uri: id
  }.to_json

  req["Content-Type"] = "application/json"
  req["Authorization"] = " Bearer " + account["token"]

  req.body = data

  res = https.request(req)

  puts res.code
  puts res.message
end


config_path = if ENV["CT_CONFIG_PATH"].nil?
                "account.json"
              else
                ENV["CT_CONFIG_PATH"]
              end
account = load_account(config_path)

if ARGV[0].nil? || ARGV[0].empty? then
  puts "Error: ARGV[0] is empty!"
  exit!
end

follow(account, ARGV[0])
