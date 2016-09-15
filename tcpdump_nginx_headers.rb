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
    header = line.split(':', 2).first
    request_headers[header.chomp] = 1
  elsif response_started
    if line.chomp.empty?
      response_started = false
      next
    end
    header = line.split(':', 2).first
    response_headers[header.chomp] = 1
  end
end
fp.close rescue nil

puts <<'EOF'
  log_format  ltsv  'time:$time_iso8601'
                    '\thost:$remote_addr'
                    '\tforwardedfor:$http_x_forwarded_for'
                    '\treq:$request'
                    '\tstatus:$status'
                    '\tmethod:$request_method'
                    '\turi:$request_uri'
                    '\tsize:$body_bytes_sent'
                    '\treferer:$http_referer'
                    '\tua:$http_user_agent'
                    '\treqtime:$request_time'
                    "\tcache:$upstream_http_x_cache"
                    "\truntime:$upstream_http_x_runtime"
                    '\tapptime:$upstream_response_time'
                    '\tport:$server_port'
                    '\tprotocol:$server_protocol'
                    '\tforwardedproto:$http_x_forwarded_proto'
                    '\tvhost:$http_host'
EOF

nginx_request_headers = request_headers.keys.map do |header|
  nginx_header = header.downcase.gsub('-', '_')
  %Q[                    '\\tHTTP-#{header}:$http_#{nginx_header}']
end
puts nginx_request_headers.join(%Q[\n]) << %Q[\n]

nginx_response_headers = response_headers.keys.map do |header|
  nginx_header = header.downcase.gsub('-', '_')
  %Q[                    '\\tSENT-HTTP-#{header}:$sent_http_#{nginx_header}']
end
puts nginx_response_headers.join(%Q[\n]) << %Q[;]
