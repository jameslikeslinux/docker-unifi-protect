#
# UniFi Protect Dockerfile
# Copyright (C) 2019 James T. Lee
#

# Start with a well-maintained image designed for cross-arch building
FROM balenalib/aarch64-ubuntu:bionic

# Enable aarch64 on x86_64
RUN ["cross-build-start"]

# Install build tools
RUN apt-get update \
 && apt-get install -y wget

# Install unifi-protect and its dependencies
RUN wget --progress=dot:mega https://apt.ubnt.com/pool/main/u/unifi-protect/unifi-protect.jessie~stretch~xenial~bionic_arm64.v1.12.3.deb -O unifi-protect.deb \
 && apt install -y ./unifi-protect.deb \
 && rm -f unifi-protect.deb

# Cleanup
RUN apt-get remove --purge --auto-remove -y wget \
 && rm -rf /var/cache/apt/lists/*

# Setup app directories based on /usr/share/unifi-protect/app/hooks/pre-start
RUN ln -s /srv/unifi-protect/logs /var/log/unifi-protect \
 && mkdir /srv/unifi-protect /srv/unifi-protect/backups /var/run/unifi-protect \
 && chown unifi-protect:unifi-protect /srv/unifi-protect /srv/unifi-protect/backups /var/run/unifi-protect \
 && ln -s /tmp /srv/unifi-protect/temp

# Configure
COPY config.json /etc/unifi-protect/config.json

# Supply simple script to run postgres and unifi-protect
COPY init /init
CMD ["/init"]

ENTRYPOINT ["/bin/sh", "-c"]
