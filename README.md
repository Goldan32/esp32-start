# ESP32-Start

- Install `espflash` and `esp-generate`
```sh
cargo install espflash esp-generate
```

- Generate an example project
```sh
esp-generate
```

- Add this repo as a submodule to the example project
```sh
git submodule add ... 
```

- Use the `container.sh` script to start a container, then
```sh
cargo build
```

- Find the port
```bash
espflash flash --list-all-ports <elf>
```

- Flash and monitor
```sh
espflash flash --monitor target/xtensa-esp32-none-elf/debug/hello-world
```
