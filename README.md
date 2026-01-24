# LockSmith - Lockpicking Service Addon

An automated lockpicking service addon for World of Warcraft Classic/Anniversary. Perfect for Rogues who want to offer lockpicking services efficiently!

## Features

### Core Functionality
- **Automatic Chat Monitoring** - Watches Trade, General, LFG, and Whisper channels for lockpick requests
- **Smart Box Detection** - Identifies specific junkbox/lockbox types and skill requirements
- **Expansion Detection** - Automatically detects your WoW version (Classic/TBC/Wrath/Retail) and shows only relevant boxes
- **Skill Checking** - Only notifies you of requests you can actually fulfill based on your current lockpicking skill
- **Notification Popups** - Shows player name, message, box type, required skill with action buttons
- **Session Ignore List** - Temporarily ignore spammy players for the current session (resets when addon stops)
- **Sound Alerts** - Plays a sound when a valid request is detected

### Advertisement System
- **Customizable Messages** - Edit your advertisement text with support for raid icons ({skull}, {rt1}, etc.) and special characters (♥)
- **Icon Helper** - Built-in reference showing all available icons you can use in messages
- **Multi-Channel Broadcasting** - Send ads to Trade, General, LFG, and/or Yell channels
- **Manual Send** - Click a button to broadcast your ad
- **Ad Timer** - Shows an "Ad Ready" popup at configurable intervals (30s - 10 minutes) with Send/Stop/Dismiss buttons

### Auto-Response
- **Low Skill Whispers** - Automatically whisper players when your skill is too low (toggleable)
- **Thank-You Whispers** - Optionally whisper after receiving a trade tip (2-second delay for natural timing)
- **Customizable Messages** - Edit low-skill and thank-you responses with icon support
- **Variable Support** - Use %CURRENT%, %REQUIRED%, and %TIP% placeholders
- **Icon Helper** - Shows available icons below message fields

### Tip Tracking
- **Automatic Gold Detection** - Tracks gold received from trade windows
- **Box Counting** - Counts boxes traded to you and tracks totals per box type
- **Job Grouping** - Multiple trades with the same player within 10 minutes count as one job
- **Statistics Dashboard** - View total gold, total jobs, total boxes, average tip, and session earnings
- **Persistent Stats** - Data saved between game sessions

### Raid Markers
- **Auto-Mark Self** - Automatically marks yourself with a Star when you create a party (toggleable)
- **Auto-Mark Customers** - Automatically marks customers with unique raid icons when they join your party (toggleable)
- **Icon Sequence** - Customers are marked in order: Diamond, Cross, Triangle, Moon, Square, Circle, Skull
- **Easy to Find** - Makes it simple for customers to locate you and each other in crowded areas
- **Smart Reset** - Markers reset automatically when you leave the group

### Minimap Button
- **Quick Access** - Convenient minimap button for easy access to all features
- **Draggable** - Position it anywhere around your minimap
- **Interactive** - Left-click for settings, right-click to start/stop, shift-click to advertise
- **Informative Tooltip** - Shows current status and lockpicking skill

### Universal Use
- **Works on Any Class** - Has a Start/Stop button so anyone can run it (though only Rogues can actually pick locks!)
- **Channel Customization** - Choose which channels to monitor
- **Spam Protection** - Built-in message throttling to avoid spam

## Installation

