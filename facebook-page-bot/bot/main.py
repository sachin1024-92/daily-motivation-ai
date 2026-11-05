"""Entry point. Run once per hour (cron / GitHub Actions).

    python -m bot.main                 # publish whatever is due now
    python -m bot.main --dry-run       # print posts instead of publishing
    python -m bot.main --page comedy --force 1   # post 1 now to one page (testing)
"""
from __future__ import annotations

import argparse
import json
import os
import random
import sys
import time
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

import yaml

from .ai import AIWriter
from .facebook import FacebookError, publish
from .scheduler import State, due_now
from .sources import SourceUnavailable, make_post

ROOT = Path(__file__).resolve().parent.parent


def load_credentials() -> dict:
    raw = os.environ.get("FB_PAGES_JSON", "")
    if raw:
        return json.loads(raw)
    path = ROOT / "config" / "pages.secrets.json"
    return json.loads(path.read_text()) if path.exists() else {}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default=str(ROOT / "config" / "pages.yaml"))
    ap.add_argument("--state", default=str(ROOT / "state" / "state.json"))
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--page", help="only process this page key")
    ap.add_argument("--force", type=int, default=0, help="post N now, ignoring the schedule")
    ap.add_argument("--no-sleep", action="store_true", help="don't pause between posts")
    args = ap.parse_args(argv)

    cfg = yaml.safe_load(Path(args.config).read_text())
    s = cfg.get("settings", {})
    tz = ZoneInfo(s.get("timezone", "UTC"))
    now = datetime.now(tz)
    today = now.strftime("%Y-%m-%d")
    start, end = s.get("active_hours", [7, 23])
    cap = int(s.get("max_posts_per_run", 4))

    ai = AIWriter(s.get("ai_provider", "grok"), s.get("ai_model", ""), dry_run=args.dry_run)
    creds = load_credentials()
    state = State(Path(args.state))
    failures = 0

    for page in cfg["pages"]:
        key = page["key"]
        if args.page and key != args.page:
            continue
        if page.get("enabled", True) is False:
            continue
        ppd = min(int(page.get("posts_per_day", 3)), 20)
        pstate = state.page(key, today)
        n = args.force or due_now(ppd, pstate["posted_today"], now, start, end)
        n = min(n, cap) if not args.force else n
        if n <= 0:
            continue

        cred = creds.get(key, {})
        if not args.dry_run and not (cred.get("id") and cred.get("token")):
            print(f"[{key}] skipped: no page id/token in FB_PAGES_JSON")
            continue

        for i in range(n):
            seen = set(pstate["seen"])
            try:
                post = make_post(page, ai, seen)
            except SourceUnavailable as e:
                print(f"[{key}] nothing to post: {e}")
                failures += 1
                break
            if args.dry_run:
                print(f"\n[{key}] ({post.kind}) {post.link or post.media_url or ''}\n{post.message}")
                post_id = "dry-run"
            else:
                try:
                    post_id = publish(cred["id"], cred["token"], post, s.get("graph_api_version", "v23.0"))
                    print(f"[{key}] published {post.kind} -> {post_id}")
                except FacebookError as e:
                    print(f"[{key}] publish failed: {e}")
                    failures += 1
                    break
            state.record(key, today, post.dedupe_key, post_id)
            pstate = state.page(key, today)
            if not args.dry_run:
                state.save()  # persist after each post so a crash never causes duplicates
                if i < n - 1 and not args.no_sleep:
                    time.sleep(random.randint(60, 240))  # avoid bursts of identical-timestamp posts

    if not args.dry_run:
        state.save()
    return 1 if failures and not args.dry_run else 0


if __name__ == "__main__":
    sys.exit(main())
