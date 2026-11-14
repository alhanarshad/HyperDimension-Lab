"""Generate original Dashverse product artwork and audio masters."""

from array import array
import csv
import math
from pathlib import Path
import random
import re
import struct
import sys
import wave
import zlib


root = Path(__file__).resolve().parents[1]
destination = Path(sys.argv[1]).resolve()
icons = destination / "product-icons"
audio = destination / "audio"
icons.mkdir(parents=True, exist_ok=True)
audio.mkdir(parents=True, exist_ok=True)

SIZE = 512
MID = 256
RATE = 24000


def write_png(path, pixels):
    def chunk(label, data):
        return struct.pack(">I", len(data)) + label + data + struct.pack(">I", zlib.crc32(label + data))

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    stride = SIZE * 3
    scanlines = b"".join(b"\0" + pixels[i:i + stride] for i in range(0, len(pixels), stride))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(scanlines, 8)) + chunk(b"IEND", b""))


def polygon(points, x, y):
    inside = False
    ax, ay = points[-1]
    for bx, by in points:
        if (ay > y) != (by > y) and x < (bx - ax) * (y - ay) / (by - ay) + ax:
            inside = not inside
        ax, ay = bx, by
    return inside


def star(cx, cy, radius, inner, points=4, phase=0):
    return [
        (cx + math.sin(phase + k * math.pi / points) * r, cy - math.cos(phase + k * math.pi / points) * r)
        for k in range(points * 2)
        for r in [radius if k % 2 == 0 else inner]
    ]


def draw_icon(key, color):
    pixels = bytearray()
    main = None
    bolt = [(257, 118), (176, 266), (235, 266), (226, 374), (338, 221), (270, 221), (286, 118)]
    polygons = []
    coins = []
    if key == "spark":
        polygons = [star(252, 250, 113, 42), star(335, 172, 36, 14), star(174, 311, 33, 13)]
    elif key == "trail":
        polygons = [
            [(129, 308), (243, 185), (372, 171), (279, 239), (216, 308)],
            [(157, 347), (268, 235), (372, 218), (311, 264), (235, 347)],
        ]
    elif key in {"coins", "coinboost"}:
        coins = [(215, 287, 70), (284, 232, 71)]
        if key == "coinboost":
            coins.append((207, 201, 62))
    elif key == "shoes":
        polygons = [
            [(134, 300), (176, 248), (213, 244), (219, 191), (277, 192), (294, 254), (361, 275), (376, 311), (153, 328)],
            [(167, 337), (352, 319), (366, 331), (172, 352)],
        ]
    elif key in {"energy", "training"}:
        polygons = [bolt]
        if key == "training":
            polygons += [star(142, 262, 33, 13), star(362, 199, 33, 13)]
    else:
        polygons = [star(256, 257, 121, 67, 5 if key == "founder" else 4)]
        polygons += [star(354, 170, 35, 14), star(166, 340, 29, 11)]
        main = star(256, 257, 63, 33, 4)

    def contains(x, y):
        for poly in polygons:
            if polygon(poly, x, y):
                return True
        return False

    for y in range(SIZE):
        for x in range(SIZE):
            radius = math.hypot(x - MID, y - MID)
            glow = max(0, 1 - radius / 220)
            border = max(0, 1 - abs(radius - 194) / 2.2) * 0.49
            shine = max(0, 1 - math.hypot(x - 186, y - 160) / 310)
            shade = tuple(int(10 + channel * (glow * 0.12 + border + shine * 0.045)) for channel in color)
            if 115 <= x <= 392 and 108 <= y <= 380:
                if coins:
                    for cx, cy, r in coins:
                        d = math.hypot((x - cx) * 1.13, y - cy)
                        if d < r:
                            accent = 0.28 if abs(d - r + 9) < 3 or abs(x - cx) < 5 and abs(y - cy) < 22 else 0
                            shade = tuple(min(255, int(c * (0.77 + accent + 0.13 * (cy + r - y) / r))) for c in color)
                elif contains(x, y):
                    lit = 0.2 + (1 - (y - 108) / 272) * 0.34
                    if main and polygon(main, x, y):
                        lit = 0.81
                    shade = tuple(int(c + (255 - c) * lit) for c in color)
            pixels.extend(shade)
    write_png(icons / (key + ".png"), pixels)


catalog = (root / "src/shared/Catalog.luau").read_text(encoding="utf-8")
matches = re.findall(
    r'\{id = "([^"]+)", name = "([^"]+)", price = (\d+), kind = "([^"]+)", world = (\d+), stand = "([^"]+)",\s*'
    r'details = "([^"]+)",[^\n]*\s*[^\n]*?color = rgb\((\d+), (\d+), (\d+)\)',
    catalog,
)
if len(matches) != 9:
    raise RuntimeError("Expected nine prepared catalog items")
with (destination / "catalog.csv").open("w", encoding="utf-8-sig", newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["Key", "Name", "Type", "Target Robux", "World", "Display", "Description", "Icon", "Confirmed Roblox ID"])
    for key, name, price, kind, world, stand, description, r, g, b in matches:
        draw_icon(key, (int(r), int(g), int(b)))
        writer.writerow([key, name, kind, price, world, stand, description, "product-icons/" + key + ".png", ""])


def save_audio(name, duration, signal):
    values = array("h")
    for i in range(int(duration * RATE)):
        level = max(-1, min(1, signal(i / RATE)))
        values.append(round(level * 32767))
    if sys.byteorder != "little":
        values.byteswap()
    with wave.open(str(audio / (name + ".wav")), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(values.tobytes())


def motif(notes):
    def signal(t):
        total = 0
        for start, frequency, length, gain in notes:
            p = t - start
            if 0 <= p < length:
                env = min(1, p / 0.013) * ((1 - p / length) ** 2.3)
                total += gain * env * (math.sin(math.tau * frequency * p) + 0.23 * math.sin(math.tau * 2.005 * frequency * p))
        return total
    return signal


save_audio("pickup", 0.26, motif([(0, 783.99, 0.19, 0.27), (0.055, 1174.66, 0.19, 0.18)]))
save_audio("upgrade", 0.61, motif([(0, 392, 0.29, 0.22), (0.085, 587.33, 0.35, 0.21), (0.16, 783.99, 0.42, 0.23)]))
save_audio("countdown", 0.25, motif([(0, 523.25, 0.24, 0.30)]))
save_audio("victory", 0.98, motif([(0, 523.25, 0.41, 0.20), (0.10, 659.25, 0.46, 0.20), (0.20, 783.99, 0.49, 0.20), (0.30, 1046.50, 0.64, 0.26)]))
save_audio("click", 0.15, motif([(0, 435, 0.14, 0.20)]))
save_audio("dash", 0.43, motif([(0, 230, 0.20, 0.24), (0.025, 460, 0.29, 0.19), (0.065, 650, 0.36, 0.11)]))
rng = random.Random(1904)
phases = [rng.random() * math.tau for _ in range(6)]


def ambience(t):
    swell = 0.65 + 0.22 * math.sin(math.tau * t / 12)
    return swell * sum(
        0.034 * math.sin(math.tau * cycles * t / 12 + phases[i]) / (1 + i * 0.31)
        for i, cycles in enumerate((330, 440, 495, 660, 880, 991))
    )


save_audio("ambience", 12, ambience)
