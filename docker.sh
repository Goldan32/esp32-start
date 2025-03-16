docker build -t "esp32-tag" . && \
docker run -d -it --name "esp32-container" \
    --mount type=bind,source=./project,target="/home/esp/project" \
    --device=/dev/ttyUSB0 \
    --device=/dev/ttyUSB1 \
    --privileged \
    "esp32-tag" && \
docker exec -it "esp32-container" /bin/bash
