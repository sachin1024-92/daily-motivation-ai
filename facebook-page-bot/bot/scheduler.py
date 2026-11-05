"""Decides how many posts each page should publish in the current run, and keeps state."""
from __future__ import annotations

import json
import math
from datetime import datetime
from pathlib import Path

MAX_SEEN = 1000


def due_now(posts_per_day: int, posted_today: int, now: datetime, start_hour: int, end_hour: int) -> int:
    """How many posts should go out right now so that `posts_per_day` is spread
    evenly over the active window [start_hour, end_hour)."""
    if posts_per_day <= 0 or end_hour <= start_hour:
        return 0
    hour = now.hour + now.minute / 60
    if hour < start_hour:
        return 0
    fraction = min(1.0, (hour - start_hour + 1) / (end_hour - start_hour))
    target = math.ceil(posts_per_day * fraction) if fraction < 1 else posts_per_day
    return max(0, target - posted_today)


class State:
    def __init__(self, path: Path):
        self.path = path
        self.data: dict = {}
        if path.exists():
            self.data = json.loads(path.read_text() or "{}")

    def page(self, key: str, today: str) -> dict:
        p = self.data.setdefault(key, {"date": today, "posted_today": 0, "seen": []})
        if p["date"] != today:
            p["date"], p["posted_today"] = today, 0
        return p

    def record(self, key: str, today: str, dedupe_key: str, post_id: str) -> None:
        p = self.page(key, today)
        p["posted_today"] += 1
        p["seen"] = (p["seen"] + [dedupe_key])[-MAX_SEEN:]
        p["last_post_id"] = post_id

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(self.data, indent=1, sort_keys=True) + "\n")
