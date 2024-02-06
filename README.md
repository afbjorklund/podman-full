
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
