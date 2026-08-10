# Cues

Seven in all, built by two scripts. The three the menus speak through are cut
from a pack; the four the duel speaks through are synthesised. Everything below
about how Qt plays a cue — and the 1.2 s of silence every one of them carries —
applies to all seven.

## Combat cues

`build-combat.py` generates these outright, standard library only. There is
nothing to download, nothing to resample and no third party in the licence,
because a lock tone and a threat warble *are* tones and a launch and an impact
are shaped noise — the source is the code, and retuning one is editing the
function that builds it.

| file         | what it is                               | ms  | fires on                                  |
| ------------ | ---------------------------------------- | --- | ----------------------------------------- |
| `launch.wav` | noise transient over a 70 Hz thump       | 340 | a round leaving ownship's rail            |
| `lock.wav`   | two 1180 Hz pips                         | 165 | a guided rack taking a return             |
| `threat.wav` | 500/660 Hz warble, odd harmonics         | 400 | a homing round marked inbound on ownship  |
| `impact.wav` | dark noise over a 55 Hz thump            | 420 | ownship's hull taking damage              |

The lock and the threat are the pair that must never be confused, so they are
kept apart deliberately: the lock is two clean high pips and the threat sits a
fifth below it with harmonics on, which still reads as two different sounds
when both fire inside a second. `qml/systems/SystemCue.qml` is what decides
when each one speaks, and the mix is the four `volume` values in
`qml/audio/Sfx.qml`.

Tones get a 3-4 ms attack and the noise bursts get none — see *Choosing a cue*
below for why that asymmetry is the right way round.

## Interface cues

Three short cues the menus speak through, from Kenney's **Interface Sounds**
pack (<https://kenney.nl/assets/interface-sounds>), released under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) — public domain,
no attribution required. Credited here anyway, and usable under briarthorn's
own license without adding a condition to it.

Each file is renamed to the role it plays rather than kept under its pack name,
so swapping a cue is one file and no QML edit:

| file           | Kenney source    | ms | fires on                                 |
| -------------- | ---------------- | -- | ---------------------------------------- |
| `navigate.wav` | `tick_001.ogg`   | 23 | the cursor or the mouse reaching an item |
| `press.wav`    | `select_002.ogg` | 43 | an item being chosen                     |
| `back.wav`     | `back_002.ogg`   | 70 | a page being dismissed                   |

The `.wav` files are derived, not authored: `build-cues.py` beside them is the
recipe, and swapping a cue is one line in its table and a re-run. It lists the
other sources that pass the rule below, for a cue that wants more or less body
than the one in place.

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
  makes the cue outlast itself.
- **Peaks pulled under 0.97**, because resampling overshoots and a sample that
  clips on write clips on every play.

## Why each file is a quarter of a megabyte of mostly silence

This is the important part, and it is not about the samples at all. **Qt stops
the audio device when an effect finishes playing, and stopping it just after
audible content clicks.** Recorded off the output, every cue was followed about
40 ms later — after 20 ms of pure digital silence — by a separate 3 ms
transient. The matching stream *start* clipped the front of the next cue, so
each one came out a slightly different length and loudness.

Heard from the outside that is a tick, then a click; cues that cut out; cues
that sound different every time. It survived three changes of sample, because
it was never in the sample.

The fix is the **1.2 s of digital silence appended to every cue**. It holds the
stream open across a run of navigation, so it never restarts mid-menu, and when
it does finally close it closes out of a long quiet where the stop is inaudible.
Measured over fourteen plays:

| | short files | with the silent tail |
| ------------------ | ----------- | -------------------- |
| events recorded    | 18          | 12 — no extras       |
| peak spread        | 9.01×       | **1.00×**            |
| length             | 2.9–9.6 ms  | **9.6 ms every time** |

Shorten `TAIL` in `build-cues.py` and the stream starts closing between
keypresses, which is the fault coming straight back. `Sfx` also keeps exactly
one `SoundEffect` per cue: a pool multiplies Qt's per-effect device work — the
format probing on first play is dozens of blocking `IsFormatSupported` calls —
and buys nothing at these lengths, since no one navigates fast enough to overlap
a 23 ms tick with itself.

One thing that is **not** safe: nothing may play a cue muted at startup to warm
the device. Unmuting from inside `playingChanged` re-enters Qt's state machine
and takes the process down on exit, reproducibly. `Cue.warm()` is deliberately
empty because of it.

Levels are otherwise untouched: the mix is the three `volume` values in
`qml/audio/Sfx.qml`, and nothing else.
