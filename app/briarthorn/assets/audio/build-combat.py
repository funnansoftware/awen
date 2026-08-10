"""Rebuild the combat cues.

The .wav files beside this script are derived, not authored, and this is the
recipe — same as build-cues.py next door, except that these four are
synthesised rather than cut from a pack. Nothing to download and no third
party in the licence: a lock tone and a threat warble are tones, and a launch
and an impact are shaped noise, so the source *is* the code.

    python build-combat.py

Standard library only, deliberately. build-cues.py needs numpy/soundfile/soxr
because it reads and resamples Ogg Vorbis; there is nothing here to read.

Everything build-cues.py learned about how Qt plays these applies unchanged,
and README.md is where it is written down. In particular the 1.2 s of digital
silence on the end is not padding — Qt stops the audio device when an effect
finishes and stopping it just after audible content clicks. Shorten TAIL and
that comes straight back.
"""
import array
import math
import random
import os
import wave

HERE = os.path.dirname(os.path.abspath(__file__))

# What desktop, android and the browser's Web Audio all run at. Anything else
# is resampled by Qt at play time, and that is audible as crackle.
RATE = 48000

# Seconds of silence appended to every cue. See the module docstring.
TAIL = 1.2


def seconds(n):
    return int(RATE * n)


def noise(n, seed):
    """White noise in [-1, 1], seeded so a rebuild is byte-identical."""
    rng = random.Random(seed)
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(xs, cutoff):
    """One-pole lowpass. Rounds the hiss off noise so it reads as body."""
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff / RATE)
    out = []
    y = 0.0
    for x in xs:
        y += alpha * (x - y)
        out.append(y)
    return out


def tone(n, freq, harmonics=(1.0,)):
    """A sine, or a stack of harmonics for something with an edge on it.

    Phase starts at zero, so the waveform starts at zero amplitude and needs no
    fade-in to avoid a step — see README.md on why fading a cue in is usually
    the wrong instinct.
    """
    out = []
    for i in range(n):
        t = i / RATE
        out.append(sum(a * math.sin(2 * math.pi * freq * h * t)
                       for h, a in enumerate(harmonics, start=1)))
    return out


def decay(xs, tau, attack=0.0):
    """Exponential decay over the whole run, with an optional attack ramp.

    The attack is for tones only. A percussive burst starts at its transient
    and ramping that edge does not remove an artifact, it removes the sound.
    """
    n = len(xs)
    rise = seconds(attack)
    out = []
    for i, x in enumerate(xs):
        gain = math.exp(-(i / RATE) / tau)
        if rise and i < rise:
            gain *= 0.5 - 0.5 * math.cos(math.pi * i / rise)
        out.append(x * gain)
    return out


def silence(n):
    return [0.0] * n


def mix(*parts):
    """Sum runs of different lengths, left-aligned."""
    out = [0.0] * max(len(p) for p in parts)
    for part in parts:
        for i, x in enumerate(part):
            out[i] += x
    return out


def launch():
    """The round leaving the rail: a hard noise transient over a low thump."""
    body = decay(lowpass(noise(seconds(0.34), 1), 2600), 0.10)
    thump = decay(tone(seconds(0.34), 70), 0.055)
    return mix([x * 0.85 for x in body], [x * 0.7 for x in thump])


def lock():
    """Seeker acquisition: two clean high pips, the classic two-tone bite."""
    pip = decay(tone(seconds(0.055), 1180), 0.030, attack=0.003)
    return mix(pip + silence(seconds(0.055)) + pip, silence(seconds(0.165)))


def threat():
    """Inbound: a lower, harsher warble that cannot be mistaken for the lock.

    Two alternating tones with odd harmonics on them, so it reads as an alarm
    rather than an instrument — and it lives a fifth below the lock pips, which
    is what keeps the two apart when both fire inside a second.
    """
    out = []
    for step in range(4):
        freq = 500 if step % 2 == 0 else 660
        piece = tone(seconds(0.10), freq, harmonics=(1.0, 0.0, 0.32, 0.0, 0.14))
        out += decay(piece, 0.25, attack=0.004)
    return out


def impact():
    """A hit landing on the hull: dark noise, no tone, gone fast."""
    body = decay(lowpass(noise(seconds(0.42), 2), 700), 0.13)
    thump = decay(tone(seconds(0.42), 55), 0.085)
    return mix([x * 0.9 for x in body], [x * 0.85 for x in thump])


CUES = {
    "launch": launch,
    "lock": lock,
    "threat": threat,
    "impact": impact,
}

for role, build in CUES.items():
    data = build()
    sound = len(data)

    # Fade OUT only, capped at a sixth of the file, so the tail lands on
    # silence rather than on a step.
    fade = min(seconds(0.005), sound // 6)
    for i in range(fade):
        data[sound - fade + i] *= 0.5 - 0.5 * math.cos(math.pi * (fade - i) / fade)

    # A sample that clips on write clips on every play.
    ceiling = max(abs(x) for x in data)
    if ceiling > 0.97:
        data = [x * 0.97 / ceiling for x in data]

    data += silence(seconds(TAIL))

    # Interleaved 16-bit stereo, the same value in both channels: the content
    # is mono and the device wants two, so upmixing here costs nothing and
    # doing it at play time costs a channel conversion on every cue.
    frames = array.array("h")
    for x in data:
        s = max(-32768, min(32767, int(x * 32767)))
        frames.append(s)
        frames.append(s)

    target = os.path.join(HERE, f"{role}.wav")
    with wave.open(target, "wb") as out:
        out.setnchannels(2)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames.tobytes())

    print(f"{role:<8} {sound / RATE * 1000:>5.0f} ms sound + {TAIL:.1f}s silence  "
          f"peak {max(abs(x) for x in data):.3f}  "
          f"{os.path.getsize(target) / 1024:>6.0f} KiB")
