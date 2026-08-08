# Interface cues

Three short cues the menus speak through, from Kenney's **Interface Sounds**
pack (<https://kenney.nl/assets/interface-sounds>), released under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) — public domain,
no attribution required. Credited here anyway, and usable under briarthorn's
own license without adding a condition to it.

Each file is renamed to the role it plays rather than kept under its pack name,
so swapping a cue is one file and no QML edit:

| file           | Kenney source  | fires on                                 |
| -------------- | -------------- | ---------------------------------------- |
| `navigate.wav` | `tick_004.ogg` | the cursor or the mouse reaching an item |
| `press.wav`    | `select_004.ogg` | an item being chosen                   |
| `back.wav`     | `back_003.ogg` | a page being dismissed                   |

## Why these three, and why they are not the pack's own files

`SoundEffect` plays uncompressed audio, so the Ogg Vorbis the pack ships has to
be re-containered regardless. Three things beyond the container decide whether a
UI cue sounds clean, and all three bit the first attempt:

- **The sample must begin and end at silence.** A one-shot that starts partway
  up its waveform steps the speaker cone the instant it is triggered, and that
  step *is* the click — no amount of volume trimming hides it. Most of the
  pack's shortest cues are cut hard at the transient (`tick_002` starts at 0.86
  of full scale, a step with no attack in front of it). These three were picked
  by measuring instead: their heads sit at −44, −80 and −53 dB below their own
  peaks, so none needs a fade-in, and the attack survives intact. Only a 5 ms
  fade-out is applied, to guarantee the tail.
- **The rate and channel count should match the output device.** Desktop,
  Android and the browser's Web Audio all run at 48 kHz stereo; at 44.1 kHz mono
  every play went through Qt's real-time resampler and an upmix. Resampled once,
  offline, at high quality instead.
- **Resampling overshoots.** Peaks are checked afterwards and pulled under
  0.97, because a sample that clips on write clips on every play.

`press.wav` also has its trailing silence trimmed: below −60 dB it is inaudible
but still holds a voice in `Sfx`'s pool for as long as a real sound would.

Levels are otherwise untouched — the mix is the three `volume` values in
`qml/audio/Sfx.qml`, and nothing else.
