"""Profile/cover images for the connected Pages + 9:16 animated tip Reels (MP4)."""
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from make_cards import PAGES, BOLD, REG, hex2rgb, fit

ROOT = Path(__file__).parent


def grad(w, h, c1, c2):
    a, b = hex2rgb(c1), hex2rgb(c2)
    img = Image.new("RGB", (w, h)); d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)))
    return img


BRAND = {
    "4kedits": ("4K", "4KEdits", "Edit like a pro • One tip a day"),
    "housebuilder": ("3D", "House Builder 3-D", "Smart home design • 3D projects"),
}

# ---- branding
for key, (mono, title, tag) in BRAND.items():
    cfg = PAGES[key]; out = ROOT / "branding"; out.mkdir(exist_ok=True)
    p = grad(720, 720, *cfg["colors"]); d = ImageDraw.Draw(p)
    d.ellipse([50, 50, 670, 670], outline=cfg["accent"], width=16)
    f = ImageFont.truetype(BOLD, 280); bb = d.textbbox((0, 0), mono, font=f)
    d.text(((720 - (bb[2] - bb[0])) / 2 - bb[0], (720 - (bb[3] - bb[1])) / 2 - bb[1]), mono, font=f, fill="white")
    p.save(out / f"{key}_profile.png")
    c = grad(1640, 624, *cfg["colors"]); d = ImageDraw.Draw(c)
    for text, font, y, col in [(title, fit(d, title, BOLD, 120, 1100), 170, "white"),
                               (tag, ImageFont.truetype(REG, 56), 340, cfg["accent"]),
                               ("New tips every day — follow ✓", ImageFont.truetype(REG, 38), 440, "white")]:
        w = d.textbbox((0, 0), text, font=font)[2]
        d.text(((1640 - w) / 2, y), text, font=font, fill=col)
    c.save(out / f"{key}_cover.png")

# ---- reels
FPS, SECS, W, H = 30, 9, 1080, 1920


def reel(key, n, title, lines):
    cfg = PAGES[key]
    base = grad(W, H, *cfg["colors"])
    out = ROOT / "reels" / key; out.mkdir(parents=True, exist_ok=True)
    path = out / f"{n:02d}.mp4"
    proc = subprocess.Popen(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
         "-r", str(FPS), "-i", "-", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo",
         "-shortest", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-profile:v", "high", "-crf", "20",
         "-c:a", "aac", "-b:a", "128k", "-movflags", "+faststart", str(path)],
        stdin=subprocess.PIPE)
    tf = fit(ImageDraw.Draw(base), title, BOLD, 100, W - 160)
    total = FPS * SECS
    for i in range(total):
        t = i / FPS
        img = base.copy(); d = ImageDraw.Draw(img)
        d.text((80, 260), cfg["brand"].upper(), font=ImageFont.truetype(BOLD, 40), fill=cfg["accent"])
        # title slides in
        x = 80 - max(0, 1 - t / 0.6) * 900
        d.text((x, 420), title, font=tf, fill="white")
        d.rectangle([80, 560, 80 + min(1, t / 0.8) * 220, 572], fill=cfg["accent"])
        for j, line in enumerate(lines):
            start = 1.0 + j * 1.3
            if t >= start:
                a = min(1, (t - start) / 0.4)
                col = tuple(int(255 * a + base.getpixel((80, 660 + j * 130))[k] * (1 - a)) for k in range(3))
                d.text((80, 660 + j * 130 + (1 - a) * 30), line, font=fit(d, line, REG, 56, W - 160), fill=col)
        if t > SECS - 2.2:
            d.text((80, H - 420), "Follow for a new tip every day →", font=ImageFont.truetype(BOLD, 46), fill=cfg["accent"])
        proc.stdin.write(img.tobytes())
    proc.stdin.close(); proc.wait()
    return path


if __name__ == "__main__":
    import sys
    picks = {"4kedits": [1, 3, 9, 15, 22, 25], "housebuilder": [1, 2, 8, 20, 21, 27]}
    for key, nums in picks.items():
        for n in nums:
            title, lines, _ = PAGES[key]["posts"][n - 1]
            print(reel(key, n, title, lines))
