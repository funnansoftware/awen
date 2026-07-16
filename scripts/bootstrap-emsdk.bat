@echo off
setlocal

rem Bootstraps the emscripten toolchain into a per-host prefix (.emsdk\Windows),
rem the Windows counterpart of scripts/bootstrap-emsdk.sh. The name "Windows"
rem matches CMake's ${hostSystemName} so the web presets (compiler-emcc:
rem EMSDK=.emsdk/${hostSystemName}) address the same directory.
rem
rem The version is pinned in .emscripten-version rather than tracking "latest",
rem because Qt requires one specific emscripten release — see the comment in
rem scripts/bootstrap-emsdk.sh for why a mismatch fails late and quietly.
rem
rem Requires Python on PATH (emsdk is driven by emsdk.py).

rem Repo root = the parent of this script's own directory.
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "PREFIX=%ROOT%\.emsdk\Windows"
set "STAMP=%PREFIX%\.awen-emsdk-version"

set "VERSION="
for /f "usebackq tokens=* delims= " %%V in ("%ROOT%\.emscripten-version") do (
    if not defined VERSION set "VERSION=%%V"
)
if not defined VERSION (
    echo no version found in .emscripten-version 1>&2
    exit /b 1
)

rem emsdk activate writes .emscripten last, so its presence (alongside an emcc
rem launcher) means a previous install + activate finished. The stamp records
rem which version, so a bump re-bootstraps instead of reusing the old toolchain.
set "EMCC="
if exist "%PREFIX%\upstream\emscripten\emcc.exe" set "EMCC=1"
if exist "%PREFIX%\upstream\emscripten\emcc.bat" set "EMCC=1"
if defined EMCC if exist "%PREFIX%\.emscripten" if exist "%STAMP%" (
    set "INSTALLED="
    for /f "usebackq tokens=* delims= " %%V in ("%STAMP%") do set "INSTALLED=%%V"
    if "%INSTALLED%"=="%VERSION%" (
        echo emscripten %VERSION% already installed at %PREFIX%
        exit /b 0
    )
)

if not exist "%ROOT%\emsdk\emsdk.py" (
    echo emsdk submodule is missing or empty; run: git submodule update --init 1>&2
    exit /b 1
)

rem emsdk installs into whatever directory its scripts run from, so copy the
rem installer files out of the (pristine) submodule into the per-host prefix and
rem run them there.
if not exist "%PREFIX%" mkdir "%PREFIX%"
for %%F in ("%ROOT%\emsdk\*") do copy /y "%%F" "%PREFIX%\" >nul

call "%PREFIX%\emsdk.bat" install %VERSION%
if errorlevel 1 exit /b 1
call "%PREFIX%\emsdk.bat" activate %VERSION%
if errorlevel 1 exit /b 1
> "%STAMP%" echo %VERSION%
