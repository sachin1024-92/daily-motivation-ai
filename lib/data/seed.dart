import 'package:flutter/painting.dart';
import 'package:daily_motivation_ai/models/chat.dart';
import 'package:daily_motivation_ai/models/media_art.dart';
import 'package:daily_motivation_ai/models/post.dart';
import 'package:daily_motivation_ai/models/reel.dart';
import 'package:daily_motivation_ai/models/story.dart';
import 'package:daily_motivation_ai/models/user.dart';
import 'package:daily_motivation_ai/models/video.dart';

// Demo content so Orbit is fully usable offline. Every person and channel
// here is fictional. Swap these functions for a real backend (Firebase,
// Supabase, your own API) without touching the UI: providers only depend on
// the model classes.

const String meId = 'me';
const String orbitAiId = 'orbit-ai';
const String myChannelId = 'c-my-channel';

DateTime _ago({int d = 0, int h = 0, int m = 0}) => DateTime.now().subtract(Duration(days: d, hours: h, minutes: m));

MediaArt _art(int palette, String emoji, [int seed = 0]) =>
    MediaArt(colors: artPalettes[palette % artPalettes.length], emoji: emoji, seed: seed);

const OrbitUser seedMe = OrbitUser(
  id: meId,
  name: 'Sachin',
  handle: 'sachin',
  bio: 'Building in public · PhD life · 1% better every day 🌱',
  colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
  online: true,
  followers: 1284,
  following: 312,
);

const Map<String, OrbitUser> seedUsers = {
  'aisha': OrbitUser(
    id: 'aisha',
    name: 'Aisha Khan',
    handle: 'aisha.creates',
    bio: 'Photographer · chasing golden hour 📸',
    colors: [Color(0xFFFF512F), Color(0xFFF09819)],
    verified: true,
    online: true,
    followers: 48200,
    following: 530,
  ),
  'leo': OrbitUser(
    id: 'leo',
    name: 'Leo Martins',
    handle: 'leo.codes',
    bio: 'Flutter dev · open source · too much coffee ☕',
    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
    online: true,
    followers: 8900,
    following: 410,
  ),
  'mei': OrbitUser(
    id: 'mei',
    name: 'Mei Tanaka',
    handle: 'meitravels',
    bio: '47 countries and counting 🌏 · slow travel',
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    verified: true,
    followers: 312000,
    following: 220,
  ),
  'rohan': OrbitUser(
    id: 'rohan',
    name: 'Rohan Iyer',
    handle: 'rohan.fit',
    bio: 'Coach · 5am club · mobility nerd 🏋️',
    colors: [Color(0xFFEE0979), Color(0xFFFF6A00)],
    followers: 21400,
    following: 380,
  ),
  'zara': OrbitUser(
    id: 'zara',
    name: 'Zara Okafor',
    handle: 'zara.sounds',
    bio: 'Singer-songwriter · new single out now 🎶',
    colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    verified: true,
    online: true,
    followers: 128000,
    following: 610,
  ),
  'nia': OrbitUser(
    id: 'nia',
    name: 'Nia Brooks',
    handle: 'chefnia',
    bio: '15-minute meals for busy humans 🍜',
    colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
    followers: 67000,
    following: 290,
  ),
  'techpulse': OrbitUser(
    id: 'techpulse',
    name: 'TechPulse',
    handle: 'techpulse',
    bio: 'Daily tech in 60 seconds ⚡',
    colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
    verified: true,
    followers: 904000,
    following: 12,
  ),
  orbitAiId: OrbitUser(
    id: orbitAiId,
    name: 'Orbit AI',
    handle: 'orbit.ai',
    bio: 'Your AI coach inside every chat — motivation, plans and captions ✨',
    colors: [Color(0xFF7C4DFF), Color(0xFF40C4FF)],
    verified: true,
    online: true,
    isBot: true,
    followers: 1000000,
  ),
};

Set<String> seedFollowing() => {'aisha', 'leo', 'mei', 'zara', 'techpulse'};

