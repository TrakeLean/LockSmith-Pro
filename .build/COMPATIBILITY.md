# LockSmithPro 1.1.0 compatibility notes

Prepared 2026-11-04 from GitHub `dashboard-redesign` commit `0f3ef365d62b23d00bd91b9ddada21a33929700d`. The GitHub default branch contains an older addon named LockSmith; this update preserves the published LockSmithPro dashboard and saved-variable name.

## Target clients

| Client | Version | Interface | Manifest |
| --- | --- | --- | --- |
| Retail | 12.1.5 | 120105 | LockSmithPro_Mainline.toc |
| Classic Era | 1.15.9 | 11509 | LockSmithPro_Vanilla.toc |
| TBC Anniversary | 2.5.6 | 20506 | LockSmithPro_TBC.toc |
| MoP Classic | 5.5.4 | 50504 | LockSmithPro_Mists.toc |
| Forever | 1.60.1 | 16001 | LockSmithPro_Camelot.toc |

The base manifest also lists all five interfaces. Camelot is the verified Forever suffix; no unverified alias is required.

Runtime metadata sources: [Retail](https://github.com/Ketho/BlizzardInterfaceResources/blob/live/README.md), [Era](https://github.com/Ketho/BlizzardInterfaceResources/blob/classic_era/README.md), [Anniversary](https://github.com/Ketho/BlizzardInterfaceResources/blob/classic_anniversary/README.md), [MoP](https://github.com/Ketho/BlizzardInterfaceResources/blob/classic/README.md), [Forever](https://github.com/Ketho/BlizzardInterfaceResources/blob/forever/README.md). These are captured client results, not local in-game verification.

Relevant Blizzard UI/API source mirrors:

- [Forever full-name helper](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua): joins first name and surname using the client separator. The second name is never treated as a realm.
- [Forever skill API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SkillInfoDocumentation.lua): `C_SkillInfo.GetSkillLineInfoByID(633)` provides rank and maximum. Retail can legitimately return no exposed rank; the UI reports unknown.
- [Chat API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua): readable input checks, namespaced sending, lockdown/outgoing restriction checks.
- [Party API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/PartyInfoDocumentation.lua): invitation permissions and dispatch semantics. A successful Lua call is not proof of delivery or acceptance.
- [Settings API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Settings.lua): numeric category IDs.

## Confirmed resource issues addressed

Every board rebuild previously created five frames per existing job and detached the old cards. The old structure created at least 25,250 explicit frames for 100 sequential jobs, plus template objects and animation frames. The new board pools 100 cards and bounds the job list. The stress regression reaches a stable 601 total mock frames and 648 regions, including the rest of the UI, with no further allocation during another 1,000 additions or repeated rebuilds.

Ad timer restarts and raid-marker delay frames also retained frames. Native tickers replace ad frames; marker updates no longer create delayed per-frame handlers. Expiring caches are bounded to 512 entries. Explicit session ignore/decline lists are capped at 2,048 entries each. Unused mail scanning was removed.

These defects are credible causes of client memory growth and stalls. A server/world desync or a specific July patch regression has not been reproduced or proven.

## Automated validation

`LUA=/path/to/lua5.1 sh tests/run.sh` runs startup and runtime scenarios for all five profiles. It covers full identities, surname fallback, sparse profession returns, absent legacy chat functions, secret payloads, restrictions, automatic/manual invites, filters, group permissions, card rebinding, frame/region and retained-memory plateaus, timer restarts, bounded caches, trade cancellation/completion, duplicate success events, slot-7 unlocks and stop/start invalidation of delayed replies. `python3 .build/package.py` validates matching manifest load orders and ZIP contents.

Mocks cannot emulate Blizzard's secure execution/taint engine, the live server, or actual frame rendering.

## Required in-game smoke tests before publishing

1. Install into `Interface/AddOns/LockSmithPro` on each target client. Log in with existing settings, open the dashboard and Blizzard settings, start/stop, then reload. Confirm no Lua errors and retained settings/statistics.
2. In Forever, use two players sharing a first name but with different surnames. Check their separate jobs, invite/whisper targets, ignores and trade credit. On Retail, repeat with the same character name on different realms. Change selected target during a trade; credit must remain with the trade partner.
3. Enable phrase invites, exercise Trade/General/LFG/Say/Whisper toggles and exclusions, repeat messages, join a full group and test without leader permissions. Ensure blocked invites keep jobs visible. Disable “Auto-invite on Whisper” when testing phrase-only behavior.
4. Test chat and invite behavior during actual lockdown/restricted contexts. No secret-value errors, blocked-action retry loops or false delivery claims should occur. Test automatic raid markers during roster changes and combat.
5. Complete and cancel tipped trades, change the offered money before accepting again, unlock a box in slot 7, and stop/restart before the thank-you delay. Check exact totals and intended recipient.
6. Let busy city chat run for at least 30 minutes with the board open and hidden. Resize repeatedly, clear jobs, and restart the advertisement timer. Compare memory after garbage collection and frame counts after warm-up; they should plateau. Verify long Forever names wrap without covering action buttons.
7. Send advertisements manually and through the Yell button. Check available channels in the client language; advertisement lookup still uses the existing English channel labels. Monitoring itself uses numeric channel IDs and is independent of locale.

This build is prepared for in-game validation. No release tag or CurseForge upload has been performed.
