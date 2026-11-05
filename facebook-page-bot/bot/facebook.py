"""Publishing to Facebook Pages through the official Graph API."""
from __future__ import annotations

import requests

from .sources import Post


class FacebookError(RuntimeError):
    pass


def publish(page_id: str, token: str, post: Post, api_version: str = "v23.0") -> str:
    base = f"https://graph.facebook.com/{api_version}/{page_id}"
    if post.kind == "photo":
        endpoint, data = f"{base}/photos", {"url": post.media_url, "caption": post.message}
    elif post.kind == "video":
        endpoint, data = f"{base}/videos", {"file_url": post.media_url, "description": post.message}
    elif post.kind == "link":
        endpoint, data = f"{base}/feed", {"message": post.message, "link": post.link}
    else:
        endpoint, data = f"{base}/feed", {"message": post.message}

    data["access_token"] = token
    r = requests.post(endpoint, data=data, timeout=120)
    if r.status_code >= 400:
        raise FacebookError(f"Graph API {r.status_code}: {r.text[:500]}")
    body = r.json()
    return body.get("post_id") or body.get("id", "")
