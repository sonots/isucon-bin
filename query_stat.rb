#!/usr/bin/env ruby

stats = {}
STDIN.readlines.each do |line|
  query, elapsed = line.split("\t")
  elapsed = elapsed.to_f
  stat = stats[query] ||= { :count => 0, :sum => 0, :min => 0, :max => 0}
  stat[:sum] += elapsed
  stat[:max] = [stat[:max], elapsed].max
  stat[:min] = [stat[:min], elapsed].min
  stat[:count] += 1
end

stats.each do |query, val|
  val[:mean] = val[:sum] / val[:count].to_f
  out = val.merge({ :query => query })
  puts out.map {|key, v| "#{key}:#{v}" }.join("\t")
end
