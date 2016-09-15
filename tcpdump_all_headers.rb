#!/usr/bin/env ruby
require 'set'

request_started = nil
response_started = nil
request_headers = {}
response_headers = {}
request = nil
response = nil

if ARGV.size > 0
  fp = open(ARGV.first)
else
  fp = STDIN
end
 
fp.readlines.each_with_index do |line, lineno|
  if md = line.match(%r{Flags.*seq.*})
    next
  elsif md = line.match(%r{(GET|POST|PUT|DELETE|PATCH).*HTTP/1.1.*})
    request_started = true
    request = md[0].chomp
    next
  elsif md = line.match(%r{HTTP/1.1.*})
    response_started = true
    response = md[0].chomp
    next
  end
  if request_started
    if line.chomp.empty?
      request_started = false
      next
    end
    header, value = line.split(': ', 2)
    request_headers[header.chomp] ||= Set.new
    request_headers[header.chomp] << value.chomp
  elsif response_started
    if line.chomp.empty?
      response_started = false
      next
    end
    header, value = line.split(': ', 2)
    response_headers[header.chomp] ||= Set.new
    response_headers[header.chomp] << value.chomp
  end
end
fp.close rescue nil

puts "Request Headers"
request_headers.each do |key, values|
  puts "#{key}:"
  values.each {|val| puts "  - #{val}" }
end
puts "============================================================================"
puts "Response Headers"
response_headers.each do |key, values|
  puts "#{key}:"
  values.each {|val| puts "  - #{val}" }
end
