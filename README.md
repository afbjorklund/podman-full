
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

Need to install `iptables`, for network namespaces.

```
sudo apt-get install -y iptables
```
