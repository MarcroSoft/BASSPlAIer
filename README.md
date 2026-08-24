# BASS PlAIer

A minimal native Windows player in C built on **BASS**, **BASS_FX** and **BASSenc**.
Status is shown in a real `SysListView32`, and everything is controlled from the keyboard.

The player is written entirely by AI, hence the name.

## Features

- Playlist pane to the left of the status list: opened files are queued and
  played in order (auto-advance when a track ends). Double-click or `Enter`
  plays the selected entry, `Delete` removes it; the playing track is marked
  with `>`. Removing the playing track stops playback, so an empty playlist
  plays nothing.
- Open files from Explorer: audio files can be dragged onto the window, passed
  on the command line, or opened via **Open with → BASS PlAIer** (the file
  formats can be registered during the installation process). If the player is already running, the file is handed
  to the running instance instead of starting a new one.
- Playback via BASS with plugin loading (all `.dll` files in the `plugins\` folder **next to the exe** are loaded with `BASS_PluginLoad`, e.g. `bassflac.dll`, `bassopus.dll`, `bass_aac.dll`).
- Real-time tempo change with BASS_FX (`BASS_ATTRIB_TEMPO`) — without changing the pitch.
- Reverse playback (`BASS_FX_ReverseCreate`) and tape-recorder-style fast cue/review: hold `F11`/`F12` to scrub backward/forward at speed.
- Independent pitch shift in semitones (`BASS_ATTRIB_TEMPO_PITCH`) and playback sample-rate / frequency control in 100 Hz steps (`BASS_ATTRIB_TEMPO_FREQ`).
- Command box (`C`): type `30` to jump to 30 minutes, `+5` / `-3` to seek relative, `t75` to set tempo, `p6` for pitch, `q44100` for frequency, `v150` for volume.
- 10-band graphic equalizer with BASS_FX (`BASS_FX_BFX_PEAKEQ`) at centres 80, 160, 320, 450, 900 Hz, 1.8, 3.6, 7, 10, 14 kHz. The band gains are also applied to the recording.
- Optional BPM detection with BASS_FX (`BASS_FX_BPM_DecodeGet`), hidden by default: press `Ctrl+B` to show the row and analyse the track in a background thread. While the row is shown each new track is analysed as it starts, and the reading follows the speed and frequency settings.
- Recording of what is currently playing to a `.wav` file with BASSenc (`BASS_Encode_Start` / `BASS_Encode_Stop`).
- Time, status, length, tempo etc. are shown continuously in a `SysListView32` (report view).

## Keyboard shortcuts

| Key | Action |
|------|----------|
| `O` | Open file(s) — added to the playlist |
| `Tab` | Switch between the playlist and the status list |
| `Space` | Play / pause |
| `Enter` | Play from the start (in the playlist: play the selected track) |
| `Delete` | Remove the selected track (in the playlist); stops it if it is playing |
| `Pause`/`Break` | Play / pause — **global** hotkey, works even when the window is not focused |
| `←` / `→` | Seek −5 / +5 sec |
| `Ctrl+←` / `Ctrl+→` | Seek −30 / +30 sec |
| `B` | Play backwards (toggle) |
| `F11` / `F12` (hold) | Fast rewind / forward like a tape recorder — releases back to normal |
| `↑` / `↓` | Navigate the list |
| `T` / `Shift+T` | Tempo down / up |
| `Ctrl+T` | Reset tempo to 0 % |
| `P` / `Shift+P` | Pitch down / up (1 semitone) |
| `Ctrl+P` | Reset pitch to 0 |
| `Q` / `Shift+Q` | Frequency down / up (100 Hz) |
| `Ctrl+Q` | Reset frequency to the file's native rate |
| `Backspace` | Reset tempo, pitch and frequency at once |
| `C` | Command box (`30` = go to 30 min, `+5`/`-3` = seek relative, `t75`, `p6`, `q44100`, `v150`) |
| `V` / `Shift+V` | Volume down / up |
| `Ctrl+V` | Reset volume (100 %) |
| `1`…`9`, `0` | Cut EQ band 1 dB (`1` = 80 Hz … `0` = 14 kHz); top row or numpad |
| `Shift`+`1`…`9`, `0` | Boost that EQ band 1 dB (range ±15 dB) |
| `Ctrl`+`1`…`9`, `0` | Reset that EQ band to 0 dB |
| `I` / `Shift+I` | Cut / boost all EQ bands 1 dB |
| `Ctrl+I` | Reset all EQ bands to flat |
| `Ctrl+B` | Show the BPM row and detect it from the current position |
| `Ctrl+Shift+B` | Hide the BPM row again |
| `R` | Start recording |
| `E` | Stop recording |
| `Alt+F4` | Quit |

> **Equalizer:** the two `EQ …` rows show all 10 bands as `freq:gain` cells — bands 1-5 (80-900 Hz) on the first row, 6-10 (1.8-14 kHz) on the second. Each band has its own number key (`1` = 80 Hz … `0` = 14 kHz): press it to cut that band, or `Shift`+the number to boost it — just like the volume keys. `Ctrl`+the number resets that single band, and `Ctrl+I` flattens everything. The setting persists when you open another file. The two EQ rows are only shown while at least one band is non-zero, and the `Tempo` row only while the tempo isn't 0 %.

> The list (`SysListView32`) is subclassed and gets focus automatically. Keys it doesn't use itself (e.g. arrow up/down) are passed on, so you can freely navigate the list.

## Download

Prebuilt packages are attached to each [GitHub release](../../releases): a portable x64
`.zip`, a portable 32-bit `.zip` (`BASSPlAIer-x86.zip`, see below), and a Windows
installer (`BASSPlAIer-Setup.exe`, built with NSIS, x64) that adds Start-menu and desktop
shortcuts and an uninstaller, and registers the audio formats so they can be opened from
Explorer's **Open with** menu. The BASS DLLs are bundled in.

Format plugins for Opus, FLAC, AAC, Apple Lossless, WavPack, Monkey's Audio, DSD and Speex are
offered on the installer's components page — none are ticked by default, so pick the ones
you want. The portable `.zip` simply ships them all in its `plugins\` folder.

## How to build

You need to fetch the BASS libraries yourself from un4seen (free for non-commercial use):

1. Download **BASS**, **BASS_FX** and **BASSenc** from https://www.un4seen.com
2. Place in the same folder as `player.c`:
   - Headers: `bass.h`, `bass_fx.h`, `bassenc.h`
   - Import libs: `bass.lib`, `bass_fx.lib`, `bassenc.lib`
   - The DLLs next to `BASSPlAIer.exe`: `bass.dll`, `bass_fx.dll`, `bassenc.dll`
3. (Optional) Create the `plugins\` folder and put extra BASS add-on DLLs there.
4. Build with MSVC (from a Developer Command Prompt):

```
build.bat
```

which compiles the version resource and the player:

```
rc /nologo /d APP_VERSION=... /d APP_VERSION_NUM=... version.rc
cl /O2 player.c version.res /link bass.lib bass_fx.lib bassenc.lib comctl32.lib comdlg32.lib user32.lib gdi32.lib shell32.lib /OUT:BASSPlAIer.exe
```

The version is taken from the `APPVERSION` environment variable (dotted, e.g. `1.2.3`;
defaults to `0.0.0`) and is embedded as the exe's product name / version info.

### 32-bit build (experimental)

`build32.bat` produces a 32-bit exe with **PE subsystem 4.0**, i.e. one the Windows 95
and NT 4.0 loaders will accept. It uses MinGW-w64's i686 `gcc` and `windres` rather than
MSVC, whose linker enforces a minimum subsystem version of 5.01 and silently discards
anything lower (`LNK4010`). It links straight against the DLLs, so no MinGW import
libraries are needed, and is built for size: `-Os -ffunction-sections
-Wl,--gc-sections -s`. CI builds it in a separate job and attaches the resulting
`BASSPlAIer-x86.zip` to the release.

How far back it actually runs is untested: the exe is only one of three layers. The BASS
DLLs have their own requirements, the listview styles need comctl32 4.70 (the IE 4 era,
not a bare NT 4.0 install), and NT 4.0 has very limited DirectSound, so `BASS_Init` is
likelier to succeed on Windows 95/98 than on NT 4.0.

## Notes

- The stream is created as a decoder channel (`BASS_STREAM_DECODE`) and wrapped in `BASS_FX_TempoCreate`, so the tempo can be changed live. `BASS_FX_FREESOURCE` ensures the source is freed automatically.
- The BPM row is hidden until you press `Ctrl+B`, and nothing is analysed while it is hidden. BASS_FX always returns its best guess, so material without a clear beat gives a meaningless number rather than nothing - which is why it is off by default. `Ctrl+Shift+B` hides it again. The BPM is found with `BASS_FX_BPM_DecodeGet` on a separate decoding channel of the same file (60 seconds of audio, range 45-230 BPM). It runs in a worker thread, so playback and the UI are not held up; until the result arrives the row shows `analysing...`. The row shows the BPM of the file itself, and when the speed is changed with tempo or frequency also the current BPM. Pressing `Ctrl+B` again analyses from where you are - useful for tracks that change tempo along the way, or where the intro fools the detection.
- The recording captures exactly the samples the playing channel delivers — including the tempo change — because the encoder is attached to the tempo stream.
- Each recording gets a unique name with date and time (`recording_20260620_143005.wav`), so earlier recordings are not overwritten. The file is written as a WAV in the channel's own format — the channel runs in float, so the result is a 32-bit float WAV. Add `BASS_ENCODE_FP_16BIT` to `BASS_Encode_Start` if you want 16-bit integer instead. If you want MP3/OGG instead, BASSenc can be hooked up to a command-line encoder (`BASS_Encode_Start` with an encoder command).
