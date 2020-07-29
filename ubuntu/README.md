# firefox-novnc

base on ubuntu 18.04
using xvfb x11vnc novnc dwm firefox to provide web explorer server

## dockerfile

```dockerfile
FROM ubuntu:18.04 as builder

WORKDIR /home/www
RUN apt update && apt install -y curl unzip
RUN curl https://codeload.github.com/novnc/noVNC/zip/v1.1.0  -o /home/www/noVNC-1.1.0.zip && curl https://codeload.github.com/novnc/websockify/zip/v0.8.0  -o /home/www/websockify-0.8.0.zip && cd /home/www && unzip noVNC-1.1.0.zip && unzip websockify-0.8.0.zip && ls -lah &&  mv /home/www/noVNC-1.1.0 /home/www/novnc && mv /home/www/websockify-0.8.0 /home/www/novnc/utils/websockify && rm -f noVNC-1.1.0.zip websockify-0.8.0.zip

# FROM ubuntu_firefox_base:0.1
FROM ubuntu:18.04

ENV VNC_PASSWD="docker-firefox"
# display config
ENV DISPLAY_WIDTH=1440
ENV DISPLAY_HEIGHT=900
ENV HOMEPAGE="https://www.google.com"

ENV HOME /home/www
# disable interactive
ENV DEBIAN_FRONTEND noninteractive
# setup locale
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# setup timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN apt update && apt install -y xvfb x11vnc dwm dmenu supervisor firefox language-pack-zh-hant language-pack-zh-hans fonts-arphic-* \
   && useradd www

COPY --from=builder /home/www /home/www

RUN  mkdir -p '/home/www/.vnc' \
   && mkdir -p '/home/www/.cache/dconf/' \
   && mkdir -p '/home/www/.mozilla/firefox/2r0k03hw.default/' \
   && mkdir -p '/home/www/.mozilla/firefox/Crash Reports/'  \
   && echo '[Profile0] \n\
Name=default \n\
IsRelative=1 \n\
Path=2r0k03hw.default \n\
 \n\
[General] \n\
StartWithLastProfile=1 \n\
Version=2 \n\
 ' > /home/www/.mozilla/firefox/profiles.ini \
   && echo '[supervisord] \n\
nodaemon=true \n\
 \n\
[program:Xvfb] \n\
priority=100 \n\
command=/usr/bin/Xvfb :0 -screen 0 "%(ENV_DISPLAY_WIDTH)s"x"%(ENV_DISPLAY_HEIGHT)s"x24 \n\
user=www \n\
autorestart=true \n\
 \n\
[program:x11vnc] \n\
priority=300 \n\
command=/usr/bin/x11vnc -passwd "%(ENV_VNC_PASSWD)s" -display :0 -xkb -noxrecord -noxfixes -noxdamage -wait 5 -shared  \n\
user=www \n\
autorestart=true \n\
 \n\
[program:dwm] \n\
priority=400 \n\
command=/usr/bin/dwm \n\
user=www \n\
autorestart=true \n\
environment=DISPLAY=":0",HOME="/home/www",USER="www" \n\
 \n\
[program:novnc] \n\
priority=500 \n\
command=/home/www/novnc/utils/launch.sh --vnc localhost:5900 --listen 8060 \n\
user=www \n\
autorestart=true \n\
 \n\
[program:firefox] \n\
command=/usr/bin/firefox --display :0 -no-remote -P default  -new-window "%(ENV_HOMEPAGE)s" 2> /dev/null \n\
user=www \n\
autorestart=true \n\
' > /etc/supervisor/conf.d/supervisord.conf \
   && echo -e -n "\x00\x00" > /home/www/.cache/dconf/user \
   && echo '{"created": 1566899590753,"firstUse": null}' > /home/www/.mozilla/firefox/2r0k03hw.default/times.json \
   && echo '1566462541' > /home/www/.mozilla/firefox/Crash Reports/InstallTime20190814054548 \
   && ln -s /home/www/novnc/vnc_lite.html /home/www/novnc/index.html \
   && chown -R www:www /home/www \
   && cd /home/www/novnc/utils && sed -i 's/ps -p/ps | grep/' launch.sh


# expose ports
EXPOSE 8060
VOLUME /home/www/Downloads
USER www
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf" ]
```

## Script

```shell
docker container kill firefox
docker container rm firefox
docker build -t firefox-novnc:1.0 ./
docker run -d -p 127.0.0.1:8060:8060 --name "firefox"  firefox-novnc:1.0
docker run -d -p 127.0.0.1:8060:8060 --name "firefox" -e VNC_PASSWD="$(date | openssl md5)" --restart always -v /root/Downloads/:/root/Downloads firefox-novnc:1.0
```
