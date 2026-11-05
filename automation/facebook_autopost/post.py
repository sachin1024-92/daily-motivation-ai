"""Facebook Page auto-poster: viral "OLD vs NEW" comparison images.

Pipeline (one run = one post):
  1. Claude picks a fresh comparison topic (not used before) and writes the
     image prompt + caption + hashtags.
  2. An image model renders the 1:1 split-screen image.
  3. The image is published to your Facebook Page via the Graph API.
  4. The topic is saved to history.json so it is never repeated.

Configuration is entirely through environment variables (GitHub Secrets in CI):
  ANTHROPIC_API_KEY      - Claude API key (required)
  IMAGE_PROVIDER         - "openai" (default) or "xai"
  OPENAI_API_KEY         - required when IMAGE_PROVIDER=openai
  XAI_API_KEY            - required when IMAGE_PROVIDER=xai
  IMAGE_MODEL            - optional override (default gpt-image-1 / grok-2-image)
  FB_PAGE_ID             - your Facebook Page ID (required unless DRY_RUN)
  FB_PAGE_ACCESS_TOKEN   - Page access token with pages_manage_posts (required unless DRY_RUN)
  NICHE                  - optional, what to compare (default: vehicles, gadgets, places...)
  DRY_RUN                - "1" to generate the image locally without posting
"""

from __future__ import annotations

import base64
import datetime as dt
import json
import os
import sys
from pathlib import Path

import anthropic
import requests
from pydantic import BaseModel, Field

HERE = Path(__file__).resolve().parent
HISTORY_FILE = HERE / "history.json"
OUTPUT_DIR = HERE / "output"
GRAPH_API = "https://graph.facebook.com/v21.0"

DEFAULT_NICHE = (
    "iconic things then vs now: motorcycles, cars, phones, computers, game consoles, "
    "cameras, famous city streets, train stations, airports, shops, household gadgets. "
    "Favour items with strong nostalgia for Indian and global audiences."
)


class PostPlan(BaseModel):
    topic: str = Field(description="Short unique topic id, e.g. 'Royal Enfield Bullet 1990 vs 2026'")
    image_prompt: str = Field(description="Full prompt for the image model")
    caption: str = Field(description="Facebook caption, 1-3 short lines, ends with an engagement question")
    hashtags: list[str] = Field(description="5-8 hashtags without the # sign")


def env(name: str, default: str | None = None, required: bool = False) -> str:
    value = os.environ.get(name, default)
    if required and not value:
        sys.exit(f"Missing required environment variable: {name}")
    return value or ""


def load_history() -> dict:
    if HISTORY_FILE.exists():
        return json.loads(HISTORY_FILE.read_text())
    return {"posts": []}


def plan_post(history: dict) -> PostPlan:
    used = [p["topic"] for p in history["posts"]][-200:]
    niche = env("NICHE", DEFAULT_NICHE)
    year = dt.date.today().year

    prompt = f"""You run a Facebook Page that posts viral "OLD vs NEW" comparison images.

Niche: {niche}

Pick ONE new comparison that is NOT in this list of topics already posted:
{json.dumps(used, ensure_ascii=False)}

Then write:
- image_prompt: an ultra-realistic 1:1 square split-screen image prompt. Two stacked
  panels of equal size divided by a thin clean white line. TOP panel: the old
  version (state the year, e.g. 1990) with authentic period details and warm
  nostalgic film tone. BOTTOM panel: the {year} version, same angle, same framing,
  same location, crisp modern look. A bold year label ("1990" / "{year}") in the
  top-left corner of each panel. Photorealistic, correct proportions, no people,
  no other text, no watermark, no brand logos.
- caption: short, curiosity-driven, ends with a question that invites comments
  (e.g. "Which one would you pick?").
- hashtags: 5-8 relevant hashtags.
Only depict generic designs or widely known models; never copy someone else's photo."""

    client = anthropic.Anthropic()
    # Server-side fallback: if a request is declined by a safety classifier,
    # the API retries on a fallback model automatically.
    response = client.beta.messages.parse(
        model="claude-opus-5-5",
        max_tokens=16000,
        output_config={"effort": "low"},
        betas=["server-side-fallback-2026-07-01"],
        fallbacks="default",
        messages=[{"role": "user", "content": prompt}],
        output_format=PostPlan,
    )
    if response.stop_reason == "refusal" or response.parsed_output is None:
        sys.exit(f"Claude did not return a post plan (stop_reason={response.stop_reason}).")
    return response.parsed_output


def generate_image(prompt: str) -> bytes:
    provider = env("IMAGE_PROVIDER", "openai").lower()
    if provider == "openai":
        url = "https://api.openai.com/v1/images/generations"
        key = env("OPENAI_API_KEY", required=True)
        body = {"model": env("IMAGE_MODEL", "gpt-image-1"), "prompt": prompt,
                "size": "1024x1024", "n": 1}
    elif provider == "xai":
        url = "https://api.x.ai/v1/images/generations"
        key = env("XAI_API_KEY", required=True)
        body = {"model": env("IMAGE_MODEL", "grok-2-image"), "prompt": prompt,
                "n": 1, "response_format": "b64_json"}
    else:
        sys.exit(f"Unknown IMAGE_PROVIDER: {provider}")

    r = requests.post(url, headers={"Authorization": f"Bearer {key}"}, json=body, timeout=300)
    if r.status_code != 200:
        sys.exit(f"Image generation failed ({r.status_code}): {r.text[:500]}")
    item = r.json()["data"][0]
    if item.get("b64_json"):
        return base64.b64decode(item["b64_json"])
    img = requests.get(item["url"], timeout=120)
    img.raise_for_status()
    return img.content


def post_to_facebook(image: bytes, message: str) -> str:
    page_id = env("FB_PAGE_ID", required=True)
    token = env("FB_PAGE_ACCESS_TOKEN", required=True)
    r = requests.post(
        f"{GRAPH_API}/{page_id}/photos",
        data={"message": message, "access_token": token, "published": "true"},
        files={"source": ("image.png", image, "image/png")},
        timeout=120,
    )
    if r.status_code != 200:
        sys.exit(f"Facebook post failed ({r.status_code}): {r.text[:500]}")
    data = r.json()
    return data.get("post_id") or data.get("id", "")


def main() -> None:
    dry_run = env("DRY_RUN", "0") == "1"
    history = load_history()

    plan = plan_post(history)
    print(f"Topic: {plan.topic}\nCaption: {plan.caption}")

    image = generate_image(plan.image_prompt)
    OUTPUT_DIR.mkdir(exist_ok=True)
    slug = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%d-%H%M%S")
    (OUTPUT_DIR / f"{slug}.png").write_bytes(image)

    message = plan.caption.strip() + "\n\n" + " ".join(
        "#" + h.lstrip("#").replace(" ", "") for h in plan.hashtags
    )

    if dry_run:
        print(f"DRY_RUN: image saved to output/{slug}.png, not posted.")
        return

    post_id = post_to_facebook(image, message)
    print(f"Posted to Facebook: {post_id}")

    history["posts"].append({
        "topic": plan.topic,
        "post_id": post_id,
        "posted_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
    })
    HISTORY_FILE.write_text(json.dumps(history, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
