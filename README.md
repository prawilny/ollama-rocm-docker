# Description
Personal OCI image of [ollama](https://github.com/jmorganca/ollama) with [ROCm support](https://github.com/jmorganca/ollama/pull/814) enabled.
Tested on default configuration (default AMD driver, SELinux enabled, ...) Fedora 39 with podman, podman-compose and AMD 6700XT.

Contains a fix for AMD 6700XT, which will possibly break it for other GPUs.
If you want to use this image with another GPU, you will likely want to remove `ENV HSA_OVERRIDE_GFX_VERSION=10.3.0` from [/Dockerfile](Dockerfile).

# Rootless podman and SELinux
You need to allow rootless podman containers to use devices:
```sh
sudo setsebool container_use_devices=true
```

# Quick demo
```sh
docker compose up -d --build
docker compose exec ollama ollama run mistral
```

# More links:
https://github.com/jmorganca/ollama/issues/738

https://github.com/jmorganca/ollama/pull/814

https://hub.docker.com/r/bergutman/ollama-rocm

https://github.com/RadeonOpenCompute/ROCm-docker
