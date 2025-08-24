FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    bc \
    libncurses5-dev \
    libssl-dev \
    libelf-dev \
    bison \
    flex \
    libfdt-dev \
    device-tree-compiler \
    python3 \
    python3-pip \
    qemu-system-arm \
    qemu-user-static \
    binfmt-support \
    parted \
    dosfstools \
    e2fsprogs \
    mtools \
    kpartx \
    rsync \
    xz-utils \
    unzip \
    zip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy script to build and test the image
COPY docker-build.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-build.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-build.sh"]
