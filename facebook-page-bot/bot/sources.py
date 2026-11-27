"""Content generators. Every source here is either original AI writing or
media whose licence/API terms allow reuse:

* News   - RSS headlines, rewritten as a short summary and LINKED to the publisher
           (Facebook shows the publisher's own preview image).
* Photos - Pexels API (free licence, commercial use allowed). Photographer is credited.
* Videos - Pexels API, same licence.
* Memes  - Imgflip API: popular templates captioned with original AI text.
"""
from __future__ import annotations

import hashlib
import json
import os
import random
import re
from dataclasses import dataclass
from typing import Callable

import feedparser
import requests

from .ai import AIWriter

UA = {"User-Agent": "facebook-page-bot/1.0"}


@dataclass
class Post:
    kind: str                 # "text" | "link" | "photo" | "video" | "reel"
    message: str
    dedupe_key: str
    link: str | None = None
    media_url: str | None = None


class SourceUnavailable(RuntimeError):
    """Raised when a source has nothing new or is not configured."""


def _hash(text: str) -> str:
    return hashlib.sha1(text.encode()).hexdigest()[:16]


_TRENDS: dict[str, list[str]] = {}


def trending_topics(geo: str = "US", limit: int = 15) -> list[str]:
    """Today's top Google searches (cached per run) so posts ride current interest."""
    if geo not in _TRENDS:
        try:
            feed = feedparser.parse(f"https://trends.google.com/trending/rss?geo={geo}", agent=UA["User-Agent"])
            _TRENDS[geo] = [_strip_html(e.get("title", "")) for e in feed.entries[:limit] if e.get("title")]
        except Exception:  # trends are a bonus; never block posting
            _TRENDS[geo] = []
    return _TRENDS[geo]


def _trend_hint(page: dict) -> str:
    topics = trending_topics(page.get("trends_geo", "US"))
    if not topics:
        return ""
    return (
        "\nTrending searches right now: " + ", ".join(topics) + ". If one of them fits this page's "
        "topic naturally, build the post around it (don't invent facts about it); otherwise ignore the list."
    )


def _system(page: dict) -> str:
    return (
        f"You write Facebook posts for the page '{page['name']}'. Voice: {page['voice']}\n"
        "Rules: write ORIGINAL content only; never copy text from elsewhere; keep it "
        "family-friendly and within Facebook Community Standards; no hate, no adult content, "
        "no medical/financial claims, no made-up facts or quotes attributed to real people. "
        "Use at most 2 emojis and 3 relevant hashtags. Output ONLY the post text."
    )


def _strip_html(s: str) -> str:
    return re.sub(r"<[^>]+>", "", s or "").strip()


# ---------------------------------------------------------------- generators

def ai_text(page: dict, ai: AIWriter, seen: set[str]) -> Post:
    angle = random.choice([
        "a short post", "a question that invites comments", "a quick list of 3",
        "a one-liner", "a 'this or that' poll-style question",
    ])
    msg = ai.write(_system(page), f"Write {angle} for the page. Under 60 words.{_trend_hint(page)}")
    key = "ai:" + _hash(msg)
    if key in seen:
        raise SourceUnavailable("duplicate AI text")
    return Post("text", msg, key)


def news(page: dict, ai: AIWriter, seen: set[str]) -> Post:
    feeds = list(page.get("feeds") or [])
    if not feeds:
        raise SourceUnavailable("no feeds configured")
    random.shuffle(feeds)
    for url in feeds:
        parsed = feedparser.parse(url, agent=UA["User-Agent"])
        for entry in parsed.entries[:15]:
            link = entry.get("link")
            if not link:
                continue
            key = "news:" + _hash(link)
            if key in seen:
                continue
            title = _strip_html(entry.get("title", ""))
            summary = _strip_html(entry.get("summary", ""))[:600]
            msg = ai.write(
                _system(page),
                "Write a 1-2 sentence summary IN YOUR OWN WORDS of this news item, based only on "
                "the facts given (do not add facts). End with a short question to readers.\n"
                f"Headline: {title}\nSummary: {summary}",
            )
            source = re.sub(r"^www\.", "", requests.utils.urlparse(link).netloc)
            return Post("link", f"{msg}\n\nSource: {source}", key, link=link)
    raise SourceUnavailable("no new news items")


def _pexels_key() -> str:
    key = os.environ.get("PEXELS_API_KEY", "")
    if not key:
        raise SourceUnavailable("PEXELS_API_KEY not set")
    return key


def photo(page: dict, ai: AIWriter, seen: set[str]) -> Post:
    query = random.choice(page.get("photo_queries") or [page["key"]])
    r = requests.get(
        "https://api.pexels.com/v1/search",
        headers={"Authorization": _pexels_key()},
        params={"query": query, "per_page": 40, "page": random.randint(1, 5)},
        timeout=30,
    )
    r.raise_for_status()
    photos = [p for p in r.json().get("photos", []) if f"pexels:{p['id']}" not in seen]
    if not photos:
        raise SourceUnavailable(f"no new photos for '{query}'")
    p = random.choice(photos)
    caption = ai.write(
        _system(page),
        f"Write a caption for a photo described as: '{p.get('alt') or query}'. Under 50 words.",
    )
    credit = f"📷 {p['photographer']} / Pexels"
    return Post("photo", f"{caption}\n\n{credit}", f"pexels:{p['id']}", media_url=p["src"]["large2x"])


