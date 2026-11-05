"""Post today's motivation quote as an image to a Telegram channel.

Quotes are read from lib/models/quote.dart so the app and the channel share
one list. The quote rotates by day of year.

Environment:
  TELEGRAM_BOT_TOKEN  bot token from @BotFather (not needed with --dry-run)
  TELEGRAM_CHAT_ID    target channel, e.g. @dailymotivationai or -100123...
  CHANNEL_HANDLE      optional footer text, defaults to TELEGRAM_CHAT_ID

Usage:
  python telegram_bot/post_daily.py --dry-run out.png
  python telegram_bot/post_daily.py
"""

import argparse
import datetime as dt
import io
import os
import re
import sys
import textwrap
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
QUOTES_FILE = REPO_ROOT / "lib" / "models" / "quote.dart"
SIZE = 1080
FONT_DIRS = [
    Path("/usr/share/fonts/truetype/dejavu"),
    Path("/usr/share/fonts/dejavu"),
]
# Background gradients (top colour, bottom colour), one picked per day.
PALETTES = [
    ((67, 56, 202), (219, 39, 119)),
    ((15, 118, 110), (59, 130, 246)),
    ((234, 88, 12), (190, 24, 93)),
    ((30, 41, 59), (79, 70, 229)),
    ((22, 101, 52), (202, 138, 4)),
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


def gradient(top, bottom):
    img = Image.new("RGB", (SIZE, SIZE))
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        colour = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        draw.line([(0, y), (SIZE, y)], fill=colour)
    return img


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


def render_card(text, author, palette, footer):
    img = gradient(*palette)
    draw = ImageDraw.Draw(img)
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
    return img


def todays_post(today=None):
    today = today or dt.date.today()
    quotes = load_quotes()
    day = today.timetuple().tm_yday
    text, author = quotes[day % len(quotes)]
    palette = PALETTES[day % len(PALETTES)]
    return text, author, palette


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
    args = parser.parse_args(argv)

    chat_id = os.environ.get("TELEGRAM_CHAT_ID", "")
    footer = os.environ.get("CHANNEL_HANDLE") or (chat_id if chat_id.startswith("@") else "Daily Motivation AI")
    today = dt.date.fromisoformat(args.date) if args.date else None
    text, author, palette = todays_post(today)
    img = render_card(text, author, palette, footer)

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
    message_id = send_photo(token, chat_id, buf.getvalue(), caption)
    print(f"Posted message {message_id} to {chat_id}")


if __name__ == "__main__":
    sys.exit(main())
