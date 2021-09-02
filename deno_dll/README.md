## Idea

Create a DLL that embeds deno, a JS runtime.  Use this DLL to run tasks such as asset downloads,
asset hosting via http server, NAT punch-through, and master server queries.

These tasks may benefit from rapid iteration to the technologies and protocols used.  For example,
QUIC, sending/receiving complex JSON payloads, hosting rich web-based user interfaces.
For these non-performance-critical tasks, we may benefit from implementing them in TypeScript.

## Building (WIP)

Some commands I ran when writing this library:

```shell
rustup target add x86_64-pc-windows-gnu
rustup toolchain install stable-x86_64-pc-windows-gnu

cargo build --target x86_64-pc-windows-gnu

cargo install cross

cargo install --force cbindgen
cbindgen --config cbindgen.toml --crate deno_dll --output deno_dll.h
```

## C test harness

Made a VS solution in `./c-test-harness` which uses the DLL, to prove that it
works.