List<Post> seedPosts() => [
      Post(
        id: 'p1',
        authorId: 'mei',
        text: 'Sunrise over Kyoto from the Fushimi Inari trail. Worth the 4:30am alarm, every single time. 🌅',
        createdAt: _ago(m: 42),
        art: _art(1, '🌅', 3),
        location: 'Kyoto, Japan',
        reactions: const {'❤️': 2140, '🔥': 380, '😮': 91},
        comments: [
          Comment(id: 'c1', authorId: 'aisha', text: 'The colours here are unreal 😍', at: _ago(m: 30)),
          Comment(id: 'c2', authorId: 'rohan', text: 'That stair climb is a leg day on its own', at: _ago(m: 12)),
        ],
        shares: 87,
      ),
      Post(
        id: 'p2',
        authorId: 'leo',
        text: 'Hot take: the best feature you can ship this week is deleting one you never should have built. 🧹\n\nWhat did you delete recently?',
        createdAt: _ago(h: 2),
        reactions: const {'👏': 312, '😂': 44, '❤️': 120},
        comments: [
          Comment(id: 'c3', authorId: 'zara', text: 'Deleted 3 unfinished songs. Felt amazing honestly', at: _ago(h: 1)),
        ],
        shares: 23,
      ),
      Post(
        id: 'p3',
        authorId: 'zara',
        text: 'Which cover should the new single get? Vote below 👇',
        createdAt: _ago(h: 3),
        art: _art(4, '🎧', 5),
        poll: const [PollOption('Neon night 🌃', 812), PollOption('Golden hour 🌇', 604), PollOption('Monochrome 🖤', 233)],
        reactions: const {'❤️': 4200, '🔥': 900},
        shares: 140,
      ),
      Post(
        id: 'p4',
        authorId: 'nia',
        text: '15-minute miso ramen: soft egg, crispy garlic, charred corn. Recipe is pinned in my channel. 🍜',
        createdAt: _ago(h: 5),
        art: _art(6, '🍜', 7),
        location: 'Home kitchen',
        reactions: const {'❤️': 980, '😮': 40, '🔥': 210},
        comments: [
          Comment(id: 'c4', authorId: 'leo', text: 'Making this tonight', at: _ago(h: 4)),
        ],
        shares: 66,
      ),
      Post(
        id: 'p5',
        authorId: 'rohan',
        text: 'Mobility check: can you touch your toes with straight legs? No shame either way — just start where you are. 🧘',
        createdAt: _ago(h: 8),
        art: _art(3, '🏃', 9),
        poll: const [PollOption('Easily', 140), PollOption('Almost there', 380), PollOption('Not even close 😅', 510)],
        reactions: const {'👏': 260, '😂': 120},
      ),
      Post(
        id: 'p6',
        authorId: 'aisha',
        text: 'Blue hour > golden hour. Change my mind. 💙',
        createdAt: _ago(h: 11),
        art: _art(2, '🌊', 11),
        location: 'Lisbon, Portugal',
        reactions: const {'❤️': 6100, '😮': 300, '🔥': 740},
        comments: [
          Comment(id: 'c5', authorId: 'mei', text: 'Cannot and will not change your mind', at: _ago(h: 10)),
          Comment(id: 'c6', authorId: 'zara', text: 'This could be an album cover', at: _ago(h: 9)),
        ],
        shares: 402,
      ),
      Post(
        id: 'p7',
        authorId: 'techpulse',
        text: 'On-device AI just crossed a big line: full chat assistants now run on mid-range phones with no network. Privacy wins. ⚡',
        createdAt: _ago(d: 1, h: 1),
        art: _art(7, '🚀', 13),
        reactions: const {'🔥': 12000, '😮': 3100, '👏': 2200},
        shares: 5400,
      ),
    ];

