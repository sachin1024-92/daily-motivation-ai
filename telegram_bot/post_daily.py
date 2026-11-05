"""Post today's motivation quote as an image to a Telegram channel.

Quotes are read from lib/models/quote.dart so the app and the channel share
one list. The quote rotates by day of year.

Environment:
  TELEGRAM_BOT_TOKEN  bot token from @BotFather (not needed with --dry-run)
  TELEGRAM_CHAT_ID    target channel, e.g. @dailymotivationai or -100123...
  CHANNEL_HANDLE      optional footer text, defaults to TELEGRAM_CHAT_ID
  PEXELS_API_KEY      optional; picks nature photos from Pexels. Without it a
                      Lorem Picsum photo is used, and if no photo can be
                      downloaded a drawn landscape is used instead.

Usage:
  python telegram_bot/post_daily.py --dry-run out.png
  python telegram_bot/post_daily.py
"""

import argparse
import datetime as dt
import io
import math
import random
import os
import re
import sys
import textwrap
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

REPO_ROOT = Path(__file__).resolve().parent.parent
QUOTES_FILE = REPO_ROOT / "lib" / "models" / "quote.dart"
SIZE = 1080
FONT_DIRS = [
    Path("/usr/share/fonts/truetype/dejavu"),
    Path("/usr/share/fonts/dejavu"),
]
# Pexels searches, one picked per day.
NATURE_QUERIES = [
    "mountain landscape", "forest sunlight", "ocean sunrise", "misty lake",
    "waterfall", "snowy mountains", "green valley", "desert dunes",
    "autumn forest", "starry night sky", "beach sunset", "meadow flowers",
]
# Sky colours (top, horizon) for the drawn landscape fallback.
PALETTES = [
    ((37, 99, 235), (253, 186, 116)),   # morning blue to peach
    ((76, 29, 149), (251, 146, 60)),    # violet dusk
    ((14, 116, 144), (167, 243, 208)),  # teal to mint
    ((30, 58, 138), (244, 114, 182)),   # navy to pink sunset
    ((21, 94, 117), (254, 240, 138)),   # sea to golden hour
]

QUOTE_RE = re.compile(
    r'Quote\(\s*text:\s*"((?:[^"\\]|\\.)*)"\s*,\s*author:\s*"((?:[^"\\]|\\.)*)"\s*\)'
)


def load_quotes(path=QUOTES_FILE):
    quotes = [
        (text.replace('\\"', '"'), author.replace('\\"', '"'))
        for text, author in QUOTE_RE.findall(path.read_text(encoding="utf-8"))
    ]
    if not quotes:
        raise SystemExit(f"No quotes found in {path}")
    return quotes


def load_font(name, size):
    for font_dir in FONT_DIRS:
        candidate = font_dir / name
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default(size)


def gradient(top, bottom, size=SIZE):
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        colour = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        draw.line([(0, y), (size, y)], fill=colour)
    return img


def drawn_landscape(palette, seed):
    """Sky, sun and layered mountain ridges, used when no photo is available."""
    rng = random.Random(seed)
    sky_top, horizon = palette
    img = gradient(sky_top, horizon)
    draw = ImageDraw.Draw(img)

    sun_x, sun_y, sun_r = rng.randint(220, 860), rng.randint(150, 240), rng.randint(60, 95)
    draw.ellipse([sun_x - sun_r, sun_y - sun_r, sun_x + sun_r, sun_y + sun_r], fill=(255, 236, 200))

    ridges = 4
    for i in range(ridges):
        depth = (i + 1) / ridges
        base = 560 + i * 120
        shade = tuple(round(h * (1 - depth) * 0.55 + t * (0.9 - 0.5 * depth) * depth) for t, h in zip(sky_top, horizon))
        phases = [rng.uniform(0, math.tau) for _ in range(3)]
        points = [(0, SIZE)]
        for x in range(0, SIZE + 1, 8):
            y = base
            for k, (freq, amp) in enumerate([(1.5, 70), (3.7, 30), (9.1, 10)]):
                y -= amp * (1 - 0.3 * depth) * math.sin(x / SIZE * freq * math.tau / 2 + phases[k])
            points.append((x, y))
        points.append((SIZE, SIZE))
        draw.polygon(points, fill=shade)
    return img


def fetch_image(url, headers=None):
    resp = requests.get(url, headers=headers, timeout=30)
    resp.raise_for_status()
    return Image.open(io.BytesIO(resp.content)).convert("RGB")


