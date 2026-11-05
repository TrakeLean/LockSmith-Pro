-- Run from repository root: lua5.1 tests/regression.lua [classic|retail|forever|mop]
-- Mocked APIs test addon behavior; these do not emulate Blizzard taint enforcement.
local flavor = arg[1] or "classic"
local interfaces = {classic=20506, era=11509, retail=120105, forever=16001, mop=50504}
local interface = assert(interfaces[flavor])
local now, frames, timers, invites, whispers = 100, {}, {}, {}, {}
local allocations, regions = 0, 0
local secret = setmetatable({}, {__tostring=function() error("secret inspected") end})
local player = flavor == "forever" and "Ada Locksmith" or "Ada"
local units = {player={player, flavor ~= "forever" and "HomeRealm" or nil}, NPC={flavor == "forever" and "Alex Oak" or "Alex", flavor ~= "forever" and "OtherRealm" or nil}}
local combat, groupCount, leader = false, 0, true
local chatLocked, outgoingRestricted, canInvite = false, false, true
local money, tradeLink, slot7, skill = 500, nil, nil, 300
local methods = {}
local function noop() end
local function object(name)
    return setmetatable({name=name, scripts={}, events={}, shown=true, width=400,height=600}, {__index=function(_,k) if methods[k] then return methods[k] end; if k:match("^[A-Z]") then return noop end; return nil end})
