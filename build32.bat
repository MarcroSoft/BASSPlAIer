@echo off
rem 32-bit build with MinGW-w64, targeting PE subsystem 4.0 (Windows 95 / NT 4.0).
rem
rem MSVC cannot produce this: its linker enforces a minimum subsystem version
rem (5.01 on x86) and silently falls back to the default with LNK4010, so the
rem 32-bit build uses gcc/windres instead of cl/rc.
rem
rem Needs an i686 gcc + windres on PATH and the 32-bit BASS DLLs and headers in
rem this folder. Version comes from the APPVERSION env var, as in build.bat.
if "%APPVERSION%"=="" set APPVERSION=0.0.0
set APPVERNUM=%APPVERSION:.=,%,0

windres -DAPP_VERSION=%APPVERSION% -DAPP_VERSION_NUM=%APPVERNUM% version.rc version32.o
if errorlevel 1 exit /b 1

rem _WIN32_WINNT/_WIN32_IE pin the API surface to NT 4.0 with IE 4 era common
rem controls: the listview extended styles need comctl32 4.70 (_WIN32_IE 0x0300)
rem and NMITEMACTIVATE, used for the playlist double-click, needs 0x0400.
rem Linking straight against the DLLs avoids needing MinGW import libraries.
gcc -O2 -D_WIN32_WINNT=0x0400 -D_WIN32_IE=0x0400 player.c version32.o -o BASSPlAIer.exe ^
  -mwindows ^
  -Wl,--major-os-version,4 -Wl,--minor-os-version,0 ^
  -Wl,--major-subsystem-version,4 -Wl,--minor-subsystem-version,0 ^
  bass.dll bass_fx.dll bassenc.dll ^
  -lcomctl32 -lcomdlg32 -luser32 -lgdi32 -lshell32
if errorlevel 1 exit /b 1