### Manual Installation
1. Download the latest release
2. Extract the `LockSmith` folder to your WoW AddOns directory:
   - Windows (Anniversary/TBC): `World of Warcraft\_anniversary_\Interface\AddOns\`
   - Windows (Classic Era): `World of Warcraft\_classic_\Interface\AddOns\`
   - Mac: `Applications/World of Warcraft/_classic_/Interface/AddOns/`
3. Restart WoW if it's currently running
4. At the character select screen, click "AddOns" and make sure LockSmith is enabled

## Usage

### Quick Start
1. Log in to your Rogue (or any character)
2. Type `/locksmith` to open the settings panel
3. Click the **Start** button to begin monitoring for requests
4. Customize your advertisement message and settings
5. Click **Send Advertisement** or enable the ad timer (popup prompt)

### Slash Commands
- `/locksmith` or `/ls` - Open settings panel
- `/locksmith start` - Start the addon
- `/locksmith stop` - Stop the addon
- `/locksmith toggle` - Toggle on/off
- `/locksmith ad` - Send advertisement to selected channels
- `/locksmith skill` - Check your current lockpicking skill
- `/locksmith stats` - View your statistics in chat
- `/locksmith minimap` - Toggle minimap button visibility

### Settings Panel

Access via `/locksmith` or through Interface Options -> AddOns -> LockSmith

**Addon Control**
- Start/Stop button
- Real-time status display with current skill level

**Channel Monitoring**
- Toggle Trade, General, LFG, and Whisper monitoring on/off
- Toggle sound effects on/off for notification popups
- Toggle auto-mark self with Star (when party leader)
- Toggle auto-mark customers with unique raid icons

**Advertisement Settings**
- Edit your advertisement message
- Choose which channels to broadcast to (Trade, General, LFG, Yell)
- Send manually or enable the ad timer (shows a ready popup; click to send)
- Use "Set Default" to restore the default message

**Auto-Response Settings**
- Toggle low-skill whispers on/off
- Toggle thank-you whispers after a tip
- Customize low-skill and thank-you messages
- Use %CURRENT%, %REQUIRED%, and %TIP% as placeholders
- Icon reference helper shows available raid icons and symbols

**Statistics**
- Total gold earned
- Total jobs completed (grouped per customer within 10 minutes)
- Total boxes opened
- Per-box counts
- Average tip per job
- Last session earnings
- Refresh and Reset buttons

## Supported Boxes

### Junkboxes
- **Battered Junkbox** (1 skill)
- **Worn Junkbox** (100 skill)
- **Sturdy Junkbox** (175 skill)
- **Heavy Junkbox** (250 skill) - Classic
- **Strong Junkbox** (300 skill) - TBC

### Lockboxes
- **Strong Iron Lockbox** (125 skill)
- **Steel Lockbox** (175 skill)
- **Reinforced Steel Lockbox** (225 skill)
- **Mithril Lockbox** (225 skill)
- **Thorium Lockbox** (225 skill) - Classic
- **Eternium Lockbox** (225 skill) - Classic
- **Khorium Lockbox** (325 skill) - TBC
- **Ironbound Locked Chest** (175 skill) - Classic
- **Reinforced Locked Chest** (250 skill) - Classic

*Note: The addon automatically detects your WoW version and shows only relevant boxes for that expansion.*

## How It Works

1. **Monitoring**: When running, LockSmith monitors your selected chat channels
2. **Detection**: When someone mentions lockpicking keywords (e.g., "lockpick", "unlock", "open box"), it analyzes the message
3. **Skill Check**: Identifies the box type and checks if your skill is sufficient
4. **Notification**: If you can help, shows a popup with the message and action buttons
5. **Response**: If your skill is too low and enabled, whispers them automatically
6. **Tracking**: Monitors trade windows for gold and box counts, then updates your statistics

## Tips for Success

- Keep the addon running while in capital cities (Trade chat only works there)
- Customize your advertisement to stand out
- Be responsive to notifications - first come, first served!
- Tips are appreciated but not required (mention this in your ad!)
- Check your stats regularly to track your earnings

## Default Messages

**Advertisement:**
```
Locksmith, Let me open your Junkbox tips appreciated!
```

**Low Skill Response:**
```
Sorry, my lockpicking skill (%CURRENT%) is too low for that box (requires %REQUIRED%)
```

**Thank-You Response:**
```
Thank you for the %TIP% tip! ♥
```

**Available Icons:**
You can use these in your messages to make them stand out:
- Raid markers: `{rt1}` `{rt2}` `{rt3}` `{rt4}` `{rt5}` `{rt6}` `{rt7}` `{rt8}`
- Named icons: `{skull}` `{circle}` `{diamond}` `{triangle}` `{moon}` `{square}` `{cross}` `{star}`
- Special: `♥` (heart)

Example: `{skull} Locksmith - Fast service - Tips welcome! {skull}`

All messages are fully customizable in the settings panel!

## Troubleshooting

**Addon not loading?**
- Make sure it's enabled at character select screen
- Check that all files are in the correct folder

**Not seeing notifications?**
- Make sure the addon is Started (green status)
- Check that you're monitoring the correct channels
- Verify your lockpicking skill is high enough

**Advertisements not sending?**
- Trade channel only works in capital cities
- Check that you've selected at least one channel
- The ad timer only shows a ready popup; click Send to post (protected chat rules)
- Make sure you're not in a LFG/raid group (some channels are restricted)

**Stats not tracking?**
- Gold tracking only works from direct trades (not mail)
- Box counting only works for boxes traded to you
- Jobs are grouped per customer within 10 minutes
- Make sure the addon is running when you receive gold
- Click "Refresh Stats" to update the display

## Version

**Current Version:** 1.0.0

## Author

Created for World of Warcraft Classic/Anniversary Edition

Enjoy your lockpicking business!
