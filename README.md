# 画面を触る

まず最初に rack-lineprof を仕込んでアプリを触って画面、仕様確認すると良い https://github.com/kainosnoema/rack-lineprof

config.ru

```ruby
require_relative './app.rb'
require 'rack-lineprof'

use Rack::Lineprof, profile: /app/
run Isuconp::App
```

# メトリクス取得

## 仕込み

### Ruby アプリ

* https://github.com/sonots/rack-ltsv_logger <= nginx でログを出すなら不要
* https://github.com/sonots/sinatra-template_metrics
* https://github.com/sonots/mysql2-metrics <= mysqldumpslow を使うなら不要

を仕込む。

### Mysql

slow query log を出すように仕込む. cf. https://github.com/sonots/isucon5_cheatsheet/blob/master/06.mysql_5.6.md

```
slow_query_log = ON
slow_query_log_file = /var/lib/mysql/slow.log
long_query_time = 0
# log-queries-not-using-indexes # show queries not using index
```

show create table の情報をだしておく
al
```
~/isucon-bin/show_create_tables.rb -u USER -p PASSWORD -h HOST -P port DB > ~/log/show_create_tables.txt
```

### Nginx

ログを仕込む. cf. https://github.com/sonots/isucon5_cheatsheet/blob/master/10.nginx.md

```
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
                    '\tvhost:$http_host';

  access_log /var/log/nginx/access.log ltsv;
```

## 実行前準備


DATE変数を作っておく

```
DATE=$(date +%H%m)
```

```
bundle exec unicorn -c unicorn_config.rb -p 8080 | tee ~/log/${DATE}_app.log
```

mysql, nginx のログをきれいにして再起動

```
sudo ~/isucon-bin/prepare.sh
```

```
# sudo tcpdump -A port 80 -i lo > ~/log/${DATE}_tcpdump.log
sudo tcpdump -A port 80 > ~/log/${DATE}_tcpdump.log
```

```
vmstat 1 | tee ~/log/${DATE}_vmstat.log
```

```
iostat -dkxt 1 | tee ~/log/${DATE}_iostat.log
```

top を起動しておく。iftop を起動しておく。

## 統計値の取得

time benchmarker で起動してベンチマーカーの時間も測りつつ、各種ログを取得後、

### アプリ

```
~/isucon-bin/http_stat.sh ~/log/${DATE}_app.log | tee ~/log/${DATE}_http_stat.log
~/isucon-bin/template_stat.sh ~/log/${DATE}_app.log | tee ~/log/${DATE}_template_stat.log
~/isucon-bin/query_stat.sh ~/log/${DATE}_app.log | tee ~/log/${DATE}_app_stat.log
```

### MySQL

```
cp /var/lib/mysql/slow.log ~/log/${DATE}_slow.log
mysqldumpslow -s t ~/log/${DATE}_slow.log | tee ~/log/${DATE}_mysqldumpslow.log
```


### Nginx

```
cp /var/log/nginx/access.log ~/log/${DATE}_access.log
~/isucon-bin/alp -f ~/log/${DATE}_access.log --sum -r --aggregates "/image/\d+,/@.+,/posts\?.+,/posts/.*" --start-time "11:47:26" | tee ~/log/${DATE}_access_stat.log
```

全部 git push してシェア。 (サンプル実行結果 https://gist.github.com/sonots/0a6211ea5bb5fc1f795c)

https://github.com/tkuchiki/alp

## 全ヘッダの取得

$ ~/isucon-bin/tcpdump_all_headers.rb ~/log/${DATE}_tcpdump.log

## エンドポイント別ヘッダの取得

ToDo: nginx のアクセスログ形式を変えて再度ベンチ走らせるので手間...

```
$ ~/isucon-bin/tcpdump_nginx_headers.rb ~/log/${DATE}_tcpdump.log

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
                    '\tHTTP-Host:$http_host'
                    '\tHTTP-User-Agent:$http_user_agent'
                    '\tHTTP-Cookie:$http_cookie'
                    '\tHTTP-Accept-Encoding:$http_accept_encoding'
                    '\tHTTP-Content-Length:$http_content_length'
                    '\tHTTP-Content-Type:$http_content_type'
                    '\tHTTP-Referer:$http_referer'
                    '\tHTTP-x-ms-agent-name:$http_x_ms_agent_name'
                    '\tHTTP-x-ms-version:$http_x_ms_version'
                    '\tSENT-HTTP-Server:$sent_http_server'
                    '\tSENT-HTTP-Date:$sent_http_date'
                    '\tSENT-HTTP-Content-Type:$sent_http_content_type'
                    '\tSENT-HTTP-Transfer-Encoding:$sent_http_transfer_encoding'
                    '\tSENT-HTTP-Connection:$sent_http_connection'
                    '\tSENT-HTTP-X-XSS-Protection:$sent_http_x_xss_protection'
                    '\tSENT-HTTP-X-Content-Type-Options:$sent_http_x_content_type_options'
                    '\tSENT-HTTP-X-Frame-Options:$sent_http_x_frame_options'
                    '\tSENT-HTTP-Content-Encoding:$sent_http_content_encoding'
                    '\tSENT-HTTP-Content-Length:$sent_http_content_length'
                    '\tSENT-HTTP-Last-Modified:$sent_http_last_modified'
                    '\tSENT-HTTP-ETag:$sent_http_etag'
                    '\tSENT-HTTP-Accept-Ranges:$sent_http_accept_ranges'
                    '\tSENT-HTTP-Set-Cookie:$sent_http_set_cookie'
                    '\tSENT-HTTP-Location:$sent_http_location';
```

nginx のログを挿げ替えて

```
sudo mv /var/log/nginx/access.log{,.bak}
sudo /etc/init.d/nginx restart
```

再計測して、

```
DATE=$(date +%H%m)
cp /var/log/nginx/access.log ~/log/${DATE}_access.log
```

ヘッダを含めた全エンドポイントの unique パラメータを一覧化 cf. https://github.com/sonots/isucon-bin/pull/1

```
~/isucon-bin/http_unique_params.rb /var/log/nginx/access.log > ~/log/${DATE}_http_unique_params.log
```


ヘッダを含めた全エンドポイントのリクエストパターンを解析 cf. https://github.com/sonots/isucon-bin/pull/2

```
~/isucon-bin/http_unique_requests.rb /var/log/nginx/access.log > ~/log/${DATE}_http_unique_requests.log
```

## http traffic replay ツール gor

記録して

```
sudo ~/isucon-bin/gor --input-raw :80 --output-file ~/log/requests.gor
```

再生

```
sudo ~/isucon-bin/gor --input-file ~/log/requests.gor --output-http "http://localhost:80"
```

## アプリレベルでのプロファイリング

ベンチ回して統計取りたい場合は stackprof https://github.com/tmm1/stackprof

config.rb

```ruby
use StackProf::Middleware, enabled: true,
                           mode: :cpu,
                           interval: 1000,
                           save_every: 5
```