List<StoryGroup> seedStories() => [
      StoryGroup(userId: 'aisha', frames: [
        StoryFrame(id: 's1', art: _art(1, '📸', 21), caption: 'Behind the scenes of today\'s shoot', at: _ago(h: 1)),
        StoryFrame(id: 's2', art: _art(8, '🌇', 22), caption: 'Golden hour, as promised', at: _ago(m: 20)),
      ]),
      StoryGroup(userId: 'mei', frames: [
        StoryFrame(id: 's3', art: _art(3, '🏔️', 23), caption: 'Day 3 in the Alps. No signal, no problem', at: _ago(h: 3)),
      ]),
      StoryGroup(userId: 'zara', frames: [
        StoryFrame(id: 's4', art: _art(4, '🎤', 24), caption: 'Studio night 🎶 new single Friday', at: _ago(h: 2)),
        StoryFrame(id: 's5', art: _art(0, '🎧', 25), caption: 'Guess the bpm 👀', at: _ago(h: 1)),
      ]),
      StoryGroup(userId: 'leo', frames: [
        StoryFrame(id: 's6', art: _art(2, '💻', 26), caption: 'Shipped it. Going to sleep for a week', at: _ago(h: 6)),
      ]),
      StoryGroup(userId: 'rohan', seen: true, frames: [
        StoryFrame(id: 's7', art: _art(8, '🏃', 27), caption: '5km before sunrise ✅', at: _ago(h: 9)),
      ]),
      StoryGroup(userId: 'nia', seen: true, frames: [
        StoryFrame(id: 's8', art: _art(6, '🍳', 28), caption: 'Tomorrow: 3-ingredient breakfast', at: _ago(h: 12)),
      ]),
    ];

List<Reel> seedReels() => [
      Reel(
        id: 'r1',
        authorId: 'zara',
        caption: 'Stripped-back version of the new single 🎶 #acoustic #newmusic',
        audio: 'Zara Okafor · Midnight Orbit',
        art: _art(4, '🎸', 31),
        likes: 48200,
        shares: 2100,
        views: 910000,
        comments: [Comment(id: 'rc1', authorId: 'aisha', text: 'Chills. Actual chills.', at: _ago(h: 2))],
      ),
      Reel(
        id: 'r2',
        authorId: 'nia',
        caption: 'Garlic chilli oil in 60 seconds 🌶️ #15minutemeals',
        audio: 'Original audio · chefnia',
        art: _art(8, '🌶️', 32),
        likes: 31000,
        shares: 5400,
        views: 640000,
      ),
      Reel(
        id: 'r3',
        authorId: 'mei',
        caption: 'POV: you took the slow train through the Swiss Alps 🚆 #slowtravel',
        audio: 'Lo-fi Travel Beats',
        art: _art(3, '🚆', 33),
        likes: 120000,
        shares: 8800,
        views: 2400000,
      ),
      Reel(
        id: 'r4',
        authorId: 'rohan',
        caption: '3 moves to undo a day of sitting 🧘 save this for later',
        audio: 'Morning Energy Mix',
        art: _art(9, '🧘', 34),
        likes: 22000,
        shares: 6300,
        views: 380000,
      ),
      Reel(
        id: 'r5',
        authorId: 'techpulse',
        caption: 'The phone that folds three times — first look ⚡ #tech',
        audio: 'TechPulse Theme',
        art: _art(5, '📱', 35),
        likes: 88000,
        shares: 12000,
        views: 3100000,
      ),
      Reel(
        id: 'r6',
        authorId: 'aisha',
        caption: 'One lens, one street, one hour 📸 #streetphotography',
        audio: 'Cinematic Piano',
        art: _art(2, '📷', 36),
        likes: 54000,
        shares: 1900,
        views: 720000,
      ),
    ];

