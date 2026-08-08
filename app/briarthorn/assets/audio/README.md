# Interface cues

Three short cues the menus speak through, from Kenney's **Interface Sounds**
pack (<https://kenney.nl/assets/interface-sounds>), released under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) — public domain,
no attribution required. Credited here anyway, and usable under briarthorn's
own license without adding a condition to it.

Each file is renamed to the role it plays rather than kept under its pack name,
so swapping a cue is one file and no QML edit:

| file           | Kenney source    | ms | fires on                                 |
| -------------- | ---------------- | -- | ---------------------------------------- |
| `navigate.wav` | `click_005.ogg`  | 10 | the cursor or the mouse reaching an item |
| `press.wav`    | `select_002.ogg` | 43 | an item being chosen                     |
| `back.wav`     | `back_002.ogg`   | 70 | a page being dismissed                   |

## Choosing a cue

`SoundEffect` plays uncompressed audio, so the pack's Ogg Vorbis has to be
re-containered regardless. Three properties decide whether a cue reads as one
clean tick, and they are worth measuring rather than judging by name:

- **One transient.** Two is heard as two, however short the file — and several
  of the pack's cues are double hits. `tick_004`, whose name could not sound
  more like a single tick, is two strikes 16 ms apart.
- **The transient at sample zero.** Leading silence is latency the player feels
  on every keypress. `tick_004` again: 30 ms of nothing before it starts.
- **Short.** Consecutive ticks must not overlap, because two copies of the same
  sample a few milliseconds apart comb-filter into something that sounds
  different every time.

**These samples therefore begin at high amplitude, and that is correct.** A
percussive one-shot whose first sample *is* its attack is a step because the
sound is a step. Do not fade it in: 1.5 ms of raised cosine band-limits the
transient to a couple of kHz and the tick goes dull and far away. Only a sample
cut mid-*sustain* needs a fade-in, and none of these are — which is exactly the
mistake a "first sample must be near zero" rule leads to, since leading silence
passes it for free.

## Processing

Only what the output device wants, and nothing to the samples themselves:

- **48 kHz stereo**, what desktop, android and the browser's Web Audio all run
  at. At 44.1 kHz mono every play went through Qt's real-time resampler and a
  channel upmix, which is audible as crackle.
- **A 5 ms fade-out**, capped at a sixth of the file, so the tail lands on
  silence without eating the body of a very short cue. No fade-in — see above.
- **Trailing silence below −60 dB trimmed**, because it is inaudible but still
  holds a voice in `Sfx`'s pool for as long as a real sound.
- **Peaks pulled under 0.97**, because resampling overshoots and a sample that
  clips on write clips on every play.

Levels are otherwise untouched: the mix is the three `volume` values in
`qml/audio/Sfx.qml`, and nothing else.
