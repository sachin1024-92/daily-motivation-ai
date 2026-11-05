"""Thin AI text writer supporting xAI Grok and Anthropic Claude via plain HTTP."""
from __future__ import annotations

import os

import requests

DEFAULT_MODELS = {
    "grok": "grok-4",
    "claude": "claude-sonnet-5-5",
}


class AIWriter:
    def __init__(self, provider: str = "grok", model: str = "", dry_run: bool = False):
        self.provider = provider.lower()
        if self.provider not in DEFAULT_MODELS:
            raise ValueError(f"Unknown ai_provider '{provider}' (use 'grok' or 'claude')")
        self.model = model or DEFAULT_MODELS[self.provider]
        key_var = "XAI_API_KEY" if self.provider == "grok" else "ANTHROPIC_API_KEY"
        self.api_key = os.environ.get(key_var, "")
        self.dry_run = dry_run and not self.api_key
        if not self.api_key and not dry_run:
            raise RuntimeError(f"Missing {key_var} environment variable")

    def write(self, system: str, prompt: str, max_tokens: int = 400) -> str:
        if self.dry_run:
            return f"[dry-run AI text] {prompt[:120]}"
        if self.provider == "grok":
            return self._grok(system, prompt, max_tokens)
        return self._claude(system, prompt, max_tokens)

    def _grok(self, system: str, prompt: str, max_tokens: int) -> str:
        r = requests.post(
            "https://api.x.ai/v1/chat/completions",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json={
                "model": self.model,
                "max_tokens": max_tokens,
                "messages": [
                    {"role": "system", "content": system},
                    {"role": "user", "content": prompt},
                ],
            },
            timeout=90,
        )
        r.raise_for_status()
        return r.json()["choices"][0]["message"]["content"].strip()

    def _claude(self, system: str, prompt: str, max_tokens: int) -> str:
        r = requests.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": self.api_key,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": self.model,
                "max_tokens": max_tokens,
                "system": system,
                "messages": [{"role": "user", "content": prompt}],
            },
            timeout=90,
        )
        r.raise_for_status()
        parts = r.json()["content"]
        return "".join(p.get("text", "") for p in parts if p.get("type") == "text").strip()
