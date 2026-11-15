FROM docker.io/library/rust:1-bookworm

ARG ESP_RUST=1.97.0.0

ARG USERNAME=esp
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    pkg-config \
    libssl-dev \
    clang \
    libudev-dev \
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
    htop \
    && rm -rf /var/lib/apt/lists/*

ENV HOME=/opt/home
RUN mkdir -p "$HOME" \
 && cargo install espup --locked \
 && espup install --targets esp32 --toolchain-version "${ESP_RUST}" \
      --export-file /opt/export-esp.sh \
 && chmod -R a+rwX /opt /usr/local/rustup

RUN printf '#!/bin/bash\n. /opt/export-esp.sh\nexec "$@"\n' > /usr/local/bin/esp-env \
 && chmod +x /usr/local/bin/esp-env

RUN getent group "${USER_GID}" >/dev/null || groupadd -g "${USER_GID}" "${USERNAME}"; \
    useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/bash "${USERNAME}"

USER ${USERNAME}

ENTRYPOINT ["/usr/local/bin/esp-env"]
CMD ["bash"]

