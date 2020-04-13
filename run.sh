#!/bin/bash
python3 manage.py collectstatic
uwsgi --ini ./uwsgi.ini
nginx -c /usr/local/nginx/conf/myblog.conf -g 'daemon off;'