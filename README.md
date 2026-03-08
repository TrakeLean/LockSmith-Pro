# LockSmithPro - Professional Lockpicking Service Addon

![Available on CurseForge](https://img.shields.io/badge/Available_on-CurseForge-6441A4?style=flat&logo=curseforge)
![Version](https://img.shields.io/badge/Version-1.0.1-brightgreen)
![WoW Compatibility](https://img.shields.io/badge/WoW-Classic%20Era%20|%20TBC%20|%20Wrath%20|%20Retail-blue)

**The ultimate lockpicking business automation addon for World of Warcraft!** Transform your Rogue into a professional locksmith with automatic chat monitoring, smart notifications, comprehensive earnings tracking, and powerful automation tools. Built for maximum efficiency and ease of use across all WoW versions.

Available for download at [CurseForge](https://www.curseforge.com/wow/addons/locksmithpro).

![LockSmithPro Dashboard](https://via.placeholder.com/800x450.png?text=LockSmithPro+Dashboard+Screenshot)

## 🎲 Core Features

### **🔍 Intelligent Chat Monitoring**
- **Multi-channel detection** - Automatically monitors Trade, General, LFG, and Whisper channels
- **Language-independent box detection** - Recognizes lockbox requests regardless of phrasing
- **Smart skill checking** - Only notifies you of requests you can actually fulfill
- **Include/exclude keyword filters** - Customize what triggers notifications
- **Session ignore list** - Temporarily ignore spammy players (resets when addon stops)
- **Recent trade partner tracking** - Prevents duplicate notifications from the same customer

### **📢 Professional Advertisement System**
- **Customizable messages** - Full support for raid icons ({skull}, {rt1}, etc.) and special characters (♥)
- **Multi-channel broadcasting** - Send ads to Trade, General, LFG, and/or Yell channels
- **Automatic timer mode** - Get "Ad Ready" popups at configurable intervals (30s - 10 minutes)
- **Manual send option** - One-click broadcast whenever you want
- **Icon helper reference** - Built-in guide showing all available icons and symbols
- **Spell link support** - Include your lockpicking spell in advertisements

### **💬 Automated Response System**
- **Low skill whispers** - Automatically notify players when your skill is too low (fully toggleable)
- **Thank-you whispers** - Optional automatic thank-you messages after receiving tips (2-second delay)
- **Variable substitution** - Use %CURRENT%, %REQUIRED%, and %TIP% placeholders
- **Customizable messages** - Edit all auto-response text with raid icon support
- **Smart timing** - Natural message delays to avoid appearing robotic

### **💰 Advanced Earnings Tracking**
- **Automatic gold detection** - Tracks gold received from trade windows in real-time
- **Smart box counting** - Tracks both boxes traded to you AND boxes unlocked in-window (slot 7)
- **In-window unlock tracking** - Counts Pick Lock spell casts during active trades
- **Job grouping** - Multiple trades with same player within 10 minutes = one job
- **Session statistics** - Separate tracking for current session vs. all-time
- **Per-box analytics** - See which box types you open most frequently
- **Average tip calculation** - Know your typical earnings per job
- **Persistent data** - All stats saved between game sessions

### **🎯 Smart Raid Markers**
- **Auto-mark self** - Automatically place Star marker when you create a party
- **Auto-mark customers** - Assign unique raid icons to customers as they join (Diamond, Cross, Triangle, Moon, Square, Circle, Skull)
- **Easy location** - Makes finding customers simple in crowded areas
- **Smart reset** - Markers automatically clear when group disbands
- **Fully toggleable** - Enable/disable independently for self and customers

### **🎨 Professional Interface**
- **Persistent dashboard** - Main UI with Job Board, Settings, and Statistics tabs
- **Notification popups** - Beautiful WoW-style popups with player name, box type, and required skill
- **Minimap button** - Draggable icon with multiple interaction modes
  - Left-click: Open settings
  - Right-click: Start/Stop monitoring
  - Shift-click: Send advertisement
- **Informative tooltips** - Shows current status and lockpicking skill
- **Sound alerts** - Customizable audio notifications for new requests

### **⚙️ Smart Automation**
- **Works on any class** - Start/Stop button allows anyone to run it (though only Rogues can pick locks!)
- **Expansion detection** - Automatically detects WoW version and shows only relevant boxes
- **Spam protection** - Built-in message throttling and invite cooldowns
- **Channel customization** - Choose which channels to monitor
- **Cross-version compatibility** - Seamless operation on Classic Era, TBC, Wrath, and Retail

## 🚀 Quick Start

1. Type `/locksmith` or `/ls` to open the dashboard
2. Click the **Start** button to begin monitoring chat channels
3. Customize your advertisement message in Settings tab
4. Click **Send Advertisement** or enable the ad timer for automatic prompts
5. Accept requests from notification popups and start earning!

## 📥 Installation

### CurseForge (Recommended)
1. Visit [LockSmithPro on CurseForge](https://www.curseforge.com/wow/addons/locksmithpro)
2. Download via CurseForge app or manual download
3. The addon will be automatically installed to the correct location

### Manual Installation
1. Download the latest release from CurseForge
2. Extract the `LockSmithPro` folder to your WoW AddOns directory:
   - **Windows (Classic Era):** `World of Warcraft\_classic_\Interface\AddOns\`
   - **Windows (TBC/Wrath):** `World of Warcraft\_classic_\Interface\AddOns\`
   - **Windows (Retail):** `World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac:** `Applications/World of Warcraft/_classic_/Interface/AddOns/`
3. Restart WoW if currently running
4. At character select, click **AddOns** and ensure LockSmithPro is enabled

## 📋 Commands

- **`/locksmith`** or **`/ls`** - Open dashboard
- **`/locksmith start`** - Start monitoring
- **`/locksmith stop`** - Stop monitoring
- **`/locksmith toggle`** - Toggle on/off
- **`/locksmith ad`** - Send advertisement to selected channels
- **`/locksmith skill`** - Check current lockpicking skill
- **`/locksmith stats`** - View statistics in chat
- **`/locksmith minimap`** - Toggle minimap button visibility

## 🎨 Dashboard Navigation

Access via `/locksmith` or click the minimap button

### **Job Board Tab**
- **Active job tracking** - See current lockpicking requests
- **Job history** - View recent completed jobs
- **Quick actions** - Accept, ignore, or invite from the board
- **Status overview** - Current monitoring state and skill level

### **Settings Tab**
- **Addon Control** - Start/Stop button with real-time status
- **Channel Monitoring** - Toggle Trade, General, LFG, and Whisper channels
- **Sound Effects** - Enable/disable audio notifications
- **Raid Markers** - Auto-mark self with Star and customers with unique icons
- **Advertisement** - Edit message, choose channels, enable timer
- **Auto-Response** - Configure low-skill and thank-you whispers
- **Variable Support** - Use %CURRENT%, %REQUIRED%, and %TIP% placeholders
- **Icon Helper** - Reference guide for raid icons and symbols

### **Statistics Tab**
- **Total Gold Earned** - All-time and session earnings
- **Total Jobs Completed** - Job count with grouping (10-minute window)
- **Total Boxes Opened** - Overall count with per-type breakdown
- **Average Tip Per Job** - Know your typical earnings
- **Session Stats** - Current session tracking separate from all-time
- **Refresh & Reset** - Update display or clear all data

## 📦 Supported Boxes

The addon automatically detects your WoW version and shows only relevant boxes for that expansion.

### Junkboxes (Pickpocketed)
| Box Type | Required Skill | Expansion |
|----------|----------------|-----------|
| Battered Junkbox | 1 | All |
| Worn Junkbox | 100 | All |
| Sturdy Junkbox | 175 | All |
| Heavy Junkbox | 250 | Classic+ |
| Strong Junkbox | 300 | TBC+ |
| Reinforced Junkbox | 350 | Wrath+ |
| Flame-Scarred Junkbox | 400 | Cata+ |

### Lockboxes (World Drops)
| Box Type | Required Skill | Expansion |
|----------|----------------|-----------|
| Strong Iron Lockbox | 125 | All |
| Steel Lockbox | 175 | All |
| Reinforced Steel Lockbox | 225 | All |
| Mithril Lockbox | 225 | All |
| Thorium Lockbox | 225 | Classic+ |
| Eternium Lockbox | 225 | Classic+ |
| Khorium Lockbox | 325 | TBC+ |
| Froststeel Lockbox | 375 | Wrath+ |
| Titanium Lockbox | 400 | Wrath+ |
| Elementium Lockbox | 425 | Cata+ |
| Ghost Iron Lockbox | 450 | MoP+ |
| True Steel Lockbox | 500 | WoD+ |
| Leystone Lockbox | 550 | Legion+ |
| Barnacled Lockbox | 600 | BFA+ |
| Synvir Lockbox | Auto | Shadowlands+ |
| Oxxein Lockbox | Auto | Shadowlands+ |
| Bismuth Lockbox | 80 | War Within+ |

### Locked Chests (Dungeon/World)
| Box Type | Required Skill | Expansion |
|----------|----------------|-----------|
| Ironbound Locked Chest | 175 | Classic+ |
| Reinforced Locked Chest | 250 | Classic+ |

**Note:** The addon includes **26 different box types** across all WoW expansions and automatically shows only boxes available in your current WoW version. For example, Classic Era players won't see Wrath or retail boxes, while Retail players can see all boxes. Smart expansion detection ensures you only get notified for relevant requests!

## ⚙️ How It Works

1. **Monitoring** - LockSmithPro monitors your selected chat channels in real-time
2. **Detection** - Recognizes lockpicking keywords and box types via item links
3. **Skill Check** - Identifies the specific box and verifies your skill is sufficient
4. **Notification** - Shows popup with player name, message, box type, and action buttons
5. **Response** - If skill is too low and enabled, automatically whispers the player
6. **Trade Tracking** - Monitors trade windows for:
   - Gold received from customer
   - Boxes traded in slots 1-6 (received in your inventory)
   - Pick Lock spell casts on slot 7 (in-window unlocking)
7. **Job Grouping** - Multiple trades with same player within 10 minutes = one job
8. **Statistics** - All data automatically saved and displayed in dashboard

## 💡 Tips for Success

- **Stay in capital cities** - Trade chat only works in major cities
- **Customize your ad** - Make it stand out with raid icons and personality
- **Be responsive** - First come, first served in the lockpicking business
- **Mention tips** - Let customers know tips are appreciated but optional
- **Check your stats** - Monitor earnings to understand your busiest times
- **Use raid markers** - Makes finding customers easy in crowded areas
- **Enable auto-responses** - Save time with automated whispers for common situations

## 💬 Message Customization

All messages are fully customizable in the settings panel with support for raid icons and special characters.

### Default Messages

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

### Available Icons & Variables

**Raid Markers:**
- `{rt1}` through `{rt8}` - Numbered raid icons
- Named icons: `{skull}` `{circle}` `{diamond}` `{triangle}` `{moon}` `{square}` `{cross}` `{star}`

**Special Characters:**
- `♥` - Heart symbol
- Any Unicode character supported by WoW

**Variables:**
- `%CURRENT%` - Your current lockpicking skill
- `%REQUIRED%` - Required skill for the box
- `%TIP%` - Gold amount received (formatted)

**Example Ad:**
```
{skull} Master Locksmith - All boxes - Fast service - Tips welcome! {skull}
```

## 🔧 Troubleshooting

### Addon Not Loading?
- Verify it's enabled at character select screen under "AddOns"
- Check all files are in the correct AddOns directory
- Ensure folder name is exactly `LockSmithPro`
- Try `/reload` command in-game

### Not Seeing Notifications?
- Confirm addon is **Started** (green status in dashboard)
- Verify you're monitoring the correct channels (Settings tab)
- Check your lockpicking skill is high enough for the box type
- Ensure sound effects aren't muted if expecting audio alerts

### Advertisements Not Sending?
- Trade channel **only works in capital cities**
- Verify at least one channel is selected in settings
- Ad timer shows a popup prompt - must click **Send** to broadcast (WoW chat protection)
- Cannot send to some channels while in LFG/raid groups
- Check you're not being rate-limited by WoW (spam protection)

### Stats Not Tracking?
- Gold tracking only works from **direct trades** (not mail or quest rewards)
- Box counting tracks both:
  - Boxes **traded to you** in slots 1-6
  - Boxes **unlocked in-window** via Pick Lock spell on slot 7
- Jobs group trades within 10 minutes with same player
- Addon must be **running** when you receive gold
- Click **Refresh Stats** button to update the display
- Use `/locksmith stats` to verify data in chat

### General Issues?
- Try `/reload` to restart the UI
- Check for addon conflicts by disabling other addons
- Verify WoW version compatibility
- Review error messages in chat for specific issues

## 🏆 Perfect For

- **Rogue players** offering lockpicking services for profit
- **Business-minded players** who want professional tools for their side hustle
- **Statistics enthusiasts** who enjoy tracking earnings and performance
- **AFK gold makers** who want automated monitoring and responses
- **Guild service providers** running organized lockpicking operations
- **Casual players** who occasionally help others with boxes

## 🛠️ Technical Details

- **Built for WoW** - Native WoW addon using standard Lua API
- **Persistent storage** - All data saved in WoW's SavedVariables
- **Event-driven** - Efficient chat monitoring with minimal performance impact
- **Cross-version compatible** - Works on Classic Era, TBC, Wrath, Cata, and Retail
- **Memory efficient** - Smart caching and data management
- **No dependencies** - Standalone addon, no external libraries required

## 🔨 Development

LockSmithPro uses a symlink-based development workflow for instant testing.

### Development Setup

**Create symlinks for live development:**
```powershell
# Run as Administrator
.\.build\create-symlink.ps1
```

This creates symbolic links from your GitHub folder to all WoW installations:
- Retail (`_retail_`)
- Classic Era (`_classic_era_`)
- Wrath/Cata Classic (`_classic_`)
- Anniversary (`_anniversary_`)

After running this, any changes you make in your GitHub folder instantly appear in WoW. Just type `/reload` in-game to see changes.

**Remove symlinks when done:**
```powershell
# Run as Administrator
.\.build\remove-symlink.ps1
```

**Custom WoW path:**
```powershell
.\.build\create-symlink.ps1 -WowPath "D:\Games\World of Warcraft"
```

### Creating Releases

LockSmithPro now uses **CurseForge automatic packaging** via Git tags.

1. Configure the GitHub webhook once:
   - `https://www.curseforge.com/api/projects/1443477/package?token=YOUR_TOKEN`
2. Push a release tag:
```powershell
# Release
.\.build\push-release-tag.ps1 -Version "1.0.1" -Channel release

# Beta
.\.build\push-release-tag.ps1 -Version "1.1.0" -Channel beta -Iteration 1

# Alpha
.\.build\push-release-tag.ps1 -Version "1.1.0" -Channel alpha -Iteration 1
```

Tag mapping on CurseForge:
- `vX.Y.Z` => release
- `vX.Y.Z-beta` or `vX.Y.Z-beta.N` => beta
- `vX.Y.Z-alpha` or `vX.Y.Z-alpha.N` => alpha

### Project Structure

```
LockSmithPro/
├── .build/              # Build scripts and release tools
├── Core/                # Core functionality (Statistics, Skills, Utils)
├── Data/                # Box database and configuration
├── Features/            # Advertisement, AutoResponse, ChatMonitor
├── UI/                  # Dashboard, Settings, Notifications, Minimap
├── Init.lua             # Main entry point
├── LockSmithPro.toc     # Addon metadata
└── SlashCommands.lua    # Slash command handlers
```

## 📖 Version History

**Current Version:** 1.0.1

### Recent Updates
- Initial release with full feature set
- Chat monitoring across all major channels
- Advertisement system with timer support
- Automatic earnings and box tracking
- Raid marker automation
- Auto-response system
- Dashboard UI with multiple tabs

---

**Author:** 0xTrk

*Transform your Rogue into a professional lockpicking business with LockSmithPro!*
