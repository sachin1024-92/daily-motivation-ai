# Facebook Page Bot

Automatically posts to up to 10 Facebook Pages using Facebook's official Graph API.
It posts AI-written captions with news, photos, videos and memes, spread through the day.

| Page key | Topic | Content mix |
|---|---|---|
| comedy | Jokes, relatable humour | memes, AI jokes, funny photos |
| entertainment | Movies, TV, music | real headlines (BBC, Variety) + photos |
| news | World news | real headlines (BBC, Al Jazeera, NYT), linked to source |
| games | Gaming | gaming news (GameSpot, Polygon, Eurogamer) + memes |
| motivation | Mindset, discipline | photos + original quotes + videos |
| sports | Football, cricket, NBA | sports headlines (BBC Sport, ESPN) |
| tech | Gadgets, AI, science | tech headlines (BBC, The Verge, TechCrunch) |
| food | Recipes, food polls | food photos + videos |
| travel | Places, tips | travel photos + videos |
| facts | Fun facts | AI facts + photos |

You can edit every page in `config/pages.yaml`: name, voice, posts per day, RSS feeds, photo search words and content mix.

## Where the content comes from (and why)

| Content | Source | Why it's safe to post |
|---|---|---|
| News | Public RSS feeds | Posted as a **link** with a summary in our own words. Facebook shows the publisher's own preview image, so we never re-upload their photos. |
| Photos | [Pexels API](https://www.pexels.com/api/) | Free licence that allows commercial reuse. Photographers are credited. |
| Videos / Reels | Pexels API (vertical clips → published as **Reels**) | Same licence. Reels get the most reach on Facebook. |
| Trending topics | Google Trends live searches (per country, `trends_geo`) | Only topic names are used; the AI writes about what people are searching for right now. |
| Memes | [Imgflip API](https://imgflip.com/api) | Popular meme templates with **original** captions written by the AI. |
| Text | Grok or Claude | Original writing in each page's voice. |

**Not included: copying memes, reels or audio from Instagram, or photos found on random websites.** Those belong to their creators. Facebook's Rights Manager detects reposted media and will remove posts, block audio and eventually unpublish the Page. Scraping Instagram also breaks Instagram's terms. For music on Reels, add it in the Facebook app from **Meta Sound Collection**, which is free and licensed.

## Setup (about 30 minutes, once)

### 1. Create the Pages (manual, ~2 min each)
Facebook doesn't allow bots to create Pages. In the Facebook app, go to **Menu → Pages → Create**. Create one Page per topic and add a profile picture and cover photo.

### 2. Create a Meta developer app
1. Go to <https://developers.facebook.com/apps> → **Create app** → choose the **Business** type.
2. Add the **Facebook Login for Business** product.
3. Open the [Graph API Explorer](https://developers.facebook.com/tools/explorer/) and select your app. Under **User token**, add these permissions: `pages_show_list`, `pages_read_engagement`, `pages_manage_posts`. Click **Generate Access Token**.
4. Exchange it for a **long-lived** user token:
   ```
   https://graph.facebook.com/v23.0/oauth/access_token?grant_type=fb_exchange_token&client_id=APP_ID&client_secret=APP_SECRET&fb_exchange_token=SHORT_TOKEN
   ```
5. Using that long-lived token, open `https://graph.facebook.com/v23.0/me/accounts?access_token=LONG_TOKEN`. It lists every Page with its `id` and an `access_token`. These Page tokens **don't expire**.

> While the app is in *Development* mode, it can post to Pages you admin, which is all you need. App Review is only required if other people's Pages will use your app.

### 3. Get the free API keys
- **AI:** an xAI key (Grok) from <https://console.x.ai>, *or* an Anthropic key (Claude) from <https://console.anthropic.com>. Choose one with `ai_provider` in `pages.yaml`.
- **Photos/videos:** <https://www.pexels.com/api/> (free).
- **Memes:** a free account at <https://imgflip.com/signup>.

### 4. Add GitHub secrets
In the repo, go to **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret | Value |
|---|---|
| `FB_PAGES_JSON` | `{"comedy":{"id":"123","token":"EAAB..."},"news":{"id":"456","token":"EAAB..."}, ...}` |
| `XAI_API_KEY` *or* `ANTHROPIC_API_KEY` | your AI key |
| `PEXELS_API_KEY` | Pexels key |
| `IMGFLIP_USERNAME`, `IMGFLIP_PASSWORD` | Imgflip login |

The bot skips any page that has no entry in `FB_PAGES_JSON`, so you can start with one or two Pages.

### 5. Turn it on
- Merge this branch into `main`. GitHub only runs scheduled workflows from the default branch.
- Go to **Actions → Facebook Page Bot → Run workflow** and leave *Dry run* ticked. Check the log to see the posts it would make.
- After that, it runs every hour by itself.

## Posting volume: start low

Every page starts at **5 posts/day**. The code caps it at 20. New Pages that post 20 times a day from the first day often get their reach cut or are flagged as spam. Run 3–5 posts a day for a few weeks, then raise `posts_per_day` gradually if engagement holds.

## Run locally

```bash
cd facebook-page-bot
pip install -r requirements.txt
python -m bot.main --dry-run --force 1          # preview one post per page, no keys needed
export XAI_API_KEY=... PEXELS_API_KEY=...
python -m bot.main --dry-run --force 2 --page motivation   # preview with real AI + photos
# put {"comedy": {"id": "...", "token": "..."}} in config/pages.secrets.json (git-ignored), then:
python -m bot.main --page comedy --force 1     # really publish one post
python -m pytest -q tests
```

## Rules the bot follows
- No adult or sexual content. Facebook bans it, and it would get your account and all Pages removed.
- News is summarised from the feed's own facts, always links to the publisher and names the source.
- The posting state is saved in `state/state.json`, so the same article, photo or meme is never posted twice.
