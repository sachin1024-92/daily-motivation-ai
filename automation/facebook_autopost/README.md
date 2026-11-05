# Facebook Auto-Post: "OLD vs NEW" comparison images

Automates the method from the reel: ask an AI for a viral "1990 vs 2026"
split-screen image prompt, generate the image, post it to your Facebook Page.
It runs twice a day on GitHub Actions, and every run makes one new post.

```
Claude (topic + prompt + caption)  ->  image model  ->  Facebook Graph API  ->  history.json
```

## One-time setup (about 15 minutes)

You **do not** give anyone your Facebook password. The script posts with a
**Page access token**, which only lets it post to your Page, and you can
revoke it at any time.

### 1. Facebook Page access token
1. You need a **Facebook Page** (not a personal profile). The Graph API can't post to profiles.
2. Go to <https://developers.facebook.com/apps> → **Create app** → type **Business**.
3. Open **Tools → Graph API Explorer**, select your app, then click
   **Get Token → Get User Access Token** and tick:
   `pages_show_list`, `pages_read_engagement`, `pages_manage_posts`.
4. Make it long-lived: open **Tools → Access Token Debugger**, paste the token,
   and click **Extend Access Token**.
5. Back in Graph API Explorer, paste the long-lived user token and run
   `GET me/accounts`. Copy your Page's `id` (→ `FB_PAGE_ID`) and `access_token`
   (→ `FB_PAGE_ACCESS_TOKEN`). A Page token taken from a long-lived user token
   doesn't expire.

### 2. AI keys
- `ANTHROPIC_API_KEY`: from <https://console.anthropic.com>, for the prompts and captions.
- `OPENAI_API_KEY`: from <https://platform.openai.com>, for images (default provider).
  - Or use Grok images instead: add `XAI_API_KEY` and set the repo **variable**
    `IMAGE_PROVIDER=xai`.

### 3. Add them to GitHub
Repo → **Settings → Secrets and variables → Actions → New repository secret**:
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `FB_PAGE_ID`, `FB_PAGE_ACCESS_TOKEN`.

Optional **variables** (same page, *Variables* tab):
- `NICHE`: what to compare, e.g. `Indian motorcycles and cars then vs now`
- `IMAGE_PROVIDER`: `openai` or `xai`

### 4. Test it
**Actions → Facebook Auto-Post → Run workflow**, with `dry_run = 1`. Download
the image from the run's artifacts and check it. When you like the results,
run it with `dry_run = 0`, or just wait for the schedule.

## Run locally
```bash
cd automation/facebook_autopost
pip install -r requirements.txt
export ANTHROPIC_API_KEY=... OPENAI_API_KEY=... DRY_RUN=1
python post.py          # image saved to output/
```

## Schedule
Edit the `cron` line in `.github/workflows/facebook-autopost.yml`. It's set to
09:13 and 19:13 IST.

## Keep the Page monetizable
Meta's content monetization pays less for, or demonetizes, pages that post
mass-produced, repetitive or unoriginal content. To stay safe:
- Run a few dry runs first and only post images you'd be happy to put your name on.
- Keep the frequency moderate (1–2 posts a day).
- Mix in your own posts, replies to comments, and Reels.
- Don't use brand logos or copy other creators' photos (the prompt already says this).
- Mark posts as AI-generated where Meta asks you to.
