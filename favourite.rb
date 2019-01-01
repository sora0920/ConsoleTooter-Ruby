#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'
require 'optparse'
require_relative "./account.rb"
require_relative "./api.rb"


account = load_account
count = 1

OptionParser.new do |opt|
  opt.on('--count [n]', 'Favourite count times') { |n| count = n.to_i - 1 }
  opt.parse!(ARGV)
end


if ARGV[0].nil? || ARGV[0].empty? then
  puts "Error: ARGV[0] is empty!"
  exit!
end

if count > 2
  i = 0
  unfavourite(account, ARGV[0])
  while count > i
    favourite(account, ARGV[0])
    unfavourite(account, ARGV[0])
    puts "#{count - i} count left."
    i += 1
  end
  favourite(account, ARGV[0])
else
  favourite(account, ARGV[0])
end
