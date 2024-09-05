# syntax=docker/dockerfile:1

ARG golang_version=1.22.6
ARG ubuntu_version=jammy-20240808
ARG xx_version=1.5.0

# https://github.com/tonistiigi/xx/
FROM --platform=$BUILDPLATFORM tonistiigi/xx:$xx_version AS xx

#################### Builder ####################

FROM ubuntu:$ubuntu_version AS builder

COPY --from=xx / /

ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/root/go

ARG golang_version
ENV golang_version=${golang_version}

RUN apt update && apt install -y --no-install-recommends \
    wget \
    ca-certificates \
    clang \
    pkg-config \
    dpkg-dev \
    libusb-1.0-0-dev \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

RUN wget https://go.dev/dl/go${golang_version}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${golang_version}.linux-amd64.tar.gz

RUN apt update
RUN apt install -y --no-install-recommends wget
RUN apt install -y --no-install-recommends cmake
RUN apt install -y --no-install-recommends git
RUN apt install -y --no-install-recommends patch
RUN apt install -y --no-install-recommends python3
RUN apt install -y --no-install-recommends libssl-dev
RUN apt install -y --no-install-recommends lzma-dev
RUN apt install -y --no-install-recommends libxml2-dev
RUN apt install -y --no-install-recommends xz-utils
RUN apt install -y --no-install-recommends bzip2
RUN apt install -y --no-install-recommends cpio
RUN apt install -y --no-install-recommends libbz2-dev
RUN apt install -y --no-install-recommends zlib1g-dev

########################################
# Set up environment variables for osxcross
ENV OSX_VERSION=12.3
ENV OSX_SDK_VERSION=12.3
ENV OSX_TARGET="x86_64-apple-darwin21"

# Install osxcross
WORKDIR /osxcross
RUN git clone https://github.com/tpoechtrager/osxcross.git .
COPY tarballs tarballs

ENV UNATTENDED=1
ENV TARGET_DIR=/usr/local/osxcross
RUN ./build.sh

# Export osxcross environment variables
ENV PATH="/usr/local/osxcross/bin:$PATH"
ENV CC=o64-clang
ENV CXX=o64-clang++

# Configure Go environment variables for Cgo cross-compilation
ENV GOOS=darwin
ENV GOARCH=amd64
ENV CGO_ENABLED=1
ENV CC=o64-clang
ENV CXX=o64-clang++
#######################################

#######################################
WORKDIR /

ARG libusb_version=467b6a8896daea3d104958bf0887312c5d14d150
ENV libusb_version=${libusb_version}

RUN apt install -y --no-install-recommends autoconf
RUN apt install -y --no-install-recommends automake
RUN apt install -y --no-install-recommends libtool

RUN git clone https://github.com/libusb/libusb \
    && cd libusb \
    && git checkout $libusb_version \
    && ./bootstrap.sh \
    #&& ./configure --host=x86_64-apple-darwin --prefix=/osxcross/target/macports/pkgs/usr \
    # Static link attempt
    && ./configure --host=x86_64-apple-darwin --disable-shared --prefix=/osxcross/target/macports/pkgs/usr \
    && make \
    && make install
#RUN ranlib /osxcross/target/macports/pkgs/usr/lib/libusb-1.0.a
#RUN o64-ranlib /osxcross/target/macports/pkgs/usr/lib/libusb-1.0.a
RUN /usr/local/osxcross/bin/x86_64-apple-darwin23.5-ranlib /osxcross/target/macports/pkgs/usr/lib/libusb-1.0.a
#RUN ar -t /osxcross/target/macports/pkgs/usr/lib/libusb-1.0.a
#
ENV CGO_CFLAGS="-I/osxcross/target/macports/pkgs/usr/include/libusb-1.0"
#ENV CGO_LDFLAGS="-L/osxcross/target/macports/pkgs/usr/lib"
# Static link attempt
#ENV CGO_LDFLAGS="-L/osxcross/target/macports/pkgs/usr/lib -lusb-1.0 -static"
#ENV CGO_LDFLAGS="-L/osxcross/target/macports/pkgs/usr/lib -lusb-1.0"
ENV CGO_LDFLAGS="-L/osxcross/target/macports/pkgs/usr/lib -lusb-1.0 -framework CoreFoundation -framework IOKit -framework Security"
ENV OSXCROSS_NO_INCLUDE_PATH_WARNINGS=1
#######################################

WORKDIR /src

COPY . .

ARG TARGETPLATFORM=darwin/amd64

RUN xx-go --wrap
RUN --mount=type=cache,target=/root/.cache/go-build go build -mod=vendor -ldflags "-w -s " -o /usr/local/bin/agent .

#################### Final layer ####################

FROM --platform=linux/amd64 ubuntu:$ubuntu_version

COPY --from=builder /usr/local/bin/agent /usr/local/bin/agent

ENTRYPOINT ["cp", "/usr/local/bin/agent", "/output"]
