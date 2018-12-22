#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require_relative "./account.rb"

def favourite(account, id)
  uri = URI.parse("https://" + account["host"] + "/api/v1/statuses/#{id}/favourite")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  req = Net::HTTP::Post.new(uri.request_uri)
  req["Authorization"] = " Bearer " + account["token"]

  res = https.request(req)

  puts res.code
  puts res.message
end

account = load_account

if ARGV[0].nil? || ARGV[0].empty? then
  puts "Error: ARGV[0] is empty!"
  exit!
end

favourite(account, ARGV[0])
