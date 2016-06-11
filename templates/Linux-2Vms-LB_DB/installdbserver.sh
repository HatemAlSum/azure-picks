#!/bin/bash
yum -y update
# Install PhpMyAdmin
yum -y install phpmyadmin 
# Install MySQL
yum install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm 
yum install Percona-Server-server-55 
service mysql start 