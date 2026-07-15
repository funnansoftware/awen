@echo off
setlocal

rem Bootstraps the emscripten toolchain into a per-host prefix (.emsdk\Windows),
rem the Windows counterpart of scripts/bootstrap-emsdk.sh. The name "Windows"
rem matches CMake's ${hostSystemName} so the web presets (compiler-emcc:
rem EMSDK=.emsdk/${hostSystemName}) address the same directory.
rem
rem The zig web build (zig build -Dtarget=wasm32-emscripten) bootstraps the same
rem layout automatically; this script is for the CMake-only flow. Requires
rem Python on PATH (emsdk is driven by emsdk.py).

rem Repo root = the parent of this script's own directory.
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "PREFIX=%ROOT%\.emsdk\Windows"

rem emsdk activate writes .emscripten last, so its presence (alongside an emcc
rem launcher) means a previous install + activate finished; skip the download.
set "EMCC="
if exist "%PREFIX%\upstream\emscripten\emcc.exe" set "EMCC=1"
if exist "%PREFIX%\upstream\emscripten\emcc.bat" set "EMCC=1"
if defined EMCC if exist "%PREFIX%\.emscripten" (
    echo emscripten already installed at %PREFIX%
    exit /b 0
)

if not exist "%ROOT%\emsdk\emsdk.py" (
    echo emsdk submodule is missing or empty; run: git submodule update --init 1>&2
    exit /b 1
)

rem emsdk installs into whatever directory its scripts run from, so copy the
rem installer files out of the (pristine) submodule into the per-host prefix and
rem run them there. build.zig (resolveRoot) mirrors this.
if not exist "%PREFIX%" mkdir "%PREFIX%"
for %%F in ("%ROOT%\emsdk\*") do copy /y "%%F" "%PREFIX%\" >nul

rem "latest" resolves against the release list checked into the pinned submodule
rem commit, so the submodule pin determines the toolchain version.
call "%PREFIX%\emsdk.bat" install latest
if errorlevel 1 exit /b 1
call "%PREFIX%\emsdk.bat" activate latest
if errorlevel 1 exit /b 1
