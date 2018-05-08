#!/bin/sh

service redis-server start
service postgresql start
service gitlab start
service ssh start

exec nginx -g 'daemon off;'
