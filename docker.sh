#!/bin/bash

# Figure out current folder and climb up
CURRENT_DIR="$(pwd)"
SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
PROJECT_ROOT="$(realpath "${SCRIPT_DIR}"/..)"
WORK_DIR="${SCRIPT_DIR}/workdir"
mkdir -p "${WORK_DIR}"

# Dynamically change container_bashrc
ELF_NAME="$(basename "${PROJECT_ROOT}")"
cp "${SCRIPT_DIR}/container_bashrc" "${WORK_DIR}/container_bashrc"
sed -i "s/TARGET_NAME=\"\"/TARGET_NAME=\"${ELF_NAME}\"/g" "${WORK_DIR}/container_bashrc"

# Set ESPFLASH_PORT if port was provided (First arg of script for now)
PORT="$1"
sed -i "s|ESPFLASH_PORT=\"\"|ESPFLASH_PORT=\"${PORT}\"|g" "${WORK_DIR}/container_bashrc"


cd "${SCRIPT_DIR}" || exit 1
docker build -t "esp32-tag" . && \
docker run -d -it --name "esp32-container" \
    --mount type=bind,source="${PROJECT_ROOT}",target="/home/esp/project" \
    --mount type=bind,source="${WORK_DIR}/container_bashrc",target="/home/esp/.bashrc" \
    --device=/dev/ttyUSB0 \
    --device=/dev/ttyUSB1 \
    --privileged \
    "esp32-tag" && \
docker exec -it "esp32-container" /bin/bash

cd "$CURRENT_DIR" || exit 1
