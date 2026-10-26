#!/usr/bin/env python3
"""Footprint Guard launcher icons — pure stdlib PNG generation.
Mark: radar rings + emerald sweep on Amoled black (matches in-app gauge).
Supersampled 4x for clean edges. Usage: python3 tools/gen_icons.py
"""
import math, os, struct, zlib

EMERALD = (0, 255, 163)
BG = (4, 6, 7)
RING_DIM = (30, 90, 68)

def shade(nx, ny):
    """nx, ny in [-1, 1]. Returns (r,g,b)."""
    r = math.hypot(nx, ny)
    ang = math.atan2(-ny, nx)  # screen y down -> flip
    col = list(BG)
    # Sweep wedge: sector from -55deg..15deg, fading toward tail
    a0, a1 = math.radians(-55), math.radians(15)
    if r < 0.76 and a0 <= ang <= a1:
        t = (ang - a0) / (a1 - a0)  # 0 tail -> 1 leading edge
        k = 0.10 + 0.30 * t
        col = [int(col[i] * (1 - k) + EMERALD[i] * k) for i in range(3)]
    # Leading edge line at a1
    if r < 0.76 and abs(ang - a1) < 0.022:
        col = [int(c * 0.25 + e * 0.75) for c, e in zip(col, EMERALD)]
    # Rings
    for rr, bright in ((0.30, 0.85), (0.52, 0.7), (0.74, 1.0)):
        if abs(r - rr) < 0.028:
            base = EMERALD if rr == 0.74 else RING_DIM
            col = [int(c * (1 - bright) + b * bright) for c, b in zip(col, base)]
    # Crosshair ticks on outer ring at cardinal points
    if 0.74 < r < 0.86 and (abs(nx) < 0.02 or abs(ny) < 0.02):
        col = [int(c * 0.4 + e * 0.6) for c, e in zip(col, EMERALD)]
    # Blips
    for bx, by in ((0.38, -0.26), (-0.44, 0.3), (0.14, 0.5)):
        if math.hypot(nx - bx, ny - by) < 0.045:
            col = list(EMERALD)
    # Center dot: white core, emerald rim
    if r < 0.055:
        col = [245, 255, 250]
    elif r < 0.105:
        col = list(EMERALD)
    return tuple(col)

def render(size, ss=4):
    big = size * ss
    rows = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            acc = [0, 0, 0]
            for sy in range(ss):
                for sx in range(ss):
                    px = x * ss + sx
                    py = y * ss + sy
                    nx = (px / big) * 2 - 1
                    ny = (py / big) * 2 - 1
                    c = shade(nx, ny)
                    for i in range(3):
                        acc[i] += c[i]
            n = ss * ss
            row += bytes((acc[0] // n, acc[1] // n, acc[2] // n, 255))
        rows.append(bytes(row))
    return rows

def png(size, rows):
    def chunk(t, data):
        c = struct.pack(">I", len(data)) + t + data
        return c + struct.pack(">I", zlib.crc32(t + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    raw = b"".join(b"\x00" + r for r in rows)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))

TARGETS = {
    "mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192,
}

if __name__ == "__main__":
    base = "android/app/src/main/res"
    for folder, size in TARGETS.items():
        os.makedirs(f"{base}/{folder}", exist_ok=True)
        data = png(size, render(size))
        path = f"{base}/{folder}/ic_launcher.png"
        with open(path, "wb") as f:
            f.write(data)
        print(f"{path}  {size}x{size}  {len(data)} bytes")
    # Preview copy for README / web preview
    os.makedirs("web_preview", exist_ok=True)
    with open("web_preview/icon-192.png", "wb") as f:
        f.write(png(192, render(192)))
    print("web_preview/icon-192.png written")
