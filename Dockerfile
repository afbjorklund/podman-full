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
ARG CONMON_VERSION=v2.1.10
ARG CRUN_VERSION=1.14

# Extra deps
ARG CATATONIT_VERSION=v0.1.7

# Test deps
ARG GO_VERSION=1.21

FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.3.0 AS xx


FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-bullseye AS build-base-debian
COPY --from=xx / /
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y git pkg-config dpkg-dev
ARG TARGETARCH
# libbtrfs: for containerd
# libseccomp: for runc
RUN xx-apt-get update && \
  xx-apt-get install -y binutils gcc libc6-dev libbtrfs-dev libseccomp-dev

FROM build-base-debian AS build-conmon
ARG CONMON_VERSION
ARG TARGETARCH
RUN xx-apt-get update && \
  xx-apt-get install -y libglib2.0-dev
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
RUN git clone https://github.com/containers/crun.git /go/src/github.com/containers/crun
WORKDIR /go/src/github.com/containers/crun
RUN git checkout ${CRUN_VERSION} && \
  mkdir -p /out /out/$TARGETARCH
RUN ./autogen.sh && ./configure && make && \
  cp -v -a crun /out/$TARGETARCH

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

FROM build-base-debian AS build-base
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
ARG CONMON_VERSION
COPY --from=build-conmon /out/${TARGETARCH:-amd64}/* /out/bin/
RUN ln /out/libexec/podman/conmon /out/bin/conmon
ARG CRUN_VERSION
COPY --from=build-crun /out/${TARGETARCH:-amd64}/* /out/bin/
ARG CATATONIT_VERSION
COPY --from=build-catatonit /out/${TARGETARCH:-amd64}/* /out/libexec/podman/

RUN chown -R 0:0 /out

FROM scratch
COPY --from=build-full /out /
