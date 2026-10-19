#!/usr/bin/env python3
"""Render the EclipseOS brand assets from branding/tokens.json.

The renderer is deliberately dependency-free (Python standard library only).
It draws the "occluded sun with corona" motif used by the wallpaper, the GRUB
boot menu, the Plymouth splash and the application icon, and writes ordinary
PNG files plus one SVG.

Why not commit PNGs: every asset is generated from the tokens file at build
time, so the palette and geometry have a single source of truth and the
repository stays free of binary artwork. `scripts/build.sh` runs this script
and copies the output into the live-build tree; the PNGs are gitignored.

Rendering is deterministic: a fixed star-field seed and no timestamp chunks.
The same tokens file and Python version produce byte-identical PNGs.

Usage:
    python3 branding/render.py --out branding/assets
"""

from __future__ import annotations

import argparse
import json
import math
import random
import struct
import sys
import zlib
from pathlib import Path

WALLPAPER_SIZE = (1920, 1080)
GRUB_SIZE = (1024, 768)
MARK_SIZE = 1024
MARK_SMALL_SIZE = 256

STAR_SEED = 20261001


# ---------------------------------------------------------------------------
# Colour and PNG helpers
# ---------------------------------------------------------------------------

def parse_hex(value: str) -> tuple[int, int, int]:
    value = value.strip()
    if not value.startswith("#") or len(value) != 7:
        raise ValueError(f"not a #rrggbb colour: {value!r}")
    return (int(value[1:3], 16), int(value[3:5], 16), int(value[5:7], 16))


def clamp(value: float, low: float = 0.0, high: float = 255.0) -> float:
    return low if value < low else high if value > high else value


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[float, float, float]:
    t = clamp(t, 0.0, 1.0)
    return (
        a[0] + (b[0] - a[0]) * t,
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
    )


def smoothstep(edge0: float, edge1: float, x: float) -> float:
    if edge1 == edge0:
        return 1.0 if x >= edge1 else 0.0
    t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


class Canvas:
    """A small RGB or RGBA raster with source-over and additive blending."""

    def __init__(self, width: int, height: int, channels: int, fill=(0, 0, 0, 0)) -> None:
        if channels not in (3, 4):
            raise ValueError("channels must be 3 or 4")
        self.width = width
        self.height = height
        self.channels = channels
        self.data = bytearray(bytes(fill[:channels]) * (width * height))

    # -- pixel access ------------------------------------------------------

    def _offset(self, x: int, y: int) -> int:
        return (y * self.width + x) * self.channels

    def alpha_at(self, x: int, y: int) -> int:
        """Alpha byte at a pixel (255 for opaque RGB canvases, 0 off-canvas)."""
        if x < 0 or y < 0 or x >= self.width or y >= self.height:
            return 0
        if self.channels == 3:
            return 255
        return self.data[self._offset(x, y) + 3]

    def blend(self, x: int, y: int, color: tuple[int, int, int], alpha: float) -> None:
        if alpha <= 0.0 or x < 0 or y < 0 or x >= self.width or y >= self.height:
            return
        alpha = min(alpha, 1.0)
        offset = self._offset(x, y)
        data = self.data
        channels = self.channels
        if channels == 3:
            data[offset] = int(clamp(data[offset] + (color[0] - data[offset]) * alpha))
            data[offset + 1] = int(clamp(data[offset + 1] + (color[1] - data[offset + 1]) * alpha))
            data[offset + 2] = int(clamp(data[offset + 2] + (color[2] - data[offset + 2]) * alpha))
        else:
            src_a = alpha
            dst_a = data[offset + 3] / 255.0
            out_a = src_a + dst_a * (1.0 - src_a)
            if out_a <= 0.0:
                return
            for index in range(3):
                src = color[index] * src_a
                dst = data[offset + index] * dst_a * (1.0 - src_a)
                data[offset + index] = int(clamp((src + dst) / out_a))
            data[offset + 3] = int(clamp(out_a * 255.0))

    def add(self, x: int, y: int, color: tuple[int, int, int], amount: float) -> None:
        if amount <= 0.0 or x < 0 or y < 0 or x >= self.width or y >= self.height:
            return
        offset = self._offset(x, y)
        data = self.data
        for index in range(3):
            data[offset + index] = int(clamp(data[offset + index] + color[index] * amount))
        if self.channels == 4:
            # Additive light on a transparent canvas must also raise alpha,
            # otherwise the glow is invisible when the icon is composited.
            data[offset + 3] = int(clamp(data[offset + 3] + amount * 255.0))

    # -- PNG output --------------------------------------------------------

    def write_png(self, path: Path) -> None:
        stride = self.width * self.channels
        raw = bytearray()
        for row in range(self.height):
            raw.append(0)  # filter type: none
            start = row * stride
            raw.extend(self.data[start:start + stride])

        color_type = 2 if self.channels == 3 else 6
        header = struct.pack(">IIBBBBB", self.width, self.height, 8, color_type, 0, 0, 0)
        payload = (
            b"\x89PNG\r\n\x1a\n"
            + png_chunk(b"IHDR", header)
            + png_chunk(b"IDAT", zlib.compress(bytes(raw), 6))
            + png_chunk(b"IEND", b"")
        )
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(payload)


