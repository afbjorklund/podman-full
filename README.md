
Build script for building <https://github.com/containers/podman>

* conmon
* crun

* netavark
* catatonit

Installed files for `podman-full`, excluding documentation:

* [podman-files.txt](./podman-files.txt)

----

Build script adapted from <https://github.com/containerd/nerdctl>

* containerd
* runc

* cni-plugins
* tini

Installed files for `nerdctl-full`, excluding documentation:

* [nerdctl-files.txt](./nerdctl-files.txt)

-----

## Building

The default `make` target will build an image, and export it.

You can set which engine to use, with the `DOCKER` variable.

## Installation

Normally in [lima](https://lima-vm.io), the archive is just extracted on the lima:

`sudo tar Cxzf /usr/local nerdctl-full.tgz`

## Dependencies

Some dependencies are required, with `sudo apt install`.

* [dependencies.txt](./dependencies.txt)

## Configuration

You are required to add a `/etc/containers/registries.conf`.

```
Error: [...] no containers-registries.conf(5) was found
```

As well as `/etc/containers/policy.json` configuration file.

```
Error: open /etc/containers/policy.json: no such file or directory
```

## User Session

Need to make sure to have `newuidmap` and a dbus session.

```
exec: "newuidmap": executable file not found in $PATH
```
```
WARN[0000] The cgroupv2 manager is set to systemd
           but there is no systemd user session available
WARN[0000] Falling back to --cgroup-manager=cgroupfs
```

They are available as packages, but needs to be started.

```
sudo apt-get install -y uidmap dbus-user-session
```
```
systemctl --user enable --now dbus
```

## Networking

Need to install `slirp4netns`, for network namespaces.

```
exec: "slirp4netns": executable file not found in $PATH
```

It is available as a deb package, since the old podman.

```
sudo apt-get install -y iptables slirp4netns
```

## Testing

Template based on `debian`:

* [lima.yaml](./lima.yaml)

Assuming that lima is installed, and archive is built:

```shell
mkdir -p /tmp/lima
cp policy.json registries.conf podman-full-4.9.2-linux-amd64.tar.gz /tmp/lima
limactl start ./lima.yaml
export LIMA_INSTANCE=lima

lima sudo mkdir /etc/containers
lima sudo cp /tmp/lima/policy.json /tmp/lima/registries.conf /etc/containers
lima sudo tar Cxzf /usr/local /tmp/lima/podman-full-4.9.2-linux-amd64.tar.gz
lima systemctl --user enable --now podman.socket
```

After that, you can add forwarding of the `podman.sock`:

```yaml
portForwards:
- guestSocket: "/run/user/{{.UID}}/podman/podman.sock"
  hostSocket: "{{.Dir}}/sock/podman.sock"
```

You can also run it locally:

`lima podman version`
