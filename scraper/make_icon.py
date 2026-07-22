"""Generate launcher icon: a blood tear on a dark gradient background."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "icon" / "icon.png"
OUT.parent.mkdir(parents=True, exist_ok=True)

S = 1024  # source size


def background() -> Image.Image:
    # Radial gradient from warm dark red to near-black.
    img = Image.new("RGB", (S, S), (10, 8, 8))
    px = img.load()
    cx, cy = S // 2, S // 2
    max_r = (cx ** 2 + cy ** 2) ** 0.5
    for y in range(S):
        for x in range(S):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / max_r
            t = max(0, 1 - d * 1.6)
            r = int(20 + 80 * t)
            g = int(8 + 8 * t)
            b = int(8 + 8 * t)
            px[x, y] = (r, g, b)
    return img


def draw_tear(img: Image.Image) -> Image.Image:
    overlay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    # Tear shape: triangle on top, circle on bottom.
    cx = S // 2
    top_y = int(S * 0.18)
    bottom_y = int(S * 0.86)
    radius = int(S * 0.22)

    # Bottom circle (the bulb).
    d.ellipse(
        (cx - radius, bottom_y - 2 * radius, cx + radius, bottom_y),
        fill=(220, 30, 30, 255),
    )
    # Top triangle (the point).
    d.polygon(
        [
            (cx - radius, bottom_y - radius),
            (cx + radius, bottom_y - radius),
            (cx, top_y),
        ],
        fill=(220, 30, 30, 255),
    )

    # Highlight on left side.
    hl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hr = int(radius * 0.55)
    hd.ellipse(
        (cx - hr - 30, bottom_y - 2 * radius + 30, cx - 30, bottom_y - 2 * radius + 30 + hr),
        fill=(255, 200, 200, 180),
    )
    hl = hl.filter(ImageFilter.GaussianBlur(8))

    overlay = Image.alpha_composite(overlay, hl)

    # Soft outer glow.
    glow = overlay.filter(ImageFilter.GaussianBlur(20))
    glow_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    glow_layer.paste(glow)
    base = img.convert("RGBA")
    base = Image.alpha_composite(base, glow_layer)
    base = Image.alpha_composite(base, overlay)
    return base


def main() -> None:
    bg = background()
    final = draw_tear(bg)
    final.convert("RGB").save(OUT, "PNG", optimize=True)

    # Foreground for adaptive icon (transparent bg, just the tear, scaled in 66%).
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fg = draw_tear(Image.new("RGB", (S, S), (0, 0, 0)))
    # Replace black bg with transparent.
    fg_rgba = fg.convert("RGBA")
    px = fg_rgba.load()
    for y in range(S):
        for x in range(S):
            r, g, b, a = px[x, y]
            if r < 20 and g < 20 and b < 20:
                px[x, y] = (0, 0, 0, 0)
    fg_rgba.save(OUT.parent / "icon_foreground.png", "PNG", optimize=True)

    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