end
function methods:SetScript(k,f) self.scripts[k]=f end
function methods:GetScript(k) return self.scripts[k] end
function methods:HookScript(k,f) self.scripts[k]=f end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:UnregisterEvent(e) self.events[e]=nil end
function methods:GetName() return self.name end
function methods:GetObjectType() return "Frame" end
function methods:GetChildren() end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetCenter() return 0,0 end
function methods:GetPoint() return "CENTER",nil,"CENTER",0,0 end
function methods:SetPoint(...) self.point={...} end
function methods:GetEffectiveScale() return 1 end
function methods:SetText(t) self.text=t end
function methods:GetText() return self.text or "" end
function methods:GetStringHeight() return 14 end
function methods:GetStringWidth() return 100 end
function methods:GetVerticalScroll() return 0 end
function methods:GetVerticalScrollRange() return 100 end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:CreateFontString(name) regions=regions+1; local r=object(name); if name then _G[name]=r end; return r end
methods.CreateTexture=methods.CreateFontString
methods.CreateMaskTexture=methods.CreateFontString
function CreateFrame(kind,name,parent,template)
    allocations=allocations+1
    local f=object(name); f.parent=parent; frames[#frames+1]=f
    if name then _G[name]=f end
    if template == "ChatConfigCheckButtonTemplate" then _G[name.."Text"]=f:CreateFontString() end
    if template == "OptionsSliderTemplate" then for _,suffix in ipairs({"Text","Low","High"}) do _G[name..suffix]=f:CreateFontString() end end
    return f
end
UIParent=object(); Minimap=object(); GameTooltip=object()
Minimap:SetSize(140,140)
UISpecialFrames={}; SlashCmdList={}; StaticPopupDialogs={}; SOUNDKIT={TELL_MESSAGE=1}
Settings={RegisterCanvasLayoutCategory=function() return {GetID=function() return 42 end} end, RegisterAddOnCategory=noop, OpenToCategory=function(id) assert(id==42,"settings category must be ID") end}
GetBuildInfo=function() return "test","test","test",interface end
GetTime=function() return now end
GetNormalizedRealmName=function() return "HomeRealm" end
UnitFullName=function(unit) if units[unit] then return unpack(units[unit]) end end
UnitName=UnitFullName
if flavor == "forever" then
    units.player={"Ada", "Locksmith"};units.NPC={"Alex", "Oak"}
    UnitNameUnmodified=UnitName
    Constants={CharacterNameSeparatorConsts={CHARACTERNAME_SURNAME_SEPARATOR=" "}}
    NameUtil={GetUnmodifiedUnitFullName=function(unit)
        local first,last=UnitNameUnmodified(unit)
        if last then return first .. " " .. last end
        return first
    end}
    C_SkillInfo={GetSkillLineInfoByID=function(id) assert(id==633);return {rank=300,maxRank=300} end}
end
UnitExists=function(u) return units[u] ~= nil end
UnitInRaid=function() return false end
IsInRaid=UnitInRaid
IsInGroup=function() return groupCount>0 end
GetNumGroupMembers=function() return groupCount end
GetNumSubgroupMembers=function() return math.max(0,groupCount-1) end
UnitIsGroupLeader=function() return leader end
UnitIsGroupAssistant=function() return false end
InCombatLockdown=function() return combat end
SetRaidTarget=noop
issecretvalue=function(v) return rawequal(v,secret) end
C_Spell={GetSpellName=function() return "Lockpicking" end}
if flavor == "classic" or flavor == "era" then
    GetNumSkillLines=function() return 1 end
    GetSkillLineInfo=function() return "Lockpicking",false,false,skill,0,0,375 end
end
C_PartyInfo={CanInvite=function() return canInvite end, InviteUnit=function(name) invites[#invites+1]=name end}
local function send(msg,channel,_,target) whispers[#whispers+1]={target=target,message=msg,channel=channel} end
C_ChatInfo={SendChatMessage=send, InChatMessagingLockdown=function() return chatLocked end, AreOutgoingAddonChatMessagesRestricted=function() return outgoingRestricted end}
if flavor == "classic" or flavor == "mop" then SendChatMessage=send end
ChatFrameUtil={SendTell=function(name) assert(type(name)=="string") end}
if flavor == "classic" or flavor == "era" or flavor == "mop" then ChatFrame_SendTell=ChatFrameUtil.SendTell end
GetChannelName=function(name) return 1 end
GetTradeTargetItemLink=function(slot) if slot==7 then return slot7 else return tradeLink end end
GetTradeTargetItemInfo=function() return "Battered Junkbox",nil,1 end
GetTargetTradeMoney=function() return money end
ERR_TRADE_COMPLETE="Trade complete."
PlaySound=noop; date=os.date; time=os.time; print=noop
C_Timer={}
local function timer(delay,fn,repeating)
    local t={due=now+delay,fn=fn,delay=delay,repeating=repeating}
    function t:Cancel() self.cancelled=true end
    timers[#timers+1]=t
    return t
end
C_Timer.NewTicker=function(delay,fn) return timer(delay,fn,true) end
C_Timer.NewTimer=function(delay,fn) return timer(delay,fn,false) end
C_Timer.After=function(delay,fn) timer(delay,fn,false) end
local function advance(delta)
    now=now+delta
    local ready=timers; timers={}
    for _,t in ipairs(ready) do
        if not t.cancelled then
            if t.due<=now then
                if t.repeating then t.due=now+t.delay;timers[#timers+1]=t end
                t.fn()
            else timers[#timers+1]=t end
        end
    end
end
local function event(name,...)
    for _,f in ipairs(frames) do if f.events[name] and f.scripts.OnEvent then f.scripts.OnEvent(f,name,...) end end
end
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." ~= "..tostring(b)) end
local function channel(msg,sender,id) event("CHAT_MSG_CHANNEL",msg,sender,nil,nil,nil,nil,id,1,"Localized channel") end
for line in io.lines("LockSmithPro.toc") do
    if line:match("%.lua$") then assert(loadfile((line:gsub("\\","/"))))("LockSmithPro") end
end
event("ADDON_LOADED","LockSmithPro")
event("PLAYER_LOGIN")
local A=LockSmithPro
A:Start(); A.UI:OpenSettingsGUI()
local initialFrames=allocations
A.ChatMonitor:RegisterEvents(); eq(allocations,initialFrames,"duplicate registration")
-- Identities remain distinct, even when first names match.
assert(A.Compat:NameKey("Alex Oak")~=A.Compat:NameKey("Alex Pine"))
if flavor == "forever" then
    eq(A.Compat:UnitAddress("player"),"Ada Locksmith")
    local helper=NameUtil;NameUtil=nil
    eq(A.Compat:UnitAddress("player"),"Ada Locksmith","surname fallback")
    NameUtil=helper
end
assert(A.Compat:NameKey("Alex-HomeRealm")~=A.Compat:NameKey("Alex-OtherRealm"))
if flavor ~= "forever" then eq(A.Compat:NameKey("Alex"),A.Compat:NameKey("Alex-HomeRealm")) end
-- Native skill absence is unknown, not proof of insufficient skill.
local _,_,known=A.Skills:GetCachedSkill();eq(known,flavor=="classic" or flavor=="era" or flavor=="forever")
if flavor=="classic" then
    local legacy1,legacy2=GetNumSkillLines,GetSkillLineInfo
    GetNumSkillLines=nil;GetSkillLineInfo=nil
    GetProfessions=function() return nil,nil,nil,4 end
    GetProfessionInfo=function(i) assert(i==4);return "Lockpicking",nil,200,300,nil,nil,633 end
    eq(A.Skills:UpdateCache(),200,"sparse profession returns")
    GetProfessions=nil;GetProfessionInfo=nil;GetNumSkillLines=legacy1;GetSkillLineInfo=legacy2
    A.Skills:UpdateCache()
end
-- Matching respects channels, exclusions, ignores, skill and global cooldown.
LockSmithProDB.autoInviteOnMatch=true
LockSmithProDB.excludeKeywords="wts"
channel("need lockpick","Buyer One",2)
eq(#invites,1,"automatic invite when client permits")
local sent=#invites
channel("need lockpick","Buyer One",2);eq(#invites,sent)
channel("need lockpick","Buyer Two",2);eq(#invites,sent,"aggregate invite throttle")
advance(31)
A.ChatMonitor:AddToSessionIgnore("Ignored One")
channel("need lockpick","Ignored One",2);eq(#invites,sent)
channel("wts lockpick","Seller One",2);eq(#invites,sent)
channel("need lockpick","Custom One",777);eq(#invites,sent)
LockSmithProDB.monitorTrade=false;channel("need lockpick","Disabled One",2);eq(#invites,sent);LockSmithProDB.monitorTrade=true
channel(secret,"Secret One",2);channel("lockpick",secret,2);channel("lockpick","Secret Two",secret)
combat=true;channel("need lockpick","Combat One",2);eq(#invites,sent);combat=false
leader=false;groupCount=2;channel("need lockpick","No Leader",2);eq(#invites,sent);leader=true;groupCount=0
chatLocked=true;channel("need lockpick","Locked One",2);eq(#invites,sent);chatLocked=false
outgoingRestricted=true;channel("need lockpick","Restricted One",2);eq(#invites,sent);outgoingRestricted=false
canInvite=false;channel("need lockpick","No Permission",2);eq(#invites,sent);canInvite=true
if known then
    local countBefore=#invites
    channel("lockpick |Hitem:31952:0|h[Khorium]|h", "Too Hard", 2)
    eq(#invites,countBefore,"insufficient known skill prevents invitation")
end
assert(A.ChatMonitor:IsSelfSender(flavor=="forever" and "Ada Locksmith" or "Ada-HomeRealm"))
assert(not A.ChatMonitor:IsSelfSender(flavor=="forever" and "Ada Different" or "Ada-OtherRealm"))
assert(A.Compat:OpenWhisper("Alex Oak"))
-- Manual action retains the full address on modern clients too.
advance(31);assert(A.Utils:InvitePlayer("Alex Oak"));eq(invites[#invites],"Alex Oak")
-- Removing/ignoring one same-first-name customer leaves the other intact.
A.Dashboard:ClearAllJobs()
local first,second="Alex-HomeRealm","Alex-OtherRealm"
if flavor=="forever" then first,second="Alex Oak","Alex Pine" end
A.Dashboard:AddJob(first,"lockpick",nil,"WHISPER",1)
A.Dashboard:AddJob(second,"lockpick",nil,"WHISPER",1)
A.Dashboard:RemoveJobsBySender(first)
local remaining=0
for _,f in ipairs(frames) do if rawget(f,"job") then remaining=remaining+1;eq(f.job.sender,second) end end
eq(remaining,1,"distinct customer removal")
A.ChatMonitor:AddToSessionIgnore(first);assert(not A.ChatMonitor:IsSessionIgnored(second))
-- Marker errors never create a repeating frame or delayed callback.
local oldMarker=SetRaidTarget
local markerFrames,markerTimers=allocations,#timers
SetRaidTarget=function() error("simulated restriction") end
for i=1,100 do event("GROUP_ROSTER_UPDATE") end
SetRaidTarget=oldMarker
eq(allocations,markerFrames,"marker frame allocation");eq(#timers,markerTimers,"marker scheduling")
-- Pooled job cards stop allocating after reaching the fixed cap.
A.Dashboard:ClearAllJobs()
for i=1,110 do A.Dashboard:AddJob("Customer "..i,"lockpick",nil,"TRADE",1) end
local plateauFrames,plateauRegions=allocations,regions
collectgarbage("collect");local memory=collectgarbage("count")
for i=111,1110 do A.Dashboard:AddJob("Customer "..i,"lockpick",nil,"TRADE",1) end
for i=1,50 do A.Dashboard:RebuildJobList() end
eq(allocations,plateauFrames,"job frame pool plateau");eq(regions,plateauRegions,"job region pool plateau")
collectgarbage("collect");assert(collectgarbage("count")-memory<150,"retained memory grew after job cap")
-- Rebound click handlers address the current job, not a previous card occupant.
local firstCard
for _,f in ipairs(frames) do if rawget(f,"job") and f.index==1 then firstCard=f end end
assert(firstCard);advance(31);firstCard.inviteBtn.scripts.OnClick();eq(invites[#invites],"Customer 1110")
A.Dashboard:ClearAllJobs()
for _,f in ipairs(frames) do if rawget(f,"index") then eq(rawget(f,"job"),nil,"release card data") end end
-- Repeated ad timer restarts allocate no frames and cancellation stops callbacks.
LockSmithProDB.adTimerEnabled=true
local before=allocations
for i=1,1000 do A.Advertisement:StartAdTimer();A.Advertisement:StopAdTimer() end
eq(allocations,before,"ad timer allocations")
advance(601);eq(A.Advertisement.adReady,false,"cancelled ad callback")
-- Bounded timestamp map under unique-sender flood.
local cache={}
for i=1,10000 do A.Compat:Remember(cache,"Name"..i,30) end
local count=0;for _ in pairs(cache) do count=count+1 end;eq(count,512)
advance(31);A.Compat:Remember(cache,"fresh",30);count=0;for _ in pairs(cache) do count=count+1 end;eq(count,1)
-- Server confirmation, cancellation, duplicate success and full trade identity.
A.Statistics:ResetStats()
event("TRADE_SHOW");event("TRADE_ACCEPT_UPDATE",1,1);eq(LockSmithProDB.stats.totalGold,0)
event("TRADE_CLOSED");advance(1);eq(LockSmithProDB.stats.totalGold,0)
event("TRADE_SHOW");event("TRADE_ACCEPT_UPDATE",1,1);event("TRADE_CLOSED");event("UI_INFO_MESSAGE",1,ERR_TRADE_COMPLETE)
eq(LockSmithProDB.stats.totalGold,500)
event("UI_INFO_MESSAGE",1,ERR_TRADE_COMPLETE);eq(LockSmithProDB.stats.totalGold,500)
local beforeWhispers=#whispers
A:Stop();A:Start();advance(3);eq(#whispers,beforeWhispers,"old thank-you cannot survive stop/start")
-- Slot 7 counts only a successful Pick Lock, and only after trade success.
slot7="|Hitem:16882:0|h[Box]|h";money=0
local oldBoxes=LockSmithProDB.stats.totalBoxes
event("TRADE_SHOW");event("TRADE_TARGET_ITEM_CHANGED",7)
event("UNIT_SPELLCAST_SUCCEEDED",secret,nil,secret)
event("UNIT_SPELLCAST_SUCCEEDED","player","cast",1804)
event("TRADE_ACCEPT_UPDATE",1,1);event("UI_INFO_MESSAGE",1,ERR_TRADE_COMPLETE)
eq(LockSmithProDB.stats.totalBoxes,oldBoxes+1)
-- A successful thank-you uses the cached actual trade partner after closure.
advance(31);slot7=nil;money=750
local partnerBefore=units.NPC
event("TRADE_SHOW");event("TRADE_ACCEPT_UPDATE",1,1);event("TRADE_CLOSED")
units.NPC=nil;units.target={"Wrong", "Target"}
event("UI_INFO_MESSAGE",1,ERR_TRADE_COMPLETE)
advance(3)
eq(whispers[#whispers].target,flavor=="forever" and "Alex Oak" or "Alex-OtherRealm","trade recipient")
units.NPC=partnerBefore
-- An older close timer cannot clear the next trade's snapshot.
event("TRADE_SHOW");event("TRADE_CLOSED")
event("TRADE_SHOW");event("TRADE_ACCEPT_UPDATE",1,1)
local totalBefore=LockSmithProDB.stats.totalGold
advance(1);event("UI_INFO_MESSAGE",1,ERR_TRADE_COMPLETE)
eq(LockSmithProDB.stats.totalGold,totalBefore+750,"new trade survives old close timer")
-- Background communication remains gated; manual buttons reach the native API.
local sendsBefore=#whispers
chatLocked=true;eq(A.Compat:SendChat("hello","YELL"),false);eq(#whispers,sendsBefore)
outgoingRestricted=true
A.AutoResponse:SendThankYouWhisper("Alex Oak",50);eq(#whispers,sendsBefore)
local originalAd=LockSmithProDB.adMessage
local originalChannels=LockSmithProDB.adChannels
LockSmithProDB.adMessage="%SPELL_LINK% service available"
LockSmithProDB.adChannels={yell=true}
assert(A.Advertisement:SendAdvertisement());eq(#whispers,sendsBefore+1)
eq(whispers[#whispers].channel,"YELL")
assert(A.Advertisement:SendYellAdvertisement());eq(#whispers,sendsBefore+2)
chatLocked=false;outgoingRestricted=false
-- Expanded links count against the byte limit; neither button sends malformed ads.
LockSmithProDB.adMessage=string.rep("x",220).."%SPELL_LINK%"
sendsBefore=#whispers
eq(A.Advertisement:SendAdvertisement(),false)
eq(A.Advertisement:SendYellAdvertisement(),false)
eq(#whispers,sendsBefore)
local valid,reason=A.Compat:ValidateChatMessage(A.Advertisement:ProcessAdMessage(LockSmithProDB.adMessage))
eq(valid,false);eq(reason,"too_long")
eq(A.Compat:ValidateChatMessage(string.rep("x",255)),true)
eq(A.Compat:ValidateChatMessage("   "),false)
-- API rejection is not reported as dispatch and does not clear the ready reminder.
LockSmithProDB.adMessage="Lockpicking service"
local nativeSend=C_ChatInfo.SendChatMessage
C_ChatInfo.SendChatMessage=function() error("hardware event or client restriction") end
A.Advertisement.adReady=true
eq(A.Advertisement:SendAdvertisement(),false);eq(A.Advertisement.adReady,true)
eq(A.Advertisement:SendYellAdvertisement(),false)
C_ChatInfo.SendChatMessage=nativeSend
-- Unjoined channels are not submitted; missing namespaced API uses the legacy API.
local originalGetChannelName=GetChannelName
GetChannelName=function() return 0 end
LockSmithProDB.adChannels={trade=true,general=true}
eq(A.Advertisement:SendAdvertisement(),false);eq(#whispers,sendsBefore)
GetChannelName=originalGetChannelName
local legacySend=SendChatMessage
SendChatMessage=nativeSend;C_ChatInfo.SendChatMessage=nil
assert(A.Advertisement:SendYellAdvertisement())
SendChatMessage=legacySend;C_ChatInfo.SendChatMessage=nativeSend
LockSmithProDB.adMessage=originalAd;LockSmithProDB.adChannels=originalChannels

-- The minimap button follows the map edge at every size, shape and UI scale.
local button=LockSmithProMinimapButton
local function near(actual,expected,label)
    assert(math.abs(actual-expected)<0.00001,(label or "position")..": "..actual.." ~= "..expected)
end
local function offset() return button.point[4],button.point[5] end
local shape="ROUND"
GetMinimapShape=function() return shape end
A.Minimap:SetButtonPosition(0)
local x,y=offset();near(x,80);near(y,0)
Minimap:SetSize(280,280);Minimap.scripts.OnSizeChanged()
x,y=offset();near(x,150);near(y,0)
Minimap:SetSize(280,180)
for _,angle in ipairs({0,45,90,135,180,225,270,315}) do
    A.Minimap:SetButtonPosition(angle);x,y=offset()
    near((x/150)^2+(y/100)^2,1,"ellipse edge")
end
shape="SQUARE"
for _,angle in ipairs({0,45,90,135,180,225,270,315}) do
    A.Minimap:SetButtonPosition(angle);x,y=offset()
    near(math.max(math.abs(x)/150,math.abs(y)/100),1,"square edge")
end
shape="CORNER-TOPLEFT"
A.Minimap:SetButtonPosition(135);x,y=offset();near((x/150)^2+(y/100)^2,1,"rounded corner")
A.Minimap:SetButtonPosition(315);x,y=offset();near(math.max(math.abs(x)/150,math.abs(y)/100),1,"square corner")
shape="custom-unknown"
A.Minimap:SetButtonPosition(45);x,y=offset();near((x/150)^2+(y/100)^2,1,"unknown shape fallback")
A.Minimap:SetButtonPosition(math.huge);eq(LockSmithProDB.minimapPosition,225)
shape="ROUND"
Minimap.GetCenter=function() return 100,80 end
Minimap.GetEffectiveScale=function() return 1.5 end
GetCursorPosition=function() return 600,120 end
button.scripts.OnDragStart(button);button.scripts.OnUpdate(button)
near(LockSmithProDB.minimapPosition,0,"scaled cursor angle")
x,y=offset();near(x,150);near(y,0)
Minimap.GetCenter=function() return nil,nil end
button.scripts.OnUpdate(button);near(LockSmithProDB.minimapPosition,0,"hidden map preserves angle")
button.scripts.OnDragStop(button);eq(button.scripts.OnUpdate,nil)
button.scripts.OnDragStart(button);button.scripts.OnHide(button);eq(button.scripts.OnUpdate,nil)
Minimap.GetCenter=nil;Minimap.GetEffectiveScale=nil;GetCursorPosition=nil;GetMinimapShape=nil
Minimap:SetSize(140,140)
A.Minimap:SetButtonPosition(90);Minimap:SetSize(220,220);Minimap.scripts.OnSizeChanged()
x,y=offset();near(x,0);near(y,120,"resize keeps saved angle")
io.write("PASS ",flavor,": identity, chat guards, manual ads, minimap geometry, invites, skill fallback, UI pooling, timers, trade events; ",allocations," frames, ",regions," regions\n")
