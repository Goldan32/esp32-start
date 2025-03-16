# ESP32-Start

Also install `espflash` and `cargo generate`

```
cargo install espflash cargo-generate
```

Generate an example project

```
cargo generate esp-rs/esp-template
```

Flash

```
espflash flash --list-all-ports <elf>
```
