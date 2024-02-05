
DOCKER = podman

BRANCH = v4.9

VERSION = 4.9.2

TARGETARCH ?= amd64

ARCHIVE = podman-full-$(VERSION)-linux-$(TARGETARCH)

all: build archive

podman:
	git clone https://github.com/containers/podman.git --branch=$(BRANCH)

build: podman
	git -C podman checkout v$(VERSION)
	$(DOCKER) build -t podman-full --build-arg TARGETARCH=$(TARGETARCH) .

archive: $(ARCHIVE).tar.gz

$(ARCHIVE).tar:
	$(DOCKER) image inspect podman-full >/dev/null
	ctr=`$(DOCKER) create podman-full :`; \
	$(DOCKER) export $$ctr --output=$@ && \
	$(DOCKER) rm $$ctr

$(ARCHIVE).tar.gz: $(ARCHIVE).tar
	gzip -9 <$< >$@
