# LockSmith - Lockpicking Service Addon

An automated lockpicking service addon for World of Warcraft Classic/Anniversary. Perfect for Rogues who want to offer lockpicking services efficiently!

## Features

### Core Functionality
- **Automatic Chat Monitoring** - Watches Trade, General, LFG, and Whisper channels for lockpick requests
- **Smart Box Detection** - Identifies specific junkbox/lockbox types and skill requirements
- **Skill Checking** - Only notifies you of requests you can actually fulfill based on your current lockpicking skill
- **Notification Popups** - Shows player name, box type, required skill with Invite/Whisper/Ignore buttons
- **Sound Alerts** - Plays a sound when a valid request is detected

### Advertisement System
- **Customizable Messages** - Edit your advertisement text
- **Multi-Channel Broadcasting** - Send ads to Trade, General, and/or LFG channels
- **Manual Send** - Click a button to broadcast your ad
- **Auto-Timer** - Automatically send ads at configurable intervals (30s - 10 minutes)

### Auto-Response
- **Low Skill Whispers** - Automatically whisper players when your skill is too low (toggleable)
- **Customizable Message** - Edit the low-skill response message
- **Variable Support** - Use %CURRENT% and %REQUIRED% placeholders

### Tip Tracking
- **Automatic Gold Detection** - Tracks gold received from trade windows
- **Statistics Dashboard** - View total gold, total jobs, average tip, and session earnings
- **Persistent Stats** - Data saved between game sessions

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
   - Windows: `World of Warcraft\_classic_\Interface\AddOns\`
   - Mac: `Applications/World of Warcraft/_classic_/Interface/AddOns/`
3. Restart WoW if it's currently running
4. At the character select screen, click "AddOns" and make sure LockSmith is enabled

## Usage

### Quick Start
1. Log in to your Rogue (or any character)
2. Type `/locksmith` to open the settings panel
3. Click the **Start** button to begin monitoring for requests
4. Customize your advertisement message and settings
5. Click **Send Advertisement** or enable the auto-timer

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

Access via `/locksmith` or through Interface Options → AddOns → LockSmith

**Addon Control**
- Start/Stop button
- Real-time status display with current skill level

**Channel Monitoring**
- Toggle Trade, General, LFG, and Whisper monitoring on/off

**Advertisement Settings**
- Edit your advertisement message
- Choose which channels to broadcast to
- Send manually or enable auto-timer (default 1 minute, adjustable)

**Auto-Response Settings**
- Toggle low-skill whispers on/off
- Customize the message sent when your skill is too low
- Use %CURRENT% and %REQUIRED% as placeholders

**Statistics**
- Total gold earned
- Total jobs completed
- Average tip per job
- Last session earnings
- Refresh and Reset buttons

## Supported Boxes

### Junkboxes
- **Battered Junkbox** (1 skill)
- **Worn Junkbox** (100 skill)
- **Sturdy Junkbox** (175 skill)
- **Heavy Junkbox** (250 skill)

### Lockboxes
- **Strong Iron Lockbox** (125 skill)
- **Steel Lockbox** (175 skill)
- **Reinforced Steel Lockbox** (225 skill)
- **Mithril Lockbox** (225 skill)
- **Thorium Lockbox** (225 skill)
- **Ironbound Locked Chest** (175 skill)
- **Reinforced Locked Chest** (250 skill)

## How It Works

1. **Monitoring**: When running, LockSmith monitors your selected chat channels
2. **Detection**: When someone mentions lockpicking keywords (e.g., "lockpick", "unlock", "open box"), it analyzes the message
3. **Skill Check**: Identifies the box type and checks if your skill is sufficient
4. **Notification**: If you can help, shows a popup with player info and action buttons
5. **Response**: If your skill is too low and enabled, whispers them automatically
6. **Tracking**: Monitors trade windows for gold received and updates your statistics

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
Sorry, my lockpicking skill (X) is too low for that box (requires Y)
```

Both messages are fully customizable in the settings panel!

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
- Make sure you're not in a LFG/raid group (some channels are restricted)

**Stats not tracking?**
- Gold tracking only works from direct trades (not mail)
- Make sure the addon is running when you receive gold
- Click "Refresh Stats" to update the display

## Version

**Current Version:** 1.0.0

## Author

Created for World of Warcraft Classic/Anniversary Edition

Enjoy your lockpicking business!
