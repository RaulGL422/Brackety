"""Writes the scoreboard sounds to assets/sounds/, synthesised here (no third-party samples or licences).

- bell_start.wav: one strong strike of a boxing-ring bell (the clock starts).
- bell_end.wav: three strikes (the match ends: points, time or disqualification).
- ten_seconds.wav: wooden clapper knocks, the timekeeper's warning with 10 s left.

Run from app/: python tool/make_bell.py
"""
import math
import random
import struct
import wave

RATE = 22050

# A ring bell: inharmonic partials (relative frequency, amplitude, decay per second). Two partials a few
# hertz apart beat against each other: the slow shimmer of a big bell.
BELL_HZ = 860.0
BELL_PARTIALS = [
    (1.0, 1.0, 1.1),
    (1.006, 0.5, 1.1),
    (2.0, 0.45, 1.8),
    (2.76, 0.55, 2.4),
    (4.07, 0.3, 3.5),
    (5.40, 0.25, 4.5),
    (8.93, 0.12, 7.0),
]

NOISE = random.Random(7)
KNOCK_NOISE = [NOISE.uniform(-1, 1) for _ in range(int(RATE * 0.05))]


def bell(dt):
    if dt < 0:
        return 0.0
    attack = min(1.0, dt / 0.002)
    tone = sum(
        amplitude * math.exp(-decay * dt) * math.sin(2 * math.pi * BELL_HZ * ratio * dt)
        for ratio, amplitude, decay in BELL_PARTIALS
    )
    # The hammer's metallic click on top of the ring.
    click = 0.6 * math.exp(-dt / 0.004) * math.sin(2 * math.pi * 3900 * dt)
    return attack * tone + click


def knock(dt):
    """A short, dry knock of hard wood: three resonant modes and a burst of noise, gone in ~60 ms."""
    if dt < 0 or dt > 0.12:
        return 0.0
    body = math.exp(-dt / 0.018) * (
        math.sin(2 * math.pi * 820 * dt)
        + 0.6 * math.sin(2 * math.pi * 1450 * dt)
        + 0.3 * math.sin(2 * math.pi * 2380 * dt)
    )
    index = int(dt * RATE)
    noise = KNOCK_NOISE[index] * math.exp(-dt / 0.004) if index < len(KNOCK_NOISE) else 0.0
    return body + 0.8 * noise


def render(name, seconds, voice, strikes):
    samples = [sum(voice(i / RATE - start) for start in strikes) for i in range(int(RATE * seconds))]
    peak = max(abs(s) for s in samples)
    with wave.open(f"assets/sounds/{name}", "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.9 * 32767)) for s in samples))


render("bell_start.wav", 3.0, bell, [0.0])
render("bell_end.wav", 3.6, bell, [0.0, 0.45, 0.9])
render("ten_seconds.wav", 0.9, knock, [0.0, 0.22, 0.44])
