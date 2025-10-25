
DOCKER = podman

BRANCH = v4.9

VERSION = 4.9.5

TARGETARCH ?= $(shell ./host-arch.sh)

ARCHIVE = podman-full-$(VERSION)-linux-$(TARGETARCH)

all: build archive

podman:
	git clone https://github.com/containers/podman.git --branch=$(BRANCH)

.PHONY: versions
versions: package-versions.txt argument-versions.txt
	@printf '\033[1m%.30s%65s\033[0m\n' $^
	@colordiff --side-by-side $^

versions.txt:
	$(DOCKER) run --rm -i docker.io/library/almalinux:8 sh < dnf-versions.sh | tee versions.txt

packages.txt: versions.txt
	@grep -vi "^Available Packages" $< | grep -v release | sort -rV | awk '{print $$2,$$1}' | uniq -f 1 | awk '{print $$2,$$1}' | tee packages.txt

package-versions.txt: packages.txt
	@sort $< | ./packages.sh | sort >$@

arguments.txt: Dockerfile
	@(echo "ARG PODMAN_VERSION v$(VERSION)"; grep "^ARG" $< | grep "=" | tr "=" " " ) | tee arguments.txt

argument-versions.txt: arguments.txt
	@sort $< | ./arguments.sh | sort >$@

DEBIAN_VERSION = $(shell grep "ARG DEBIAN_VERSION" Dockerfile | cut -f2 -d=)
DEBIAN_IMAGE = debian:${DEBIAN_VERSION}

GO_VERSION = $(shell grep "ARG GO_VERSION" Dockerfile | cut -f2 -d=)
GO_IMAGE = $(shell grep FROM Dockerfile | grep GO_VERSION | cut -f3 -d' ' | GO_VERSION=$(GO_VERSION) DEBIAN_VERSION=$(DEBIAN_VERSION) envsubst)

RUST_VERSION = $(shell grep "ARG RUST_VERSION" Dockerfile | cut -f2 -d=)
RUST_IMAGE = $(shell grep FROM Dockerfile | grep RUST_VERSION | cut -f3 -d' ' | RUST_VERSION=$(RUST_VERSION) DEBIAN_VERSION=$(DEBIAN_VERSION) envsubst)

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