# ---------------------------------------------------------------------------
# Backgrounds
# ---------------------------------------------------------------------------

Glow = tuple[float, float, float, tuple[int, int, int], float]


def render_background(
    width: int,
    height: int,
    top: tuple[int, int, int],
    bottom: tuple[int, int, int],
    glows: list[Glow],
    vignette: float = 0.0,
) -> Canvas:
    """Smooth gradient + radial glows, computed small and upscaled.

    Radial glows are cheap and cover large areas; rendering them at 1/8 scale
    and interpolating avoids two million Python-level pow() calls per image
    while staying perfectly smooth for this kind of soft light.
    """
    low_width = max(2, width // 8)
    low_height = max(2, height // 8)
    aspect = width / height
    low = bytearray(low_width * low_height * 3)

    for y in range(low_height):
        v = y / (low_height - 1) if low_height > 1 else 0.0
        base = mix(top, bottom, v)
        for x in range(low_width):
            u = x / (low_width - 1) if low_width > 1 else 0.0
            red, green, blue = base
            for cx, cy, radius, color, strength in glows:
                dx = (u - cx) * aspect
                dy = v - cy
                distance = math.hypot(dx, dy)
                falloff = 1.0 - distance / radius
                if falloff > 0.0:
                    amount = falloff * falloff * strength
                    red += color[0] * amount
                    green += color[1] * amount
                    blue += color[2] * amount
            if vignette > 0.0:
                # Darken the corners slightly so the centre stays luminous.
                dx = (u - 0.5) * 2.0
                dy = (v - 0.5) * 2.0
                shade = 1.0 - vignette * min(1.0, math.hypot(dx, dy) / 1.45) ** 2
                red *= shade
                green *= shade
                blue *= shade
            offset = (y * low_width + x) * 3
            low[offset] = int(clamp(red))
            low[offset + 1] = int(clamp(green))
            low[offset + 2] = int(clamp(blue))

    canvas = Canvas(width, height, 3)
    data = canvas.data
    # Precompute horizontal interpolation coefficients once.
    x0s = [0] * width
    x1s = [0] * width
    txs = [0.0] * width
    for x in range(width):
        fx = (x / (width - 1)) * (low_width - 1) if width > 1 else 0.0
        x0 = int(fx)
        x1 = min(x0 + 1, low_width - 1)
        x0s[x] = x0 * 3
        x1s[x] = x1 * 3
        txs[x] = fx - x0

    for y in range(height):
        fy = (y / (height - 1)) * (low_height - 1) if height > 1 else 0.0
        y0 = int(fy)
        y1 = min(y0 + 1, low_height - 1)
        ty = fy - y0
        row0 = y0 * low_width * 3
        row1 = y1 * low_width * 3
        out = y * width * 3
        for x in range(width):
            tx = txs[x]
            i0 = x0s[x]
            i1 = x1s[x]
            for channel in range(3):
                top_value = low[row0 + i0 + channel] * (1.0 - tx) + low[row0 + i1 + channel] * tx
                bottom_value = low[row1 + i0 + channel] * (1.0 - tx) + low[row1 + i1 + channel] * tx
                data[out] = int(clamp(top_value * (1.0 - ty) + bottom_value * ty))
                out += 1
    return canvas


def draw_stars(canvas: Canvas, count: int, seed: int, avoid: tuple[float, float, float] | None = None) -> None:
    rng = random.Random(seed)
    for _ in range(count):
        x = rng.randrange(0, canvas.width)
        y = rng.randrange(0, int(canvas.height * 0.85))
        if avoid is not None:
            cx, cy, radius = avoid
            if math.hypot(x - cx, y - cy) < radius:
                continue
        brightness = rng.uniform(0.12, 0.55)
        size = 1 if rng.random() < 0.85 else 2
        colour = (255, 245, 230) if rng.random() < 0.35 else (200, 190, 255)
        for dy in range(size):
            for dx in range(size):
                canvas.add(x + dx, y + dy, colour, brightness * (0.55 if size == 2 else 1.0))


# ---------------------------------------------------------------------------
# The eclipse motif
# ---------------------------------------------------------------------------

def draw_arc(
    canvas: Canvas,
    cx: float,
    cy: float,
    inner: float,
    outer: float,
    start: float,
    end: float,
    color: tuple[int, int, int],
    opacity: float,
    feather: float = 0.35,
) -> None:
    """Additive ring segment between two angles (radians, y-down)."""
    import math as _math

    outer_ceil = int(outer) + 2
    for y in range(max(0, int(cy - outer_ceil)), min(canvas.height, int(cy + outer_ceil) + 1)):
        dy = y - cy
        for x in range(max(0, int(cx - outer_ceil)), min(canvas.width, int(cx + outer_ceil) + 1)):
            dx = x - cx
            distance = _math.hypot(dx, dy)
            if distance < inner or distance > outer:
                continue
            angle = _math.atan2(dy, dx)
            if angle < start or angle > end:
                continue
            # Fade at both angular ends and at the outer edge.
            angular = min(angle - start, end - angle)
            angular_fade = smoothstep(0.0, feather, angular)
            radial = 1.0 - (distance - inner) / max(1.0, outer - inner)
            canvas.add(x, y, color, opacity * angular_fade * (radial ** 1.4))


def draw_disc(canvas: Canvas, cx: float, cy: float, radius: float, color: tuple[int, int, int]) -> None:
    """Anti-aliased filled circle (source-over, opaque)."""
    for y in range(max(0, int(cy - radius) - 2), min(canvas.height, int(cy + radius) + 3)):
        dy = y - cy
        for x in range(max(0, int(cx - radius) - 2), min(canvas.width, int(cx + radius) + 3)):
            distance = math.hypot(x - cx, dy)
            coverage = clamp(radius + 0.5 - distance, 0.0, 1.0)
            if coverage > 0.0:
                canvas.blend(x, y, color, coverage)


def draw_sparkle(canvas: Canvas, cx: float, cy: float, size: float, color: tuple[int, int, int]) -> None:
    """Four-point star: a bright core with two thin additive rays."""
    core = max(1.0, size * 0.12)
    for y in range(max(0, int(cy - size) - 1), min(canvas.height, int(cy + size) + 2)):
        dy = y - cy
        for x in range(max(0, int(cx - size) - 1), min(canvas.width, int(cx + size) + 2)):
            dx = x - cx
            distance = math.hypot(dx, dy)
            if distance <= core:
                canvas.add(x, y, color, 0.95)
                continue
            horizontal = max(0.0, 1.0 - abs(dx) / size) * max(0.0, 1.0 - abs(dy) / max(1.0, size * 0.06))
            vertical = max(0.0, 1.0 - abs(dy) / size) * max(0.0, 1.0 - abs(dx) / max(1.0, size * 0.06))
            amount = (horizontal + vertical) * 0.55
            if amount > 0.0:
                canvas.add(x, y, color, min(amount, 0.9))


def draw_eclipse(
    canvas: Canvas,
    cx: float,
    cy: float,
    radius: float,
    void_color: tuple[int, int, int],
    corona_color: tuple[int, int, int],
    amber_color: tuple[int, int, int],
    violet_color: tuple[int, int, int],
    with_flare: bool = True,
) -> None:
    # Corona arc: from the lower right, over the top, to the upper left.
    start = math.radians(-172.0)
    end = math.radians(-8.0)
    draw_arc(canvas, cx, cy, radius + 1.5, radius + max(10.0, radius * 0.075), start, end, amber_color, 0.75, 0.42)
    draw_arc(canvas, cx, cy, radius + 1.0, radius + max(16.0, radius * 0.115), start, end, corona_color, 0.35, 0.50)

    # A faint, complete rim makes the disc read as a sphere rather than a hole.
    draw_arc(canvas, cx, cy, radius - 0.5, radius + 2.0, -math.pi, math.pi, violet_color, 0.28, 0.0)

    # The occluding body.
    draw_disc(canvas, cx, cy, radius, void_color)

    # Earthshine: a very faint violet crescent on the lower left edge.
    draw_arc(canvas, cx, cy, radius * 0.90, radius, math.radians(15.0), math.radians(165.0), violet_color, 0.10, 0.6)

    if with_flare:
        angle = math.radians(-38.0)
        distance = radius + max(12.0, radius * 0.10)
        draw_sparkle(
            canvas,
            cx + math.cos(angle) * distance,
            cy + math.sin(angle) * distance,
            max(6.0, radius * 0.11),
            corona_color,
        )


# ---------------------------------------------------------------------------
# Compositions
# ---------------------------------------------------------------------------

def render_wallpaper(colors: dict, out: Path) -> None:
    width, height = WALLPAPER_SIZE
    canvas = render_background(
        width,
        height,
        parse_hex(colors["night"]),
        parse_hex(colors["void"]),
        [
            (0.50, 0.40, 0.62, parse_hex(colors["violet"]), 0.30),
            (0.50, 0.42, 0.30, parse_hex(colors["violetSoft"]), 0.10),
            (0.80, 0.78, 0.45, parse_hex(colors["violetDeep"]), 0.10),
            (0.18, 0.88, 0.35, parse_hex(colors["amber"]), 0.035),
        ],
        vignette=0.35,
    )

    cx = width * 0.5
    cy = height * 0.44
    radius = height * 0.27

    draw_stars(canvas, 170, STAR_SEED, avoid=(cx, cy, radius * 1.25))

    # Two very faint orbit arcs give the composition depth without text.
    draw_arc(canvas, cx, cy, radius * 1.48, radius * 1.49, math.radians(-35.0), math.radians(205.0), parse_hex(colors["violetSoft"]), 0.045, 0.9)
    draw_arc(canvas, cx, cy, radius * 1.72, radius * 1.725, math.radians(80.0), math.radians(260.0), parse_hex(colors["amber"]), 0.025, 0.9)

    draw_eclipse(
        canvas, cx, cy, radius,
        parse_hex(colors["void"]),
        parse_hex(colors["corona"]),
        parse_hex(colors["amber"]),
        parse_hex(colors["violetSoft"]),
    )
    canvas.write_png(out / "eclipseos-wallpaper-1920x1080.png")


def render_grub_splash(colors: dict, out: Path) -> None:
    width, height = GRUB_SIZE
    canvas = render_background(
        width,
        height,
        parse_hex(colors["night"]),
        parse_hex(colors["void"]),
        [
            (0.80, 0.30, 0.55, parse_hex(colors["violet"]), 0.28),
            (0.79, 0.28, 0.25, parse_hex(colors["violetSoft"]), 0.10),
            (0.15, 0.95, 0.40, parse_hex(colors["violetDeep"]), 0.08),
        ],
        vignette=0.30,
    )

    cx = width * 0.79
    cy = height * 0.29
    radius = height * 0.155
    draw_stars(canvas, 90, STAR_SEED + 7, avoid=(cx, cy, radius * 1.3))

    draw_eclipse(
        canvas, cx, cy, radius,
        parse_hex(colors["void"]),
        parse_hex(colors["corona"]),
        parse_hex(colors["amber"]),
        parse_hex(colors["violetSoft"]),
        with_flare=False,
    )

    # Keep the bottom third (attribution + timeout bar) quiet and dark.
    for y in range(int(height * 0.80), height):
        t = clamp((y - height * 0.80) / (height * 0.20), 0.0, 1.0)
        for x in range(width):
            canvas.blend(x, y, parse_hex(colors["void"]), 0.55 * (t ** 1.6))

    canvas.write_png(out / "eclipseos-grub-splash-1024x768.png")


def render_plymouth_splash(colors: dict, out: Path) -> None:
    width, height = WALLPAPER_SIZE
    canvas = render_background(
        width,
        height,
        parse_hex(colors["night"]),
        parse_hex(colors["void"]),
        [
            (0.50, 0.42, 0.48, parse_hex(colors["violet"]), 0.26),
            (0.50, 0.42, 0.22, parse_hex(colors["violetSoft"]), 0.10),
            (0.85, 0.15, 0.35, parse_hex(colors["violetDeep"]), 0.06),
        ],
        vignette=0.45,
    )
    draw_stars(canvas, 140, STAR_SEED + 13)
    canvas.write_png(out / "eclipseos-plymouth-splash-1920x1080.png")


def render_plymouth_progress(colors: dict, out: Path) -> None:
    """Solid images used by the Plymouth script theme's progress bar.

    Plymouth's script API has no drawing primitives in the stable plugin, so
    the track and fill are ordinary PNGs. The script scales the fill image at
    runtime; a 360x4 source keeps that operation cheap.
    """
    width, height = 360, 4
    Canvas(width, height, 4, fill=parse_hex(colors["void"]) + (255,)).write_png(
        out / "eclipseos-progress-track.png"
    )
    Canvas(width, height, 4, fill=parse_hex(colors["amber"]) + (255,)).write_png(
        out / "eclipseos-progress-fill.png"
    )


def render_mark(colors: dict, out: Path) -> Canvas:
    size = MARK_SIZE
    canvas = Canvas(size, size, 4)
    centre = size / 2.0
    radius = size * 0.295

    draw_eclipse(
        canvas, centre, centre, radius,
        parse_hex(colors["void"]),
        parse_hex(colors["corona"]),
        parse_hex(colors["amber"]),
        parse_hex(colors["violetSoft"]),
    )

    # Soft violet halo (alpha, not additive, so the icon keeps clean edges on
    # both light and dark backgrounds). Drawn after the eclipse and only on
    # still-transparent pixels: painting it first would leave a violet value
    # under the additive corona and wash the amber rim out to white.
    max_distance = size * 0.5
    halo_inner = radius * 1.15
    for y in range(size):
        dy = y + 0.5 - centre
        for x in range(size):
            dx = x + 0.5 - centre
            distance = math.hypot(dx, dy)
            if distance < halo_inner:
                continue
            if canvas.alpha_at(x, y) != 0:
                continue
            t = 1.0 - distance / max_distance
            if t > 0.0:
                canvas.blend(x, y, parse_hex(colors["violet"]), 0.22 * (t ** 2.2))

    canvas.write_png(out / "eclipseos-mark.png")

    small = downscale(canvas, MARK_SMALL_SIZE)
    small.write_png(out / "eclipseos-mark-256.png")
    return canvas


def downscale(source: Canvas, target_size: int) -> Canvas:
    """Premultiplied box filter, only for square RGBA sources."""
    factor = source.width // target_size
    if factor * target_size != source.width or source.height != source.width:
        raise ValueError("downscale expects a square source divisible by target size")
    target = Canvas(target_size, target_size, 4)
    data = target.data
    for y in range(target_size):
        for x in range(target_size):
            alpha_sum = 0.0
            red_sum = 0.0
            green_sum = 0.0
            blue_sum = 0.0
            for sy in range(y * factor, (y + 1) * factor):
                base = sy * source.width * 4
                for sx in range(x * factor, (x + 1) * factor):
                    offset = base + sx * 4
                    alpha = source.data[offset + 3] / 255.0
                    alpha_sum += alpha
                    red_sum += source.data[offset] * alpha
                    green_sum += source.data[offset + 1] * alpha
                    blue_sum += source.data[offset + 2] * alpha
            samples = factor * factor
            alpha = alpha_sum / samples
            offset = (y * target_size + x) * 4
            if alpha > 0.0:
                data[offset] = int(clamp(red_sum / samples / alpha))
                data[offset + 1] = int(clamp(green_sum / samples / alpha))
                data[offset + 2] = int(clamp(blue_sum / samples / alpha))
                data[offset + 3] = int(clamp(alpha * 255.0))
    return target


def render_svg(colors: dict, out: Path) -> None:
    void = colors["void"]
    violet = colors["violet"]
    violet_deep = colors["violetDeep"]
    violet_soft = colors["violetSoft"]
    corona = colors["corona"]
    amber = colors["amber"]
    svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<!-- EclipseOS logo. Original artwork, GPL-3.0-or-later.
     Generated by branding/render.py from branding/tokens.json. -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024" role="img" aria-label="EclipseOS">
  <defs>
    <radialGradient id="halo" cx="50%" cy="50%" r="50%">
      <stop offset="58%" stop-color="{violet}" stop-opacity="0.55"/>
      <stop offset="80%" stop-color="{violet_deep}" stop-opacity="0.22"/>
      <stop offset="100%" stop-color="{void}" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="corona" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="{corona}"/>
      <stop offset="55%" stop-color="{amber}"/>
      <stop offset="100%" stop-color="{violet}" stop-opacity="0.15"/>
    </linearGradient>
  </defs>
  <circle cx="512" cy="512" r="500" fill="url(#halo)"/>
  <circle cx="512" cy="512" r="312" fill="none" stroke="{violet_soft}" stroke-opacity="0.30" stroke-width="3"/>
  <circle cx="512" cy="512" r="314" fill="none" stroke="url(#corona)" stroke-width="24"
          stroke-linecap="round" stroke-dasharray="1180 792" transform="rotate(-58 512 512)" opacity="0.95"/>
  <circle cx="512" cy="512" r="300" fill="{void}" stroke="{violet}" stroke-opacity="0.35" stroke-width="2"/>
  <circle cx="712" cy="352" r="9" fill="{corona}"/>
  <path d="M712 312 L716 348 L752 352 L716 356 L712 392 L708 356 L672 352 L708 348 Z" fill="{corona}" opacity="0.55"/>
</svg>
"""
    (out / "eclipseos-logo.svg").write_text(svg, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, help="output directory")
    parser.add_argument(
        "--tokens",
        default=str(Path(__file__).resolve().parent / "tokens.json"),
        help="brand tokens file (default: branding/tokens.json)",
    )
    args = parser.parse_args()

    tokens_path = Path(args.tokens).resolve()
    try:
        tokens = json.loads(tokens_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"error: cannot read {tokens_path}: {error}", file=sys.stderr)
        return 1

    colors = tokens.get("colors")
    if not isinstance(colors, dict):
        print("error: tokens file has no colours object", file=sys.stderr)
        return 1

    required = (
        "void", "night", "violet", "violetDeep", "violetSoft",
        "amber", "corona",
    )
    missing = [name for name in required if name not in colors]
    if missing:
        print(f"error: missing brand colours: {', '.join(missing)}", file=sys.stderr)
        return 1

    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    print(f"Rendering EclipseOS assets with tokens {tokens_path}")

    render_wallpaper(colors, out)
    render_grub_splash(colors, out)
    render_plymouth_splash(colors, out)
    render_plymouth_progress(colors, out)
    render_mark(colors, out)
    render_svg(colors, out)

    for name in sorted(path.name for path in out.iterdir()):
        path = out / name
        print(f"  {name:<44} {path.stat().st_size:>10} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
