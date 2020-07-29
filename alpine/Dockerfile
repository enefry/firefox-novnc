FROM alpine:3.9 as builder

WORKDIR /home/alpine
RUN apk --no-cache add curl unzip
RUN curl https://codeload.github.com/novnc/noVNC/zip/v1.1.0  -o /home/alpine/noVNC-1.1.0.zip && curl https://codeload.github.com/novnc/websockify/zip/v0.8.0  -o /home/alpine/websockify-0.8.0.zip && cd /home/alpine && unzip noVNC-1.1.0.zip && unzip websockify-0.8.0.zip && ls -lah &&  mv /home/alpine/noVNC-1.1.0 /home/alpine/novnc && mv /home/alpine/websockify-0.8.0 /home/alpine/novnc/utils/websockify && rm -f noVNC-1.1.0.zip websockify-0.8.0.zip


FROM alpine:3.9

ENV VNC_PASSWD="docker-firefox"
# display config
ENV DISPLAY_WIDTH=1440
ENV DISPLAY_HEIGHT=900
ENV HOMEPAGE="https://www.google.com"

ENV HOME /home/alpine
# disable interactive
ENV DEBIAN_FRONTEND noninteractive
# setup locale
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# setup timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk add --update --no-cache \
    x11vnc xvfb supervisor \
    dwm dmenu ii st \
    ttf-ubuntu-font-family firefox-esr wqy-zenhei bash \
 && addgroup alpine \
 && adduser -G alpine -s /bin/ash -D alpine \
 && echo "alpine:alpine" | /usr/sbin/chpasswd \
 && mkdir -p /etc/supervisor/conf.d \
 && rm -rf /apk /tmp/* /var/cache/apk/*

WORKDIR /home/alpine

COPY --from=builder /home/alpine /home/alpine

RUN  mkdir -p '/home/alpine/.vnc' \
   && mkdir -p '/home/alpine/.cache/dconf/' \
   && mkdir -p '/home/alpine/.mozilla/firefox/2r0k03hw.default/' \
   && mkdir -p '/home/alpine/.mozilla/firefox/Crash Reports/'  \
   && echo $'[Profile0] \n\
Name=default \n\
IsRelative=1 \n\
Path=2r0k03hw.default \n\
 \n\
[General] \n\
StartWithLastProfile=1 \n\
Version=2 \n\
 ' > /home/alpine/.mozilla/firefox/profiles.ini \
   && echo $'[supervisord] \n\
nodaemon=true \n\
 \n\
[program:Xvfb] \n\
priority=100 \n\
command=/usr/bin/Xvfb :0 -screen 0 "%(ENV_DISPLAY_WIDTH)s"x"%(ENV_DISPLAY_HEIGHT)s"x24 \n\
user=alpine \n\
autorestart=true \n\
 \n\
[program:x11vnc] \n\
priority=300 \n\
command=/usr/bin/x11vnc -passwd "%(ENV_VNC_PASSWD)s" -display :0 -xkb -noxrecord -noxfixes -noxdamage -wait 5 -shared  \n\
user=alpine \n\
autorestart=true \n\
 \n\
[program:dwm] \n\
priority=400 \n\
command=/usr/bin/dwm \n\
user=alpine \n\
autorestart=true \n\
environment=DISPLAY=":0",HOME="/home/alpine",USER="alpine" \n\
 \n\
[program:novnc] \n\
priority=500 \n\
command=/home/alpine/novnc/utils/launch.sh --vnc localhost:5900 --listen 8060 \n\
user=alpine \n\
autorestart=true \n\
 \n\
[program:firefox] \n\
command=/usr/bin/firefox --display :0 -no-remote -P default  -new-window "%(ENV_HOMEPAGE)s" 2> /dev/null \n\
user=alpine \n\
autorestart=true \n\
' > /etc/supervisor/conf.d/supervisord.conf \
   && echo -e -n "\x00\x00" > /home/alpine/.cache/dconf/user \
   && echo '{"created": 1566899590753,"firstUse": null}' > /home/alpine/.mozilla/firefox/2r0k03hw.default/times.json \
   && echo '1566462541' > /home/alpine/.mozilla/firefox/Crash Reports/InstallTime20190814054548 \
   && ln -s /home/alpine/novnc/vnc_lite.html /home/alpine/novnc/index.html \
   && chown -R alpine:alpine /home/alpine \
   && cd /home/alpine/novnc/utils && sed -i 's/ps -p/ps | grep/' launch.sh

# RUN cat /home/alpine/.mozilla/firefox/profiles.ini && cat /etc/supervisor/conf.d/supervisord.conf
# RUN apk add --update --no-cache bash
# expose ports
EXPOSE 8060
VOLUME /home/alpine/Downloads
USER alpine
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf" ]