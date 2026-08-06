; NSIS installer for BASS PlAIer.
; Built in CI; expects the payload staged in the "release\" folder.
; Version and output name are passed on the command line:
;   makensis /DAPPVERSION=1.2.3 /DOUTFILE=BASSPlAIer-Setup.exe installer.nsi

Unicode true
!include "MUI2.nsh"

!ifndef APPVERSION
  !define APPVERSION "0.0.0"
!endif
!ifndef OUTFILE
  !define OUTFILE "BASSPlAIer-Setup.exe"
!endif

!define APPNAME   "BASS PlAIer"
!define PUBLISHER "MarcroSoft"
!define EXENAME   "BASSPlAIer.exe"
!define UNINSTKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
!define PROGID    "BASSPlAIer.audio"

; register/unregister one audio extension for "Open with" in Explorer
!macro RegisterExt EXT
  WriteRegStr HKLM "Software\Classes\${EXT}\OpenWithProgids" "${PROGID}" ""
  WriteRegStr HKLM "Software\Classes\Applications\${EXENAME}\SupportedTypes" "${EXT}" ""
!macroend
!macro UnregisterExt EXT
  DeleteRegValue HKLM "Software\Classes\${EXT}\OpenWithProgids" "${PROGID}"
!macroend

Name "${APPNAME}"
OutFile "${OUTFILE}"
InstallDir "$PROGRAMFILES64\${APPNAME}"
InstallDirRegKey HKLM "Software\${APPNAME}" "InstallDir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXENAME}"

; MUI's default icon carries 7 images, i.e. 7 RT_ICON resources. installer.ico
; holds a single 32x32 16-colour image (744 bytes as a resource), so the
; installer and the uninstaller carry one icon resource each instead of seven.
!define MUI_ICON   "installer.ico"
!define MUI_UNICON "installer.ico"

; One icon is the floor here - do not try to strip it entirely. Deleting the
; icon resources from the exe stub via !packhdr does work (it runs before the
; data is appended and the CRC is computed, so the "corrupted" check stays
; happy), but makensis then aborts with
;   Error generating uninstaller icon: invalid icon offset
; because installer and uninstaller share one stub: at run time the installer
; writes a copy of its own stub out as Uninstall.exe and patches the
; uninstaller icon in at offsets makensis derives from the stub's icon
; resources. With the resources gone there is nothing to patch. Deleting only
; the icon group (as the NSIS wiki recipe does) fails the same way, since the
; group is what those offsets come from. Removing WriteUninstaller would be the
; only way out, which is not worth an icon.

!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "BASS PlAIer (required)" SEC_APP
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "release\BASSPlAIer.exe"
  File "release\bass.dll"
  File "release\bass_fx.dll"
  File "release\bassenc.dll"
  File "release\README.html"

  CreateShortcut "$SMPROGRAMS\${APPNAME}.lnk" "$INSTDIR\${EXENAME}"

  WriteRegStr HKLM "Software\${APPNAME}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayName"     "${APPNAME}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayVersion"  "${APPVERSION}"
  WriteRegStr HKLM "${UNINSTKEY}" "Publisher"       "${PUBLISHER}"
  WriteRegStr HKLM "${UNINSTKEY}" "DisplayIcon"     "$INSTDIR\${EXENAME}"
  WriteRegStr HKLM "${UNINSTKEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoRepair" 1
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Desktop shortcut" SEC_DESKTOP
  ; CreateShortcut takes its working directory from $OUTDIR, so pin it to
  ; $INSTDIR rather than inheriting whatever the previous section left.
  SetOutPath "$INSTDIR"
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${EXENAME}"
SectionEnd

