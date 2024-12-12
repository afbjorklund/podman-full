
DOCKER = podman

BRANCH = v4.9

VERSION = 4.9.5

TARGETARCH ?= $(shell ./host-arch.sh)

ARCHIVE = podman-full-$(VERSION)-linux-$(TARGETARCH)

all: build archive

podman:
	git clone https://github.com/containers/podman.git --branch=$(BRANCH)

GO_VERSION = $(shell grep "ARG GO_VERSION" Dockerfile | cut -f2 -d=)
GO_IMAGE= $(shell grep FROM Dockerfile | grep GO_VERSION | cut -f3 -d' ' | GO_VERSION=$(GO_VERSION) envsubst)

RUST_VERSION = $(shell grep "ARG RUST_VERSION" Dockerfile | cut -f2 -d=)
RUST_IMAGE = $(shell grep FROM Dockerfile | grep RUST_VERSION | cut -f3 -d' ' | RUST_VERSION=$(RUST_VERSION) envsubst)

images:
	$(DOCKER) image inspect $(GO_IMAGE) >/dev/null || $(DOCKER) pull $(GO_IMAGE)
	$(DOCKER) image inspect $(RUST_IMAGE) >/dev/null || $(DOCKER) pull $(RUST_IMAGE)

build: podman images
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
	-@test $(DOCKER) != "docker" || ( tar --delete .dockerenv --delete dev --delete etc --delete proc --delete sys <$@ >$@.$$$$ && mv $@.$$$$ $@ )

$(ARCHIVE).tar.gz: $(ARCHIVE).tar
	gzip -9 <$< >$@
