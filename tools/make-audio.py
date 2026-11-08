#!/usr/bin/env python3
"""Generates the game's sound effects and music loop into assets/audio/ (ADR 0031).

Standard library only and deterministic: the same script always writes the same files. The sounds are our own
synthesis (no sample of any other game), mono, 16-bit, 22050 Hz.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")


def n(seconds):
    return int(seconds * RATE)


def sine(f, t):
    return math.sin(2 * math.pi * f * t)


def square(f, t):
    return 1.0 if math.sin(2 * math.pi * f * t) >= 0 else -1.0


def triangle(f, t):
    return 2.0 * abs(2.0 * ((f * t) % 1.0) - 1.0) - 1.0


def env(i, total, attack=0.005, release=0.5):
    """Linear attack then exponential-ish decay over the rest."""
    t = i / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    d = (1.0 - i / total) ** (1.0 / max(release, 0.05) * 1.0 + 0.0)
    return a * max(d, 0.0)


def tone(wave_fn, f0, f1, seconds, vol=0.6, release=1.0):
    """A tone gliding from f0 to f1 (Hz) with a decaying envelope."""
    total = n(seconds)
    out = []
    phase = 0.0
    for i in range(total):
        f = f0 + (f1 - f0) * i / total
        phase += f / RATE
        out.append(wave_fn(1.0, phase) * vol * env(i, total, release=release))
    return out


def noise(seconds, vol=0.6, release=0.4, lowpass=1.0, seed=1):
    rng = random.Random(seed)
    total = n(seconds)
    out = []
    y = 0.0
    for i in range(total):
        y += lowpass * (rng.uniform(-1, 1) - y)
        out.append(y * vol * env(i, total, attack=0.002, release=release))
    return out


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def silence(seconds):
    return [0.0] * n(seconds)


def write(name, samples, peak=0.8):
    top = max(max(abs(v) for v in samples), 1e-9)
    gain = min(1.0, peak / top) if top > peak else 1.0
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * gain)) * 32000)) for v in samples))
    print("%-10s %5.2f s" % (name, len(samples) / RATE))


def effects():
    write("click", tone(sine, 1800, 1400, 0.045, 0.7, release=0.5))
    write("beep", tone(square, 880, 880, 0.12, 0.35, release=0.7))
    write("start", mix(tone(square, 660, 1320, 0.4, 0.3, release=0.8), tone(sine, 330, 660, 0.4, 0.4, release=0.8)))
    write("shieldup", seq(*[tone(sine, f, f, 0.09, 0.5, release=0.6) for f in (660, 880, 1320)]))
    write("breakobs", mix(noise(0.22, 0.7, 0.35, 0.6, 2), tone(sine, 140, 50, 0.22, 0.6, release=0.5)))
    write("warning", seq(tone(square, 800, 800, 0.15, 0.3, release=1.5), tone(square, 600, 600, 0.15, 0.3, release=1.5),
                         tone(square, 800, 800, 0.15, 0.3, release=1.5), tone(square, 600, 600, 0.15, 0.3, release=1.5)))
    write("charge", tone(sine, 400, 1400, 0.3, 0.5, release=1.5))
    write("shockwave", mix(tone(sine, 90, 28, 0.7, 0.8, release=0.8), noise(0.7, 0.45, 0.5, 0.15, 3)))
    write("powerdown", tone(sine, 700, 90, 0.5, 0.6, release=0.8))
    write("torpedo", mix(noise(0.3, 0.4, 0.6, 0.35, 4), tone(sine, 300, 1500, 0.3, 0.4, release=1.2)))
    write("crash", mix(noise(0.55, 0.8, 0.5, 0.5, 5), tone(sine, 70, 35, 0.55, 0.8, release=0.6)))
    write("finish", seq(*[tone(triangle, f, f, 0.12, 0.5, release=0.8) for f in (523, 659, 784)], tone(triangle, 1046, 1046, 0.4, 0.5, release=0.6)))
    write("phase", mix(tone(sine, 900, 1500, 0.4, 0.3, release=1.0), tone(sine, 905, 1510, 0.4, 0.3, release=1.0)))


def music():
    bpm = 120
    beat = 60.0 / bpm
    bars = 8
    total = n(bars * 4 * beat)
    track = [0.0] * total
    # A minor: Am Am F F C C G G
    chords = [(57, 60, 64), (57, 60, 64), (53, 57, 60), (53, 57, 60), (48, 52, 55), (48, 52, 55), (43, 47, 50), (43, 47, 50)]

    def hz(midi):
        return 440.0 * 2 ** ((midi - 69) / 12)

    def add(start_beat, samples):
        start = n(start_beat * beat)
        for i, v in enumerate(samples):
            if start + i < total:
                track[start + i] += v

    rng = random.Random(7)
    for bar, chord in enumerate(chords):
        base = bar * 4
        # bass: eighth notes on the root, an octave down
        for e in range(8):
            add(base + e * 0.5, tone(square, hz(chord[0] - 12), hz(chord[0] - 12), beat * 0.45, 0.16, release=0.9))
        # arpeggio: sixteenth notes over the chord tones
        for s in range(16):
            note = chord[[0, 1, 2, 1][s % 4]] + 12
            add(base + s * 0.25, tone(triangle, hz(note), hz(note), beat * 0.24, 0.12, release=0.8))
        # kick on every beat, hat on the off-beats
        for b in range(4):
            add(base + b, tone(sine, 120, 45, beat * 0.3, 0.5, release=0.6))
            add(base + b + 0.5, noise(beat * 0.1, 0.12, 0.5, 0.9, rng.randint(1, 99)))
    write("music", track, peak=0.55)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    effects()
    music()