List<Video> seedVideos() => [
      Video(
        id: 'v1',
        channelId: 'techpulse',
        title: 'I used only on-device AI for 30 days — here\'s what happened',
        description: 'No cloud, no network, just the phone in my pocket. We test chat, photos, translation and battery life.',
        category: 'Tech',
        durationSeconds: 14 * 60 + 32,
        views: 1840000,
        likes: 92000,
        uploadedAt: _ago(d: 2),
        art: _art(7, '🤖', 41),
        comments: [Comment(id: 'vc1', authorId: 'leo', text: 'The battery section was eye-opening', at: _ago(d: 1))],
      ),
      Video(
        id: 'v2',
        channelId: 'zara',
        title: 'Midnight Orbit (Official Live Session)',
        description: 'Recorded in one take at the rooftop studio. Stream the single everywhere Friday.',
        category: 'Music',
        durationSeconds: 4 * 60 + 5,
        views: 2600000,
        likes: 310000,
        uploadedAt: _ago(d: 5),
        art: _art(4, '🎤', 42),
      ),
      Video(
        id: 'v3',
        channelId: 'rohan',
        title: '20-minute full body mobility (no equipment)',
        description: 'Follow along every morning for two weeks and feel the difference.',
        category: 'Fitness',
        durationSeconds: 20 * 60 + 11,
        views: 530000,
        likes: 28000,
        uploadedAt: _ago(d: 9),
        art: _art(9, '🧘', 43),
      ),
      Video(
        id: 'v4',
        channelId: 'nia',
        title: '5 dinners, 1 grocery bag, under 15 minutes each',
        description: 'Meal prep without the prep. Shopping list in the channel.',
        category: 'Food',
        durationSeconds: 11 * 60 + 48,
        views: 890000,
        likes: 51000,
        uploadedAt: _ago(d: 3),
        art: _art(6, '🥘', 44),
      ),
      Video(
        id: 'v5',
        channelId: 'mei',
        title: 'Japan on a budget: 10 days, every cost explained',
        description: 'Rail passes, capsule hotels, konbini breakfasts and the one splurge worth it.',
        category: 'Travel',
        durationSeconds: 26 * 60 + 3,
        views: 4100000,
        likes: 240000,
        uploadedAt: _ago(d: 14),
        art: _art(1, '🗾', 45),
      ),
      Video(
        id: 'v6',
        channelId: 'leo',
        title: 'Build a chat app in Flutter in 30 minutes',
        description: 'Riverpod, clean models and a UI you\'d actually ship. Source in the description.',
        category: 'Tech',
        durationSeconds: 31 * 60 + 40,
        views: 210000,
        likes: 15000,
        uploadedAt: _ago(d: 1),
        art: _art(2, '💙', 46),
      ),
      Video(
        id: 'v7',
        channelId: orbitAiId,
        title: 'The 2-minute rule: start any habit today',
        description: 'Make it so small you can\'t say no. A tiny guide to momentum.',
        category: 'Mindset',
        durationSeconds: 6 * 60 + 12,
        views: 760000,
        likes: 61000,
        uploadedAt: _ago(d: 4),
        art: _art(0, '🌱', 47),
      ),
      Video(
        id: 'v8',
        channelId: 'aisha',
        title: 'Phone photography masterclass: light is everything',
        description: 'Find, shape and chase light with just your phone camera.',
        category: 'Travel',
        durationSeconds: 18 * 60 + 27,
        views: 980000,
        likes: 74000,
        uploadedAt: _ago(d: 6),
        art: _art(8, '📸', 48),
      ),
    ];

