# LockSmithPro - Changelog

## Version 1.0.0 - Initial Release

### New Features
- **Intelligent Chat Monitoring** - Automatic detection of lockpicking requests across Trade, General, LFG, and Whisper channels
- **Language-Independent Box Detection** - Recognizes all junkbox and lockbox types regardless of phrasing
- **Smart Skill Checking** - Only notifies for requests you can fulfill based on current skill level
- **Professional Advertisement System** - Customizable messages with raid icons, multi-channel broadcasting, and timer support
- **Automated Response System** - Automatic whispers for low skill situations and thank-you messages after tips
- **Advanced Earnings Tracking** - Automatic gold detection, box counting, job grouping, and session statistics
- **Smart Raid Markers** - Auto-mark self with Star and customers with unique raid icons
- **Professional Dashboard UI** - Persistent window with Job Board, Settings, and Statistics tabs
- **Notification Popups** - Beautiful WoW-style popups with player name, box type, and required skill
- **Minimap Button** - Draggable icon with multiple interaction modes
- **Session Ignore List** - Temporarily ignore spammy players
- **Include/Exclude Keyword Filters** - Customize what triggers notifications
- **Variable Substitution** - Use %CURRENT%, %REQUIRED%, and %TIP% in messages
- **Cross-Version Compatibility** - Works on Classic Era, TBC, Wrath, and Retail

### Technical Details
- Event-driven architecture for efficient chat monitoring
- Persistent data storage with SavedVariables
- Smart caching and message throttling
- Comprehensive database of all box types with skill requirements
- Automatic expansion detection

### Supported Boxes
- **Junkboxes (7 total)**: Battered (1), Worn (100), Sturdy (175), Heavy (250), Strong (300), Reinforced (350), Flame-Scarred (400)
- **Lockboxes (17 total)**: Strong Iron (125), Steel (175), Reinforced Steel (225), Mithril (225), Thorium (225), Eternium (225), Khorium (325), Froststeel (375), Titanium (400), Elementium (425), Ghost Iron (450), True Steel (500), Leystone (550), Barnacled (600), Synvir (SL), Oxxein (SL), Bismuth (80)
- **Locked Chests (2 total)**: Ironbound (175), Reinforced (250)
- **Expansion Detection**: Automatically shows only relevant boxes for Classic Era, TBC, Wrath, Cata, MoP, WoD, Legion, BFA, Shadowlands, Dragonflight, and War Within
- **Total Database**: 26 different box types across all WoW expansions

### Known Limitations
- Trade channel only works in capital cities
- Gold tracking only works from direct trades (not mail)
- Ad timer requires manual click to send (WoW chat protection)
- Jobs are grouped within 10-minute windows with same player

---
