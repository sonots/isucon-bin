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
slow_query_log = 1
slow_query_log_file = /var/lib/mysql/slow.log
long_query_time = 0
```

show create table の情報をだしておく

```
/home/isucon/env.sh ~/bin/show_create_tables.rb > ~/metrics/show_create_tables.txt
```

### Nginx

ログを仕込む. cf. https://github.com/sonots/isucon5_cheatsheet/blob/master/10.nginx.md

```
log_format  ltsv  'host:$remote_addr\t'
                    'vhost:$http_host\t'
                    'port:$server_port\t'
                    'time:$time_iso8601\t'
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

  # access_log /var/log/nginx/access.log ltsv;
```

## 実行前準備


DATE変数を作っておく

```
DATE=$(date +%H%m)
```

```
bundle exec unicorn -c unicorn_config.rb -p 8080 | tee ~/metrics/$DATE_app.log
```

ログをきれいにして再起動

```
sudo mv /var/lib/mysql/slow.log /var/lib/mysql/slow.log.bak
sudo /etc/init.d/mysql restart
```


ログをきれいにして再起動 (reload じゃダメ)

```
sudo mv /var/log/nginx/access.log /var/log/nginx/access.log.bak
sudo /etc/init.d/nginx restart
```

```
vmstat 1 | tee ~/metrics/$DATE_vmstat.log
```

```
iostat -dkxt 1 | tee ~/metrics/$DATE_iostat.log
```

top を起動しておく。iftop を起動しておく。

## 統計値の取得

time benchmarker で起動してベンチマーカーの時間も測りつつ、各種ログを取得後、

### アプリ

```
~/bin/http_stat.sh ~/metrics/$DATE_app.log | tee ~/metrics/$DATE_http_stat.log
~/bin/template_stat.sh ~/metrics/$DATE_app.log | tee ~/metrics/$DATE_template_stat.log
~/bin/query_stat.sh ~/metrics/$DATE_app.log | tee ~/metrics/$DATE_app_stat.log
```

### MySQL

```
cp /var/lib/mysql/slow.log ~/metrics/$DATE_slow.log
mysqldumpslow -s t /var/lib/mysql/slow.log | tee ~/metrics/$DATE_mysqldumpslow.log
```


### Nginx

```
/var/log/nginx/access.log ~/metrics/$DATE_access.log
~/bin/http_stat.sh /var/log/nginx/access.log | tee ~/metrics/$DATE_access_stat.log
```

全部 git push してシェア。 (サンプル実行結果 https://gist.github.com/sonots/0a6211ea5bb5fc1f795c)
