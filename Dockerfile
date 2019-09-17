#
# UniFi Protect Dockerfile
# Copyright (C) 2019 James T. Lee
#

FROM ubuntu:18.04

RUN apt-get update

# Install build tools
RUN apt-get install -y qemu-user wget xz-utils

# Install arm64 libraries
RUN wget --progress=dot:mega https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-arm64-root.tar.xz -O ubuntu-arm64.tar.xz \
 && tar -xvf ubuntu-arm64.tar.xz lib/ld-linux-aarch64.so.1 lib/aarch64-linux-gnu usr/lib/aarch64-linux-gnu \
 && rm ubuntu-arm64.tar.xz

# Install a compatible arm64 nodejs release
RUN wget --progress=dot:mega https://nodejs.org/download/release/v8.16.1/node-v8.16.1-linux-arm64.tar.xz -O node-arm64.tar.xz \
 && tar -C /usr -xvf node-arm64.tar.xz --strip-components=1 \
 && rm node-arm64.tar.xz

# Install unifi-protect and its dependencies
RUN apt-get install -y postgresql sudo \
 && wget --progress=dot:mega https://apt.ubnt.com/pool/main/u/unifi-protect/unifi-protect.jessie~stretch~xenial~bionic_arm64.v1.12.1.deb -O unifi-protect.deb \
 && dpkg -x unifi-protect.deb / \
 && rm -f unifi-protect.deb \
 && useradd unifi-protect

# Cleanup
RUN apt-get remove --purge --auto-remove -y wget xz-utils \
 && rm -rf /var/cache/apt/lists/*

# Configure
COPY config.json /etc/unifi-protect/config.json

# Initialize based on /usr/share/unifi-protect/app/hooks/pre-start
RUN pg_ctlcluster 10 main start \
 && su postgres -c 'createuser unifi-protect -d' \
 && pg_ctlcluster 10 main stop \
 && ln -s /srv/unifi-protect/logs /var/log/unifi-protect \
 && mkdir /srv/unifi-protect /srv/unifi-protect/backups /var/run/unifi-protect \
 && chown unifi-protect:unifi-protect /srv/unifi-protect /srv/unifi-protect/backups /var/run/unifi-protect \
 && ln -s /tmp /srv/unifi-protect/temp \
 && sed -i 's/^\(ExecStartPre\|ExecStopPost\)=.*//' /lib/systemd/system/unifi-protect.service

COPY init /init

CMD ["/init"]
