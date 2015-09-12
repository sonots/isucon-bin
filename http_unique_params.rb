#!/usr/bin/env ruby

require 'uri'
stats = {}
STDIN.readlines.each do |line|
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

stats.each do |path, params|
  puts "#{path}:"
  params.keys.each do |key|
    if params[key].keys.size == 1
      puts "  #{key}:#{params[key].keys.first}"
    else
      if %w[time http_x_forwarded_for].include?(key)
        puts "  #{key}:[abbreviated]"
      else
        puts "  #{key}:[#{params[key].keys.join(",")}]"
      end
    end
  end
end
