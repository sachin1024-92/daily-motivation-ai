"""Renders 1080x1350 branded tip cards + a schedule.json for the connected Pages."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).parent
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
W, H = 1080, 1350

PAGES = {
    "4kedits": {
        "page_id": "441287292403639", "brand": "4KEdits", "colors": ("#0F0C29", "#302B63"), "accent": "#00E5FF",
        "tags": "#videoediting #4KEdits #editingtips #reels #contentcreator",
        "posts": [
            ("THE 3-SECOND HOOK", ["Viewers decide in ~3 seconds.", "Open with motion or the best shot.", "Put the payoff first, then explain.", "Cut every intro and logo sting."], "What's the best hook you've ever seen in a Reel? 👇"),
            ("J-CUT & L-CUT", ["J-cut: next clip's AUDIO starts early.", "L-cut: current audio carries over.", "Makes dialogue & vlogs flow.", "The #1 trick pros use invisibly."], "Did you know this one? Save it for your next edit 🎬"),
            ("CUT ON ACTION", ["Cut while the subject is moving.", "The motion hides the cut.", "Door opens → cut → walk through.", "Smooth, seamless, cinematic."], "Try it in your next edit and tag us 👇"),
            ("SMOOTH SLOW-MO", ["Shoot at 60fps, edit in 30fps", "→ clean 50% slow motion.", "Shoot 120fps → clean 25%.", "Slowing 30fps footage = choppy."], "What FPS do you usually shoot at? 👇"),
            ("180° SHUTTER RULE", ["Shutter speed = 1 / (2 × fps)", "24fps → 1/50", "30fps → 1/60", "60fps → 1/125", "Natural motion blur, no jitter."], "Do you shoot manual or auto? 👇"),
            ("CORRECT, THEN GRADE", ["1. Fix exposure & white balance", "2. Match all clips", "3. THEN add the creative look", "Grading uncorrected clips = mess."], "Which colour look is your favourite? 🎨"),
            ("EDIT TO THE BEAT", ["Drop markers on the beat first", "(tap M while music plays).", "Snap cuts to the markers.", "Big moment = big drop."], "What song should we edit to next? 🎵"),
            ("SPEED RAMPS", ["Fast → slow → fast on one clip.", "Always ease the curve in/out.", "Ramp INTO the key moment.", "Add a whoosh at the speed change."], "Speed ramps: overused or always 🔥? 👇"),
            ("REELS SAFE ZONE", ["Keep text out of the bottom ~20%", "(captions & buttons cover it).", "Leave space on the right edge.", "Centre your subject."], "Ever had text hidden by the buttons? 😅"),
            ("EXPORT FOR REELS", ["1080 × 1920 (9:16)", "H.264, MP4", "30fps (match your timeline)", "High bitrate, AAC audio", "Upload over Wi-Fi."], "Save this for your next export 📌"),
            ("MATCH CUT", ["Cut between two shots that share", "a shape, motion or position.", "Ball → sun. Spin → spin.", "Plan the match while shooting."], "What's the best match cut in a movie? 👇"),
            ("WHY SHOOT IN 4K?", ["Edit on a 1080p timeline", "and crop up to 2× with no quality loss.", "Fake zooms, reframes, 2 angles", "from one camera."], "Do you shoot in 4K or 1080p? 👇"),
            ("SOUND IS 50%", ["Whoosh on transitions", "Riser before the drop", "Room tone under dialogue", "Bad audio = people scroll away."], "Do you add sound effects to your edits? 🔊"),
            ("WHICH EDITOR?", ["CapCut", "Premiere Pro", "DaVinci Resolve", "Final Cut Pro", "Comment your pick 👇"], "Which app do YOU edit on? Vote below 👇"),
        ],
    },
    "housebuilder": {
        "page_id": "1146791875179075", "brand": "House Builder 3-D projects", "colors": ("#134E5E", "#71B280"), "accent": "#FFE29A",
        "tags": "#homedesign #3dhouse #architecture #floorplan #houseplan",
        "posts": [
            ("THE KITCHEN TRIANGLE", ["Sink • Stove • Fridge", "Each side: 1.2 – 2.7 m", "Total: under ~7.9 m", "No walkway cutting through it."], "Does your kitchen follow the triangle? 👇"),
            ("COMFORTABLE STAIRS", ["2 × riser + 1 tread ≈ 63 cm", "Riser ~15–18 cm", "Tread ~25–30 cm", "Same height on every step!"], "Straight, L-shaped or spiral stairs? 👇"),
            ("DOOR WIDTHS", ["Main door: ~ 1.0 m", "Bedrooms: ~ 0.9 m", "Bathrooms: ~ 0.75 m", "Wider = easier furniture moves."], "Save this before you finalise your plan 📌"),
            ("CROSS VENTILATION", ["Put windows on OPPOSITE walls.", "Air needs an inlet and an outlet.", "Cooler rooms, less AC.", "High vents let hot air escape."], "Is your home naturally breezy? 🌬️"),
            ("BEDROOM SIZES", ["Double bed room: 3.0 × 3.6 m+", "Leave ~60 cm around the bed.", "Wardrobe depth ~60 cm.", "Door shouldn't hit the bed."], "What's your dream bedroom size? 👇"),
            ("PLAN FURNITURE FIRST", ["Place the bed, sofa & TV in 3D", "BEFORE fixing windows & sockets.", "Avoid a window behind the TV.", "Sockets where furniture goes."], "Ever had a socket hidden behind a cupboard? 😅"),
            ("FLAT OR SLOPED ROOF?", ["Flat: usable terrace, modern look", "Sloped: sheds rain fast, cooler attic", "Mix: sloped + terrace", "Comment your pick 👇"], "Team flat roof or team sloped roof? 🏠"),
            ("FREE 3D HOUSE TOOLS", ["Sweet Home 3D: free & easy", "SketchUp Free: in the browser", "Blender: free, photo-real renders", "Pro: Revit, ArchiCAD"], "Which software do you design in? 👇"),
            ("REALISTIC RENDERS", ["Model at real-world scale", "Light with an HDRI sky", "Add bevels: no razor-sharp edges", "Add imperfections & plants"], "Want a render tutorial? Comment 'YES' 👇"),
            ("CORRIDOR WIDTHS", ["Minimum: ~ 0.9 m", "Comfortable: 1.0 – 1.2 m", "Wheelchair turn: 1.5 m circle", "Less corridor = more room."], "Do you prefer open plan or separate rooms? 👇"),
            ("OPEN PLAN: PROS & CONS", ["✔ More light, feels bigger", "✔ Easy to socialise", "✘ Cooking smells & noise travel", "✘ Less privacy"], "Open kitchen or closed kitchen? 👇"),
            ("NATURAL LIGHT", ["Window area ≈ 10–20% of floor area", "Light-coloured walls & ceilings", "Glass doors between rooms", "Skylights for deep spaces"], "Which room in your home gets the best light? ☀️"),
            ("CEILING HEIGHT", ["~2.7 m feels comfortable", "~3.0 m feels spacious & cooler", "Double height = wow living room", "Low ceilings feel cramped."], "Would you choose a double-height living room? 👇"),
            ("WHICH ROOM FIRST?", ["Living room", "Kitchen", "Master bedroom", "Terrace / garden", "Comment your pick 👇"], "If we designed ONE room for you in 3D, which one? 👇"),
        ],
    },
}


def hex2rgb(h):
    return tuple(int(h.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))


def bg(c1, c2):
    a, b = hex2rgb(c1), hex2rgb(c2)
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)))
    return img


def fit(d, text, path, size, maxw):
    while size > 30:
        f = ImageFont.truetype(path, size)
        if d.textbbox((0, 0), text, font=f)[2] <= maxw:
            return f
        size -= 4
    return ImageFont.truetype(path, size)


schedule = []
for key, cfg in PAGES.items():
    out = ROOT / key
    out.mkdir(exist_ok=True)
    for n, (title, lines, question) in enumerate(cfg["posts"], 1):
        img = bg(*cfg["colors"])
        d = ImageDraw.Draw(img)
        d.text((80, 80), cfg["brand"].upper(), font=ImageFont.truetype(BOLD, 34), fill=cfg["accent"])
        d.text((W - 200, 80), f"TIP #{n:02d}", font=ImageFont.truetype(BOLD, 34), fill="white")
        tf = fit(d, title, BOLD, 96, W - 160)
        d.text((80, 230), title, font=tf, fill="white")
        d.rectangle([80, 360, 260, 370], fill=cfg["accent"])
        y = 440
        for line in lines:
            lf = fit(d, line, REG, 52, W - 160)
            d.text((80, y), line, font=lf, fill="white")
            y += 110
        d.text((80, H - 140), "Follow for a new tip every day →", font=ImageFont.truetype(REG, 38), fill=cfg["accent"])
        fname = f"{n:02d}.png"
        img.save(out / fname, optimize=True)
        schedule.append({
            "page": key, "page_id": cfg["page_id"], "n": n, "file": f"facebook-page-bot/page-content/{key}/{fname}",
            "caption": f"{title.title()} 💡\n\n{question}\n\n{cfg['tags']}",
        })
(ROOT / "schedule.json").write_text(json.dumps(schedule, indent=1, ensure_ascii=False))
print(len(schedule), "cards")
