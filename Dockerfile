# Build: docker build --platform linux/amd64 -t libasm-dev .
# Run: docker run --rm -it --platform linux/amd64 -v "$PWD:/work" libasm-dev
FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        file \
        gdb \
        nasm \
        binutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

CMD ["/bin/bash"]
