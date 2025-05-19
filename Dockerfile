#   Copyright The containers Authors.
#   Copyright The containerd Authors.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# -----------------------------------------------------------------------------

# Basic deps
ARG CONMON_VERSION=v2.1.13
ARG CRUN_VERSION=1.21
ARG NETAVARK_VERSION=v1.15.0

# Extra deps
ARG PASST_VERSION=2025_05_12.8ec1341
ARG CATATONIT_VERSION=v0.2.1
ARG AARDVARK_DNS_VERSION=v1.15.0

# Test deps
ARG GO_VERSION=1.24.3
ARG RUST_VERSION=1.86

FROM --platform=$BUILDPLATFORM docker.io/tonistiigi/xx:1.5.0 AS xx


FROM --platform=$BUILDPLATFORM docker.io/library/golang:${GO_VERSION}-bookworm AS build-base-debian
COPY --from=xx / /
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -qq --no-install-recommends \
    git \
    dpkg-dev
ARG TARGETARCH
# libbtrfs: for containerd
# libseccomp: for runc
RUN xx-apt-get update -qq && xx-apt-get install -qq --no-install-recommends \
    binutils \
    gcc \
    libc6-dev \
    libbtrfs-dev \
    libseccomp-dev \
    pkg-config
RUN git config --global advice.detachedHead false

FROM --platform=$BUILDPLATFORM docker.io/library/rust:${RUST_VERSION}-bookworm AS build-rust-debian
COPY --from=xx / /
ARG TARGETARCH
ADD rust-jobs.sh /usr/local/bin/rust-jobs
RUN git config --global advice.detachedHead false

FROM build-base-debian AS build-conmon
ARG CONMON_VERSION
ARG TARGETARCH
RUN xx-apt-get update && \
  xx-apt-get install -y libglib2.0-dev libsystemd-dev
RUN git clone https://github.com/containers/conmon.git /go/src/github.com/containers/conmon
WORKDIR /go/src/github.com/containers/conmon
RUN git checkout ${CONMON_VERSION} && \
  mkdir -p /out /out/$TARGETARCH
RUN make && \
  cp -a bin/conmon /out/$TARGETARCH

FROM build-base-debian AS build-crun
ARG CRUN_VERSION
ARG TARGETARCH
RUN apt-get update && \
  apt-get install -y autoconf automake libtool
RUN xx-apt-get update && \
  xx-apt-get install -y libsystemd-dev libcap-dev libyajl-dev
RUN : downgrade libsystemd ABI so it works in ubuntu too; \
  echo "deb http://deb.debian.org/debian buster main" >/etc/apt/sources.list.d/buster.list; \
  echo "deb http://deb.debian.org/debian buster-updates main" >>/etc/apt/sources.list.d/buster.list; \
  xx-apt-get update; \
  version=$(apt list --all-versions libsystemd-dev | grep oldoldstable | awk '{ printf $2 }'); \
  xx-apt-get install -y --allow-downgrades libsystemd-dev'='$version libsystemd0'='$version
RUN git clone https://github.com/containers/crun.git /go/src/github.com/containers/crun
WORKDIR /go/src/github.com/containers/crun
RUN git checkout ${CRUN_VERSION} && \
  mkdir -p /out /out/$TARGETARCH
RUN ./autogen.sh && ./configure && make && \
  cp -v -a crun /out/$TARGETARCH

FROM build-rust-debian AS build-netavark
ARG NETAVARK_VERSION
ARG TARGETARCH
RUN apt-get update && \
  apt-get install -y protobuf-compiler go-md2man
RUN git clone https://github.com/containers/netavark.git /go/src/github.com/containers/netavark
WORKDIR /go/src/github.com/containers/netavark
RUN git checkout ${NETAVARK_VERSION} && \
  mkdir -p /out /out/$TARGETARCH
