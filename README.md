# UniFi Protect for Docker (x86_64)

This is a slightly hacky x86_64-compatible build of UniFi Protect, which is
normally only available for the ARMv8-based CloudKey.  The image is based on
x86_64 Ubuntu, but contains ARMv8 system libraries and `qemu-aarch64` to
perform user-mode emulation of ARMv8.  Performance is reasonable.

This image is modeled after my
[other](https://github.com/iamjamestl/docker-unifi)
[images](https://github.com/iamjamestl/docker-unifi-video), which eliminate
complicated port and user mapping by expecting to be attached directly to your
network and using named volumes.

**WARNING**: This is a wholly unsupported build and it may stop working at any
time depending on where Ubiquiti takes things.  Use at your own risk.

## Usage

### Host Configuration

In order for your kernel to know how to execute the ARMv8 binaries contained in
this image, you must register the format on your Docker host.  Create the file
`/etc/binfmt.d/qemu-aarch64.conf` containing:

```
:aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-aarch64:
```

and run `systemctl restart systemd-binfmt`.  If you aren't using systemd,
you're on your own.

### Network

Create a Docker interface to your video network.  Suppose your video network is
on VLAN 100 with subnet 192.168.100.0/24 and accessible via the host interface
eth0.  Run the following:

```
docker network create \
  --driver macvlan \
  --subnet 192.168.100.0/24 \
  --gateway 192.168.100.1 \
  --opt parent=eth0.100 \
  video
```

### Storage

To ensure your UniFi Protect configs and recordings persist across restarts,
prepare a Docker volume to map into the container.  Do not simply map a host
directory into the container!  Docker won't initialize it properly and UniFi
Protect almost certainly won't have permission to write to it.

```
docker volume create unifi-protect
docker volume create unifi-protect-postgresql
```

On a typical Docker installation, you will have access to this volume from the
host at `/var/lib/docker/volumes/unifi-protect/_data`.

Optionally, if you want to store the bulk video data on a larger device, create the volume like:

```
docker volume create -o type=none -o o=bind -o device=/path/to/some/empty/dir unifi-protect
```

Finally, run the container as follows:

```
docker run \
  --name unifi-protect \
  --net video \
  --ip 192.168.100.2 \
  -v unifi-protect:/srv/unifi-protect \
  -v unifi-protect-postgresql:/var/lib/postgresql \
  iamjamestl/unifi-protect
```
