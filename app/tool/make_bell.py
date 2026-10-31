"""Writes assets/sounds/bell.wav: a synthetic boxing-ring bell (two strikes).

Generated here, not downloaded, so the sound has no third-party licence.
Run from app/: python tool/make_bell.py
"""
import math
import struct
import wave

RATE = 22050
SECONDS = 2.0
# Inharmonic partials (relative frequency, amplitude, decay per second) give the metallic ring.
PARTIALS = [(1.0, 1.0, 2.2), (2.76, 0.6, 3.5), (5.40, 0.35, 5.0), (8.93, 0.2, 7.0)]
BASE_HZ = 1150.0
STRIKES = [0.0, 0.35]


def sample(t):
    value = 0.0
    for start in STRIKES:
        dt = t - start
        if dt < 0:
            continue
        attack = min(1.0, dt / 0.004)
        for ratio, amplitude, decay in PARTIALS:
            value += amplitude * attack * math.exp(-decay * dt) * math.sin(2 * math.pi * BASE_HZ * ratio * dt)
    return value


samples = [sample(i / RATE) for i in range(int(RATE * SECONDS))]
peak = max(abs(s) for s in samples)
with wave.open("assets/sounds/bell.wav", "wb") as out:
    out.setnchannels(1)
    out.setsampwidth(2)
    out.setframerate(RATE)
    out.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.9 * 32767)) for s in samples))
