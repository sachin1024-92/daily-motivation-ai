"""Publishing to Facebook Pages through the official Graph API."""
from __future__ import annotations

import requests

from .sources import Post


class FacebookError(RuntimeError):
    pass


def _check(r: requests.Response) -> dict:
    if r.status_code >= 400:
        raise FacebookError(f"Graph API {r.status_code}: {r.text[:500]}")
    return r.json()


def publish_reel(page_id: str, token: str, post: Post, api_version: str) -> str:
    """Three-step Reels publishing: start -> hosted-file upload -> finish."""
    base = f"https://graph.facebook.com/{api_version}/{page_id}/video_reels"
    start = _check(requests.post(base, data={"upload_phase": "start", "access_token": token}, timeout=60))
    video_id = start["video_id"]
    _check(requests.post(
        f"https://rupload.facebook.com/video-upload/{api_version}/{video_id}",
        headers={"Authorization": f"OAuth {token}", "file_url": post.media_url},
        timeout=300,
    ))
    _check(requests.post(base, data={
        "upload_phase": "finish", "video_id": video_id, "video_state": "PUBLISHED",
        "description": post.message, "access_token": token,
    }, timeout=120))
    return video_id


def publish(page_id: str, token: str, post: Post, api_version: str = "v23.0") -> str:
    if post.kind == "reel":
        return publish_reel(page_id, token, post, api_version)
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
    body = _check(requests.post(endpoint, data=data, timeout=120))
    return body.get("post_id") or body.get("id", "")
