# QuestCast

Show a Meta Quest's view in a normal Windows window over Wi-Fi, so OBS can capture **native Quest games** (the ones that run on the headset, not on your PC).

It is one batch file that starts [scrcpy](https://github.com/Genymobile/scrcpy) with settings that suit a Quest, plus an OBS scene that captures the window.

Virtual Desktop, Air Link and Steam Link only carry PC games. They do not carry native Quest games, which is the gap this fills.

## What you need

- Windows PC and a Meta Quest (built and tested on a Quest 3) on the same network
- [Developer mode](https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/) on in the Meta Horizon phone app
- `adb` and `scrcpy` ([install scrcpy](https://github.com/Genymobile/scrcpy#windows): `winget install Genymobile.scrcpy`)
- A USB cable, for the first run and after each headset reboot
- OBS Studio 30 or newer

## Quick start

1. Plug the headset in and accept the USB debugging prompt inside it.
2. Run `questcast.bat`. On the first run it:
   - switches adb to Wi-Fi mode,
   - reads the headset's IP address,
   - saves it to `questcast.ip` next to the script,
   - starts the cast.
3. Unplug the cable. The cast keeps running over Wi-Fi.
4. Start a game in the headset. A window titled `QuestCast` shows the left eye.
5. In OBS, use **Scene Collection → Import** and pick `obs/QuestCast.json`. The scene has a **Window Capture** source for the picture and an **Application Audio Capture** source for the sound. To build it by hand, add those two sources and choose `QuestCast:SDL_app:scrcpy.exe` in both. I have not tried the scene in OBS with a headset.

Start the cast before you open the OBS scene, because OBS has to find the window.

After a headset reboot, plug in the USB cable and run the script again. adb returns to USB mode on every reboot.

## Options

Set these as environment variables before running, or pass the headset IP as the first argument.

| Variable | Default | Meaning |
|---|---|---|
| `ADB` | `adb` | Path to `adb.exe` |
| `SCRCPY` | `scrcpy` | Path to `scrcpy.exe` |
| `PORT` | `5555` | adb over Wi-Fi port |
| `CROP` | `1600:900:420:700` | `width:height:x:y`, a 16:9 piece of the left eye |
| `BITRATE` | `20M` | Video bitrate |
| `FPS` | `60` | Maximum frame rate |
| `TITLE` | `QuestCast` | Window title (the OBS source matches this) |
| `AUDIO` | `1` | Set to `0` for video only (adds `--no-audio`) |
| `AUDIO_ARGS` | `--audio-source=playback --audio-dup` | scrcpy audio flags, used when `AUDIO` is not `0` |

## Audio

Audio is on by default. scrcpy sends the game sound from the headset to your PC, and the `QuestCast Audio` source in the OBS scene (an Application Audio Capture) takes it from `scrcpy.exe`. For video only, run:

```
set "AUDIO=0" & questcast.bat
```

Use Command Prompt for this. The variable stays set in that window until you close it or run `set "AUDIO="`.

**Audio is untested on a real Quest.** I could not test it on a headset, and it may stay silent. In [scrcpy issue #4354](https://github.com/Genymobile/scrcpy/issues/4354), a Quest 3 on Android 12 gave video but no audio, with the message `Could not get any audio timestamp`. A scrcpy contributor there says that, with no headphones connected, Quest OS sends all audio to an internal device. If audio capture fails, the video keeps running, because scrcpy falls back to video only ([scrcpy audio docs](https://github.com/Genymobile/scrcpy/blob/master/doc/audio.md)).

The default `--audio-source=playback --audio-dup` keeps the sound in the headset too. It is a guess for the Quest: a scrcpy contributor in that issue suggested `playback` but did not know if it would work. scrcpy needs Android 13 or later for both flags. `--audio-source=output` is the scrcpy default and needs Android 11 or later, but it mutes the headset. Set `AUDIO_ARGS` to change the flags, for example `set "AUDIO_ARGS=--audio-source=output" & questcast.bat`.

## About the crop

The Quest hands scrcpy both eyes side by side, with lens distortion. On a Quest 3 the frame is 4128x2208, which is two 2064x2208 views. The default `CROP` takes a 16:9 piece from the middle of the left eye. That avoids the curved edges but still shows a good part of the view.

If a game looks off-center, move the last two numbers. The left eye ends at x=2064. To preview a crop without scrcpy, grab a frame and cut it:

```
adb exec-out screencap -p > frame.png
ffmpeg -i frame.png -vf "crop=1600:900:420:700" preview.png
```

Quest 2, Quest Pro and Quest 3S have different eye sizes. I have not tested them, so expect to tune `CROP`.

## Limits

- The picture is the raw left-eye view, not a flattened one. Wide scenes look slightly curved.
- Audio is untested on a real Quest and may stay silent. See [Audio](#audio).
- The cast shares your Wi-Fi with anything else the headset streams. Do not run it at full quality while playing PC VR over Wi-Fi.
- It uses the headset's hardware H.264 encoder, which adds some load on the headset.

## Troubleshooting

| Problem | Fix |
|---|---|
| The window is gray | Close it, make sure a game is running, and start the script again |
| OBS capture is black | Open the source properties and pick the `QuestCast` window again |
| "No headset found over USB" | Plug in the cable, accept the prompt in the headset, run again |
| Cannot connect | PC and headset must be on the same network (some routers isolate Wi-Fi devices) |
| Stutter | Lower `BITRATE` or `FPS` |
| No sound in OBS | Audio is untested on a real Quest. Check that the audio source targets `QuestCast:SDL_app:scrcpy.exe`. Try `set "AUDIO_ARGS=--audio-source=output" & questcast.bat`; `--audio-source=output` is the mode that failed in issue #4354, so it may not help. In that issue, plugging in headphones sent audio to the PC. I have not tested that. |
| scrcpy stops at start with an audio error | Untested: if scrcpy exits instead of falling back to video only, an older Android or scrcpy may be the cause. I do not know. Set `AUDIO=0`, or try a newer scrcpy. |

## License

MIT. See [LICENSE](LICENSE).