def video(page: dict, ai: AIWriter, seen: set[str]) -> Post:
    query = random.choice(page.get("photo_queries") or [page["key"]])
    r = requests.get(
        "https://api.pexels.com/videos/search",
        headers={"Authorization": _pexels_key()},
        params={"query": query, "per_page": 30, "max_duration": 60},
        timeout=30,
    )
    r.raise_for_status()
    vids = [v for v in r.json().get("videos", []) if f"pexelsv:{v['id']}" not in seen]
    random.shuffle(vids)
    for v in vids:
        files = [f for f in v.get("video_files", [])
                 if f.get("file_type") == "video/mp4" and (f.get("height") or 0) <= 1920]
        if not files:
            continue
        best = max(files, key=lambda f: f.get("height") or 0)
        caption = ai.write(_system(page), f"Write a caption for a short video about '{query}'. Under 40 words.")
        credit = f"🎥 {v['user']['name']} / Pexels"
        return Post("video", f"{caption}\n\n{credit}", f"pexelsv:{v['id']}", media_url=best["link"])
    raise SourceUnavailable(f"no new videos for '{query}'")


def reel(page: dict, ai: AIWriter, seen: set[str]) -> Post:
    """Vertical (9:16) short clip published as a Facebook Reel - the highest-reach format."""
    query = random.choice(page.get("photo_queries") or [page["key"]])
    r = requests.get(
        "https://api.pexels.com/videos/search",
        headers={"Authorization": _pexels_key()},
        params={"query": query, "per_page": 40, "orientation": "portrait",
                "page": random.randint(1, 3)},
        timeout=30,
    )
    r.raise_for_status()
    vids = [v for v in r.json().get("videos", [])
            if f"pexelsv:{v['id']}" not in seen and 3 <= (v.get("duration") or 0) <= 60]
    random.shuffle(vids)
    for v in vids:
        files = [f for f in v.get("video_files", [])
                 if f.get("file_type") == "video/mp4"
                 and (f.get("height") or 0) > (f.get("width") or 0)
                 and 540 <= (f.get("height") or 0) <= 1920]
        if not files:
            continue
        best = max(files, key=lambda f: f["height"])
        caption = ai.write(
            _system(page),
            f"Write a Reel caption for a short vertical clip about '{query}'. Start with a scroll-stopping "
            f"hook line, then one line inviting comments. Under 35 words.{_trend_hint(page)}",
        )
        credit = f"🎥 {v['user']['name']} / Pexels"
        return Post("reel", f"{caption}\n\n{credit}", f"pexelsv:{v['id']}", media_url=best["link"])
    raise SourceUnavailable(f"no new vertical videos for '{query}'")


def meme(page: dict, ai: AIWriter, seen: set[str]) -> Post:
    user, pw = os.environ.get("IMGFLIP_USERNAME"), os.environ.get("IMGFLIP_PASSWORD")
    if not user or not pw:
        raise SourceUnavailable("IMGFLIP_USERNAME / IMGFLIP_PASSWORD not set")
    templates = requests.get("https://api.imgflip.com/get_memes", timeout=30).json()["data"]["memes"]
    templates = [t for t in templates if t.get("box_count") == 2]
    t = random.choice(templates[:60])
    raw = ai.write(
        _system(page),
        f"Create an ORIGINAL meme for the '{t['name']}' template about a topic that fits the page. "
        'Reply with JSON only: {"top": "...", "bottom": "...", "caption": "short post caption"}. '
        f"Each text line under 60 characters.{_trend_hint(page)}",
        max_tokens=200,
    )
    m = re.search(r"\{.*\}", raw, re.S)
    if not m:
        raise SourceUnavailable("AI did not return meme JSON")
    data = json.loads(m.group(0))
    key = "meme:" + _hash(data["top"] + data["bottom"])
    if key in seen:
        raise SourceUnavailable("duplicate meme")
    r = requests.post(
        "https://api.imgflip.com/caption_image",
        data={"template_id": t["id"], "username": user, "password": pw,
              "text0": data["top"], "text1": data["bottom"]},
        timeout=30,
    ).json()
    if not r.get("success"):
        raise SourceUnavailable(f"imgflip error: {r.get('error_message')}")
    return Post("photo", data.get("caption", ""), key, media_url=r["data"]["url"])


GENERATORS: dict[str, Callable[[dict, AIWriter, set[str]], Post]] = {
    "ai_text": ai_text,
    "news": news,
    "photo": photo,
    "video": video,
    "reel": reel,
    "meme": meme,
}


def make_post(page: dict, ai: AIWriter, seen: set[str], dry_run: bool = False) -> Post:
    """Pick a content type by weight; fall back to the others if one is unavailable."""
    weights: dict[str, int] = dict(page.get("content") or {"ai_text": 1})
    errors = []
    while weights:
        kind = random.choices(list(weights), weights=list(weights.values()))[0]
        weights.pop(kind)
        gen = GENERATORS.get(kind)
        if gen is None:
            errors.append(f"{kind}: unknown content type")
            continue
        try:
            return gen(page, ai, seen)
        except (SourceUnavailable, requests.RequestException, KeyError, ValueError) as e:
            errors.append(f"{kind}: {e}")
    raise SourceUnavailable("; ".join(errors))
