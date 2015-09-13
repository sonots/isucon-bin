#!/usr/bin/env ruby
require 'uri'

if ARGV.size > 0
  fp = open(ARGV.first)
else
  fp = STDIN
end

ABBREVIATE_PARAMS = %w[time HTTP-X-Forwarded-For reqtime apptime HTTP-Content-Length SENT-HTTP-Content-Length size]

stats = {}
fp.readlines.each do |line|
  params = line.chomp.split("\t").map {|arg| arg.split(':', 2) }.to_h
  path, query = params['uri'].split('?')
  params['query'] = query if query and !query.empty?
  stats[path] ||= {}
  text = params.map do |key, val|
    next if val == '-'
    val.gsub!(/rack.session=.*/, 'rack.session=abbreviated') if val and val.start_with?('rack.session')
    if ABBREVIATE_PARAMS.include?(key)
      val = 'abbreviated'
    end
    "#{key}: #{val}"
  end.compact.join("\n    ")
  stats[path][text] = true
end
fp.close rescue nil

stats.each do |path, params|
  puts "#{path}:"
  params.keys.each_with_index do |text, i|
    puts "  pattern#{i}:"
    puts "    #{text}"
  end
end
