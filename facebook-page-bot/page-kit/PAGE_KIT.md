# Facebook Page Kit: 10 ready-to-create Pages

Each Page takes about **2 minutes**. Open <https://www.facebook.com/pages/create> (or in the app: **Menu → Pages → + Create**) and copy and paste the fields below.
Profile and cover images are in `images/`. Download them from GitHub to your phone or computer first.

Steps for each Page:
1. **Page name** and **Category**: paste from below, then tap *Create Page*.
2. **Bio**: paste.
3. **Profile picture**: `images/<key>_profile.png`. **Cover photo**: `images/<key>_cover.png`.
4. Skip the contact info, then tap *Done*.
5. Go to **Settings → Username** and set the suggested username (if it's taken, add `daily`, `hq` or numbers).
6. Publish the **first post** below and pin it (⋯ → *Pin to top*).
7. Go to **Invite friends** and invite everyone. Your first 50–100 followers are what get Facebook to start showing your posts to others.

---

### 1. comedy: Daily Laughs
- **Category:** Comedy Club → if not found, use *Entertainment Website*
- **Bio:** Your daily dose of laughter 😂 Memes, jokes & relatable moments. Tag a friend who needs this!
- **Username:** `dailylaughsfun`
- **First post:** Welcome to Daily Laughs! 😂 Fresh memes and jokes every day. Comment your favourite joke below 👇 the best one gets featured!

### 2. entertainment: Showbiz Buzz
- **Category:** Entertainment Website
- **Bio:** Movies 🎬 TV 📺 Music 🎵 Stars ⭐ The biggest entertainment stories, every day.
- **Username:** `showbizbuzzdaily`
- **First post:** Welcome to Showbiz Buzz! 🎬 Which movie or show are you watching right now? Tell us below 👇

### 3. news: World Brief
- **Category:** News & Media Website
- **Bio:** The world in 60 seconds 🌍 Clear, neutral headlines from trusted sources, every day.
- **Username:** `worldbriefnews`
- **First post:** Welcome to World Brief 🌍 Short, neutral summaries of the day's biggest stories, always with a link to the original source. Follow to stay informed.

### 4. games: Game Zone
- **Category:** Gaming Video Creator → or *Video Game*
- **Bio:** 🎮 Gaming news, memes & debates. PC, console & mobile. Which side are you on?
- **Username:** `gamezonedaily`
- **First post:** Welcome to Game Zone 🎮 What game are you playing this week? Drop it below 👇

### 5. motivation: Rise & Grind Daily
- **Category:** Motivational Speaker → or *Personal Blog*
- **Bio:** Small steps. Every day. 💪 Daily motivation, mindset & discipline to help you level up.
- **Username:** `riseandgrinddaily`
- **First post:** Welcome to Rise & Grind Daily 💪 One small step today beats a perfect plan tomorrow. Type "I'M IN" if you're ready to grow with us 👇

### 6. sports: Sports Pulse
- **Category:** Sports & Recreation → or *Sports*
- **Bio:** ⚽🏏🏀 Every big moment, every day. Scores, highlights & fan debates.
- **Username:** `sportspulsedaily`
- **First post:** Welcome to Sports Pulse ⚽🏏🏀 Which team do you support? Represent in the comments 👇

### 7. tech: Tech Today
- **Category:** Science, Technology & Engineering → or *Media/News Company*
- **Bio:** 📱 Tech, gadgets & AI explained simply. Stay ahead in 1 minute a day.
- **Username:** `techtodaydaily`
- **First post:** Welcome to Tech Today 📱 What's the one app you can't live without? Tell us 👇

### 8. food: Tasty Corner
- **Category:** Food & Beverage → or *Recipe website*
- **Bio:** 🍕 Quick recipes, cravings & food fights. Warning: you will get hungry.
- **Username:** `tastycornerdaily`
- **First post:** Welcome to Tasty Corner 🍕 Settle this: pizza 🍕 or burger 🍔? Vote in the comments 👇

### 9. travel: Wander Daily
- **Category:** Travel Company → or *Travel & Transportation*
- **Bio:** ✈️ Your daily escape. Beautiful places, travel tips & dream destinations.
- **Username:** `wanderdailytravel`
- **First post:** Welcome to Wander Daily ✈️ If you could fly anywhere tomorrow, where would you go? 👇

### 10. facts: Did You Know?
- **Category:** Education Website → or *Personal Blog*
- **Bio:** 🤯 Mind-blowing (and true!) facts about science, space, history & animals. Daily.
- **Username:** `didyouknowdailyfacts`
- **First post:** Welcome to Did You Know? 🤯 Here's one to start: honey never spoils. Edible honey has been found in ancient Egyptian tombs. Share a fact you love 👇

---

## After creating the Pages: connect the bot (10 minutes, once)
1. Go to <https://developers.facebook.com/apps> → **Create app** (Business type).
2. Open the [Graph API Explorer](https://developers.facebook.com/tools/explorer/), add the permissions `pages_show_list`, `pages_read_engagement`, `pages_manage_posts` and click **Generate Access Token**.
3. Open `https://graph.facebook.com/v23.0/me/accounts?access_token=YOUR_TOKEN`. Copy each Page's `id` and `access_token` into the `FB_PAGES_JSON` GitHub secret (format in `../README.md`).
4. Merge the branch into `main`. The bot then posts by itself every hour.

## Reach checklist (do these, they matter more than post count)
- Invite all your friends to every Page on day 1.
- Share the first 2–3 posts from each Page to your own profile and to relevant Facebook Groups you belong to.
- Reply to every comment in the first few weeks. Facebook boosts posts that have conversations.
- Keep Reels in the mix; they reach non-followers.
- Turn on **Professional mode / Content monetization** once a Page qualifies (Meta shows this in *Professional dashboard*).