RUN CARGO_BUILD_JOBS=`rust-jobs` DESTDIR=/out/$TARGETARCH make build docs install && \
  mv /out/$TARGETARCH/usr/local/* /out/$TARGETARCH && \
  rmdir /out/$TARGETARCH/usr/local /out/$TARGETARCH/usr

FROM build-base-debian AS build-passt
ARG PASST_VERSION
ARG TARGETARCH
RUN git clone https://passt.top/passt /go/src/passt.top/passt
WORKDIR /go/src/passt.top/passt
RUN git checkout ${PASST_VERSION} && \
  mkdir -p /out /out/$TARGETARCH
RUN make && \
  cp -v -a passt pasta /out/$TARGETARCH

FROM build-base-debian AS build-catatonit
ARG CATATONIT_VERSION
ARG TARGETARCH
RUN apt-get update && \
  apt-get install -y autoconf automake libtool
RUN git clone https://github.com/openSUSE/catatonit.git /go/src/github.com/openSUSE/catatonit
WORKDIR /go/src/github.com/openSUSE/catatonit
RUN git checkout ${CATATONIT_VERSION} && \
  mkdir -p /out /out/$TARGETARCH
RUN autoreconf -fi && ./configure && make && \
  cp -v -a catatonit /out/$TARGETARCH

FROM build-rust-debian AS build-aardvark-dns
ARG AARDVARK_DNS_VERSION
ARG TARGETARCH
RUN git clone https://github.com/containers/aardvark-dns.git /go/src/github.com/containers/aardvark-dns
WORKDIR /go/src/github.com/containers/aardvark-dns
RUN git checkout ${AARDVARK_DNS_VERSION} && \
  mkdir -p /out /out/$TARGETARCH
RUN CARGO_BUILD_JOBS=`rust-jobs` make && \
  cp -a bin/aardvark-dns /out/$TARGETARCH

FROM build-base-debian AS build-base
RUN apt-get update && \
  apt-get install -y man-db
RUN xx-apt-get update && \
  xx-apt-get install -y libgpgme-dev libsystemd-dev
COPY ./podman /go/src/github.com/containers/podman
WORKDIR /go/src/github.com/containers/podman

FROM build-base AS build-minimal
RUN DESTDIR=/out make binaries install.bin

FROM build-base AS build-full
ARG TARGETARCH
ENV GOARCH=${TARGETARCH}
RUN DESTDIR=/out make binaries docs install && \
  mv /out/usr/local/* /out && rmdir /out/usr/local /out/usr
RUN mkdir -p /out/share/doc/podman-full && \
  echo "# podman (full distribution)" > /out/share/doc/podman-full/README.md && \
  echo "- podman: $(cd /go/src/github.com/containers/podman && git describe --tags)" >> /out/share/doc/podman-full/README.md
ARG CONMON_VERSION
COPY --from=build-conmon /out/${TARGETARCH:-amd64}/* /out/bin/
RUN ln /out/bin/conmon /out/libexec/podman/conmon
RUN echo "- conmon: ${CONMON_VERSION}" >> /out/share/doc/podman-full/README.md
ARG CRUN_VERSION
COPY --from=build-crun /out/${TARGETARCH:-amd64}/* /out/bin/
RUN echo "- crun: ${CRUN_VERSION}" >> /out/share/doc/podman-full/README.md
ARG NETAVARK_VERSION
COPY --from=build-netavark /out/${TARGETARCH:-amd64}/libexec/podman/* /out/libexec/podman/
COPY --from=build-netavark /out/${TARGETARCH:-amd64}/lib/systemd/* /out/lib/systemd/
RUN echo "- netavark: ${NETAVARK_VERSION}" >> /out/share/doc/podman-full/README.md
ARG PASST_VERSION
COPY --from=build-passt /out/${TARGETARCH:-amd64}/* /out/libexec/podman/
RUN echo "- passt: ${PASST_VERSION}" >> /out/share/doc/podman-full/README.md
ARG CATATONIT_VERSION
COPY --from=build-catatonit /out/${TARGETARCH:-amd64}/* /out/libexec/podman/
RUN echo "- catatonit: ${CATATONIT_VERSION}" >> /out/share/doc/podman-full/README.md
ARG AARDVARK_DNS_VERSION
COPY --from=build-aardvark-dns /out/${TARGETARCH:-amd64}/* /out/libexec/podman/
RUN echo "- aardvark-dns: ${AARDVARK_DNS_VERSION}" >> /out/share/doc/podman-full/README.md

RUN chown -R 0:0 /out

FROM scratch
COPY --from=build-full /out /
