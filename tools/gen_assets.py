#!/usr/bin/env python3
"""
Generate the Blaze's Shadows brand assets (pack icon + logo banner) procedurally.
Pure Pillow + numpy, no external network resources. Re-runnable and deterministic.
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def lerp(a, b, t):
    return a + (b - a) * t


def diagonal_gradient(w, h, c0, c1):
    """Diagonal gradient from top-left (c0) to bottom-right (c1)."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    t = (xx / (w - 1) + yy / (h - 1)) * 0.5
    img = np.zeros((h, w, 3), np.float32)
    for i in range(3):
        img[..., i] = lerp(c0[i], c1[i], t)
    return img


def radial_glow(w, h, cx, cy, radius, color):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / radius
    g = np.clip(1.0 - d, 0.0, 1.0) ** 2
    glow = np.zeros((h, w, 3), np.float32)
    for i in range(3):
        glow[..., i] = g * color[i]
    return glow


def make_icon(path, size=512):
    # Deep night-blue -> warm blaze-orange diagonal.
    night = (14, 18, 40)
    dusk = (36, 24, 66)
    base = diagonal_gradient(size, size, night, dusk)

    # A warm "blaze" sun low on the horizon.
    sun_x, sun_y = size * 0.32, size * 0.60
    base += radial_glow(size, size, sun_x, sun_y, size * 0.55, (1.0, 0.55, 0.18)) * 220.0
    base += radial_glow(size, size, sun_x, sun_y, size * 0.22, (1.0, 0.80, 0.45)) * 255.0

    # Subtle star dust in the upper sky.
    rng = np.random.default_rng(7)
    for _ in range(180):
        x = int(rng.uniform(0, size))
        y = int(rng.uniform(0, size * 0.55))
        b = rng.uniform(120, 255)
        if 0 <= x < size and 0 <= y < size:
            base[y, x] += (b, b, b)

    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB")
    img = img.filter(ImageFilter.GaussianBlur(0.6))

    # A clean horizon line + reflection hint.
    draw = ImageDraw.Draw(img, "RGBA")
    horizon = int(size * 0.66)
    draw.line([(0, horizon), (size, horizon)], fill=(255, 180, 120, 90), width=3)

    # Monogram "B" mark inside a rounded square.
    m = int(size * 0.14)
    draw.rounded_rectangle([m, m, size - m, size - m], radius=int(size * 0.10),
                           outline=(255, 210, 170, 120), width=4)

    font = ImageFont.truetype(FONT_BOLD, int(size * 0.30))
    text = "B"
    tb = draw.textbbox((0, 0), text, font=font)
    tw, th = tb[2] - tb[0], tb[3] - tb[1]
    tx = (size - tw) / 2 - tb[0]
    ty = (size - th) / 2 - tb[1] - size * 0.02
    # Soft shadow then bright glyph.
    draw.text((tx + 4, ty + 4), text, font=font, fill=(0, 0, 0, 160))
    draw.text((tx, ty), text, font=font, fill=(255, 236, 210, 255))

    img.save(path)
    print("wrote", path, img.size)


def make_logo(path, w=1024, h=320):
    night = (12, 16, 36)
    dusk = (44, 26, 70)
    base = diagonal_gradient(w, h, night, dusk)
    base += radial_glow(w, h, w * 0.12, h * 0.7, h * 1.4, (1.0, 0.5, 0.18)) * 160.0
    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB").convert("RGBA")

    draw = ImageDraw.Draw(img, "RGBA")

    title = "BLAZE'S  SHADOWS"
    # Auto-fit the title font so it never overflows the banner width.
    max_w = w * 0.88
    fs = int(h * 0.34)
    while fs > 8:
        title_font = ImageFont.truetype(FONT_BOLD, fs)
        tb = draw.textbbox((0, 0), title, font=title_font)
        if (tb[2] - tb[0]) <= max_w:
            break
        fs -= 2
    sub_font = ImageFont.truetype(FONT_BOLD, int(h * 0.11))

    tb = draw.textbbox((0, 0), title, font=title_font)
    tw = tb[2] - tb[0]
    tx = (w - tw) / 2 - tb[0]
    ty = h * 0.26

    # Warm gradient fill for the title via a clipped overlay.
    draw.text((tx + 3, ty + 3), title, font=title_font, fill=(0, 0, 0, 170))
    # Two-tone: blaze on the left, cool on the right, faked by two draws + mask.
    draw.text((tx, ty), title, font=title_font, fill=(255, 224, 190, 255))

    sub = "Cinematic  Shaders  -  Iris / OptiFine  -  1.21.x"
    sbb = draw.textbbox((0, 0), sub, font=sub_font)
    sw = sbb[2] - sbb[0]
    draw.text(((w - sw) / 2 - sbb[0], h * 0.70), sub, font=sub_font,
              fill=(210, 200, 230, 230))

    img.convert("RGB").save(path)
    print("wrote", path, img.size)


if __name__ == "__main__":
    make_icon("pack.png", 512)
    make_icon("shaders/textures/icon.png", 128)
    make_logo("shaders/textures/logo.png")
