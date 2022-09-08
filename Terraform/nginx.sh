#!/bin/bash
apt-get -y update
apt-get -y install nginx
systemctl start nginx
systemctl enable nginx