#!/bin/bash
# install apache service 
yum -y update
yum -y install httpd
service httpd start
