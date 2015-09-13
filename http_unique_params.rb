#!/usr/bin/env ruby
require 'uri'

if ARGV.size > 0
  fp = open(ARGV.first)
else
  fp = STDIN
end

stats = {}
fp.readlines.each do |line|
  params = line.chomp.split("\t").map {|arg| arg.split(':', 2) }.to_h
  path, query = params['uri'].split('?')
  params['query'] = query if query and !query.empty?
  params.each do |key, val|
    stats[path] ||= {}
    stats[path][key] ||= {}
    val.gsub!(/rack.session=.*/, 'rack.session=abbreviated') if val and val.start_with?('rack.session')
    stats[path][key][val] = true
  end
end
fp.close rescue nil

stats.each do |path, params|
  puts "#{path}:"
  params.keys.each do |key|
    values = params[key].keys
    if values.size == 1
      value = values.first
      puts "  #{key}:#{value}" unless value == '-'
    else
      if %w[time HTTP-X-Forwarded-For].include?(key)
        puts "  #{key}:[abbreviated]"
      else
        puts "  #{key}:[#{values.join(",")}]"
      end
    end
  end
end
