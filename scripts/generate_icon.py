#!/usr/bin/env python3
"""
Bolo icon generator
─────────────────────
Renders a simple placeholder app icon + splash source PNG using PIL.
The icon is a solid saffron rounded-square background with a bold white
"B" centered on it.

Idempotent: writes to app/assets/branding/icon.png and
app/assets/branding/splash.png every run.

Run:  python3 scripts/generate_icon.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).parent.parent
OUT_DIR   = REPO_ROOT / "app" / "assets" / "branding"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Design tokens copied from lib/core/theme/bolo_colors.dart so the icon
# matches the app. Update in one place if the palette shifts.
SAFFRON = (245, 93, 0, 255)
TURMERIC = (255, 183, 0, 255)
WHITE   = (255, 255, 255, 255)
PAPER   = (255, 244, 230, 255)

def load_font(size: int) -> ImageFont.ImageFont:
    # Try Nunito (matches app typography). Fall back to system-heavy.
    for path in [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ]:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()

def make_icon(size: int, out: Path) -> None:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Rounded-square background with a subtle bottom-heavy gradient feel:
    # solid saffron with a soft turmeric bloom at the top.
    radius = int(size * 0.22)
    draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=radius,
        fill=SAFFRON,
    )
    # Turmeric bloom — a soft ellipse at ~30% down for a warm highlight.
    bloom = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(bloom)
    bloom_r = int(size * 0.55)
    cx, cy = size // 2, int(size * 0.32)
    bdraw.ellipse(
        [(cx - bloom_r, cy - bloom_r), (cx + bloom_r, cy + bloom_r)],
        fill=(*TURMERIC[:3], 90),
    )
    bloom = bloom.filter_gaussian_blur(size // 12) if hasattr(bloom, "filter_gaussian_blur") else bloom
    img = Image.alpha_composite(img, bloom)

    # Big white "B" in the center.
    draw = ImageDraw.Draw(img)
    font_size = int(size * 0.62)
    font = load_font(font_size)
    text = "B"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) // 2 - bbox[0]
    ty = (size - th) // 2 - bbox[1] - int(size * 0.03)
    draw.text((tx, ty), text, font=font, fill=WHITE)

    img.save(out, "PNG")
    print(f"  wrote {out} ({size}x{size})")

def make_splash(width: int, out: Path) -> None:
    # Splash is a wide-ish paper-coloured canvas with the same icon
    # centered — flutter_native_splash will crop/scale as needed on each
    # form factor.
    img = Image.new("RGBA", (width, width), PAPER)
    icon_size = int(width * 0.42)
    icon = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    radius = int(icon_size * 0.22)
    draw.rounded_rectangle(
        [(0, 0), (icon_size, icon_size)],
        radius=radius,
        fill=SAFFRON,
    )
    font = load_font(int(icon_size * 0.62))
    bbox = draw.textbbox((0, 0), "B", font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (icon_size - tw) // 2 - bbox[0]
    ty = (icon_size - th) // 2 - bbox[1] - int(icon_size * 0.03)
    draw.text((tx, ty), "B", font=font, fill=WHITE)

    x = (width - icon_size) // 2
    y = (width - icon_size) // 2
    img.paste(icon, (x, y), icon)
    img.save(out, "PNG")
    print(f"  wrote {out} ({width}x{width})")

def make_feature_graphic(out: Path) -> None:
    # Play Store feature graphic: 1024×500 wide banner.
    width, height = 1024, 500
    img = Image.new("RGBA", (width, height), PAPER)
    draw = ImageDraw.Draw(img)

    # Rounded rectangle "hero" saffron block on the left third.
    hero_w = int(width * 0.42)
    draw.rounded_rectangle(
        [(40, 40), (hero_w, height - 40)],
        radius=48,
        fill=SAFFRON,
    )
    # Big "B" inside the hero.
    font_big = load_font(280)
    bbox = draw.textbbox((0, 0), "B", font=font_big)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (hero_w + 40) // 2 - tw // 2 - bbox[0]
    ty = height // 2 - th // 2 - bbox[1] - 10
    draw.text((tx, ty), "B", font=font_big, fill=WHITE)

    # Right-side text block.
    text_x = hero_w + 90
    title_font = load_font(72)
    sub_font   = load_font(32)
    draw.text((text_x, 140), "Bolo", font=title_font, fill=SAFFRON)
    draw.text((text_x, 230), "A speech-play space", font=sub_font, fill=(74, 46, 26, 255))
    draw.text((text_x, 280), "for little ones 2 – 5", font=sub_font, fill=(74, 46, 26, 255))
    # Bottom tag row
    tag_font = load_font(20)
    tags = "300 words · 8 categories · no ads · no accounts"
    draw.text((text_x, 380), tags, font=tag_font, fill=(122, 90, 68, 255))

    img.save(out, "PNG")
    print(f"  wrote {out} ({width}x{height})")

if __name__ == "__main__":
    print("Generating Bolo branding assets…")
    make_icon(1024, OUT_DIR / "icon.png")
    make_splash(1152, OUT_DIR / "splash.png")
    make_feature_graphic(OUT_DIR / "feature_graphic.png")
    print("Done.")
