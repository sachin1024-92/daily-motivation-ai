"""Generates a profile picture (720x720) and cover photo (1640x624) for every Page."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).parent / "images"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

PAGES = [  # key, name, initials, tagline, gradient
    ("comedy", "Daily Laughs", "DL", "Your daily dose of laughter", ("#FF8A00", "#E52E71")),
    ("entertainment", "Showbiz Buzz", "SB", "Movies • TV • Music • Stars", ("#8E2DE2", "#4A00E0")),
    ("news", "World Brief", "WB", "The world in 60 seconds", ("#0F2027", "#2C5364")),
    ("games", "Game Zone", "GZ", "News, memes & debates for gamers", ("#00C9FF", "#6A3093")),
    ("motivation", "Rise & Grind Daily", "R&G", "Small steps. Every day.", ("#F7971E", "#FFD200")),
    ("sports", "Sports Pulse", "SP", "Every big moment, every day", ("#11998E", "#38EF7D")),
    ("tech", "Tech Today", "TT", "Tech & AI, explained simply", ("#1D2B64", "#00B4DB")),
    ("food", "Tasty Corner", "TC", "Recipes, cravings & food fights", ("#F12711", "#F5AF19")),
    ("travel", "Wander Daily", "WD", "Your daily escape", ("#2193B0", "#6DD5ED")),
    ("facts", "Did You Know?", "DYK", "Mind-blowing facts, daily", ("#5433FF", "#20BDFF")),
]


def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def gradient(w, h, c1, c2):
    a, b = hex2rgb(c1), hex2rgb(c2)
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for x in range(w + h):
        t = x / (w + h)
        col = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
        d.line([(x, 0), (x - h, h)], fill=col, width=2)
    return img


def centered(d, w, y, text, font, fill="white"):
    tw = d.textbbox((0, 0), text, font=font)[2]
    d.text(((w - tw) / 2, y), text, font=font, fill=fill)


for key, name, ini, tag, (c1, c2) in PAGES:
    p = gradient(720, 720, c1, c2)
    d = ImageDraw.Draw(p)
    d.ellipse([60, 60, 660, 660], outline="white", width=14)
    f = ImageFont.truetype(BOLD, 260 if len(ini) == 2 else 190)
    bb = d.textbbox((0, 0), ini, font=f)
    d.text(((720 - bb[2]) / 2 - bb[0] / 2, (720 - bb[3]) / 2 - bb[1] / 2 - 10), ini, font=f, fill="white")
    p.save(OUT / f"{key}_profile.png")

    c = gradient(1640, 624, c1, c2)
    d = ImageDraw.Draw(c)
    # keep text inside the centre-safe area (mobile crops the sides)
    centered(d, 1640, 190, name, ImageFont.truetype(BOLD, 120))
    centered(d, 1640, 350, tag, ImageFont.truetype(REG, 60))
    centered(d, 1640, 450, "Follow for daily posts", ImageFont.truetype(REG, 38), fill=(255, 255, 255))
    c.save(OUT / f"{key}_cover.png")
print("done")
