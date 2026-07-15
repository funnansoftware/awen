# Steam Deck build container (Steam Linux Runtime "sniper")

A second devcontainer whose only job is to produce a `briarthorn` binary that
**runs on the Steam Deck**. The default dev container (`.devcontainer/`) is Ubuntu
25.10 with a bleeding-edge glibc; anything built there fails on the Deck with
`version 'GLIBC_x.xx' not found`.

## Why sniper

briarthorn's Linux build is *native* — the zig toolchain links against the build
machine's glibc (see [`cmake/toolchain/zig-linux.cmake`](../../cmake/toolchain/zig-linux.cmake)),
so a binary's minimum glibc equals the glibc of the container it was built in.
"Sniper" is Steam Linux Runtime 3.0, the container Steam guarantees at game launch
on the Deck and every other Steam platform. It is Debian 11 based (glibc 2.31),
below the Deck's ~2.37, and glibc is forward-compatible — so a binary built here
runs both directly in SteamOS Desktop Mode and inside the Steam runtime container.

|           | default dev container | this (sniper)      | Steam Deck (SteamOS 3.x) |
| ---       | ---                   | ---                | ---                      |
| base      | Ubuntu 25.10          | Debian 11 (sniper) | Arch / Holo              |
| glibc     | ~2.42                 | **2.31**           | ~2.37–2.41               |
| toolchain | gcc / clang / zig     | **zig only**       | —                        |

zig bundles its own clang + libc++/compiler-rt, so it builds C++23 and statically
links the C++ runtime; the Deck binary's only dynamic dependencies are glibc 2.31
and the system X11/GL libraries the Deck already provides. (Debian 11's
gcc-10/clang-11 cannot compile C++23, which is why this container is zig-only.)

## Open it

VS Code → **Dev Containers: Reopen in Container** → pick **awen-steamos**.
(With multiple `.devcontainer/*/devcontainer.json` files, VS Code prompts for which
configuration to use.) The first launch pulls the sniper SDK image (a few GB).

## Build

```sh
zig build        # optimized release -> build/x86_64-linux-gnu-releasefast/installed
zig build test   # run the GoogleTest suite against the sniper glibc floor
```

The existing `linux-zig-release` CMake preset works too — it drives the same zig
toolchain.

## Verify the glibc floor

Before shipping, confirm nothing newer than the sniper floor leaked in:

```sh
objdump -T build/x86_64-linux-gnu-releasefast/installed/bin/briarthorn \
  | grep -oE 'GLIBC_[0-9.]+' | sort -uV | tail -1
# expect: GLIBC_2.31 (or lower)
```

Then copy `build/x86_64-linux-gnu-releasefast/installed/` to the Deck and run
`bin/briarthorn` from Desktop Mode, or add it to Steam as a non-Steam game so
Steam wraps it in the Steam Linux Runtime.