; Format plugins. The player loads every .dll in its plugins folder at
; start-up, so dropping one in is all it takes to add that format.
SectionGroup "Extra format plugins" SEC_PLUGINS
  Section /o "Opus (.opus)" SEC_PL_OPUS
    SetOutPath "$INSTDIR\plugins"
    File "release\plugins\bassopus.dll"
  SectionEnd
  Section /o "FLAC (.flac)" SEC_PL_FLAC
    SetOutPath "$INSTDIR\plugins"
    File "release\plugins\bassflac.dll"
  SectionEnd
  Section /o "AAC (.aac, .m4a)" SEC_PL_AAC
    SetOutPath "$INSTDIR\plugins"
    File "release\plugins\bass_aac.dll"
  SectionEnd
  Section /o "Apple Lossless (.m4a)" SEC_PL_ALAC
    SetOutPath "$INSTDIR\plugins"
    File "release\plugins\bassalac.dll"
  SectionEnd
  Section /o "WavPack (.wv)" SEC_PL_WV
    SetOutPath "$INSTDIR\plugins"
    File "release\plugins\basswv.dll"
  SectionEnd
  Section /o "Monkey's Audio (.ape)" SEC_PL_APE
    SetOutPath "$INSTDIR\plugins"
    File "release\plugins\bassape.dll"
  SectionEnd
  Section /o "DSD (.dsf, .dff)" SEC_PL_DSD
    SetOutPath "$INSTDIR\plugins"
    File "release\plugins\bassdsd.dll"
  SectionEnd
  Section /o "Speex (.spx)" SEC_PL_SPX
    SetOutPath "$INSTDIR\plugins"
    File "release\plugins\bass_spx.dll"
  SectionEnd
SectionGroupEnd

Section "Associate audio files with BASSPlAIer" SEC_ASSOC
  ; ProgID describing how to open a file with the player
  WriteRegStr HKLM "Software\Classes\${PROGID}" "" "Audio file (${APPNAME})"
  WriteRegStr HKLM "Software\Classes\${PROGID}\DefaultIcon" "" "$INSTDIR\${EXENAME},0"
  WriteRegStr HKLM "Software\Classes\${PROGID}\shell\open\command" "" '"$INSTDIR\${EXENAME}" "%1"'

  ; application registration (shows up in "Open with -> Choose another app")
  WriteRegStr HKLM "Software\Classes\Applications\${EXENAME}" "FriendlyAppName" "${APPNAME}"
  WriteRegStr HKLM "Software\Classes\Applications\${EXENAME}\shell\open\command" "" '"$INSTDIR\${EXENAME}" "%1"'

  ; offer the player in Explorer's "Open with" list for the audio formats
  !insertmacro RegisterExt ".mp3"
  !insertmacro RegisterExt ".ogg"
  !insertmacro RegisterExt ".wav"
  !insertmacro RegisterExt ".flac"
  !insertmacro RegisterExt ".aac"
  !insertmacro RegisterExt ".m4a"
  !insertmacro RegisterExt ".opus"

  ; tell Explorer the associations changed (SHCNE_ASSOCCHANGED)
  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\BASSPlAIer.exe"
  Delete "$INSTDIR\bass.dll"
  Delete "$INSTDIR\bass_fx.dll"
  Delete "$INSTDIR\bassenc.dll"
  Delete "$INSTDIR\README.html"
  Delete "$INSTDIR\Uninstall.exe"

  ; only the plugins we shipped; RMDir without /r leaves the folder alone if
  ; the user dropped their own BASS add-ons in there
  Delete "$INSTDIR\plugins\bassopus.dll"
  Delete "$INSTDIR\plugins\bassflac.dll"
  Delete "$INSTDIR\plugins\bass_aac.dll"
  Delete "$INSTDIR\plugins\bassalac.dll"
  Delete "$INSTDIR\plugins\basswv.dll"
  Delete "$INSTDIR\plugins\bassape.dll"
  Delete "$INSTDIR\plugins\bassdsd.dll"
  Delete "$INSTDIR\plugins\bass_spx.dll"
  RMDir  "$INSTDIR\plugins"

  RMDir  "$INSTDIR"
  Delete "$SMPROGRAMS\${APPNAME}.lnk"
  Delete "$DESKTOP\${APPNAME}.lnk"
  DeleteRegKey HKLM "${UNINSTKEY}"
  DeleteRegKey HKLM "Software\${APPNAME}"

  ; remove the file associations again
  !insertmacro UnregisterExt ".mp3"
  !insertmacro UnregisterExt ".ogg"
  !insertmacro UnregisterExt ".wav"
  !insertmacro UnregisterExt ".flac"
  !insertmacro UnregisterExt ".aac"
  !insertmacro UnregisterExt ".m4a"
  !insertmacro UnregisterExt ".opus"
  DeleteRegKey HKLM "Software\Classes\${PROGID}"
  DeleteRegKey HKLM "Software\Classes\Applications\${EXENAME}"
  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
SectionEnd
