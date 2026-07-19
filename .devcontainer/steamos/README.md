# Steam Deck build container (Steam Linux Runtime "sniper")

A second devcontainer whose only job is to produce `briarthorn` binaries that
**run on the Steam Deck**. The default dev container (`.devcontainer/`) is Ubuntu
25.10 with a bleeding-edge glibc; anything built there fails on the Deck with
`version 'GLIBC_x.xx' not found`.

## Why sniper

The linux build is *native* — a binary's minimum glibc equals the glibc of the
container it was built in, and vcpkg builds Qt from source in that same
container, so the deployed Qt libraries inherit the same floor. "Sniper" is
Steam Linux Runtime 3.0, the container Steam guarantees at game launch on the
Deck and every other Steam platform. It is Debian 11 based (glibc 2.31), below
the Deck's ~2.37, and glibc is forward-compatible — so binaries built here run
both directly in SteamOS Desktop Mode and inside the Steam runtime container.

|           | default dev container | this (sniper)      | Steam Deck (SteamOS 3.x) |
| ---       | ---                   | ---                | ---                      |
| base      | Ubuntu 25.10          | Debian 11 (sniper) | Arch / Holo              |
| glibc     | ~2.42                 | **2.31**           | ~2.37–2.41               |
| toolchain | gcc-15 / clang-22     | **gcc-14 backport**| —                        |

Debian 11's own gcc-10/clang-11 cannot compile C++23 (or Qt 6.11). Valve
backports gcc-14 into the sniper SDK for exactly this purpose: a modern compiler
against the old glibc. The image exports `CC`/`CXX` pointing at it so vcpkg's
dependency builds (Qt included) pick it up, and the `steamos` preset pins the
same pair for the project.

gcc-14 binaries want gcc-14's libstdc++ at runtime, which is newer than the base
system's — that is the supported path: the Steam Linux Runtime uses the newest
libstdc++ of host vs runtime at game launch, and SteamOS's own libstdc++ is
newer still.

## Open it

VS Code → **Dev Containers: Reopen in Container** → pick **awen-steamos**.
(With multiple `.devcontainer/*/devcontainer.json` files, VS Code prompts for
which configuration to use.) The first launch pulls the sniper SDK image (a few
GB), and the first configure builds Qt from source via vcpkg — slow once, then
binary-cached.

## Build

```sh
cmake --preset steamos                          # configure (first run builds Qt)
cmake --build --preset steamos                  # build
ctest --preset steamos                          # run the test suite
cmake --build --preset steamos --target install # deploy into build/steamos/installed
```

The install step deploys the dynamic Qt libraries, platform plugins and QML
imports next to the binary, so `build/steamos/installed/` is the complete,
self-contained tree to ship.

## Verify the glibc floor

Before shipping, confirm nothing newer than the sniper floor leaked in (the CI
steamos workflow runs the same check over the whole installed tree):

```sh
objdump -T build/steamos/installed/briarthorn/bin/briarthorn \
  | grep -oE 'GLIBC_[0-9.]+' | sort -uV | tail -1
# expect: GLIBC_2.31 (or lower)
```

Then copy `build/steamos/installed/briarthorn/` to the Deck and run `bin/briarthorn`
from Desktop Mode, or add it to Steam as a non-Steam game so Steam wraps it in the
Steam Linux Runtime.
