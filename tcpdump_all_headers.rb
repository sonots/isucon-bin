#!/usr/bin/env ruby

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
 
fp.readlines.each do |line|
  if md = line.match(%r{(GET|POST|PUT|DELETE|PATCH).*HTTP/1.1.*})
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
  log_format  ltsv  'time:$time_iso8601\t'
                    'host:$remote_addr\t'
                    'port:$server_port\t'
                    'method:$request_method\t'
                    'uri:$request_uri\t'
                    'protocol:$server_protocol\t'
                    'status:$status\t'
                    'size:$body_bytes_sent\t'
                    'apptime:$upstream_response_time\t'
                    'reqtime:$request_time\t'
EOF

nginx_request_headers = request_headers.keys.map do |header|
  header = header.downcase.gsub('-', '_')
  %Q[                    'http_#{header}:$http_#{header}]
end
puts nginx_request_headers.join(%Q[\\t'\n]) << %Q[\\t'\n]

nginx_response_headers = response_headers.keys.map do |header|
  header = header.downcase.gsub('-', '_')
  %Q[                    'sent_http_#{header}:$sent_http_#{header}]
end
puts nginx_response_headers.join(%Q[\\t'\n]) << %Q[';]
