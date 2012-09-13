local addonName, vars = ...
SavedInstances = vars
local addon = vars
vars.core = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0", "AceTimer-3.0")
local core = vars.core
local L = vars.L
vars.LDB = LibStub("LibDataBroker-1.1", true)
vars.icon = vars.LDB and LibStub("LibDBIcon-1.0", true)

local QTip = LibStub("LibQTip-1.0")
local dataobject, db, config
local maxdiff = 10 -- max number of instance difficulties
local maxcol = 4 -- max columns per player+instance

addon.svnrev = {}
addon.svnrev["SavedInstances.lua"] = tonumber(("$Revision$"):match("%d+"))

-- local (optimal) references to provided functions
local table, math, bit, string, pairs, ipairs, unpack, strsplit, time, type, wipe, tonumber, select, strsub = 
      table, math, bit, string, pairs, ipairs, unpack, strsplit, time, type, wipe, tonumber, select, strsub
local GetSavedInstanceInfo, GetNumSavedInstances, GetSavedInstanceChatLink, GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetNumRandomDungeons, GetLFGRandomDungeonInfo, GetLFGDungeonInfo, LFGGetDungeonInfoByID, GetLFGDungeonRewards, GetTime, UnitIsUnit, GetInstanceInfo, IsInInstance, SecondsToTime, GetQuestResetTime, GetGameTime, GetCurrencyInfo, GetNumGroupMembers = 
      GetSavedInstanceInfo, GetNumSavedInstances, GetSavedInstanceChatLink, GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetNumRandomDungeons, GetLFGRandomDungeonInfo, GetLFGDungeonInfo, LFGGetDungeonInfoByID, GetLFGDungeonRewards, GetTime, UnitIsUnit, GetInstanceInfo, IsInInstance, SecondsToTime, GetQuestResetTime, GetGameTime, GetCurrencyInfo, GetNumGroupMembers

-- local (optimal) references to Blizzard's strings
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local RAID_FINDER = PLAYER_DIFFICULTY3
local FONTEND = FONT_COLOR_CODE_CLOSE
local GOLDFONT = NORMAL_FONT_COLOR_CODE
local YELLOWFONT = LIGHTYELLOW_FONT_COLOR_CODE
local REDFONT = RED_FONT_COLOR_CODE
local GREENFONT = GREEN_FONT_COLOR_CODE
local WHITEFONT = HIGHLIGHT_FONT_COLOR_CODE
local GRAYFONT = GRAY_FONT_COLOR_CODE
local LFD_RANDOM_REWARD_EXPLANATION2 = LFD_RANDOM_REWARD_EXPLANATION2
local INSTANCE_SAVED, TRANSFER_ABORT_TOO_MANY_INSTANCES, NO_RAID_INSTANCES_SAVED = 
      INSTANCE_SAVED, TRANSFER_ABORT_TOO_MANY_INSTANCES, NO_RAID_INSTANCES_SAVED

vars.Indicators = {
	ICON_STAR = ICON_LIST[1] .. "16:16:0:0|t",
	ICON_CIRCLE = ICON_LIST[2] .. "16:16:0:0|t",
	ICON_DIAMOND = ICON_LIST[3] .. "16:16:0:0|t",
	ICON_TRIANGLE = ICON_LIST[4] .. "16:16:0:0|t",
	ICON_MOON = ICON_LIST[5] .. "16:16:0:0|t",
	ICON_SQUARE = ICON_LIST[6] .. "16:16:0:0|t",
	ICON_CROSS = ICON_LIST[7] .. "16:16:0:0|t",
	ICON_SKULL = ICON_LIST[8] .. "16:16:0:0|t",
	BLANK = "None",
}

vars.Categories = {
	D0 = EXPANSION_NAME0 .. ": " .. LFG_TYPE_DUNGEON,
	R0 = EXPANSION_NAME0 .. ": " .. LFG_TYPE_RAID,
	D1 = EXPANSION_NAME1 .. ": " .. LFG_TYPE_DUNGEON,
	R1 = EXPANSION_NAME1 .. ": " .. LFG_TYPE_RAID,
	D2 = EXPANSION_NAME2 .. ": " .. LFG_TYPE_DUNGEON,
	R2 = EXPANSION_NAME2 .. ": " .. LFG_TYPE_RAID,
	D3 = EXPANSION_NAME3 .. ": " .. LFG_TYPE_DUNGEON,
	R3 = EXPANSION_NAME3 .. ": " .. LFG_TYPE_RAID,
	D4 = EXPANSION_NAME4 .. ": " .. LFG_TYPE_DUNGEON,
	R4 = EXPANSION_NAME4 .. ": " .. LFG_TYPE_RAID,
}

