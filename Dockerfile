FROM alpine:3.14.0 as builder

WORKDIR /home/alpine
RUN apk --no-cache add curl unzip make gcc libc-dev libx11-dev libxft-dev libxinerama-dev x11vnc xvfb supervisor patch
RUN curl https://codeload.github.com/novnc/noVNC/zip/v1.2.0  -o /home/alpine/noVNC-1.2.0.zip && curl https://codeload.github.com/novnc/websockify/zip/v0.10.0  -o /home/alpine/websockify-0.10.0.zip && cd /home/alpine && unzip noVNC-1.2.0.zip && unzip websockify-0.10.0.zip && ls -lah &&  mv /home/alpine/noVNC-1.2.0 /home/alpine/novnc && mv /home/alpine/websockify-0.10.0 /home/alpine/novnc/utils/websockify && rm -f noVNC-1.2.0.zip websockify-0.10.0.zip
RUN curl https://dl.suckless.org/dwm/dwm-6.2.tar.gz -o dwm-6.2.tar.gz && tar -zxf dwm-6.2.tar.gz && cd dwm-6.2  && curl https://dwm.suckless.org/patches/alwaysfullscreen/dwm-alwaysfullscreen-6.1.diff -o dwm-alwaysfullscreen-6.1.diff && curl https://dwm.suckless.org/patches/aspectresize/dwm-aspectresize-6.2.diff -o dwm-aspectresize-6.2.diff && curl https://dwm.suckless.org/patches/actualfullscreen/dwm-actualfullscreen-20191112-cb3f58a.diff -o dwm-actualfullscreen-20191112-cb3f58a.diff  && patch < dwm-actualfullscreen-20191112-cb3f58a.diff && patch < dwm-alwaysfullscreen-6.1.diff && patch < dwm-aspectresize-6.2.diff && sed 's/tags\[\] = .*/tags\[\] = \{ "1" \};/' config.def.h > config.def.h.temp && sed 's/^.*Firefox.*//g' config.def.h.temp >config.def.h && make



FROM alpine:3.14.0

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
    dmenu ii st \
    wqy-zenhei bash firefox python3 \
 && addgroup alpine \
 && adduser -G alpine -s /bin/ash -D alpine \
 && echo "alpine:alpine" | /usr/sbin/chpasswd \
 && mkdir -p /etc/supervisor/conf.d \
 && rm -rf /apk /tmp/* /var/cache/apk/*

WORKDIR /home/alpine

COPY --from=builder /home/alpine/novnc /home/alpine/novnc
COPY --from=builder /home/alpine/dwm-6.2/dwm /usr/local/bin/dwm
COPY alpine/SimSun.ttf /usr/share/fonts/simsun.ttf
RUN  mkdir -p '/home/alpine/.vnc' \
   && mkdir -p '/home/alpine/.cache/dconf/' \
   && mkdir -p '/home/alpine/.mozilla/firefox/2r0k03hw.default/' \
   && mkdir -p '/home/alpine/.mozilla/firefox/Crash Reports/'  \
   && mkdir -p "/usr/share/xsessions/" \
   && chmod +x '/usr/local/bin/dwm' \
   && echo $'[Desktop Entry] \n\
Name=dwm\n\
Comment=dwm Desktop Environment\n\
Exec=/usr/local/bin/dwm \n\
TryExec=/usr/local/bin/dwm \n' \
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
command=/usr/local/bin/dwm \n\
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
command=/usr/bin/firefox --display :0 -no-remote -P default  -new-window "%(ENV_HOMEPAGE)s" 2 > /dev/null \n\
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