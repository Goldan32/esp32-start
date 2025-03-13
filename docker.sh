docker build -t "esp32-tag" . && \
docker run -d -it --name "esp32-container" \
    --mount type=bind,source=./my-test,target="/home/esp/project" \
    --privileged \
    "esp32-tag" && \
docker exec -it "esp32-container" /bin/bash
