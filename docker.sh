#!/bin/bash

# Figure out current folder and climb up
CURRENT_DIR="$(pwd)"
SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
PROJECT_ROOT="$(realpath "${SCRIPT_DIR}"/..)"

cd "${SCRIPT_DIR}" || exit 1
docker build -t "esp32-tag" . && \
docker run -d -it --name "esp32-container" \
    --mount type=bind,source="${PROJECT_ROOT}",target="/home/esp/project" \
    --mount type=bind,source="${SCRIPT_DIR}/container_bashrc",target="/home/esp/.bashrc" \
    --device=/dev/ttyUSB0 \
    --device=/dev/ttyUSB1 \
    --privileged \
    "esp32-tag" && \
docker exec -it "esp32-container" /bin/bash

cd "$CURRENT_DIR" || exit 1
