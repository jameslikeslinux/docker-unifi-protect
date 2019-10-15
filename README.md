# UniFi Protect for Docker (x86_64)

This build delivers a not-yet-documented installation of UniFi Protect for
x86_64.  Normally it is only available for the Cloud Key Gen2.

This image is modeled after my
[other](https://github.com/iamjamestl/docker-unifi)
[images](https://github.com/iamjamestl/docker-unifi-video), which eliminate
complicated port and user mapping by expecting to be attached directly to your
network and using named volumes.

## Usage

### Host Configuration

This image should work out-of-the-box on a Linux x86_64 Docker host.

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

Optionally, if you want to store the bulk video data on a larger device, create
the volume like:

```
docker volume create -o type=none -o o=bind -o device=/path/to/some/empty/dir unifi-protect
```

### Execution

Finally, run the container as follows:

```
docker run \
  --name unifi-protect \
  --net video \
  --ip 192.168.100.2 \
  -v unifi-protect:/srv/unifi-protect \
  -v unifi-protect-postgresql:/var/lib/postgresql \
  --tmpfs /srv/unifi-protect/temp \
  iamjamestl/unifi-protect
```

After a minute or so for the service to start, visit
`http://<ip-of-the-container>:7080/`.

### Tips

The container must have outbound access to the internet.  UniFi Protect employs
STUN to poke a holes in your NAT.  Firewalls like pfSense can break STUN by
using different UDP ports on either side of the NAT.  Create a static port rule
for the UniFi Protect container to work around this.  Instructions for pfSense
can be found at
https://docs.netgate.com/pfsense/en/latest/nat/static-port.html.
