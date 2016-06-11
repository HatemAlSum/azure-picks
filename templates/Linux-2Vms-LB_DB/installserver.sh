#!/bin/bash
# install apache service 
yum -y update
yum -y install epel-release 
yum -y install httpd php php-mysql php-mbstring ImageMagick php-mcrypt 
setsebool -P httpd_can_network_connect=1 
service httpd start