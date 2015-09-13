sudo mv /var/log/nginx/access.log{,.1}
sudo mv /var/lib/mysql/slow.log{,.1}
sudo /etc/init.d/nginx restart
sudo /etc/init.d/mysqld restart
