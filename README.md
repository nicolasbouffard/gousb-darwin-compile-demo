# Instructions

1. Clone this repository on a Linux machine

2. Build the image
```
docker build -t gousb-darwin-compile-demo .
```

This step should fail with the repository in its current state. That's the whole goal of this repository : to improve it until this step succeeds.

At the time of writing, attempting to build the image should return something like this :
```
$ docker build -t gousb-darwin-compile-demo .
[+] Building 4.0s (16/17)                                                                                                                                             docker:default
 => [internal] load build definition from Dockerfile                                                                                                                            0.0s
 => => transferring dockerfile: 1.28kB                                                                                                                                          0.0s
 => resolve image config for docker-image://docker.io/docker/dockerfile:1                                                                                                       0.7s
 => CACHED docker-image://docker.io/docker/dockerfile:1@sha256:fe40cf4e92cd0c467be2cfc30657a680ae2398318afd50b0c80585784c604f28                                                 0.0s
 => [internal] load metadata for docker.io/library/ubuntu:jammy-20240808                                                                                                        0.7s
 => [internal] load metadata for docker.io/tonistiigi/xx:1.5.0                                                                                                                  0.7s
 => [internal] load .dockerignore                                                                                                                                               0.0s
 => => transferring context: 2B                                                                                                                                                 0.0s
 => [xx 1/1] FROM docker.io/tonistiigi/xx:1.5.0@sha256:0c6a569797744e45955f39d4f7538ac344bfb7ebf0a54006a0a4297b153ccf0f                                                         0.0s
 => [internal] load build context                                                                                                                                               0.0s
 => => transferring context: 886.95kB                                                                                                                                           0.0s
 => [builder 1/8] FROM docker.io/library/ubuntu:jammy-20240808@sha256:adbb90115a21969d2fe6fa7f9af4253e16d45f8d4c1e930182610c4731962658                                          0.0s
 => CACHED [builder 2/8] COPY --from=xx / /                                                                                                                                     0.0s
 => CACHED [builder 3/8] RUN apt update && apt install -y --no-install-recommends     wget     ca-certificates     clang     pkg-config     dpkg-dev     libusb-1.0-0-dev       0.0s
 => CACHED [builder 4/8] RUN wget https://go.dev/dl/go1.22.6.linux-amd64.tar.gz &&     tar -C /usr/local -xzf go1.22.6.linux-amd64.tar.gz                                       0.0s
 => CACHED [builder 5/8] WORKDIR /src                                                                                                                                           0.0s
 => [builder 6/8] COPY . .                                                                                                                                                      0.1s
 => [builder 7/8] RUN xx-go --wrap                                                                                                                                              1.5s
 => ERROR [builder 8/8] RUN --mount=type=cache,target=/root/.cache/go-build go build -mod=vendor -ldflags "-w -s " -o /usr/local/bin/agent .                                    0.5s
------
 > [builder 8/8] RUN --mount=type=cache,target=/root/.cache/go-build go build -mod=vendor -ldflags "-w -s " -o /usr/local/bin/agent .:
0.398 # runtime/cgo
0.398 clang: error: no such sysroot directory: '/xx-sdk/MacOSX11.1.sdk' [-Werror,-Wmissing-sysroot]
------

 1 warning found (use docker --debug to expand):
 - FromPlatformFlagConstDisallowed: FROM --platform flag should not use constant value "linux/amd64" (line 50)
Dockerfile:46
--------------------
  44 |
  45 |     RUN xx-go --wrap
  46 | >>> RUN --mount=type=cache,target=/root/.cache/go-build go build -mod=vendor -ldflags "-w -s " -o /usr/local/bin/agent .
  47 |
  48 |     #################### Final layer ####################
--------------------
ERROR: failed to solve: process "/bin/sh -c go build -mod=vendor -ldflags \"-w -s \" -o /usr/local/bin/agent ." did not complete successfully: exit code: 1
```

3. Extract the binary from the image
```
docker run --rm -v $(pwd)/output:/output gousb-darwin-compile-demo
```

4. Get the binary to a macOS machine somehow and try to run it, if everything went fine it should not fail