List<Chat> seedChats() => [
      Chat(
        id: 'c-orbit-ai',
        kind: ChatKind.bot,
        title: 'Orbit AI',
        peerId: orbitAiId,
        pinned: true,
        description: 'Your AI coach. Ask for motivation, a plan for today, or caption ideas.',
        messages: [
          Message(
            id: 'm-ai-1',
            senderId: orbitAiId,
            text: 'Hey! I\'m Orbit AI ✨ I can hype you up, plan your day, or write captions for your next post. What are we working on?',
            sentAt: _ago(h: 1),
          ),
        ],
      ),
      Chat(
        id: 'c-aisha',
        kind: ChatKind.direct,
        title: 'Aisha Khan',
        peerId: 'aisha',
        unread: 2,
        messages: [
          Message(id: 'm1', senderId: meId, text: 'Your Lisbon set is unreal. What lens?', sentAt: _ago(h: 3, m: 10)),
          Message(id: 'm2', senderId: 'aisha', text: '35mm the whole trip! Travel light 😄', sentAt: _ago(h: 3)),
          Message(
            id: 'm3',
            senderId: 'aisha',
            text: 'Also you NEED to see this',
            sentAt: _ago(m: 14),
            attachment: SharedRef(
              kind: SharedKind.reel,
              id: 'r3',
              ownerId: 'mei',
              title: 'POV: you took the slow train through the Swiss Alps 🚆',
              art: _art(3, '🚆', 33),
            ),
          ),
          Message(id: 'm4', senderId: 'aisha', text: 'Hiking trip this weekend? 🏔️', sentAt: _ago(m: 12)),
        ],
      ),
      Chat(
        id: 'c-hikers',
        kind: ChatKind.group,
        title: 'Weekend Hikers 🏔️',
        art: _art(3, '🏔️', 51),
        memberIds: const [meId, 'mei', 'rohan', 'leo'],
        description: 'Trails, snacks and questionable navigation.',
        unread: 3,
        messages: [
          Message(id: 'm5', senderId: 'rohan', text: 'Saturday 6am at the trailhead?', sentAt: _ago(h: 5)),
          Message(id: 'm6', senderId: meId, text: 'I\'m in! Bringing coffee ☕', sentAt: _ago(h: 4, m: 50), reactions: const ['🔥', '❤️']),
          Message(id: 'm7', senderId: 'mei', text: 'Weather says sunny with a small chance of rain', sentAt: _ago(h: 1)),
          Message(id: 'm8', senderId: 'leo', text: '6am is a crime but ok 😂', sentAt: _ago(m: 40)),
          Message(id: 'm9', senderId: 'rohan', text: 'Don\'t forget layers!', sentAt: _ago(m: 35)),
        ],
      ),
      Chat(
        id: 'c-techpulse',
        kind: ChatKind.channel,
        title: 'TechPulse Daily ⚡',
        art: _art(7, '⚡', 52),
        ownerId: 'techpulse',
        subscribers: 128400,
        unread: 2,
        description: 'The day\'s tech news in 60 seconds. Broadcast channel.',
        messages: [
          Message(id: 'm10', senderId: 'techpulse', text: 'Good morning! 3 stories you need today 👇', sentAt: _ago(h: 6), views: 81200, reactions: const ['👏', '🔥']),
          Message(
            id: 'm11',
            senderId: 'techpulse',
            text: '1/ Tri-fold phones are real and they\'re shipping next month.',
            sentAt: _ago(h: 5, m: 58),
            views: 79400,
            attachment: SharedRef(
              kind: SharedKind.reel,
              id: 'r5',
              ownerId: 'techpulse',
              title: 'The phone that folds three times — first look ⚡',
              art: _art(5, '📱', 35),
            ),
          ),
          Message(
            id: 'm12',
            senderId: 'techpulse',
            text: 'New video: 30 days of on-device AI 🤖',
            sentAt: _ago(h: 2),
            views: 64100,
            reactions: const ['🔥', '🔥', '😮'],
            attachment: SharedRef(
              kind: SharedKind.video,
              id: 'v1',
              ownerId: 'techpulse',
              title: 'I used only on-device AI for 30 days — here\'s what happened',
              art: _art(7, '🤖', 41),
            ),
          ),
        ],
      ),
      Chat(
        id: 'c-leo',
        kind: ChatKind.direct,
        title: 'Leo Martins',
        peerId: 'leo',
        messages: [
          Message(id: 'm13', senderId: 'leo', text: 'Did you try the new Riverpod version?', sentAt: _ago(d: 1, h: 2)),
          Message(id: 'm14', senderId: meId, text: 'Yes! Migrating my side project this week 🚀', sentAt: _ago(d: 1, h: 1)),
        ],
      ),
      Chat(
        id: 'c-mindful',
        kind: ChatKind.channel,
        title: 'Mindful Mornings 🌅',
        art: _art(0, '🌅', 53),
        ownerId: orbitAiId,
        subscribers: 56000,
        muted: true,
        description: 'One calm thought every morning. No noise.',
        messages: [
          Message(
            id: 'm15',
            senderId: orbitAiId,
            text: 'Today\'s thought: you don\'t need more time, you need fewer tabs open — in your browser and your head. 🌿',
            sentAt: _ago(h: 7),
            views: 33000,
            reactions: const ['❤️', '🙏'],
          ),
        ],
      ),
      Chat(
        id: 'c-builders',
        kind: ChatKind.group,
        title: 'Flutter Builders 💙',
        art: _art(2, '💙', 54),
        memberIds: const [meId, 'leo', 'aisha', 'zara'],
        description: 'Ship small, ship often.',
        messages: [
          Message(id: 'm16', senderId: 'leo', text: 'Demo day next Thursday — who\'s presenting?', sentAt: _ago(d: 2)),
          Message(id: 'm17', senderId: 'zara', text: 'Me! Building a lyrics app 🎶', sentAt: _ago(d: 2)),
        ],
      ),
      Chat(
        id: myChannelId,
        kind: ChatKind.channel,
        title: 'Sachin\'s Updates',
        art: _art(0, '🚀', 55),
        ownerId: meId,
        subscribers: 214,
        description: 'Building in public. Broadcasts from the Orbit composer land here.',
        messages: [
          Message(id: 'm18', senderId: meId, text: 'Welcome to my channel! Weekly progress updates, every Sunday. 🚀', sentAt: _ago(d: 3), views: 198),
        ],
      ),
      Chat(
        id: 'c-foodies',
        kind: ChatKind.channel,
        title: 'Foodies Unite 🍜',
        art: _art(6, '🍜', 56),
        ownerId: 'nia',
        subscribers: 41200,
        joined: false,
        description: 'Quick recipes from @chefnia, every weekday.',
        messages: [
          Message(id: 'm19', senderId: 'nia', text: 'Tonight: 15-minute miso ramen 🍜 full recipe below.', sentAt: _ago(h: 5), views: 22000),
        ],
      ),
      Chat(
        id: 'c-travel',
        kind: ChatKind.channel,
        title: 'Slow Travel Club ✈️',
        art: _art(1, '✈️', 57),
        ownerId: 'mei',
        subscribers: 88300,
        joined: false,
        description: 'Deals, routes and hidden gems from @meitravels.',
        messages: [
          Message(id: 'm20', senderId: 'mei', text: 'Rail pass prices drop next week — set a reminder!', sentAt: _ago(h: 20), views: 51000),
        ],
      ),
    ];

