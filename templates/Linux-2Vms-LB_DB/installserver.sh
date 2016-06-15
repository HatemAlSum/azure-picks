#!/bin/bash

exec >>/var/log/provisioner.log 2>&1

# install apache service 
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y update
yum -y install httpd php php-mysql 
setsebool -P httpd_can_network_connect=1 
service httpd start
chkconfig httpd on
