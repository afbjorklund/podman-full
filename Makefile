
DOCKER = podman

BRANCH = v5.3

VERSION = 5.3.0

TARGETARCH ?= $(shell ./host-arch.sh)

ARCHIVE = podman-full-$(VERSION)-linux-$(TARGETARCH)

all: build archive

podman:
	git clone https://github.com/containers/podman.git --branch=$(BRANCH)

build: podman
	-git -C podman fetch -n origin refs/heads/$(BRANCH):refs/remotes/origin/$(BRANCH)
	-git -C podman fetch -n origin refs/tags/v$(VERSION):refs/tags/v$(VERSION)
	git -C podman checkout v$(VERSION)
	$(DOCKER) build -t podman-full --build-arg TARGETARCH=$(TARGETARCH) .

archive: $(ARCHIVE).tar.gz

$(ARCHIVE).tar:
	$(DOCKER) image inspect podman-full >/dev/null
	ctr=`$(DOCKER) create podman-full :`; \
	$(DOCKER) export $$ctr --output=$@ && \
	$(DOCKER) rm $$ctr
	-@test $(DOCKER) != "docker" || tar --delete .dockerenv --delete dev --delete etc --delete proc -f $@

$(ARCHIVE).tar.gz: $(ARCHIVE).tar
	gzip -9 <$< >$@
