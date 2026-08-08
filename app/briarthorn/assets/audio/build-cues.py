"""Rebuild the interface cues from Kenney's Interface Sounds pack.

The .wav files beside this script are derived, not authored, and this is the
recipe. Swapping a cue is one line in CUES below and a re-run.

    pip install soundfile soxr numpy
    curl -LO https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip
    unzip kenney_interface-sounds.zip -d kenney
    python build-cues.py

Choosing a source matters more than anything done to it afterwards; see
README.md for the rule and how it was learned. In short: one transient, at
sample zero, and short. Alternatives that also pass, if a cue wants more body
than the one in place: tick_001 (23 ms), select_001 (43 ms), select_007 (47 ms),
toggle_004 (66 ms), click_005 (10 ms, driest).
"""
import os

import numpy as np
import soundfile as sf
import soxr

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(HERE, "kenney", "Audio")

# What desktop, android and the browser's Web Audio all run at. Anything else
# is resampled by Qt at play time, and that is audible as crackle.
RATE = 48000

CUES = {
    "navigate": "tick_001.ogg",
    "press": "select_002.ogg",
    "back": "back_002.ogg",
}

for role, source in CUES.items():
    data, rate = sf.read(os.path.join(PACK, source), always_2d=True)

    data = data - data.mean(axis=0)  # any DC offset is a step of its own
    data = soxr.resample(data, rate, RATE, quality="VHQ")
    if data.shape[1] == 1:
        data = np.repeat(data, 2, axis=1)  # no channel upmix at play time

    # Trim a tail already below -60 dB, keeping 10 ms of it: inaudible, and it
    # only makes the cue outlast itself.
    envelope = np.abs(data).max(axis=1)
    audible = np.where(envelope > np.abs(data).max() * 0.001)[0]
    if len(audible):
        data = data[:min(len(data), audible[-1] + int(RATE * 0.01))]

    # Fade OUT only, capped at a sixth of the file. Never fade in: these samples
    # begin at their attack, and ramping that edge does not remove an artifact,
    # it removes the click.
    n = len(data)
    fade = min(int(RATE * 0.005), n // 6)
    data[n - fade:] *= (0.5 - 0.5 * np.cos(np.linspace(np.pi, 0, fade)))[:, None]

    # Resampling overshoots, and a sample that clips on write clips on every play.
    ceiling = np.abs(data).max()
    if ceiling > 0.97:
        data *= 0.97 / ceiling

    target = os.path.join(HERE, f"{role}.wav")
    sf.write(target, data, RATE, subtype="PCM_16")
    print(f"{role:<9} <- {source:<16} {n / RATE * 1000:>5.0f} ms  "
          f"peak {np.abs(data).max():.3f}  {os.path.getsize(target):>6} B")