enum ActivityType { like, comment, follow, mention, milestone }

class ActivityItem {
  final String id;
  final ActivityType type;
  final String actorId;
  final String text;
  final DateTime at;
  final bool read;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.actorId,
    required this.text,
    required this.at,
    this.read = false,
  });

  ActivityItem markRead() => ActivityItem(id: id, type: type, actorId: actorId, text: text, at: at, read: true);
}

List<ActivityItem> seedActivity() => [
      ActivityItem(id: 'a1', type: ActivityType.follow, actorId: 'zara', text: 'started following you', at: _ago(m: 25)),
      ActivityItem(id: 'a2', type: ActivityType.like, actorId: 'aisha', text: 'and 23 others reacted ❤️ to your post', at: _ago(h: 1)),
      ActivityItem(id: 'a3', type: ActivityType.comment, actorId: 'leo', text: 'commented: "This is the way 🙌"', at: _ago(h: 2)),
      ActivityItem(id: 'a4', type: ActivityType.mention, actorId: 'mei', text: 'mentioned you in Weekend Hikers 🏔️', at: _ago(h: 4), read: true),
      ActivityItem(id: 'a5', type: ActivityType.milestone, actorId: orbitAiId, text: 'Your channel just passed 200 subscribers 🎉', at: _ago(d: 1), read: true),
    ];
