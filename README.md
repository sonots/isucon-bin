# メトリクス取得

## 仕込み

### Ruby アプリ

* https://github.com/sonots/rack-ltsv_logger <= nginx でログを出すなら不要
* https://github.com/sonots/sinatra-template_metrics
* https://github.com/sonots/mysql2-metrics <= mysqldumpslow を使うなら不要

を仕込む。

アプリレベルのチューニングが必要になったら

* https://github.com/kainosnoema/rack-lineprof
* https://github.com/tmm1/stackprof

### Mysql

slow query log を出すように仕込む. cf. https://github.com/sonots/isucon5_cheatsheet/blob/master/06.mysql_5.6.md

```
slow_query_log = ON
slow_query_log_file = /var/lib/mysql/slow.log
long_query_time = 0
# log-queries-not-using-indexes # show queries not using index
```

show create table の情報をだしておく

```
~/isucon-bin/show_create_tables.rb -u USER -p PASSWORD -h HOST -P port DB > ~/log/show_create_tables.txt
```

### Nginx

ログを仕込む. cf. https://github.com/sonots/isucon5_cheatsheet/blob/master/10.nginx.md

```
  log_format  ltsv  'time:$time_iso8601\t'
                    'host:$remote_addr\t'
                    'vhost:$http_host\t'
                    'port:$server_port\t'
                    'method:$request_method\t'
                    'uri:$request_uri\t'
                    'protocol:$server_protocol\t'
                    'status:$status\t'
                    'size:$body_bytes_sent\t'
                    'referer:$http_referer\t'
                    'ua:$http_user_agent\t'
                    'forwardedfor:$http_x_forwarded_for\t'
                    'forwardedproto:$http_x_forwarded_proto\t'
                    'apptime:$upstream_response_time\t'
                    'reqtime:$request_time';
  
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
sudo tcpdump -A port 80 -i lo > ~/log/${DATE}_tcpdump.log
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
~/isucon-bin/alp -f ~/log/${DATE}_access.log --sum -r --aggregates "/image/\d+,/@.+,/posts\?.+,/posts/.*" | tee ~/log/${DATE}_access_stat.log
```

全部 git push してシェア。 (サンプル実行結果 https://gist.github.com/sonots/0a6211ea5bb5fc1f795c)

## 全ヘッダの取得

```
$ ~/isucon-bin/tcpdump_all_headers.rb ~/log/${DATE}_tcpdump.log
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
                    'HTTP-Cookie:$http_cookie\t'
                    'HTTP-Referer:$http_referer\t'
                    'HTTP-Content-Length:$http_content_length\t'
                    'HTTP-Content-Type:$http_content_type\t'
                    'SENT-HTTP-Server:$sent_http_server\t'
                    'SENT-HTTP-Date:$sent_http_date\t'
                    'SENT-HTTP-Content-Type:$sent_http_content_type\t'
                    'SENT-HTTP-Connection:$sent_http_connection';
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
``