local tooltip, indicatortip
local thisToon = UnitName("player") .. " - " .. GetRealmName()
local maxlvl = MAX_PLAYER_LEVEL_TABLE[#MAX_PLAYER_LEVEL_TABLE]

local storelockout = false -- when true, store the details against the current lockout

local scantt = CreateFrame("GameTooltip", "SavedInstancesScanTooltip", UIParent, "GameTooltipTemplate")

local currency = { 
  395, -- Justice Points 
  396, -- Valor Points
  392, -- Honor Points
  390, -- Conquest Points
}

addon.LFRInstances = { 
  [416] = { total=4, base=1 }, -- The Siege of Wyrmrest Temple
  [417] = { total=4, base=5 }, -- Fall of Deathwing
}

addon.showopts = {
  always = "always",
  saved = "saved",
  never = "never",
}

local function chatMsg(msg)
     DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000"..addonName.."\124r: "..msg)
end
local function debug(msg)
  --addon.db.dbg = true
  if addon.db.dbg then
     chatMsg(msg)
  end
end
addon.debug = debug

local GTToffset = time() - GetTime()
local function GetTimeToTime(val)
  if not val then return nil end
  return val + GTToffset
end

vars.defaultDB = {
	DBVersion = 11,
	History = { }, -- for tracking 5 instance per hour limit
		-- key: instance string; value: time first entered
	Broker = {
		HistoryText = false,
	},
	Toons = { }, 	-- table key: "Toon - Realm"; value:
				-- Class: string
				-- Level: integer
				-- AlwaysShow: boolean REMOVED
				-- Show: string "always", "never", "saved"
				-- Daily1: expiry (normal) REMOVED
				-- Daily2: expiry (heroic) REMOVED
				-- LFG1: expiry (random dungeon)
				-- LFG2: expiry (deserter)
				-- WeeklyResetTime: expiry
				-- DailyResetTime: expiry
				-- DailyCount: integer
				-- PlayedLevel: integer
				-- PlayedTotal: integer
				-- Money: integer

				-- currency: key: currencyID  value:
				    -- amount: integer
				    -- earnedThisWeek: integer 
				    -- weeklyMax: integer
				    -- totalMax: integer
				    -- season: integer

				-- Quests:  key: QuestID  value:
				   -- Title: string
				   -- Link: hyperlink 
                                   -- Zone: string
				   -- isDaily: boolean
				   -- Expires: expiration (non-daily)

	Indicators = {
		D1Indicator = "BLANK", -- indicator: ICON_*, BLANK
		D1Text = "KILLED/TOTAL",
		D1Color = { 0, 0.6, 0, 1, }, -- dark green
		D1ClassColor = true,
		D2Indicator = "BLANK", -- indicator
		D2Text = "KILLED/TOTAL",
		D2Color = { 0, 1, 0, 1, }, -- green
		D2ClassColor = true,
		R0Indicator = "BLANK", -- indicator: ICON_*, BLANK
		R0Text = "KILLED/TOTAL",
		R0Color = { 0.6, 0.6, 0, 1, }, -- dark yellow
		R0ClassColor = true,
		R1Indicator = "BLANK", -- indicator: ICON_*, BLANK
		R1Text = "KILLED/TOTAL",
		R1Color = { 0.6, 0.6, 0, 1, }, -- dark yellow
		R1ClassColor = true,
		R2Indicator = "BLANK", -- indicator
		R2Text = "KILLED/TOTAL",
		R2Color = { 0.6, 0, 0, 1, }, -- dark red
		R2ClassColor = true,
		R3Indicator = "BLANK", -- indicator: ICON_*, BLANK
		R3Text = "KILLED/TOTAL+",
		R3Color = { 1, 1, 0, 1, }, -- yellow
		R3ClassColor = true,
		R4Indicator = "BLANK", -- indicator
		R4Text = "KILLED/TOTAL+",
		R4Color = { 1, 0, 0, 1, }, -- red
		R4ClassColor = true,
	},
	Tooltip = {
		Details = false,
		ReverseInstances = false,
		ShowExpired = false,
		ShowHoliday = true,
		TrackDailyQuests = true,
		TrackWeeklyQuests = true,
		ShowCategories = false,
		CategorySpaces = false,
		NewFirst = true,
		RaidsFirst = true,
		CategorySort = "EXPANSION", -- "EXPANSION", "TYPE"
		ShowSoloCategory = false,
		ShowHints = true,
		ColumnStyle = "NORMAL", -- "NORMAL", "CLASS", "ALTERNATING"
		AltColumnColor = { 0.2, 0.2, 0.2, 1, }, -- grey
		ReportResets = true,
		LimitWarn = true,
		ShowServer = false,
		ServerSort = true,
		SelfFirst = true,
		TrackLFG = true,
		TrackDeserter = true,
		Currency395 = true, -- Justice Points 
		Currency396 = true, -- Valor Points
		Currency392 = false, -- Honor Points
		Currency390 = false, -- Conquest Points
		CurrencyMax = false,
		CurrencyEarned = true,
	},
	Instances = { }, 	-- table key: "Instance name"; value:
					-- Show: boolean
					-- Raid: boolean
					-- Holiday: boolean
					-- Expansion: integer
					-- RecLevel: integer
					-- LFDID: integer
					-- LFDupdated: integer REMOVED
					-- REMOVED Encounters[integer] = { GUID : integer, Name : string }
					-- table key: "Toon - Realm"; value:
						-- table key: "Difficulty"; value:
							-- ID: integer, positive for a Blizzard Raid ID, 
                                                        --  negative value for an LFR encounter count
							-- Expires: integer
                                                        -- Locked: boolean, whether toon is locked to the save
                                                        -- Extended: boolean, whether this is an extended raid lockout
							-- Link: string hyperlink to the save
                                                        -- 1..numEncounters: boolean LFR isLooted
	MinimapIcon = { },
	--[[ REMOVED
	Lockouts = {	-- table key: lockout ID; value:
						-- Name: string
						-- Members: table "Toon name" = "Class"
						-- REMOVED Encounters[GUID : integer] = boolean
						-- Note: string
	},
	--]]
}

-- skinning support
-- skinning addons should hook this function, eg:
--   hooksecurefunc(SavedInstances,"SkinFrame",function(self,frame,name) frame:SetWhatever() end)
function addon:SkinFrame(frame,name)
  -- default behavior (ticket 81)
  if IsAddOnLoaded("ElvUI") or IsAddOnLoaded("Tukui") then
    if frame.StripTextures then
      frame:StripTextures()
    end
    if frame.SetTemplate then
      frame:SetTemplate("Transparent")
    end
    local close = _G[name.."CloseButton"]
    if close and close.SetAlpha then
      if ElvUI then
        ElvUI[1]:GetModule('Skins'):HandleCloseButton(close)
      end
      if Tukui and Tukui[1] and Tukui[1].SkinCloseButton then
        Tukui[1].SkinCloseButton(close)
      end
      close:SetAlpha(1)
    end
  end
end

-- general helper functions below

local function ColorCodeOpen(color)
	return format("|c%02x%02x%02x%02x", math.floor(color[4] * 255), math.floor(color[1] * 255), math.floor(color[2] * 255), math.floor(color[3] * 255))
end

local function ClassColorise(class, targetstring)
	local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	local color = {
		RAID_CLASS_COLORS[class].r,
		RAID_CLASS_COLORS[class].g,
		RAID_CLASS_COLORS[class].b,
		1,
	}
	return ColorCodeOpen(color) .. targetstring .. FONTEND
end

local function TableLen(table)
	local i = 0
	for _, _ in pairs(table) do
		i = i + 1
	end
	return i
end

function addon:GetServerOffset()
	-- this function was borrowed from Broker Currency with Azethoth
	local serverHour, serverMinute = GetGameTime()
	local localHour, localMinute = tonumber(date("%H")), tonumber(date("%M"))
	local server = serverHour + serverMinute / 60
	local localT = localHour + localMinute / 60
	local offset = floor((server - localT) * 2 + 0.5) / 2
	if raw then return offset end
	if offset >= 12 then
		offset = offset - 24
	elseif offset < -12 then
		offset = offset + 24
	end
	return offset
end

function addon:GetRegion()
  if not addon.region then
    local reg
    reg = GetCVar("portal")
    if not reg or #reg ~= 2 then
      reg = GetCVar("realmList"):match("^(%a+)%.")
    end
    if not reg or #reg ~= 2 then
      reg = GetRealmName():match("%(%a%a%)")
    end
    reg = reg and reg:upper()
    if reg and #reg == 2 then
      addon.region = reg
    end
  end
  return addon.region
end

function addon:GetNextDailyResetTime()
  local resettime = GetQuestResetTime()
  if not resettime or resettime <= 0 then -- ticket 43: can fail during startup
    return nil
  end
  return time() + resettime
end

function addon:GetNextWeeklyResetTime()
  if not addon.resetDays then
    local region = addon:GetRegion()
    if not region then return nil end
    addon.resetDays = {}
    if region == "US" then
      addon.resetDays["2"] = true -- tuesday
    elseif region == "EU" then
      addon.resetDays["3"] = true -- wednesday
    elseif region == "CN" or region == "KR" or region == "TW" then -- XXX: codes unconfirmed
      addon.resetDays["4"] = true -- thursday
    else
      addon.resetDays["2"] = true -- tuesday?
    end
  end
  local offset = addon:GetServerOffset() * 3600
  local nightlyReset = addon:GetNextDailyResetTime()
  if not nightlyReset then return nil end
  --while date("%A",nightlyReset+offset) ~= WEEKDAY_TUESDAY do 
  while not addon.resetDays[date("%w",nightlyReset+offset)] do
    nightlyReset = nightlyReset + 24 * 3600
  end
  return nightlyReset
end

do
local saturday_night = {hour=23, min=59}
function addon:GetNextDarkmoonResetTime()
  -- Darkmoon faire runs from first Sunday of each month to following Saturday
  -- this function only returns valid date during the faire
  local weekday, month, day, year = CalendarGetDate() -- date in server timezone (Sun==1)
  saturday_night.year = year
  saturday_night.month = month
  saturday_night.day = day + (7-weekday)
  local ret = time(saturday_night)
  local offset = addon:GetServerOffset() * 3600
  ret = ret - offset
  return ret
end
end

-- local addon functions below

local function GetLastLockedInstance()
	local numsaved = GetNumSavedInstances()
	if numsaved > 0 then
		for i = 1, numsaved do
			local name, id, expires, diff, locked, extended, mostsig, raid, players, diffname = GetSavedInstanceInfo(i)
			if locked then
				return name, id, expires, diff, locked, extended, mostsig, raid, players, diffname
			end
		end
	end
end

function addon:normalizeName(str)
  return str:gsub("%p",""):gsub("%s"," "):gsub("%s%s"," "):gsub("^%s+",""):gsub("%s+$",""):upper()
end

addon.transInstance = {
  -- lockout hyperlink id = LFDID
  [543] = 188, 	-- Hellfire Citadel: Ramparts
  [540] = 189, 	-- Hellfire Citadel: Shattered Halls : deDE
  [534] = 195, 	-- The Battle for Mount Hyjal
  [509] = 160, 	-- Ruins of Ahn'Qiraj
  [557] = 179,  -- Auchindoun: Mana-Tombs : ticket 72 zhTW
}

-- some instances (like sethekk halls) are named differently by GetSavedInstanceInfo() and LFGGetDungeonInfoByID()
-- we use the latter name to key our database, and this function to convert as needed
function addon:FindInstance(name, raid)
  if not name or #name == 0 then return nil end
  -- first pass, direct match
  local info = vars.db.Instances[name]
  if info then
    return name, info.LFDID
  end
  -- second pass, normalized substring match
  local nname = addon:normalizeName(name)
  for truename, info in pairs(vars.db.Instances) do
    local tname = addon:normalizeName(truename)
    if (tname:find(nname, 1, true) or nname:find(tname, 1, true)) and
       info.Raid == raid then -- Tempest Keep: The Botanica
      --debug("FindInstance("..name..") => "..truename)
      return truename, info.LFDID
    end
  end
  -- final pass, hyperlink id lookup
  for i = 1, GetNumSavedInstances() do
     local link = GetSavedInstanceChatLink(i) or ""
     local lid,lname = link:match(":(%d+):%d+:%d+\124h%[(.+)%]\124h")
     lname = lname and addon:normalizeName(lname) 
     lid = lid and tonumber(lid)
     local lfdid = lid and addon.transInstance[lid]
     if lname == nname and lfdid then
       local truename = select(3,addon:UpdateInstance(lfdid))
       if truename then
         return truename, lfdid
       end
     end
  end
  return nil
end

-- provide either id or name/raid to get the instance truename and db entry
function addon:LookupInstance(id, name, raid)
  --debug("LookupInstance("..(id or "nil")..","..(name or "nil")..","..(raid and "true" or "false")..")")
  local truename, instance
  if name then
    truename, id = addon:FindInstance(name, raid)
  end
  if id then
    truename = select(3,addon:UpdateInstance(id))
  end
  if truename then
    instance = vars.db.Instances[truename]
  end
  if not instance then
    debug("LookupInstance() failed to find instance: "..(name or "")..":"..(id or 0).." : "..GetLocale())
    addon.warned = addon.warned or {}
    if not addon.warned[name] then
      addon.warned[name] = true
      local lid
      for i = 1, GetNumSavedInstances() do
        local link = GetSavedInstanceChatLink(i) or ""
        local tlid,tlname = link:match(":(%d+):%d+:%d+\124h%[(.+)%]\124h")
	if tlname == name then lid = tlid end
      end
      print("SavedInstances: ERROR: Refresh() failed to find instance: "..name.." : "..GetLocale().." : "..(lid or "x"))
      print(" Please report this bug at: http://www.wowace.com/addons/saved_instances/tickets/")
    end
    instance = {}
    --vars.db.Instances[name] = instance
  end
  return truename, instance
end

function addon:InstanceCategory(instance)
	if not instance then return nil end
	local instance = vars.db.Instances[instance]
	if instance.Holiday then return "H" end
	return ((instance.Raid and "R") or ((not instance.Raid) and "D")) .. instance.Expansion
end

function addon:InstancesInCategory(targetcategory)
	-- returns a table of the form { "instance1", "instance2", ... }
	if (not targetcategory) then return { } end
	local list = { }
	for instance, _ in pairs(vars.db.Instances) do
		if addon:InstanceCategory(instance) == targetcategory then
			list[#list+1] = instance
		end
	end
	return list
end

function addon:CategorySize(category)
	if not category then return nil end
	local i = 0
	for instance, _ in pairs(vars.db.Instances) do
		if category == addon:InstanceCategory(instance) then
			i = i + 1
		end
	end
	return i
end

function addon:instanceBosses(instance,toon,diff)
  local killed,total,base = 0,0,1
  local inst = vars.db.Instances[instance]
  if not inst or not inst.LFDID then return 0,0,1 end
  total = GetLFGDungeonNumEncounters(inst.LFDID)
  local save = inst[toon] and inst[toon][diff]
  if not save then
      return killed, total, base
  elseif save.Link then
      local bits = save.Link:match(":(%d+)\124h")
      bits = bits and tonumber(bits)
      if bits then
        while bits > 0 do
	  if bit.band(bits,1) > 0 then
	    killed = killed + 1
	  end
          bits = bit.rshift(bits,1)
	end
      end
  elseif save.ID < 0 then
    for i=1,-1*save.ID do
      killed = killed + (save[i] and 1 or 0)
    end
    local LFR = addon.LFRInstances[inst.LFDID]
    if LFR then
      total = LFR.total or total
      base = LFR.base or base
    end
  end 
  return killed, total, base
end

local function instanceSort(i1, i2)
  local instance1 = vars.db.Instances[i1]
  local instance2 = vars.db.Instances[i2]
  local level1 = instance1.RecLevel or 0
  local level2 = instance2.RecLevel or 0
  local id1 = instance1.LFDID or 0
  local id2 = instance2.LFDID or 0
  local key1 = level1*10000+id1
  local key2 = level2*10000+id2
  if vars.db.Tooltip.ReverseInstances then
      return key1 < key2
  else
      return key2 < key1
  end
end

function addon:OrderedInstances(category)
	-- returns a table of the form { "instance1", "instance2", ... }
	local instances = addon:InstancesInCategory(category)
	table.sort(instances, instanceSort)
	return instances
end


function addon:OrderedCategories()
	-- returns a table of the form { "category1", "category2", ... }
	local orderedlist = { }
	local firstexpansion, lastexpansion, expansionstep, firsttype, lasttype
	if vars.db.Tooltip.NewFirst then
		firstexpansion = GetExpansionLevel()
		lastexpansion = 0
		expansionstep = -1
	else
		firstexpansion = 0
		lastexpansion = GetExpansionLevel()
		expansionstep = 1
	end
	if vars.db.Tooltip.RaidsFirst then
		firsttype = "R"
		lasttype = "D"
	else
		firsttype = "D"
		lasttype = "R"
	end
	for i = firstexpansion, lastexpansion, expansionstep do
		orderedlist[1+#orderedlist] = firsttype .. i
		if vars.db.Tooltip.CategorySort == "EXPANSION" then
			orderedlist[1+#orderedlist] = lasttype .. i
		end
	end
	if vars.db.Tooltip.CategorySort == "TYPE" then
		for i = firstexpansion, lastexpansion, expansionstep do
			orderedlist[1+#orderedlist] = lasttype .. i
		end
	end
	return orderedlist
end

local function DifficultyString(instance, diff, toon, expired)
	local setting,color
	if not instance then
		setting = "D" .. diff
	else
		local inst = vars.db.Instances[instance]
		if inst.Expansion == 0 and inst.Raid then
		  setting = "R0"
		elseif inst.Raid then
		  setting = "R"..(diff-2)
		else
		  setting = "D"..diff
		end
	end
	local prefs = vars.db.Indicators
	if expired then
	  color = { 0.5, 0.5, 0.5, 1 }
	elseif prefs[setting .. "ClassColor"] then
		local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
		color = {
		RAID_CLASS_COLORS[vars.db.Toons[toon].Class].r,
		RAID_CLASS_COLORS[vars.db.Toons[toon].Class].g,
		RAID_CLASS_COLORS[vars.db.Toons[toon].Class].b,
		1,
	}
	else
	        prefs[setting.."Color"]  = prefs[setting.."Color"] or vars.defaultDB.Indicators[setting.."Color"]
		color = prefs[setting.."Color"] 
	end
	local text = prefs[setting.."Text"] or vars.defaultDB.Indicators[setting.."Text"]
	local indicator = prefs[setting.."Indicator"] or vars.defaultDB.Indicators[setting.."Indicator"]
	text = ColorCodeOpen(color) .. text .. FONTEND
	if text:find("ICON", 1, true) and indicator ~= "BLANK" then
            text = text:gsub("ICON", FONTEND .. vars.Indicators[indicator] .. ColorCodeOpen(color))
	end
	if text:find("KILLED", 1, true) or text:find("TOTAL", 1, true) then
	  local killed, total = addon:instanceBosses(instance,toon,diff)
	  text = text:gsub("KILLED",killed)
	  text = text:gsub("TOTAL",total)
	end
	return text
end

-- run about once per session to update our database of instance info
local instancesUpdated = false
function addon:UpdateInstanceData()
  --debug("UpdateInstanceData()")
  local dungeonDB = (GetLFDChoiceInfo and GetLFDChoiceInfo()) or -- 4.2 and earlier
                    LFDDungeonList -- lazily updated
  if not dungeonDB or instancesUpdated then return end  -- nil before first use in UI
  instancesUpdated = true
  core:UnregisterEvent("LFG_UPDATE_RANDOM_INFO")
  local count = 0
  local starttime = debugprofilestop()
  local maxid = 600
  for id=1,maxid do -- start with brute force
    if addon:UpdateInstance(id) then
      count = count + 1
    end
  end
  local raidHeaders, raidDB = GetFullRaidList()
  for _,rinfo in pairs(raidDB) do
    for _,rid in pairs(rinfo) do
      if rid > 0 and rid > maxid then -- ignore headers
        if addon:UpdateInstance(rid) then
          count = count + 1
	end
      end
    end
  end
  for did,dinfo in pairs(dungeonDB) do
    local id = (type(dinfo) == "number" and dinfo) or did
    if id > 0 and id > maxid then -- ignore headers
      if addon:UpdateInstance(id) then
        count = count + 1
      end
    end
  end
  starttime = debugprofilestop()-starttime
  debug("UpdateInstanceData(): completed "..count.." updates in "..string.format("%.6f",starttime/1000.0).." sec.")
  if addon.RefreshPending then
    addon.RefreshPending = nil
    core:Refresh()
  end
end

--if LFDParentFrame then hooksecurefunc(LFDParentFrame,"Show",function() addon:UpdateInstanceData() end) end

function addon:UpdateInstance(id)
  --debug("UpdateInstance: "..id)
  if not id or id <= 0 then return end
  local currentbuild = select(2, GetBuildInfo())
  currentbuild = tonumber(currentbuild)
  local name, typeID, subtypeID, 
        minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, 
	expansionLevel, groupID, textureFilename, 
	difficulty, maxPlayers, description, isHoliday = nil
  if LFGGetDungeonInfoByID and LFGDungeonInfo then -- 4.2 (requires LFGDungeonInfo)
    local instanceInfo = LFGGetDungeonInfoByID(id)
    if not instanceInfo then return end
    name, typeID, -- subtypeID,
    minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, 
    expansionLevel, groupID, textureFilename, 
    difficulty, maxPlayers, description, isHoliday
	= unpack(instanceInfo)
  elseif GetLFGDungeonInfo and currentbuild > 14545 then -- 4.3
    name, typeID, subtypeID,
    minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, 
    expansionLevel, groupID, textureFilename, 
    difficulty, maxPlayers, description, isHoliday
        = GetLFGDungeonInfo(id)
  else -- dont know how to query
    return
  end
  -- name is nil for non-existent ids
  -- isHoliday is for single-boss holiday instances that don't generate raid saves
  -- typeID 4 = outdoor area, typeID 6 = random
  if not name or not expansionLevel or not recLevel or typeID > 2 then return end
  if name:find(PVP_RATED_BATTLEGROUND) then return end -- ignore 10v10 rated bg

  local instance = vars.db.Instances[name]
  local newinst = false
  if not instance then
    debug("UpdateInstance: "..id.." "..(name or "nil").." "..(expansionLevel or "nil").." "..(recLevel or "nil").." "..(maxPlayers or "nil"))
    instance = {}
    newinst = true
  end
  vars.db.Instances[name] = instance
  instance.Show = (instance.Show and addon.showopts[instance.Show]) or "saved"
  instance.Encounters = nil -- deprecated
  --instance.LFDupdated = currentbuild
  instance.LFDupdated = nil
  instance.LFDID = id
  instance.Holiday = isHoliday or nil
  instance.Expansion = expansionLevel
  instance.RecLevel = instance.RecLevel or recLevel
  if recLevel < instance.RecLevel then instance.RecLevel = recLevel end -- favor non-heroic RecLevel
  instance.Raid = (tonumber(maxPlayers) > 5 or (tonumber(maxPlayers) == 0 and typeID == 2))
  return newinst, true, name
end

function addon:updateSpellTip(spellid)
  local slot 
  vars.db.spelltip = vars.db.spelltip or {}
  vars.db.spelltip[spellid] = vars.db.spelltip[spellid] or {}
  for i=1,20 do
    local id = select(11,UnitDebuff("player",i))
    if id == spellid then slot = i end
  end
  if slot then
    scantt:SetOwner(UIParent,"ANCHOR_NONE")
    scantt:SetUnitDebuff("player",slot)
    for i=1,scantt:NumLines()-1 do
      local left = _G[scantt:GetName().."TextLeft"..i]
      vars.db.spelltip[spellid][i] = left:GetText()
    end
  end
end

-- run regularly to update lockouts and cached data for this toon
function addon:UpdateToonData()
        addon.activeHolidays = addon.activeHolidays or {}
        wipe(addon.activeHolidays)
	-- blizz internally conflates all the holiday flags, so we have to detect which is really active
        for i=1, GetNumRandomDungeons() do 
	   local id, name = GetLFGRandomDungeonInfo(i);
	   local d = vars.db.Instances[name]
	   if d and d.Holiday then
	     addon.activeHolidays[name] = true
	   end
	end

	for instance, i in pairs(vars.db.Instances) do
		for toon, t in pairs(vars.db.Toons) do
			if i[toon] then
				for difficulty, d in pairs(i[toon]) do
					if d.Expires and d.Expires < time() then
					    d.Locked = false
				            d.Expires = 0
					    if d.ID < 0 then
					      i[toon][difficulty] = nil
					    end
					end
				end
			end
		end
		if i.Holiday and addon.activeHolidays[instance] then
		  local id = i.LFDID
		  GetLFGDungeonInfo(id) -- forces update
		  local donetoday = GetLFGDungeonRewards(id)
		  local expires = addon:GetNextDailyResetTime()
		  if donetoday and expires then
		    i[thisToon] = i[thisToon] or {}
		    i[thisToon][1] = i[thisToon][1] or {}
		    local d = i[thisToon][1]
		    d.ID = -1
		    d.Locked = false
		    d.Expires = expires
		  end
		end
	end
	-- update random toon info
	local t = vars.db.Toons[thisToon]
	local now = time()
	if addon.logout or addon.PlayedTime or addon.playedpending then
	  if addon.PlayedTime then
	    local more = now - addon.PlayedTime
	    t.PlayedTotal = t.PlayedTotal + more
	    t.PlayedLevel = t.PlayedLevel + more
	    addon.PlayedTime = now
	  end
	else
	  addon.playedpending = true
	  addon.playedreg = {}
	  for i=1,10 do
	    local c = _G["ChatFrame"..i]
	    if c and c:IsEventRegistered("TIME_PLAYED_MSG") then
	      c:UnregisterEvent("TIME_PLAYED_MSG") -- prevent spam
	      addon.playedreg[c] = true
	    end
	  end
	  RequestTimePlayed()
	end
        t.LFG1 = GetTimeToTime(GetLFGRandomCooldownExpiration()) or t.LFG1
	t.LFG2 = GetTimeToTime(select(7,UnitDebuff("player",GetSpellInfo(71041)))) or t.LFG2 -- GetLFGDeserterExpiration()
	if t.LFG2 then addon:updateSpellTip(71041) end
	t.pvpdesert = GetTimeToTime(select(7,UnitDebuff("player",GetSpellInfo(26013)))) or t.pvpdesert
	if t.pvpdesert then addon:updateSpellTip(26013) end
	for toon, ti in pairs(vars.db.Toons) do
		if ti.LFG1 and (ti.LFG1 < now) then ti.LFG1 = nil end
		if ti.LFG2 and (ti.LFG2 < now) then ti.LFG2 = nil end
		if ti.pvpdesert and (ti.pvpdesert < now) then ti.pvpdesert = nil end
	        ti.Quests = ti.Quests or {}
	end
	local IL,ILe = GetAverageItemLevel()
	if IL and tonumber(IL) and tonumber(IL) > 0 then -- can fail during logout
	  t.IL, t.ILe = tonumber(IL), tonumber(ILe)
	end
	-- Daily Reset
	local nextreset = addon:GetNextDailyResetTime()
	if nextreset and nextreset > time() then
	 for toon, ti in pairs(vars.db.Toons) do
	  if not ti.DailyResetTime or (ti.DailyResetTime < time()) then 
	    ti.DailyCount = 0
	    for id,qi in pairs(ti.Quests) do
	      if qi.isDaily then
	        ti.Quests[id] = nil
	      end
	    end
	    ti.DailyResetTime = nextreset
          end 
	 end
	end
	-- Weekly Reset
	local nextreset = addon:GetNextWeeklyResetTime()
	if nextreset and nextreset > time() then
	 for toon, ti in pairs(vars.db.Toons) do
	  if not ti.WeeklyResetTime or (ti.WeeklyResetTime < time()) then 
	    ti.currency = ti.currency or {}
	    for _,idx in ipairs(currency) do
	      ti.currency[idx] = ti.currency[idx] or {}
	      ti.currency[idx].earnedThisWeek = 0
	    end
	    ti.WeeklyResetTime = nextreset
          end 
	 end
	end
	for toon, ti in pairs(vars.db.Toons) do
	  for id,qi in pairs(ti.Quests) do
	      if not qi.isDaily and (qi.Expires or 0) < time() then
	        ti.Quests[id] = nil
	      end
	  end
	end
	local dc = GetDailyQuestsCompleted()
	if dc > 0 then -- zero during logout
	  t.DailyCount = dc
	end
	t.currency = t.currency or {}
	for _,idx in pairs(currency) do
	  local ci = t.currency[idx] or {}
	  _, ci.amount, _, ci.earnedThisWeek, ci.weeklyMax, ci.totalMax = GetCurrencyInfo(idx)
          if idx == 396 then -- VP x 100, CP x 1
            ci.weeklyMax = ci.weeklyMax and math.floor(ci.weeklyMax/100)
          end
          ci.totalMax = ci.totalMax and math.floor(ci.totalMax/100)
          ci.season = addon:GetSeasonCurrency(idx)
	  t.currency[idx] = ci
	end
        if not addon.logout then
	  t.Money = GetMoney()
	end
end

local special_weekly_defaults = {
     -- Darkmoon Faire "weekly" quests
     [29433] = true, -- Test Your Strength
  }

function addon:QuestIsDarkmoonMonthly()
  if QuestIsDaily() then return false end
  for i=1,GetNumRewardCurrencies() do
    local name,texture,amount = GetQuestCurrencyInfo("reward",i)
    if texture:find("_ticket_darkmoon_") then
      return true
    end
  end
  return false
end

local function SI_GetQuestReward()
  local t = vars and vars.db.Toons[thisToon]
  if not t then return end
  local id = GetQuestID() or -1
  local title = GetTitleText() or "<unknown>"
  local link = nil
  local isMonthly = addon:QuestIsDarkmoonMonthly()
  local isWeekly = QuestIsWeekly()
  local isDaily = QuestIsDaily()
  for index = 1, GetNumQuestLogEntries() do
     local questLogTitleText, level, questTag, suggestedGroup, isHeader, 
           isCollapsed, isComplete, isDaily, questID, startEvent = GetQuestLogTitle(index)
     if questID == id then
        link = GetQuestLink(index)
        break
     end
  end
  local expires
  if isWeekly then
    expires = addon:GetNextWeeklyResetTime()
  elseif isMonthly then 
    expires = addon:GetNextDarkmoonResetTime()
  end
  debug("Quest Complete: "..(link or title).." "..id.." : "..title.." "..
        (isMonthly and "(Monthly)" or isWeekly and "(Weekly)" or isDaily and "(Daily)" or "(Regular)").."  "..
	(expires and date("%c",expires) or ""))
  if not isMonthly and not isWeekly and not isDaily then return end
  t.Quests = t.Quests or {}
  t.Quests[id] = { ["Title"] = title, ["Link"] = link, 
                   ["isDaily"] = isDaily, 
		   ["Expires"] = expires,
		   ["Zone"] = GetRealZoneText() }
end
hooksecurefunc("GetQuestReward", SI_GetQuestReward)

local function coloredText(fontstring)
  if not fontstring then return nil end
  local text = fontstring:GetText()
  if not text then return nil end
  local textR, textG, textB, textAlpha = fontstring:GetTextColor() 
  return string.format("|c%02x%02x%02x%02x"..text.."|r", 
                       textAlpha*255, textR*255, textG*255, textB*255)
end

local function ShowToonTooltip(cell, arg, ...)
	local toon = arg[1]
	if not toon then return end
	local t = vars.db.Toons[toon]
	if not t then return end
	indicatortip = QTip:Acquire("SavedInstancesIndicatorTooltip", 2, "LEFT","RIGHT")
	indicatortip:Clear()
	indicatortip:SetHeaderFont(tooltip:GetHeaderFont())
	indicatortip:SetCell(indicatortip:AddHeader(),1,ClassColorise(t.Class, toon))
	indicatortip:SetCell(1,2,ClassColorise(t.Class, LEVEL.." "..t.Level.." "..(t.LClass or "")))
	indicatortip:AddLine(STAT_AVERAGE_ITEM_LEVEL,("%d "):format(t.IL or 0)..STAT_AVERAGE_ITEM_LEVEL_EQUIPPED:format(t.ILe or 0))
	if t.Money then
	  indicatortip:AddLine(MONEY,GetMoneyString(t.Money))
	end
	if t.PlayedTotal and t.PlayedLevel and ChatFrame_TimeBreakDown then
	  --indicatortip:AddLine((TIME_PLAYED_TOTAL):format((TIME_DAYHOURMINUTESECOND):format(ChatFrame_TimeBreakDown(t.PlayedTotal))))
	  --indicatortip:AddLine((TIME_PLAYED_LEVEL):format((TIME_DAYHOURMINUTESECOND):format(ChatFrame_TimeBreakDown(t.PlayedLevel))))
	  indicatortip:AddLine((TIME_PLAYED_TOTAL):format(""),SecondsToTime(t.PlayedTotal))
	  indicatortip:AddLine((TIME_PLAYED_LEVEL):format(""),SecondsToTime(t.PlayedLevel))
	end
	indicatortip:SetAutoHideDelay(0.1, tooltip)
	indicatortip:SmartAnchorTo(tooltip)
	addon:SkinFrame(indicatortip,"SavedInstancesIndicatorTooltip")
	indicatortip:Show()
end

local function ShowQuestTooltip(cell, arg, ...)
	local toon,qstr,isDaily = unpack(arg)
	if not toon then return end
	indicatortip = QTip:Acquire("SavedInstancesIndicatorTooltip", 2, "LEFT", "RIGHT")
	indicatortip:Clear()
	indicatortip:SetHeaderFont(tooltip:GetHeaderFont())
	indicatortip:AddHeader(ClassColorise(vars.db.Toons[toon].Class, toon), qstr)
        local ql = {}
        for id,qi in pairs(vars.db.Toons[toon].Quests) do
          if (not isDaily) == (not qi.isDaily) then
	     table.insert(ql,(qi.Zone or "").." # "..id)
          end
        end
        table.sort(ql)
        for _,e in ipairs(ql) do
          local id = tonumber(e:match("# (%d+)"))
          local qi = id and vars.db.Toons[toon].Quests[id]
          local line = indicatortip:AddLine()
	  indicatortip:SetCell(line,1,(qi.Zone or ""),"LEFT")
          indicatortip:SetCell(line,2,(qi.Link or qi.Title),"RIGHT")
        end
	indicatortip:SetAutoHideDelay(0.1, tooltip)
	indicatortip:SmartAnchorTo(tooltip)
	addon:SkinFrame(indicatortip,"SavedInstancesIndicatorTooltip")
	indicatortip:Show()
end

local function ShowHistoryTooltip(cell, arg, ...)
        addon:HistoryUpdate()
        indicatortip = QTip:Acquire("SavedInstancesIndicatorTooltip", 2, "LEFT", "LEFT")
        indicatortip:Clear()
        local tmp = {}
        local cnt = 0
        for _,ii in pairs(db.History) do
           table.insert(tmp,ii)
        end
        local cnt = #tmp
        table.sort(tmp, function(i1,i2) return i1.last < i2.last end)
        indicatortip:SetHeaderFont(tooltip:GetHeaderFont())
        indicatortip:SetCell(indicatortip:AddHeader(),1,GOLDFONT..cnt.." "..L["Recent Instances"]..": "..FONTEND,"LEFT",2)
        for _,ii in ipairs(tmp) do
           local tstr = REDFONT..SecondsToTime(ii.last+addon.histReapTime - time(),false,false,1)..FONTEND
           indicatortip:AddLine(tstr, ii.desc)
        end
        indicatortip:AddLine("")
        indicatortip:SetCell(indicatortip:AddLine(),1,
           string.format(L["These are the instances that count towards the %i instances per hour account limit, and the time until they expire."],
                         addon.histLimit),"LEFT",2,nil,nil,nil,250)
        indicatortip:SetAutoHideDelay(0.1, tooltip)
        indicatortip:SmartAnchorTo(tooltip)
	addon:SkinFrame(indicatortip,"SavedInstancesIndicatorTooltip")
        indicatortip:Show()
end

local function ShowIndicatorTooltip(cell, arg, ...)
	local instance = arg[1]
	local toon = arg[2]
	local diff = arg[3]
	if not instance or not toon or not diff then return end
	indicatortip = QTip:Acquire("SavedInstancesIndicatorTooltip", 2, "LEFT", "RIGHT")
	indicatortip:Clear()
	indicatortip:SetHeaderFont(tooltip:GetHeaderFont())
	local thisinstance = vars.db.Instances[instance]
        local info = thisinstance[toon][diff]
	local id = info.ID
	local nameline, _ = indicatortip:AddHeader()
	indicatortip:SetCell(nameline, 1, DifficultyString(instance, diff, toon) .. " " .. GOLDFONT .. instance .. FONTEND, indicatortip:GetHeaderFont(), "LEFT", 2)
	local toonstr = (db.Tooltip.ShowServer and toon) or strsplit(' ', toon)
	indicatortip:AddHeader(ClassColorise(vars.db.Toons[toon].Class, toonstr), addon:idtext(thisinstance,diff,info))
	local EMPH = " !!! "
	if info.Extended then
	  indicatortip:SetCell(indicatortip:AddLine(),1,WHITEFONT .. EMPH .. L["Extended Lockout - Not yet saved"] .. EMPH .. FONTEND,"CENTER",2)
	elseif info.Locked == false and info.ID > 0 then
	  indicatortip:SetCell(indicatortip:AddLine(),1,WHITEFONT .. EMPH .. L["Expired Lockout - Can be extended"] .. EMPH .. FONTEND,"CENTER",2)
	end
	if info.Expires > 0 then
	  indicatortip:AddLine(YELLOWFONT .. L["Time Left"] .. ":" .. FONTEND, SecondsToTime(thisinstance[toon][diff].Expires - time()))
	end
	indicatortip:SetAutoHideDelay(0.1, tooltip)
	indicatortip:SmartAnchorTo(tooltip)
	if info.Link then
	  scantt:SetOwner(UIParent,"ANCHOR_NONE")
	  scantt:SetHyperlink(thisinstance[toon][diff].Link)
	  local name = scantt:GetName()
	  for i=2,scantt:NumLines() do
	    local left,right = _G[name.."TextLeft"..i], _G[name.."TextRight"..i]
	    if right and right:GetText() then
	      indicatortip:AddLine(coloredText(left), coloredText(right))
	    else
	      indicatortip:SetCell(indicatortip:AddLine(),1,coloredText(left),"CENTER",2)
	    end
	  end
	end
	if info.ID < 0 then
	  local killed, total, base = addon:instanceBosses(instance,toon,diff)
          for i=base,base+total-1 do
            local bossname, texture = GetLFGDungeonEncounterInfo(thisinstance.LFDID, i);
            if info[i] then 
              indicatortip:AddLine(bossname, REDFONT..ERR_LOOT_GONE..FONTEND)
            else
              indicatortip:AddLine(bossname, GREENFONT..AVAILABLE..FONTEND)
            end
          end
        end
	addon:SkinFrame(indicatortip,"SavedInstancesIndicatorTooltip")
	indicatortip:Show()
end

local colorpat = "\124c%c%c%c%c%c%c%c%c"
local weeklycap = CURRENCY_WEEKLY_CAP:gsub("%%%d*\$?([ds])","%%%1")
local weeklycap_scan = weeklycap:gsub("%%d","(%%d+)"):gsub("%%s","(\124c%%x%%x%%x%%x%%x%%x%%x%%x)")
local totalcap = CURRENCY_TOTAL_CAP:gsub("%%%d*\$?([ds])","%%%1")
local totalcap_scan = totalcap:gsub("%%d","(%%d+)"):gsub("%%s","(\124c%%x%%x%%x%%x%%x%%x%%x%%x)")
local season_scan = CURRENCY_SEASON_TOTAL:gsub("%%%d*\$?([ds])","(%%%1*)")

function addon:GetSeasonCurrency(idx) 
  scantt:SetOwner(UIParent,"ANCHOR_NONE")
  scantt:SetCurrencyByID(idx)
  local name = scantt:GetName()
  for i=1,scantt:NumLines() do
    local left = _G[name.."TextLeft"..i]
    if left:GetText():find(season_scan) then
      return left:GetText()
    end
  end  
  return nil
end

local function ShowSpellIDTooltip(cell, arg, ...)
  local toon, spellid, timestr = unpack(arg)
  if not toon or not spellid or not timestr then return end
  indicatortip = QTip:Acquire("SavedInstancesIndicatorTooltip", 2, "LEFT", "RIGHT")
  indicatortip:Clear()
  indicatortip:SetHeaderFont(tooltip:GetHeaderFont())
  indicatortip:AddHeader(ClassColorise(vars.db.Toons[toon].Class, strsplit(' ', toon)), timestr)
  if spellid > 0 then 
    local tip = vars.db.spelltip and vars.db.spelltip[spellid]
    for i=1,#tip do
      indicatortip:AddLine("")
      indicatortip:SetCell(indicatortip:GetLineCount(),1,tip[i], nil, "LEFT",2, nil, nil, nil, 250)
    end
  else
    local queuestr = LFG_RANDOM_COOLDOWN_YOU:match("^(.+)\n")
    indicatortip:AddLine(LFG_TYPE_RANDOM_DUNGEON)
    indicatortip:AddLine("")
    indicatortip:SetCell(indicatortip:GetLineCount(),1,queuestr, nil, "LEFT",2, nil, nil, nil, 250)
  end

  indicatortip:SetAutoHideDelay(0.1, tooltip)
  indicatortip:SmartAnchorTo(tooltip)
  addon:SkinFrame(indicatortip,"SavedInstancesIndicatorTooltip")
  indicatortip:Show()
end

local function ShowCurrencyTooltip(cell, arg, ...)
  local toon, idx, ci = unpack(arg)
  if not toon or not idx or not ci then return end
  local name,_,tex = GetCurrencyInfo(idx)
  tex = " \124TInterface\\Icons\\"..tex..":0\124t"
  indicatortip = QTip:Acquire("SavedInstancesIndicatorTooltip", 2, "LEFT", "RIGHT")
  indicatortip:Clear()
  indicatortip:SetHeaderFont(tooltip:GetHeaderFont())
  indicatortip:AddHeader(ClassColorise(vars.db.Toons[toon].Class, strsplit(' ', toon)), "("..(ci.amount or "0")..tex..")")

  scantt:SetOwner(UIParent,"ANCHOR_NONE")
  scantt:SetCurrencyByID(idx)
  local name = scantt:GetName()
  for i=1,scantt:NumLines() do
    local left = _G[name.."TextLeft"..i]
    if left:GetText():find(weeklycap_scan) or 
       left:GetText():find(totalcap_scan) or
       left:GetText():find(season_scan) then
      -- omit player's values
    else
      indicatortip:AddLine("")
      indicatortip:SetCell(indicatortip:GetLineCount(),1,coloredText(left), nil, "LEFT",2, nil, nil, nil, 250)
    end
  end
  if ci.weeklyMax and ci.weeklyMax > 0 then
    indicatortip:AddLine(weeklycap:format("", (ci.earnedThisWeek or 0), (ci.weeklyMax or 0)))
  end
  if ci.totalMax and ci.totalMax > 0 then
    indicatortip:AddLine(totalcap:format("", (ci.amount or 0), (ci.totalMax or 0)))
  end
  if ci.season and #ci.season > 0 then
    indicatortip:AddLine(ci.season)
  end

  indicatortip:SetAutoHideDelay(0.1, tooltip)
  indicatortip:SmartAnchorTo(tooltip)
  addon:SkinFrame(indicatortip,"SavedInstancesIndicatorTooltip")
  indicatortip:Show()
end


-- global addon code below

function core:OnInitialize()
	SavedInstancesDB = SavedInstancesDB or vars.defaultDB
	-- begin backwards compatibility
	if not SavedInstancesDB.DBVersion or SavedInstancesDB.DBVersion < 10 then
		SavedInstancesDB = vars.defaultDB
	end
	if SavedInstancesDB.DBVersion < 11 then
		SavedInstancesDB.Indicators = vars.defaultDB.Indicators
	end
	-- end backwards compatibilty
	db = db or SavedInstancesDB
	vars.db = db
	config = vars.config
	db.Toons[thisToon] = db.Toons[thisToon] or { }
	db.Toons[thisToon].LClass, db.Toons[thisToon].Class = UnitClass("player")
	db.Toons[thisToon].Level = UnitLevel("player")
	db.Toons[thisToon].Show = db.Toons[thisToon].Show or "saved"
	db.Lockouts = nil -- deprecated
	db.History = db.History or {}
	db.Tooltip.ReportResets = (db.Tooltip.ReportResets == nil and true) or db.Tooltip.ReportResets
	db.Tooltip.LimitWarn = (db.Tooltip.LimitWarn == nil and true) or db.Tooltip.LimitWarn
	db.Tooltip.ShowHoliday = (db.Tooltip.ShowHoliday == nil and true) or db.Tooltip.ShowHoliday
	db.Tooltip.TrackDailyQuests = (db.Tooltip.TrackDailyQuests == nil and true) or db.Tooltip.TrackDailyQuests
	db.Tooltip.TrackWeeklyQuests = (db.Tooltip.TrackWeeklyQuests == nil and true) or db.Tooltip.TrackWeeklyQuests
	db.Tooltip.ServerSort = (db.Tooltip.ServerSort == nil and true) or db.Tooltip.ServerSort
	db.Tooltip.SelfFirst = (db.Tooltip.SelfFirst == nil and true) or db.Tooltip.SelfFirst
        addon:SetupVersion()
	RequestRaidInfo() -- get lockout data
	if LFGDungeonList_Setup then pcall(LFGDungeonList_Setup) end -- try to force LFG frame to populate instance list LFDDungeonList
	vars.dataobject = vars.LDB and vars.LDB:NewDataObject("SavedInstances", {
		text = "",
		type = "launcher",
		icon = "Interface\\Addons\\SavedInstances\\icon.tga",
		OnEnter = function(frame)
		      if not addon:IsDetached() then
			core:ShowTooltip(frame)
	              end
		end,
		OnLeave = function(frame) end,
		OnClick = function(frame, button)
			if button == "MiddleButton" then
				ToggleFriendsFrame(4) -- open Blizzard Raid window
				RaidInfoFrame:Show()
			elseif button == "LeftButton" then
			   addon:ToggleDetached()
			else
				config:ShowConfig()
			end
		end
	})
	if vars.icon then
		vars.icon:Register("SavedInstances", vars.dataobject, db.MinimapIcon)
	end
end

function addon:SetupVersion()
   if addon.version then return end
   local svnrev = 0
   local T_svnrev = addon.svnrev
   T_svnrev["X-Build"] = tonumber((GetAddOnMetadata(addonName, "X-Build") or ""):match("%d+"))
   T_svnrev["X-Revision"] = tonumber((GetAddOnMetadata(addonName, "X-Revision") or ""):match("%d+"))
   for _,v in pairs(T_svnrev) do -- determine highest file revision
     if v and v > svnrev then
       svnrev = v
     end
   end
   addon.revision = svnrev

   T_svnrev["X-Curse-Packaged-Version"] = GetAddOnMetadata(addonName, "X-Curse-Packaged-Version")
   T_svnrev["Version"] = GetAddOnMetadata(addonName, "Version")
   addon.version = T_svnrev["X-Curse-Packaged-Version"] or T_svnrev["Version"] or "@"
   if string.find(addon.version, "@") then -- dev copy uses "@.project-version.@"
      addon.version = "r"..svnrev
   end
end

function core:OnEnable()
	self:RegisterEvent("UPDATE_INSTANCE_INFO", "Refresh")
	self:RegisterEvent("LFG_UPDATE_RANDOM_INFO", function() addon:UpdateInstanceData() end)
	self:RegisterEvent("RAID_INSTANCE_WELCOME", RequestRaidInfo)
	self:RegisterEvent("CHAT_MSG_SYSTEM", "CheckSystemMessage")
	self:RegisterEvent("CHAT_MSG_CURRENCY", "CheckSystemMessage")
	self:RegisterEvent("CHAT_MSG_LOOT", "CheckSystemMessage")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", RequestRaidInfo)
	self:RegisterEvent("LFG_LOCK_INFO_RECEIVED", RequestRaidInfo)
	self:RegisterEvent("PLAYER_LOGOUT", function() addon.logout = true ; addon:UpdateToonData() end) -- update currency spent
	self:RegisterEvent("LFG_COMPLETION_REWARD") -- for random daily dungeon tracking
	self:RegisterEvent("TIME_PLAYED_MSG", function(_,total,level) 
	                      local t = thisToon and vars and vars.db and vars.db.Toons[thisToon]
	                      if total > 0 and t then
			        t.PlayedTotal = total
			        t.PlayedLevel = level
			      end
			      addon.PlayedTime = time()
			      if addon.playedpending then
			        for c,_ in pairs(addon.playedreg) do
				  c:RegisterEvent("TIME_PLAYED_MSG") -- Restore default 
			        end
			        addon.playedpending = false
			      end
	                   end)

        if not addon.resetDetect then
          addon.resetDetect = CreateFrame("Button", "SavedInstancesResetDetectHiddenFrame", UIParent)
          for _,e in pairs({
	    "RAID_INSTANCE_WELCOME", 
	    "PLAYER_ENTERING_WORLD", "CHAT_MSG_SYSTEM", "CHAT_MSG_ADDON",
            "ZONE_CHANGED_NEW_AREA", 
	    "INSTANCE_BOOT_START", "INSTANCE_BOOT_STOP", "GROUP_ROSTER_UPDATE",
            }) do
            addon.resetDetect:RegisterEvent(e)
          end
        end
        addon.resetDetect:SetScript("OnEvent", addon.HistoryEvent)
        RegisterAddonMessagePrefix(addonName)
	addon:HistoryEvent("PLAYER_ENTERING_WORLD") -- update after initial load
end

function core:OnDisable()
	self:UnregisterAllEvents()
        addon.resetDetect:SetScript("OnEvent", nil)
end

function addon:UpdateThisLockout()
	storelockout = true
	RequestRaidInfo()
end
local currency_msg = CURRENCY_GAINED:gsub(":.*$","")
function core:CheckSystemMessage(event, msg)
        local inst, t = IsInInstance()
	-- note: currency is already updated in TooltipShow, 
	-- here we just hook JP/VP currency messages to capture lockout changes
	if inst and (t == "party" or t == "raid") and -- dont update on bg honor 
	   (msg:find(INSTANCE_SAVED) or -- first boss kill
	    msg:find(currency_msg)) -- subsequent boss kills (unless capped or over level)
	   then
	   addon:UpdateThisLockout()
	end
end

function core:LFG_COMPLETION_REWARD()
	--local _, _, diff = GetInstanceInfo()
	--vars.db.Toons[thisToon]["Daily"..diff] = time() + GetQuestResetTime() + addon:GetServerOffset() * 3600
	addon:UpdateThisLockout()
end

function addon:InGroup() 
  if IsInRaid() then return "RAID"
  elseif GetNumGroupMembers() > 0 then return "PARTY"
  else return nil end
end

local function doExplicitReset(instancemsg, failed)
  if HasLFGRestrictions() or IsInInstance() or
     (addon:InGroup() and not UnitIsGroupLeader("player")) then return end
  if not failed then
    addon:HistoryUpdate(true)
  end
 
  local reportchan = addon:InGroup()
  if reportchan then
    if not failed then
      SendAddonMessage(addonName, "GENERATION_ADVANCE", reportchan)
    end
    if vars.db.Tooltip.ReportResets then
      local msg = instancemsg or RESET_INSTANCES
      msg = msg:gsub("\1241.+;.+;","") -- ticket 76, remove |1;; escapes on koKR
      SendChatMessage("<"..addonName.."> "..msg, reportchan)
    end
  end
end
hooksecurefunc("ResetInstances", doExplicitReset)

local resetmsg = INSTANCE_RESET_SUCCESS:gsub("%%s",".+")
local resetfails = { INSTANCE_RESET_FAILED, INSTANCE_RESET_FAILED_OFFLINE, INSTANCE_RESET_FAILED_ZONING }
for k,v in pairs(resetfails) do 
  resetfails[k] = v:gsub("%%s",".+")
end
local raiddiffmsg = ERR_RAID_DIFFICULTY_CHANGED_S:gsub("%%s",".+")
local dungdiffmsg = ERR_DUNGEON_DIFFICULTY_CHANGED_S:gsub("%%s",".+")
local delaytime = 3 -- seconds to wait on zone change for settings to stabilize
function addon.HistoryEvent(f, evt, ...) 
  --myprint("HistoryEvent: "..evt, ...) 
  if evt == "CHAT_MSG_ADDON" then
    local prefix, message, channel, sender = ...
    if prefix ~= addonName then return end
    if message:match("^GENERATION_ADVANCE$") and not UnitIsUnit(sender,"player") then
      addon:HistoryUpdate(true)
    end
  elseif evt == "CHAT_MSG_SYSTEM" then
    local msg = ...
    if msg:match("^"..resetmsg.."$") then -- I performed expicit reset
      doExplicitReset(msg)
    elseif msg:match("^"..INSTANCE_SAVED.."$") then -- just got saved
      core:ScheduleTimer("HistoryUpdate", delaytime+1)
    elseif (msg:match("^"..raiddiffmsg.."$") or msg:match("^"..dungdiffmsg.."$")) and 
       not addon:histZoneKey() then -- ignore difficulty messages when creating a party while inside an instance
      addon:HistoryUpdate(true)
    elseif msg:match(TRANSFER_ABORT_TOO_MANY_INSTANCES) then
      addon:HistoryUpdate(false,true)
    else
      for _,m in pairs(resetfails) do 
        if msg:match("^"..m.."$") then
	  doExplicitReset(msg, true) -- send failure chat message
	end
      end
    end
  elseif evt == "INSTANCE_BOOT_START" then -- left group inside instance, resets on boot
    addon:HistoryUpdate(true)
  elseif evt == "INSTANCE_BOOT_STOP" and addon:InGroup() then -- invited back
    addon.delayedReset = false
  elseif evt == "GROUP_ROSTER_UPDATE" and 
         addon.histInGroup and not addon:InGroup() and -- ignore failed invites when solo
	 not addon:histZoneKey() then -- left group outside instance, resets now
    addon:HistoryUpdate(true)
  elseif evt == "PLAYER_ENTERING_WORLD" or evt == "ZONE_CHANGED_NEW_AREA" or evt == "RAID_INSTANCE_WELCOME" then
    -- delay updates while settings stabilize
    local waittime = delaytime + math.max(0,10 - GetFramerate())
    addon.delayUpdate = time() + waittime
    core:ScheduleTimer("HistoryUpdate", waittime+1)
  end
end


addon.histReapTime = 60*60 -- 1 hour
addon.histLimit = 5 -- instances per hour
function addon:histZoneKey()
  local instname, insttype, diff, diffname, maxPlayers, playerDifficulty, isDynamicInstance = GetInstanceInfo()
  if insttype == "none" or insttype == "arena" or insttype == "pvp" then -- pvp doesnt count
    return nil
  end
  if IsInLFGDungeon() then -- LFG instances don't count
    return nil
  end
  -- check if we're locked (using FindInstance so we don't complain about unsaved unknown instances)
  local truename = addon:FindInstance(instname, insttype == "raid")
  local locked = false
  local inst = truename and vars.db.Instances[truename] 
  inst = inst and inst[thisToon]
  for d=1,maxdiff do
    if inst and inst[d] and inst[d].Locked then
        locked = true
    end
  end
  if diff == 1 and maxPlayers == 5 then -- never locked to 5-man regs
    locked = false
  end
  local toonstr = thisToon
  if not db.Tooltip.ShowServer then
    toonstr = strsplit(" - ", toonstr)
  end
  local desc = toonstr .. ": " .. instname
  if diffname and #diffname > 0 then
    desc = desc .. " - " .. diffname
  end
  local key = thisToon..":"..instname..":"..insttype..":"..diff
  if not locked then
    key = key..":"..vars.db.histGeneration
  end
  return key, desc, locked
end

function addon:HistoryUpdate(forcereset, forcemesg)
  vars.db.histGeneration = vars.db.histGeneration or 1
  if forcereset and addon:histZoneKey() then -- delay reset until we zone out
     debug("HistoryUpdate reset delayed")
     addon.delayedReset = true
  end
  if (forcereset or addon.delayedReset) and not addon:histZoneKey() then
    debug("HistoryUpdate generation advance")
    vars.db.histGeneration = (vars.db.histGeneration + 1) % 100000
    addon.delayedReset = false
  end
  local now = time()
  if addon.delayUpdate and now < addon.delayUpdate then
    debug("HistoryUpdate delayed")
    return
  end
  local zoningin = false
  local newzone, newdesc, locked = addon:histZoneKey()
  -- touch zone we left
  if addon.histLastZone then
    local lz = vars.db.History[addon.histLastZone]
    if lz then
      lz.last = now
    end
  elseif newzone then
    zoningin = true
  end
  addon.histLastZone = newzone
  addon.histInGroup = addon:InGroup()
  -- touch/create new zone
  if newzone then
    local nz = vars.db.History[newzone]
    if not nz then
      nz = { create = now, desc = newdesc }
      vars.db.History[newzone] = nz
      if locked then -- creating a locked instance, delete unlocked version
        vars.db.History[newzone..":"..vars.db.histGeneration] = nil
      end
    end
    nz.last = now
  end
  -- reap old zones
  local livecnt = 0
  local oldestkey, oldesttime
  for zk, zi in pairs(vars.db.History) do
    if now > zi.last + addon.histReapTime or
       zi.last > (now + 3600) then -- temporary bug fix
      debug("Reaping "..zi.desc)
      vars.db.History[zk] = nil
    else 
      livecnt = livecnt + 1
      if not oldesttime or zi.last < oldesttime then
        oldestkey = zk
        oldesttime = zi.last
      end
    end
  end
  local oldistexp = (oldesttime and SecondsToTime(oldesttime+addon.histReapTime-now,false,false,1)) or "n/a"
  debug(livecnt.." live instances, oldest ("..(oldestkey or "none")..") expires in "..oldistexp..". Current Zone="..(newzone or "nil"))
  --myprint(vars.db.History)
  -- display update

  if forcemesg or (vars.db.Tooltip.LimitWarn and zoningin and livecnt >= addon.histLimit-1) then 
      chatMsg(L["Warning: You've entered about %i instances recently and are approaching the %i instance per hour limit for your account. More instances should be available in %s."]:format(livecnt, addon.histLimit, oldistexp))
  end
  if db.Broker.HistoryText and vars.dataobject then
    if livecnt >= addon.histLimit then
      vars.dataobject.text = oldistexp
    else
      vars.dataobject.text = livecnt
    end
  else
    vars.dataobject.text = addonName
  end
end
function core:HistoryUpdate(...) return addon:HistoryUpdate(...) end

local function localarr(name) -- save on memory churn by reusing arrays in updates
  name = "localarr#"..name
  core[name] = core[name] or {}
  return wipe(core[name])
end

function core:Refresh()
	-- update entire database from the current character's perspective
        addon:UpdateInstanceData()
	if not instancesUpdated then addon.RefreshPending = true; return end -- wait for UpdateInstanceData to succeed
	local temp = localarr("RefreshTemp")
	for name, instance in pairs(vars.db.Instances) do -- clear current toons lockouts before refresh
	  if instance[thisToon] then
	    temp[name] = instance[thisToon] -- use a temp to reduce memory churn
	    for diff,info in pairs(temp[name]) do
	      wipe(info)
	    end
	    instance[thisToon] = nil 
	  end
	end
	local numsaved = GetNumSavedInstances()
	if numsaved > 0 then
		for i = 1, numsaved do
			local name, id, expires, diff, locked, extended, mostsig, raid, players, diffname = GetSavedInstanceInfo(i)
                        local truename, instance = addon:LookupInstance(nil, name, raid)
			if expires and expires > 0 then
			  expires = expires + time()
			else
			  expires = 0
			end
			instance.Raid = instance.Raid or raid
			instance[thisToon] = instance[thisToon] or temp[truename] or { }
			local info = instance[thisToon][diff] or {}
			wipe(info)
			  info.ID = id
			  info.Expires = expires
                          info.Link = GetSavedInstanceChatLink(i)
			  info.Locked = locked
                          info.Extended = extended
			instance[thisToon][diff] = info
		end
	end

        local weeklyreset = addon:GetNextWeeklyResetTime()
	for id,_ in pairs(addon.LFRInstances) do
	  local numEncounters, numCompleted = GetLFGDungeonNumEncounters(id);
	  if ( numCompleted > 0 and weeklyreset ) then
            local truename, instance = addon:LookupInstance(id, nil, true)
            instance[thisToon] = instance[thisToon] or temp[truename] or { }
	    local info = instance[thisToon][2] or {}
	    wipe(info)
            instance[thisToon][2] = info
  	    info.Expires = weeklyreset
            info.ID = -1*numEncounters
	    for i=1, numEncounters do
	      local bossName, texture, isKilled = GetLFGDungeonEncounterInfo(id, i);
              info[i] = isKilled
	    end
	  end
	end

	for name, _ in pairs(temp) do
	 if vars.db.Instances[name][thisToon] then
	  for diff,info in pairs(vars.db.Instances[name][thisToon]) do
	    if not info.ID then
	      vars.db.Instances[name][thisToon][diff] = nil
	    end
	  end
	 end
	end
	wipe(temp)
	-- update the lockout-specific details for the current instance if necessary
	if storelockout then
		local thisname, _, thisdiff = GetInstanceInfo()
		local name, id, _, diff, locked, _, _, raid = GetLastLockedInstance()
		if thisname == name and thisdiff == diff then
			--vars.db.Lockouts[id]
		end
	end
	storelockout = false
	addon:UpdateToonData()
end

local function UpdateTooltip() 
	if tooltip:IsShown() and tooltip.anchorframe then 
	   core:ShowTooltip(tooltip.anchorframe) 
	end
end

-- sorted traversal function for character table
local cnext_sorted_names = {}
local function cnext(t,i)
   -- return them in reverse order
   if #cnext_sorted_names == 0 then
     return nil
   else
      local n = cnext_sorted_names[#cnext_sorted_names]
      table.remove(cnext_sorted_names, #cnext_sorted_names)
      return n, t[n]
   end
end
local function cpairs_sort(a,b)
  local an, _,_, as = strsplit(" - ",a)
  local bn, _,_, bs = strsplit(" - ",b)
  if db.Tooltip.SelfFirst and b == thisToon then
    return true
  elseif db.Tooltip.SelfFirst and a == thisToon then
    return false
  elseif db.Tooltip.ServerSort and as ~= bs then
    return as > bs
  else
    return a > b
  end
end
local function cpairs(t)
  wipe(cnext_sorted_names)
  for n,_ in pairs(t) do
    if vars.db.Toons[n] and vars.db.Toons[n].Show ~= "never" then
      table.insert(cnext_sorted_names, n)
    end
  end
  table.sort(cnext_sorted_names, cpairs_sort)
  --myprint(cnext_sorted_names)
  return cnext, t, nil
end

function addon:IsDetached()
  return addon.detachframe and addon.detachframe:IsShown()
end
function addon:HideDetached()
  addon.detachframe:Hide()
end
function addon:ToggleDetached()
   if addon:IsDetached() then
     addon:HideDetached()
   else
     addon:ShowDetached()
   end
end

function addon:ShowDetached()
    if not addon.detachframe then
      local f = CreateFrame("Frame","SavedInstancesDetachHeader",UIParent,"BasicFrameTemplate")
      f:SetMovable(true)
      f:SetFrameStrata("TOOLTIP")
      f:SetClampedToScreen(true)
      f:EnableMouse(true)
      f:SetUserPlaced(true)
      f:SetAlpha(0.5)
      if vars.db.Tooltip.posx and vars.db.Tooltip.posy then
        f:SetPoint("TOPLEFT",vars.db.Tooltip.posx,-vars.db.Tooltip.posy)
      else
        f:SetPoint("CENTER")
      end
      f:SetScript("OnMouseDown", function() f:StartMoving() end)
      f:SetScript("OnMouseUp", function() f:StopMovingOrSizing()
                      vars.db.Tooltip.posx = f:GetLeft()
                      vars.db.Tooltip.posy = UIParent:GetTop() - (f:GetTop()*f:GetScale())
                  end)
      f:SetScript("OnHide", function() if tooltip then QTip:Release(tooltip); tooltip = nil end  end )
      f:SetScript("OnUpdate", function(self)
		  if not tooltip then return end
		  local w,h = tooltip:GetSize()
		  self:SetSize(w*tooltip:GetScale(),(h+20)*tooltip:GetScale())
		  tooltip:ClearAllPoints()
		  tooltip:SetPoint("BOTTOMLEFT",addon.detachframe)
		  tooltip:SetFrameLevel(addon.detachframe:GetFrameLevel()+1)
	          tooltip:Show()
		end)
      f:SetScript("OnKeyDown", function(self,key) 
        if key == "ESCAPE" then 
	   f:SetPropagateKeyboardInput(false)
	   f:Hide(); 
	end 
      end)
      f:EnableKeyboard(true)
      addon.detachframe = f
    end
    local f = addon.detachframe
    f:Show()
    addon:SkinFrame(f,f:GetName())
    f:SetPropagateKeyboardInput(true)
    if tooltip then tooltip:Hide() end
    core:ShowTooltip(f)
end


local function ShowAll()
  	return (IsAltKeyDown() and true) or false
end

local columnCache = { [true] = {}, [false] = {} }
local function addColumns(columns, toon, tooltip)
	for c = 1, maxcol do
		columns[toon..c] = columns[toon..c] or tooltip:AddColumn("CENTER")
	end
	columnCache[ShowAll()][toon] = true
end

function core:ShowTooltip(anchorframe)
	local showall = ShowAll()
	if tooltip and tooltip:IsShown() and core.showall == showall then return end
	core.showall = showall
	local showexpired = showall or vars.db.Tooltip.ShowExpired
	if tooltip then QTip:Release(tooltip) end
	tooltip = QTip:Acquire("SavedInstancesTooltip", 1, "LEFT")
	tooltip:SetCellMarginH(0)
	tooltip.anchorframe = anchorframe
	tooltip:SetScript("OnUpdate", UpdateTooltip)
	tooltip:Clear()
	if not addon.headerfont then
	  addon.headerfont = CreateFont("SavedInstancedTooltipHeaderFont")
	  local hFont = tooltip:GetHeaderFont()
	  local hFontPath, hFontSize,_ hFontPath, hFontSize, _ = hFont:GetFont()
	  addon.headerfont:SetFont(hFontPath, hFontSize, "OUTLINE")
	end
	tooltip:SetHeaderFont(addon.headerfont)
	local headLine = tooltip:AddHeader(GOLDFONT .. "SavedInstances" .. FONTEND)
	tooltip:SetCellScript(headLine, 1, "OnEnter", ShowHistoryTooltip )
	tooltip:SetCellScript(headLine, 1, "OnLeave", 
					     function() if indicatortip then indicatortip:Hide(); end GameTooltip:Hide() end)
	addon:UpdateToonData()
	local columns = localarr("columns")
	for toon,_ in cpairs(columnCache[showall]) do
		addColumns(columns, toon, tooltip)
		columnCache[showall][toon] = false
        end 
	-- allocating columns for characters
	for toon, t in cpairs(vars.db.Toons) do
		if vars.db.Toons[toon].Show == "always" then
			addColumns(columns, toon, tooltip)
		end
	end
	-- determining how many instances will be displayed per category
	local categoryshown = localarr("categoryshown") -- remember if each category will be shown
	local instancesaved = localarr("instancesaved") -- remember if each instance has been saved or not (boolean)
	for _, category in ipairs(addon:OrderedCategories()) do
		for _, instance in ipairs(addon:OrderedInstances(category)) do
			local inst = vars.db.Instances[instance]
			if inst.Show == "always" then
			   categoryshown[category] = true
			end
			if inst.Show ~= "never" or showall then
			    for toon, t in cpairs(vars.db.Toons) do
				for diff = 1, maxdiff do
					if inst[toon] and inst[toon][diff] then
					    if (inst[toon][diff].Expires > 0) then
						instancesaved[instance] = true
						categoryshown[category] = true
					    elseif showall then
						categoryshown[category] = true
					    end
					end
				end
			    end
			end
		end
	end
	local categories = 0
	-- determining how many categories have instances that will be shown
	if vars.db.Tooltip.ShowCategories then
		for category, _ in pairs(categoryshown) do
			categories = categories + 1
		end
	end
	-- allocating tooltip space for instances, categories, and space between categories
	local categoryrow = localarr("categoryrow") -- remember where each category heading goes
	local instancerow = localarr("instancerow") -- remember where each instance goes
	local firstcategory = true -- use this to skip spacing before the first category
	for _, category in ipairs(addon:OrderedCategories()) do
		if categoryshown[category] then
			if not firstcategory and vars.db.Tooltip.CategorySpaces then
				tooltip:AddSeparator(6,0,0,0,0)
			end
			if (categories > 1 or vars.db.Tooltip.ShowSoloCategory) and categoryshown[category] then
				categoryrow[category], _ = tooltip:AddLine()

			end
			for _, instance in ipairs(addon:OrderedInstances(category)) do
			       local inst = vars.db.Instances[instance]
				if inst.Show == "always" then
			  	   instancerow[instance] = instancerow[instance] or tooltip:AddLine()
				end
				if inst.Show ~= "never" or showall then
				    for toon, t in cpairs(vars.db.Toons) do
					for diff = 1, maxdiff do
					        if inst[toon] and inst[toon][diff] and (inst[toon][diff].Expires > 0 or showexpired) then
							instancerow[instance] = instancerow[instance] or tooltip:AddLine()
							addColumns(columns, toon, tooltip)
						end
					end
				    end
				end
			end
			firstcategory = false
		end
	end
	-- now printing instance data
	for instance, row in pairs(instancerow) do
		if (not instancesaved[instance]) then
			tooltip:SetCell(instancerow[instance], 1, GRAYFONT .. instance .. FONTEND)
		else
			tooltip:SetCell(instancerow[instance], 1, GOLDFONT .. instance .. FONTEND)
		end
			for toon, t in cpairs(vars.db.Toons) do
			        local inst = vars.db.Instances[instance]
				if inst[toon] then
				  local showcol = localarr("showcol")
				  local showcnt = 0
				  for diff = 1, maxdiff do
				    if instancerow[instance] and 
				      inst[toon][diff] and (inst[toon][diff].Expires > 0 or showexpired) then
				      showcnt = showcnt + 1
				      showcol[diff] = true
				    end
				  end
				  local base = 1
				  local span = maxcol
				  if showcnt > 1 then
				    span = 1
				  end
				  if showcnt > maxcol then
                                     chatMsg("Column overflow! Please report this bug! showcnt="..showcnt)
				  end
				  for diff = 1, maxdiff do
				    if showcol[diff] then
					tooltip:SetCell(instancerow[instance], columns[toon..base], 
					    DifficultyString(instance, diff, toon, inst[toon][diff].Expires == 0), span)
					tooltip:SetCellScript(instancerow[instance], columns[toon..base], "OnEnter", ShowIndicatorTooltip, {instance, toon, diff})
					tooltip:SetCellScript(instancerow[instance], columns[toon..base], "OnLeave", 
					     function() indicatortip:Hide(); GameTooltip:Hide() end)
					tooltip:SetCellScript(instancerow[instance], columns[toon..base], "OnMouseDown", 
					     function()
					       local link = inst[toon][diff].Link
					       if link and ChatEdit_GetActiveWindow() then
					          ChatEdit_InsertLink(link)
					       elseif link then
					          ChatFrame_OpenChat(link, DEFAULT_CHAT_FRAME)
					       end
					     end)
					base = base + 1
				    elseif columns[toon..diff] and showcnt > 1 then
					tooltip:SetCell(instancerow[instance], columns[toon..diff], "")
				    end
				  end
				end
			end
	end

	if vars.db.Tooltip.ShowHoliday or showall then
	  local holidayinst = localarr("holidayinst")
	  for instance, info in pairs(vars.db.Instances) do
	    if info.Holiday then
		for toon, t in cpairs(vars.db.Toons) do
		  local d = info[toon] and info[toon][1]
		  if d then
		    addColumns(columns, toon, tooltip)
		    if not holidayinst[instance] then
		      if not firstcategory and vars.db.Tooltip.CategorySpaces then
		         tooltip:AddSeparator(6,0,0,0,0)
		      end
		      holidayinst[instance] = tooltip:AddLine(YELLOWFONT .. instance .. FONTEND)
		    end
		    local tstr = SecondsToTime(d.Expires - time(), false, false, 1)
     		    tooltip:SetCell(holidayinst[instance], columns[toon..1], ClassColorise(t.Class,tstr), "CENTER",maxcol)
		  end
		end
	    end
	  end
	end

	-- random dungeon
	if vars.db.Tooltip.TrackLFG or showall then
		local cd1,cd2 = false,false
		for toon, t in cpairs(vars.db.Toons) do
			cd2 = cd2 or t.LFG2
			cd1 = cd1 or (t.LFG1 and (not t.LFG2 or showall))
			if t.LFG1 or t.LFG2 then
				addColumns(columns, toon, tooltip)
			end
		end
		local randomLine
		if cd1 or cd2 then
			if not firstcategory and vars.db.Tooltip.CategorySpaces then
				tooltip:AddSeparator(6,0,0,0,0)
			end
			cd1 = cd1 and tooltip:AddLine(YELLOWFONT .. LFG_TYPE_RANDOM_DUNGEON .. FONTEND)		
			cd2 = cd2 and tooltip:AddLine(YELLOWFONT .. GetSpellInfo(71041) .. FONTEND)		
		end
		for toon, t in cpairs(vars.db.Toons) do
		    local d1 = (t.LFG1 and t.LFG1 - time()) or -1
		    local d2 = (t.LFG2 and t.LFG2 - time()) or -1
		    if d1 > 0 and (d2 < 0 or showall) then
		        local tstr = SecondsToTime(d1, false, false, 1)
			tooltip:SetCell(cd1, columns[toon..1], ClassColorise(t.Class,tstr), "CENTER",maxcol)
		        tooltip:SetCellScript(cd1, columns[toon..1], "OnEnter", ShowSpellIDTooltip, {toon,-1,tstr})
		        tooltip:SetCellScript(cd1, columns[toon..1], "OnLeave", 
							     function() indicatortip:Hide(); GameTooltip:Hide() end)
		    end
		    if d2 > 0 then
		        local tstr = SecondsToTime(d2, false, false, 1)
			tooltip:SetCell(cd2, columns[toon..1], ClassColorise(t.Class,tstr), "CENTER",maxcol)
		        tooltip:SetCellScript(cd2, columns[toon..1], "OnEnter", ShowSpellIDTooltip, {toon,71041,tstr})
		        tooltip:SetCellScript(cd2, columns[toon..1], "OnLeave", 
							     function() indicatortip:Hide(); GameTooltip:Hide() end)
		    end
		end
	end
	if vars.db.Tooltip.TrackDeserter or showall then
		local show = false
		for toon, t in cpairs(vars.db.Toons) do
			if t.pvpdesert then
				show = true
				addColumns(columns, toon, tooltip)
			end
		end
		if show then
			if not firstcategory and vars.db.Tooltip.CategorySpaces then
				tooltip:AddSeparator(6,0,0,0,0)
			end
			show = tooltip:AddLine(YELLOWFONT .. DESERTER .. FONTEND)		
		end
		for toon, t in cpairs(vars.db.Toons) do
			if t.pvpdesert and time() < t.pvpdesert then
				local tstr = SecondsToTime(t.pvpdesert - time(), false, false, 1)
				tooltip:SetCell(show, columns[toon..1], ClassColorise(t.Class,tstr), "CENTER",maxcol)
		                tooltip:SetCellScript(show, columns[toon..1], "OnEnter", ShowSpellIDTooltip, {toon,26013,tstr})
		                tooltip:SetCellScript(show, columns[toon..1], "OnLeave", 
							     function() indicatortip:Hide(); GameTooltip:Hide() end)
			end
		end
	end

        do
                local weeklycnt = localarr("weeklycnt")
                local showd, showw 
                for toon, t in cpairs(vars.db.Toons) do
			weeklycnt[toon] = 0
			for _,qi in pairs(t.Quests) do
				if not qi.isDaily then
					weeklycnt[toon] = weeklycnt[toon] + 1
				end
                        end
                        if t.DailyCount > 0 and (vars.db.Tooltip.TrackDailyQuests or showall) then
                                showd = true
                                addColumns(columns, toon, tooltip)
                        end
                        if weeklycnt[toon] > 0 and (vars.db.Tooltip.TrackWeeklyQuests or showall) then
                                showw = true
                                addColumns(columns, toon, tooltip)
                        end
                end
                if not firstcategory and vars.db.Tooltip.CategorySpaces and (showd or showw) then
                        tooltip:AddSeparator(6,0,0,0,0)
                end
                if showd then
                        showd = tooltip:AddLine(YELLOWFONT .. L["Daily Quests"] .. FONTEND)
                end
                if showw then
                        showw = tooltip:AddLine(YELLOWFONT .. L["Weekly Quests"] .. FONTEND)
                end
                for toon, t in cpairs(vars.db.Toons) do
                        if showd and columns[toon..1] and t.DailyCount > 0 then
				local qstr = t.DailyCount
                                tooltip:SetCell(showd, columns[toon..1], ClassColorise(t.Class,qstr), "CENTER",maxcol)
                                tooltip:SetCellScript(showd, columns[toon..1], "OnEnter", ShowQuestTooltip, {toon,qstr.." "..L["Daily Quests"],true})
                                tooltip:SetCellScript(showd, columns[toon..1], "OnLeave",
                                                             function() indicatortip:Hide(); GameTooltip:Hide() end)
                        end
                        if showw and columns[toon..1] and weeklycnt[toon] > 0 then
				local qstr = weeklycnt[toon]
                                tooltip:SetCell(showw, columns[toon..1], ClassColorise(t.Class,qstr), "CENTER",maxcol)
                                tooltip:SetCellScript(showw, columns[toon..1], "OnEnter", ShowQuestTooltip, {toon,qstr.." "..L["Weekly Quests"],false})
                                tooltip:SetCellScript(showw, columns[toon..1], "OnLeave",
                                                             function() indicatortip:Hide(); GameTooltip:Hide() end)
                        end
                end
        end

	local firstcurrency = true
        for _,idx in ipairs(currency) do
	  local setting = vars.db.Tooltip["Currency"..idx]
          if setting or showall then
            local show 
   	    for toon, t in cpairs(vars.db.Toons) do
		-- ci.name, ci.amount, ci.earnedThisWeek, ci.weeklyMax, ci.totalMax
                local ci = t.currency and t.currency[idx] 
		local gotsome = ((ci.earnedThisWeek or 0) > 0 and (ci.weeklyMax or 0) > 0) or
		                ((ci.amount or 0) > 0 and showall)
		       -- or ((ci.amount or 0) > 0 and ci.weeklyMax == 0 and t.Level == maxlvl)
		if ci and gotsome then
		  addColumns(columns, toon, tooltip)
		end
		if ci and (gotsome or (ci.amount or 0) > 0) and columns[toon..1] then
		  local name,_,tex = GetCurrencyInfo(idx)
		  show = name.." \124TInterface\\Icons\\"..tex..":0\124t"
		end
	    end
   	    local currLine
	    if show then
		if not firstcategory and vars.db.Tooltip.CategorySpaces and firstcurrency then
			tooltip:AddSeparator(6,0,0,0,0)
			firstcurrency = false
		end
		currLine = tooltip:AddLine(YELLOWFONT .. show .. FONTEND)		

   	      for toon, t in cpairs(vars.db.Toons) do
                local ci = t.currency and t.currency[idx] 
		if ci and columns[toon..1] then
		   local earned, weeklymax, totalmax = "","",""
		   if vars.db.Tooltip.CurrencyMax then
		     if (ci.weeklyMax or 0) > 0 then
		       weeklymax = "/"..ci.weeklyMax
		     end
		     if (ci.totalMax or 0) > 0 then
		       totalmax = "/"..ci.totalMax
		     end
		   end
		   if vars.db.Tooltip.CurrencyEarned or showall then
		     earned = "("..(ci.amount or "0")..totalmax..")"
		   end
                   local str
		   if (ci.amount or 0) > 0 or (ci.earnedThisWeek or 0) > 0 then
                     if (ci.weeklyMax or 0) > 0 then
                       str = (ci.earnedThisWeek or "0")..weeklymax.." "..earned
		     elseif (ci.amount or 0) > 0 then
                       str = "("..(ci.amount or "0")..totalmax..")"
		     end
                   end
		  if str then
		   tooltip:SetCell(currLine, columns[toon..1], ClassColorise(t.Class,str), "CENTER",maxcol)
		   tooltip:SetCellScript(currLine, columns[toon..1], "OnEnter", ShowCurrencyTooltip, {toon, idx, ci})
		   tooltip:SetCellScript(currLine, columns[toon..1], "OnLeave", 
							     function() indicatortip:Hide(); GameTooltip:Hide() end)
		  end
                end
              end
	    end
          end
        end

	-- toon names
	for toondiff, col in pairs(columns) do
		local toon = strsub(toondiff, 1, #toondiff-1)
		local diff = strsub(toondiff, #toondiff, #toondiff)
		if diff == "1" then
		        local toonname, _,_, toonserver = strsplit(" - ", toon)
			local toonstr = toonname
			if db.Tooltip.ShowServer then
			  toonstr = toonstr .. "\n" .. toonserver
			end
			tooltip:SetCell(headLine, col, ClassColorise(vars.db.Toons[toon].Class, toonstr), 
			                tooltip:GetHeaderFont(), "CENTER", maxcol)
			tooltip:SetCellScript(headLine, col, "OnEnter", ShowToonTooltip, {toon})
			tooltip:SetCellScript(headLine, col, "OnLeave", 
					     function() indicatortip:Hide(); GameTooltip:Hide() end)
	 		--[[
			tooltip:SetCellScript(headLine, col, "OnEnter", function() 
			  for i=0,3 do
			    tooltip:SetColumnColor(col+i,0.5,0.5,0.5) 
			  end
			end)
			tooltip:SetCellScript(headLine, col, "OnLeave", function() 
			  for i=0,3 do
			    tooltip:SetColumnColor(col,0,0,0) 
			  end
			end)
			--]]
		end
	end 
	-- we now know enough to put in the category names where necessary
	if vars.db.Tooltip.ShowCategories then
		for category, row in pairs(categoryrow) do
			if (categories > 1 or vars.db.Tooltip.ShowSoloCategory) and categoryshown[category] then
				tooltip:SetCell(categoryrow[category], 1, YELLOWFONT .. vars.Categories[category] .. FONTEND, "LEFT", tooltip:GetColumnCount())
			end
		end
	end

	for i=2,tooltip:GetLineCount() do -- row highlighting
	  tooltip:SetLineScript(i, "OnEnter", function() end)
	  tooltip:SetLineScript(i, "OnLeave", function() end)
	end

	-- finishing up, with hints
	if TableLen(instancerow) == 0 then
		local noneLine = tooltip:AddLine()
		tooltip:SetCell(noneLine, 1, GRAYFONT .. NO_RAID_INSTANCES_SAVED .. FONTEND, "LEFT", tooltip:GetColumnCount())
	end
	if vars.db.Tooltip.ShowHints then
		tooltip:AddSeparator(8,0,0,0,0)
		local hintLine, hintCol
	     if not addon:IsDetached() then
		hintLine, hintCol = tooltip:AddLine()
		tooltip:SetCell(hintLine, hintCol, L["|cffffff00Left-click|r to detach tooltip"], "LEFT", tooltip:GetColumnCount())
		hintLine, hintCol = tooltip:AddLine()
		tooltip:SetCell(hintLine, hintCol, L["|cffffff00Middle-click|r to show Blizzard's Raid Information"], "LEFT", tooltip:GetColumnCount())
		hintLine, hintCol = tooltip:AddLine()
		tooltip:SetCell(hintLine, hintCol, L["|cffffff00Right-click|r to configure SavedInstances"], "LEFT", tooltip:GetColumnCount())
	     end
		hintLine, hintCol = tooltip:AddLine()
		tooltip:SetCell(hintLine, hintCol, L["Hover mouse on indicator for details"], "LEFT", tooltip:GetColumnCount())
		if not showall then
		  hintLine, hintCol = tooltip:AddLine()
		  tooltip:SetCell(hintLine, hintCol, L["Hold Alt to show all data"], "LEFT", math.max(1,tooltip:GetColumnCount()-maxcol))
		  if tooltip:GetColumnCount() < maxcol+1 then
		    tooltip:AddLine(addonName.." version "..addon.version)
		  else
		    tooltip:SetCell(hintLine, tooltip:GetColumnCount()-maxcol+1, addon.version, "RIGHT", maxcol)
		  end
		end
	end
	-- tooltip column colours
	if vars.db.Tooltip.ColumnStyle == "CLASS" then
		for toondiff, col in pairs(columns) do
			local toon = strsub(toondiff, 1, #toondiff-1)
			local diff = strsub(toondiff, #toondiff, #toondiff)
			local color = RAID_CLASS_COLORS[vars.db.Toons[toon].Class]
			tooltip:SetColumnColor(col, color.r, color.g, color.b)
		end 
	end						

        -- cache check
        local fail = false
        local maxidx = 0
	for toon,val in cpairs(columnCache[showall]) do
		if not val then -- remove stale column
                   columnCache[showall][toon] = nil
                   fail = true 
                else 
                   local thisidx = columns[toon..1]
                   if thisidx < maxidx then -- sort failure caused by new middle-insertion
                      fail = true
                   end
                   maxidx = thisidx
                end
        end 
        if fail then -- retry with corrected cache
		debug("Tooltip cache miss")
		core:ShowTooltip(anchorframe)
        else -- render it
	   addon:SkinFrame(tooltip,"SavedInstancesTooltip")
	   if addon:IsDetached() then
	        tooltip.anchorframe = UIParent
	        tooltip:SmartAnchorTo(UIParent)
		tooltip:SetAutoHideDelay(nil, UIParent)
		--tooltip:UpdateScrolling(100000)
	   else
	        tooltip:SmartAnchorTo(anchorframe)
		tooltip:SetAutoHideDelay(0.1, anchorframe)
	        tooltip:Show()
	   end
        end
end

