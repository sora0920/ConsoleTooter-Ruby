#!/usr/bin/env ruby

require_relative "./account.rb"
require_relative "./api.rb"

account = load_account

if ARGV[0].nil? || ARGV[0].empty? then
  puts "Error: ARGV[0] is empty!"
  exit!
end

follow(account, ARGV[0])
