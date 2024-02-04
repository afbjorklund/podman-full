
PODMAN = podman

BRANCH = v4.9.0

TARGETARCH ?= amd64

all: build archive

podman:
	git clone https://github.com/containers/podman.git --branch=$(BRANCH)

build: podman
	$(PODMAN) build -t podman-full --build-arg TARGETARCH=$(TARGETARCH) .

archive: podman-full-$(TARGETARCH).tar

podman-full-$(TARGETARCH).tar:
	$(PODMAN) image inspect podman-full >/dev/null
	ctr=`$(PODMAN) create podman-full :`; \
	$(PODMAN) export $$ctr --output=$@ && \
	$(PODMAN) rm $$ctr
