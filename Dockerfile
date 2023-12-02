FROM ubuntu:20.04 AS rocm

# Copypasted from
# https://github.com/RadeonOpenCompute/ROCm-docker/blob/4e7caeb017aad706cd49ac433938f1226874ff9d/rocm-terminal/Dockerfile

ARG ROCM_VERSION=5.7
ARG AMDGPU_VERSION=5.7

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
  curl -sL http://repo.radeon.com/rocm/rocm.gpg.key | apt-key add - && \
  sh -c 'echo deb [arch=amd64] http://repo.radeon.com/rocm/apt/$ROCM_VERSION/ focal main > /etc/apt/sources.list.d/rocm.list' && \
  sh -c 'echo deb [arch=amd64] https://repo.radeon.com/amdgpu/$AMDGPU_VERSION/ubuntu focal main > /etc/apt/sources.list.d/amdgpu.list' && \
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  sudo \
  libelf1 \
  libnuma-dev \
  build-essential \
  git \
  vim-nox \
  cmake-curses-gui \
  kmod \
  file \
  python3 \
  python3-pip \
  rocm-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY sudo-nopasswd /etc/sudoers.d/sudo-nopasswd

RUN useradd --create-home -G sudo,video --shell /bin/bash rocm-user

USER rocm-user
WORKDIR /home/rocm-user
ENV PATH "${PATH}:/opt/rocm/bin"

FROM rocm AS ollama
# Copypasted (and then fixed) from
# https://hub.docker.com/layers/bergutman/ollama-rocm/latest/images/sha256-0b22c56813da245fe93e87d2cab145cf6bf60e00da789af9a487aa7784ff9272?context=explore
USER root

RUN apt-get update && \
  apt-get install -y rocblas-dev hipblas-dev wget git cmake build-essential && \
  rm -rf /var/lib/apt/lists/*

RUN wget https://dl.google.com/go/go1.21.4.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz && \
  rm go1.21.4.linux-amd64.tar.gz

ENV PATH "${PATH}:/usr/local/go/bin"

# Fix for 6700XT - https://github.com/RadeonOpenCompute/ROCm/issues/1756#issuecomment-1160386571
ENV HSA_OVERRIDE_GFX_VERSION=10.3.0

RUN git clone https://github.com/CNugteren/CLBlast.git && \
  cd CLBlast && \
  mkdir build && \
  cd build && \
  cmake .. && \
  make && \
  make install

RUN git clone --recursive https://github.com/65a/ollama ollama-rocm && \
  cd ollama-rocm && \
  ROCM_PATH=/opt/rocm CLBlast_DIR=/usr/lib/cmake/CLBlast go generate -tags rocm ./... && \
  go build -tags rocm && \
  cp ollama /usr/local/bin

ENV ROCM_PATH=/opt/rocm
ENV CLBlast_DIR=/usr/lib/cmake/CLBlast
USER rocm-user
ENTRYPOINT ["/run/podman-init", "--"]
CMD ["sh", "-c", "OLLAMA_HOST=0.0.0.0:11434 ollama serve"]
