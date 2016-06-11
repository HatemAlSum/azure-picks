#!/bin/bash
yum -y update
# Install PhpMyAdmin
yum -y install phpmyadmin 
# Install MySQL 
yum -y install mysql mysql-libs mysql-server
service mysqld start
chkconfig mysqld on