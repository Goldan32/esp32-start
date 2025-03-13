FROM docker.io/espressif/idf-rust:esp32_1.79.0.0

ARG USERNAME=esp

USER root

RUN apt update \
    && apt install -y libudev-dev \
    sudo \
    python3 \
    python3-virtualenv \
    python3-pip \
    libxml2-dev \
    libclang-dev \
    libgcrypt20-dev \
    ninja-build \
    flex \
    bison \
    libglib2.0-dev \
    libpixman-1-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgif-dev \
    procps \
    htop

RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER esp
