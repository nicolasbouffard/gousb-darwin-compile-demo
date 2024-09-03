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

WORKDIR /src

ENV CGO_ENABLED=1

ARG BUILDPLATFORM

COPY . .

ARG TARGETPLATFORM=darwin/amd64

RUN xx-go --wrap
RUN --mount=type=cache,target=/root/.cache/go-build go build -mod=vendor -ldflags "-w -s " -o /usr/local/bin/agent .

#################### Final layer ####################

FROM --platform=linux/amd64 ubuntu:$ubuntu_version

COPY --from=builder /usr/local/bin/agent /usr/local/bin/agent

ENTRYPOINT ["cp", "/usr/local/bin/agent", "/output"]
