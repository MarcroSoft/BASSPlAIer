@echo off
rem Version comes from the APPVERSION env var (dotted, e.g. 1.2.3); CI sets it.
if "%APPVERSION%"=="" set APPVERSION=0.0.0
rem comma form for FILEVERSION (1.2.3 -> 1,2,3,0)
set APPVERNUM=%APPVERSION:.=,%,0
rc /nologo /d APP_VERSION=%APPVERSION% /d APP_VERSION_NUM=%APPVERNUM% version.rc
cl /O2 player.c version.res /link bass.lib bass_fx.lib bassenc.lib comctl32.lib comdlg32.lib user32.lib gdi32.lib /OUT:BASSPlAIer.exe
