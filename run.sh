#!/bin/sh

WHOAMI=`whoami`
echo "[supervisord] \n\
nodaemon=true \n\
 \n\
[program:Xvfb] \n\
priority=100 \n\
command=/usr/bin/Xvfb :0 -screen 0 \"%(ENV_DISPLAY_WIDTH)s\"x\"%(ENV_DISPLAY_HEIGHT)s\"x24 \n\
user=${WHOAMI} \n\
autorestart=true \n\
 \n\
[program:x11vnc] \n\
priority=300 \n\
command=/usr/bin/x11vnc -passwd \"%(ENV_VNC_PASSWD)s\" -display :0 -xkb -noxrecord -noxfixes -noxdamage -wait 5 -shared  \n\
user=${WHOAMI} \n\
autorestart=true \n\
 \n\
[program:dwm] \n\
priority=400 \n\
command=/usr/local/bin/dwm \n\
user=${WHOAMI} \n\
autorestart=true \n\
environment=DISPLAY=\":0\",HOME=\"/home/alpine\",USER=\"${WHOAMI}\" \n\
 \n\
[program:novnc] \n\
priority=500 \n\
command=/home/alpine/novnc/utils/launch.sh --vnc localhost:5900 --listen $PORT \n\
user=${WHOAMI} \n\
autorestart=true \n\
 \n\
[program:firefox] \n\
command=/usr/bin/firefox --display :0 -no-remote -P default  -new-window \"%(ENV_HOMEPAGE)s\" 2 > /dev/null \n\
user=${WHOAMI} \n\
autorestart=true \n\
" > /home/alpine/supervisord.conf

"/usr/bin/supervisord","-c","/home/alpine/supervisord.conf"