def pexels_photo(api_key, day):
    query = NATURE_QUERIES[day % len(NATURE_QUERIES)]
    resp = requests.get(
        "https://api.pexels.com/v1/search",
        params={"query": query, "orientation": "square", "per_page": 40},
        headers={"Authorization": api_key},
        timeout=30,
    )
    resp.raise_for_status()
    photos = resp.json().get("photos", [])
    if not photos:
        raise ValueError(f"no Pexels results for {query!r}")
    photo = photos[(day // len(NATURE_QUERIES)) % len(photos)]
    img = fetch_image(photo["src"]["large2x"])
    return img, f"Photo: {photo['photographer']} / Pexels"


def picsum_photo(today):
    img = fetch_image(f"https://picsum.photos/seed/dmai-{today.isoformat()}/{SIZE}/{SIZE}")
    return img, None


def photo_background(today, day):
    """A nature photo for the day, or None if none could be downloaded."""
    sources = []
    if os.environ.get("PEXELS_API_KEY"):
        sources.append(("Pexels", lambda: pexels_photo(os.environ["PEXELS_API_KEY"], day)))
    sources.append(("Lorem Picsum", lambda: picsum_photo(today)))
    for name, fetch in sources:
        try:
            return fetch()
        except (requests.RequestException, OSError, ValueError, KeyError) as exc:
            print(f"{name} photo unavailable ({type(exc).__name__}), trying next source")
    return None


def soften(img, blur):
    """Square-crop, blur and darken a background so white text reads on it."""
    img = ImageOps.fit(img, (SIZE, SIZE), Image.LANCZOS)
    if blur:
        img = img.filter(ImageFilter.GaussianBlur(blur))
    shade = gradient((0, 0, 0), (0, 0, 0)).convert("L")
    mask = Image.linear_gradient("L").resize((SIZE, SIZE)).point(lambda v: 55 + v * 85 // 255)
    return Image.composite(shade.convert("RGB"), img, mask)


def fit_quote(draw, text, max_width, max_height):
    """Largest font size whose wrapped text fits the box."""
    for size in range(72, 27, -4):
        font = load_font("DejaVuSerif-Bold.ttf", size)
        chars = max(10, int(max_width / (size * 0.55)))
        lines = textwrap.wrap(f"“{text}”", width=chars)
        box = draw.multiline_textbbox((0, 0), "\n".join(lines), font=font, spacing=size // 3)
        if box[2] - box[0] <= max_width and box[3] - box[1] <= max_height:
            return font, lines
    return font, lines


def render_card(text, author, background, footer):
    img = background.copy()
    text_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(text_layer)
    margin = 110

    font, lines = fit_quote(draw, text, SIZE - 2 * margin, SIZE * 0.55)
    body = "\n".join(lines)
    spacing = font.size // 3
    box = draw.multiline_textbbox((0, 0), body, font=font, spacing=spacing, align="center")
    body_h = box[3] - box[1]
    top = (SIZE - body_h) // 2 - 60
    draw.multiline_text(
        (SIZE // 2, top), body, font=font, fill="white",
        spacing=spacing, align="center", anchor="ma",
    )

    author_font = load_font("DejaVuSans.ttf", 40)
    draw.text(
        (SIZE // 2, top + body_h + 70), f"— {author}",
        font=author_font, fill=(255, 255, 255, 220), anchor="ma",
    )

    if footer:
        footer_font = load_font("DejaVuSans-Bold.ttf", 30)
        draw.text((SIZE // 2, SIZE - 70), footer, font=footer_font, fill="white", anchor="ms")

    # Soft drop shadow: a blurred black copy of the text under the text.
    alpha = text_layer.getchannel("A")
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.filter(ImageFilter.GaussianBlur(6)).point(lambda v: v * 3 // 4))
    img = img.convert("RGBA")
    img.alpha_composite(shadow, (3, 4))
    img.alpha_composite(text_layer)
    return img.convert("RGB")


def todays_post(today=None, use_photos=True):
    today = today or dt.date.today()
    quotes = load_quotes()
    day = today.timetuple().tm_yday
    text, author = quotes[day % len(quotes)]

    photo = photo_background(today, day) if use_photos else None
    if photo:
        image, credit = photo
        background = soften(image, blur=10)
    else:
        credit = None
        background = soften(drawn_landscape(PALETTES[day % len(PALETTES)], seed=today.toordinal()), blur=3)
    return text, author, background, credit


def send_photo(token, chat_id, png_bytes, caption):
    try:
        resp = requests.post(
            f"https://api.telegram.org/bot{token}/sendPhoto",
            data={"chat_id": chat_id, "caption": caption},
            files={"photo": ("quote.png", png_bytes, "image/png")},
            timeout=30,
        )
    except requests.RequestException as exc:
        # The request URL contains the token, so report only the error type.
        raise SystemExit(f"Could not reach Telegram: {type(exc).__name__}") from None
    payload = resp.json() if resp.headers.get("content-type", "").startswith("application/json") else {}
    if not payload.get("ok"):
        raise SystemExit(f"Telegram API error ({resp.status_code}): {payload.get('description', resp.text)}")
    return payload["result"]["message_id"]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", metavar="PNG", help="write the image here instead of posting")
    parser.add_argument("--date", help="YYYY-MM-DD, defaults to today")
    parser.add_argument("--no-photo", action="store_true", help="skip photo download, use the drawn landscape")
    args = parser.parse_args(argv)

    chat_id = os.environ.get("TELEGRAM_CHAT_ID", "")
    footer = os.environ.get("CHANNEL_HANDLE") or (chat_id if chat_id.startswith("@") else "Daily Motivation AI")
    today = dt.date.fromisoformat(args.date) if args.date else None
    text, author, background, credit = todays_post(today, use_photos=not args.no_photo)
    img = render_card(text, author, background, footer)

    if args.dry_run:
        img.save(args.dry_run)
        print(f"Wrote {args.dry_run}: “{text}” — {author}")
        return

    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    if not token or not chat_id:
        raise SystemExit("Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID (or use --dry-run).")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    caption = f"☀️ Today's motivation\n\n“{text}” — {author}"
    if credit:
        caption += f"\n\n📷 {credit}"
    message_id = send_photo(token, chat_id, buf.getvalue(), caption)
    print(f"Posted message {message_id} to {chat_id}")


if __name__ == "__main__":
    sys.exit(main())
