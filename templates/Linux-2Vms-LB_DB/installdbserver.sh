#!/bin/bash
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y update
# Install PhpMyAdmin
yum -y install phpmyadmin 
# Install MySQL 
yum -y install mysql mysql-libs mysql-server
service mysqld start
chkconfig mysqld on