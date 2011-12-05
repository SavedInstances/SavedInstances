local addonName, vars = ...
SavedInstances = vars
local addon = vars
local addonName = "SavedInstances"
vars.core = LibStub("AceAddon-3.0"):NewAddon("SavedInstances", "AceEvent-3.0", "AceTimer-3.0")
local core = vars.core
vars.L = SavedInstances_locale()
local L = vars.L
vars.LDB = LibStub("LibDataBroker-1.1", true)
vars.icon = vars.LDB and LibStub("LibDBIcon-1.0", true)

local QTip = LibStub("LibQTip-1.0")
local dataobject, db, config

addon.svnrev = {}
addon.svnrev["SavedInstances.lua"] = tonumber(("$Revision: 48 $"):match("%d+"))

-- local (optimal) references to provided functions
local GetExpansionLevel = GetExpansionLevel
local GetInstanceDifficulty = GetInstanceDifficulty
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local IsInInstance = IsInInstance
local SecondsToTime = SecondsToTime

-- local (optimal) references to Blizzard's strings
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local NO_RAID_INSTANCES_SAVED = NO_RAID_INSTANCES_SAVED -- "You are not saved to any instances"
local RAID_FINDER = PLAYER_DIFFICULTY3
local FONTEND = FONT_COLOR_CODE_CLOSE
local GOLDFONT = NORMAL_FONT_COLOR_CODE
local YELLOWFONT = LIGHTYELLOW_FONT_COLOR_CODE
local REDFONT = RED_FONT_COLOR_CODE
local GREENFONT = GREEN_FONT_COLOR_CODE
local WHITEFONT = HIGHLIGHT_FONT_COLOR_CODE
local GRAYFONT = GRAY_FONT_COLOR_CODE
local LFD_RANDOM_REWARD_EXPLANATION2 = LFD_RANDOM_REWARD_EXPLANATION2

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
}

local tooltip, indicatortip
local history = { }
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

addon.LFRInstanceIDs = { 
  416, -- The Siege of Wyrmrest Temple
  417, -- Fall of Deathwing
}

local function debug(msg)
  --addon.db.dbg = true
  if addon.db.dbg then
     DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000"..addonName.."\124r: "..msg)
  end
end

vars.defaultDB = {
	DBVersion = 10,
	History = { }, -- for tracking 5 instance per hour limit
		-- key: instance string; value: time first entered
	Broker = {
		HistoryText = false,
	},
	Toons = { }, 	-- table key: "Toon - Realm"; value:
				-- Class: string
				-- Level: integer
				-- AlwaysShow: boolean
				-- Daily1: expiry (normal) REMOVED
				-- Daily2: expiry (heroic) REMOVED
				-- LFG1: expiry 
				-- WeeklyResetTime: expiry
	Indicators = {
		D1Indicator = "BLANK", -- indicator: ICON_*, BLANK
		D1Text = "5",
		D1Color = { 0, 0.6, 0, 1, }, -- dark green
		D1ClassColor = true,
		D2Indicator = "BLANK", -- indicator
		D2Text = "5+",
		D2Color = { 0, 1, 0, 1, }, -- green
		D2ClassColor = true,
		R0Indicator = "BLANK", -- indicator: ICON_*, BLANK
		R0Text = "X",
		R0Color = { 0.6, 0.6, 0, 1, }, -- dark yellow
		R0ClassColor = true,
		R1Indicator = "BLANK", -- indicator: ICON_*, BLANK
		R1Text = "10",
		R1Color = { 0.6, 0.6, 0, 1, }, -- dark yellow
		R1ClassColor = true,
		R2Indicator = "BLANK", -- indicator
		R2Text = "25",
		R2Color = { 0.6, 0, 0, 1, }, -- dark red
		R2ClassColor = true,
		R3Indicator = "BLANK", -- indicator: ICON_*, BLANK
		R3Text = "10+",
		R3Color = { 1, 1, 0, 1, }, -- yellow
		R3ClassColor = true,
		R4Indicator = "BLANK", -- indicator
		R4Text = "25+",
		R4Color = { 1, 0, 0, 1, }, -- red
		R4ClassColor = true,
	},
	Tooltip = {
		Details = false,
		ReverseInstances = false,
		ShowExpired = false,
		ShowCategories = false,
		CategorySpaces = false,
		NewFirst = true,
		RaidsFirst = true,
		CategorySort = "EXPANSION", -- "EXPANSION", "TYPE"
		ShowSoloCategory = false,
		ShowHints = true,
		ColumnStyle = "NORMAL", -- "NORMAL", "CLASS", "ALTERNATING"
		AltColumnColor = { 0.2, 0.2, 0.2, 1, }, -- grey
		RecentHistory = false,
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
					-- Expansion: integer
					-- RecLevel: integer
					-- LFDID: integer
					-- LFDupdated: integer
					-- REMOVED Encounters[integer] = { GUID : integer, Name : string }
					-- table key: "Toon - Realm"; value:
						-- table key: "Difficulty"; value:
							-- ID: integer, positive for a Blizzard Raid ID, 
                                                        --  negative value for an LFR encounter count
							-- Expires: integer
                                                        -- Locked: boolean, whether toon is locked to the save
                                                        -- Extended: boolean, whether this is an extended raid lockout
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
	offset = floor((server - localT) * 2 + 0.5) / 2
	if raw then return offset end
	if offset >= 12 then
		offset = offset - 24
	elseif offset < -12 then
		offset = offset + 24
	end
	return offset
end

function addon:GetNextWeeklyResetTime()
  local offset = addon:GetServerOffset() * 3600
  local resettime = GetQuestResetTime()
  if not resettime or resettime <= 0 then -- ticket 43: can fail during startup
    return nil
  end
  local nightlyReset = time() + resettime
  --while date("%A",nightlyReset+offset) ~= WEEKDAY_TUESDAY do 
  while date("%w",nightlyReset+offset) ~= "2" do
    nightlyReset = nightlyReset + 24 * 3600
  end
  return nightlyReset
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
  return str:gsub("%p",""):gsub("%s"," "):gsub("%s%s"," "):upper()
end

-- some instances (like sethekk halls) are named differently by GetSavedInstanceInfo() and LFGGetDungeonInfoByID()
-- we use the latter name to key our database, and this function to convert as needed
function addon:FindInstance(name, raid)
  if not name or #name == 0 then return nil end
  local info = vars.db.Instances[name]
  if info then
    return name, info.LFDID
  end
  local nname = addon:normalizeName(name)
  for truename, info in pairs(vars.db.Instances) do
    local tname = addon:normalizeName(truename)
    if (tname:find(nname, 1, true) or nname:find(tname, 1, true)) and
       vars.db.Instances[truename].Raid == raid then -- Tempest Keep: The Botanica
      debug("FindInstance("..name..") => "..truename)
      return truename, info.LFDID
    end
  end
  return nil
end

-- provide either id or name/raid to get the instance truename and db entry
function addon:LookupInstance(id, name, raid)
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
      print("SavedInstances: ERROR: Refresh() failed to find instance: "..name.." : "..GetLocale())
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

function addon:OrderedInstances(category)
	-- returns a table of the form { "instance1", "instance2", ... }
	local orderedlist = { }
	local instances = addon:InstancesInCategory(category)
	while #instances > 0 do
		local highest, lowest, selected
		for i, instance in ipairs(instances) do
			local instancelevel = vars.db.Instances[instance].RecLevel or 0
			if vars.db.Tooltip.ReverseInstances then
				if not lowest or (instancelevel and instancelevel < lowest) then
					lowest = instancelevel
					selected = i
				end
			else
				if not highest or (instancelevel and instancelevel > highest) then
					highest = instancelevel
					selected = i
				end
			end
		end
		if vars.db.Tooltip.ReverseInstances then
			selected = selected or 1
		else
			selected = selected or #instances
		end
		orderedlist[1+#orderedlist] = instances[selected]
		tremove(instances, selected)
	end
	return orderedlist
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
	local setting
	if not instance then
		setting = "D" .. diff
	else
		local inst = vars.db.Instances[instance]
		if inst.Expansion == 0 and inst.Raid then
		  setting = "R0"
		else
		  setting = ((inst.Raid and "R") or ((not inst.Raid) and "D")) .. diff
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
	prefs[setting.."Text"] = prefs[setting.."Text"] or vars.defaultDB.Indicators[setting.."Text"]
	prefs[setting.."Indicator"] = prefs[setting.."Indicator"] or vars.defaultDB.Indicators[setting.."Indicator"]
	if not strfind(prefs[setting.."Text"], "ICON", 1, true) then
		return ColorCodeOpen(color) .. prefs[setting.."Text"] .. FONTEND
	end
	local iconstring
	if prefs[setting.."Indicator"] == "BLANK" then
		iconstring = ""
	else
		iconstring = FONTEND .. vars.Indicators[prefs[setting.."Indicator"]] .. ColorCodeOpen(color)
	end
	return ColorCodeOpen(color) .. gsub(prefs[setting.."Text"], "ICON", iconstring) .. FONTEND
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
  local starttime = GetTime()
  local maxid = 500
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
  starttime = GetTime()-starttime
  debug("UpdateInstanceData(): completed "..count.." updates in "..string.format("%.6f",starttime).." sec.")
  core:Refresh()
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
  -- maxPlayers == 0 for non-instance zones (WotLK zones all have an entry for some reason)
  -- isHoliday is for single-boss holiday instances that don't generate raid saves
  if not name or not expansionLevel or not recLevel or not maxPlayers or maxPlayers == 0 or isHoliday then return end
  if name:find(PVP_RATED_BATTLEGROUND) then return end -- ignore 10v10 rated bg

  local instance = vars.db.Instances[name]
  local newinst = false
  if not instance then
    debug("UpdateInstance: "..id.." "..(name or "nil").." "..(expansionLevel or "nil").." "..(recLevel or "nil").." "..(maxPlayers or "nil"))
    instance = {}
    newinst = true
  end
  vars.db.Instances[name] = instance
  instance.Show = instance.Show
  instance.Encounters = nil -- deprecated
  instance.LFDID = id
  instance.LFDupdated = currentbuild
  instance.Expansion = expansionLevel
  instance.RecLevel = instance.RecLevel or recLevel
  if recLevel < instance.RecLevel then instance.RecLevel = recLevel end -- favor non-heroic RecLevel
  instance.Raid = (tonumber(maxPlayers) > 5)
  return newinst, true, name
end

-- run regularly to update lockouts and cached data for this toon
function addon:UpdateToonData()
	for instance, i in pairs(vars.db.Instances) do
		for toon, t in pairs(vars.db.Toons) do
			if i[toon] then
				for difficulty, d in pairs(i[toon]) do
					if d.Expires < time() then
					    d.Locked = false
				            d.Expires = 0
                                            for x=1,(-1*(d.ID or 0)) do
                                               d[x] = nil
                                            end
					end
				end
			end
		end
	end
	-- update random toon info
	local t = vars.db.Toons[thisToon]
        t.LFG1 = GetLFGRandomCooldownExpiration()
	local desert = select(7,UnitDebuff("player",GetSpellInfo(71041))) -- GetLFGDeserterExpiration()
	if desert and (not t.LFG1 or desert > t.LFG1) then
	  t.LFG1 = desert
	end
	t.pvpdesert = select(7,UnitDebuff("player",GetSpellInfo(26013))) 
	for toon, ti in pairs(vars.db.Toons) do
		if ti.LFG1 and (ti.LFG1 < GetTime()) then ti.LFG1 = nil end
		if ti.pvpdesert and (ti.pvpdesert < GetTime()) then ti.pvpdesert = nil end
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
          end 
	  ti.WeeklyResetTime = nextreset
	 end
	end
	t.currency = t.currency or {}
	for _,idx in pairs(currency) do
	  local ci = t.currency[idx] or {}
	  _, ci.amount, _, ci.earnedThisWeek, ci.weeklyMax, ci.totalMax = GetCurrencyInfo(idx)
          if idx == 396 then -- VP x 100, CP x 1
            ci.weeklyMax = ci.weeklyMax and ci.weeklyMax/100
          end
          ci.totalMax = ci.totalMax and ci.totalMax/100
          ci.season = addon:GetSeasonCurrency(idx)
	  t.currency[idx] = ci
	end
end

local function coloredText(fontstring)
  if not fontstring then return nil end
  local text = fontstring:GetText()
  if not text then return nil end
  local textR, textG, textB, textAlpha = fontstring:GetTextColor() 
  return string.format("|c%02x%02x%02x%02x"..text.."|r", 
                       textAlpha*255, textR*255, textG*255, textB*255)
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
	indicatortip:AddHeader(ClassColorise(vars.db.Toons[toon].Class, strsplit(' ', toon)), (id < 0 and RAID_FINDER) or id)
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
	    indicatortip:AddLine(coloredText(left), coloredText(right))
	  end
	end
	if info.ID < 0 then
          for i=1,(-1*info.ID) do
            local bossname, texture = GetLFGDungeonEncounterInfo(thisinstance.LFDID, i);
            if info[i] then 
              indicatortip:AddLine(bossname, REDFONT..ERR_LOOT_GONE..FONTEND)
            else
              --indicatortip:AddLine(bossname, GREENFONT..AVAILABLE..FONTEND)
            end
          end
        end
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

local function ShowCurrencyTooltip(cell, arg, ...)
  local toon, idx, ci = unpack(arg)
  if not toon or not idx or not ci then return end
  local name,_,tex = GetCurrencyInfo(idx)
  tex = " \124TInterface\\Icons\\"..tex..":0\124t"
  indicatortip = QTip:Acquire("SavedInstancesIndicatorTooltip", 2, "LEFT", "RIGHT")
  indicatortip:Clear()
  indicatortip:SetHeaderFont(tooltip:GetHeaderFont())
  local nameline, _ = indicatortip:AddHeader()
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
      indicatortip:SetCell(indicatortip:GetLineCount(),1,coloredText(left), nil, nil, nil, nil, nil, nil, 250)
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
  indicatortip:Show()
end

local function UpdateLDBTextMode()
	if db.Broker.HistoryText then
		--vars.dataobject.type = "data source"
		core:ScheduleRepeatingTimer("UpdateLDBText", 5, nil)
	else
		--vars.dataobject.type = "launcher"
		vars.dataobject.text = addonName
		core:CancelAllTimers()
	end
end

-- global addon code below

function core:OnInitialize()
	SavedInstancesDB = SavedInstancesDB or vars.defaultDB
	-- begin backwards compatibility
	if not SavedInstancesDB.DBVersion then
		SavedInstancesDB = vars.defaultDB
	end
	if SavedInstancesDB.DBVersion == 6 then
		SavedInstancesDB.DBVersion = 7
		SavedInstancesDB.Tooltip.ShowHints = true
	end
	if SavedInstancesDB.DBVersion == 7 then
		SavedInstancesDB.DBVersion = 8
		SavedInstancesDB.Tooltip = vars.defaultDB.Tooltip
		SavedInstancesDB.Broker = vars.defaultDB.Broker
	end
	if SavedInstancesDB.DBVersion == 8 then
		SavedInstancesDB.DBVersion = 9
		SavedInstancesDB.Tooltip.CategorySort = vars.defaultDB.Tooltip.CategorySort
		SavedInstancesDB.Categories = vars.defaultDB.Categories
		SavedInstancesDB.Broker = vars.defaultDB.Broker
	end
	if SavedInstancesDB.DBVersion == 9 then
		SavedInstancesDB.DBVersion = 10
		for instance, i in pairs(SavedInstancesDB.Instances) do
			i.Order = nil
		end
		SavedInstancesDB.Categories = nil
	end
	if SavedInstancesDB.DBVersion ~= 10 then
		SavedInstancesDB = vars.defaultDB
	end
	-- end backwards compatibilty
	db = db or SavedInstancesDB
	vars.db = db
	config = vars.config
	db.Toons[thisToon] = db.Toons[thisToon] or { }
	db.Toons[thisToon].Class = db.Toons[thisToon].Class or select(2, UnitClass("player"))
	db.Toons[thisToon].Level = UnitLevel("player")
	db.Toons[thisToon].AlwaysShow = db.Toons[thisToon].AlwaysShow or false
	db.Lockouts = nil -- deprecated
        addon:SetupVersion()
	RequestRaidInfo() -- get lockout data
	if LFGDungeonList_Setup then LFGDungeonList_Setup() end -- force LFG frame to populate instance list LFDDungeonList
	vars.dataobject = vars.LDB and vars.LDB:NewDataObject("SavedInstances", {
		text = "",
		type = "launcher",
		icon = "Interface\\Addons\\SavedInstances\\icon.tga",
		OnEnter = function(frame)
			core:ShowTooltip(frame)
		end,
		OnClick = function(frame, button)
			if button == "LeftButton" then
				ToggleFriendsFrame(4) -- open Blizzard Raid window
				RaidInfoFrame:Show()
			else
				config:ShowConfig()
			end
		end
	})
	if vars.icon then
		vars.icon:Register("SavedInstances", vars.dataobject, db.MinimapIcon)
	end
	UpdateLDBTextMode()
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
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("LFG_COMPLETION_REWARD") -- for random daily dungeon tracking
end

function core:OnDisable()
	self:UnregisterEvent("UPDATE_INSTANCE_INFO")
	self:UnregisterEvent("RAID_INSTANCE_WELCOME")
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("LFG_COMPLETION_REWARD")
end

function core:PLAYER_ENTERING_WORLD()
  addon:UpdateToonData()
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


local function localarr(name) -- save on memory churn by reusing arrays in updates
  name = "localarr#"..name
  core[name] = core[name] or {}
  return wipe(core[name])
end

function core:Refresh()
	-- update entire database from the current character's perspective
        addon:UpdateInstanceData()
	if not instancesUpdated then return end -- wait for UpdateInstanceData to succeed
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

	for _,id in pairs(addon.LFRInstanceIDs) do
	  local numEncounters, numCompleted = GetLFGDungeonNumEncounters(id);
	  if ( numCompleted > 0 ) then
            local truename, instance = addon:LookupInstance(id, nil, true)
            instance[thisToon] = instance[thisToon] or temp[truename] or { }
	    local info = instance[thisToon][2] or {}
	    wipe(info)
            instance[thisToon][2] = info
  	    info.Expires = addon:GetNextWeeklyResetTime()
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
local function cpairs(t)
  wipe(cnext_sorted_names)
  for n,_ in pairs(t) do
    table.insert(cnext_sorted_names, n)
  end
  table.sort(cnext_sorted_names, function (a,b) return b == thisToon or (a ~= thisToon and a > b) end)
  --myprint(cnext_sorted_names)
  return cnext, t, nil
end

local function ShowAll()
  	return (IsAltKeyDown() and true) or false
end

local columnCache = { [true] = {}, [false] = {} }
local function addColumns(columns, toon, tooltip)
	for diff = 1, 4 do
		columns[toon..diff] = columns[toon..diff] or tooltip:AddColumn("CENTER")
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
	tooltip.anchorframe = anchorframe
	tooltip:SetScript("OnUpdate", UpdateTooltip)
	tooltip:Clear()
	local hFont = tooltip:GetHeaderFont()
	local hFontPath, hFontSize
	hFontPath, hFontSize, _ = hFont:GetFont()
	hFont:SetFont(hFontPath, hFontSize, "OUTLINE")
	tooltip:SetHeaderFont(hFont)
	local headLine, headCol = tooltip:AddHeader(GOLDFONT .. "SavedInstances" .. FONTEND)
	addon:UpdateToonData()
	local columns = localarr("columns")
	for toon,_ in cpairs(columnCache[showall]) do
		addColumns(columns, toon, tooltip)
		columnCache[showall][toon] = false
        end 
	-- allocating columns for characters
	for toon, t in cpairs(vars.db.Toons) do
		if vars.db.Toons[toon].AlwaysShow then
			addColumns(columns, toon, tooltip)
		end
	end
	-- determining how many instances will be displayed per category
	local categoryshown = localarr("categoryshown") -- remember if each category will be shown
	local instancesaved = localarr("instancesaved") -- remember if each instance has been saved or not (boolean)
	for _, category in ipairs(addon:OrderedCategories()) do
		for _, instance in ipairs(addon:OrderedInstances(category)) do
			local inst = vars.db.Instances[instance]
			for toon, t in pairs(vars.db.Toons) do
				for diff = 1, 4 do
					if inst[toon] and inst[toon][diff] and (inst[toon][diff].Expires > 0 or showall) then
						instancesaved[instance] = true
						categoryshown[category] = true
					elseif inst.Show then
						categoryshown[category] = true
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
				for toon, t in cpairs(vars.db.Toons) do
					for diff = 1, 4 do
					        if inst[toon] and inst[toon][diff] and (inst[toon][diff].Expires > 0 or showall) then
							instancerow[instance] = instancerow[instance] or tooltip:AddLine()
							addColumns(columns, toon, tooltip)
						elseif inst.Show then
							instancerow[instance] = instancerow[instance] or tooltip:AddLine()
						end
					end
				end
			end
			firstcategory = false
		end
	end
	-- now printing instance data
	for instance, row in pairs(instancerow) do
		if instancesaved[instance] then
			tooltip:SetCell(instancerow[instance], 1, GOLDFONT .. instance .. FONTEND)
			for toon, t in pairs(vars.db.Toons) do
			        local inst = vars.db.Instances[instance]
				if inst[toon] then
				  local showcol = localarr("showcol")
				  local showcnt = 0
				  for diff = 1, 4 do
				    if instancerow[instance] and columns[toon..diff] and 
				      inst[toon][diff] and (inst[toon][diff].Expires > 0 or showexpired) then
				      showcol[diff] = true
				      showcnt = showcnt + 1
				    end
				  end
				  for diff = 1, 4 do
				    if showcol[diff] then
				      local base = diff
				      local span = 1
				      if showcnt == 1 then
				        base = 1
					span = 4
				      end
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
				    elseif columns[toon..diff] and showcnt > 1 then
					tooltip:SetCell(instancerow[instance], columns[toon..diff], "")
				    end
				  end
				end
			end
		elseif (not instancesaved[instance]) and (vars.db.Instances[instance].Show) then
			tooltip:SetCell(instancerow[instance], 1, GRAYFONT .. instance .. FONTEND)
		end
	end
	-- random dungeon
	if vars.db.Tooltip.TrackLFG or showall then
		local randomcd = false
		for toon, t in cpairs(vars.db.Toons) do
			if t.LFG1 then
				randomcd = true
				addColumns(columns, toon, tooltip)
			end
		end
		local randomLine
		if randomcd then
			if not firstcategory and vars.db.Tooltip.CategorySpaces then
				tooltip:AddSeparator(6,0,0,0,0)
			end
			randomLine = tooltip:AddLine(YELLOWFONT .. LFG_TYPE_RANDOM_DUNGEON .. FONTEND)		
		end
		for toon, t in pairs(vars.db.Toons) do
			if t.LFG1 and GetTime() < t.LFG1 then
			        local diff = t.LFG1 - GetTime()
				--[[
				local hr,min,sec = math.floor(diff/3600), math.floor((diff%3600)/60), math.floor(diff%60)
				local str = string.format(":%02d",sec)
				if (min > 0 or hr > 0) then str = string.format("%02d",min)..str end
				if (hr > 0) then str = string.format("%02d:",hr)..str end
				--]]
				local str = SecondsToTime(diff, false, false, 1)
				tooltip:SetCell(randomLine, columns[toon..1], ClassColorise(t.Class,str), "CENTER",4)
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
		for toon, t in pairs(vars.db.Toons) do
			if t.pvpdesert and GetTime() < t.pvpdesert then
			        local diff = t.pvpdesert - GetTime()
				local str = SecondsToTime(diff, false, false, 1)
				tooltip:SetCell(show, columns[toon..1], ClassColorise(t.Class,str), "CENTER",4)
			end
		end
	end

        for _,idx in ipairs(currency) do
	  local setting = vars.db.Tooltip["Currency"..idx]
          if setting or showall then
            local show 
   	    for toon, t in cpairs(vars.db.Toons) do
		-- ci.name, ci.amount, ci.earnedThisWeek, ci.weeklyMax, ci.totalMax
                local ci = t.currency and t.currency[idx] 
		if ci and (((ci.earnedThisWeek or 0) > 0 and (ci.weeklyMax or 0) > 0) or ((ci.amount or 0) > 0 and showall)
		       -- or ((ci.amount or 0) > 0 and ci.weeklyMax == 0 and t.Level == maxlvl)
		       ) then
		  addColumns(columns, toon, tooltip)
		end
		if ci and (ci.amount or 0) > 0 and columns[toon..1] then
		  local name,_,tex = GetCurrencyInfo(idx)
		  show = name.." \124TInterface\\Icons\\"..tex..":0\124t"
		end
	    end
   	    local currLine
	    if show then
		if not firstcategory and vars.db.Tooltip.CategorySpaces then
			tooltip:AddSeparator(6,0,0,0,0)
		end
		currLine = tooltip:AddLine(YELLOWFONT .. show .. FONTEND)		

   	      for toon, t in pairs(vars.db.Toons) do
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
		   tooltip:SetCell(currLine, columns[toon..1], ClassColorise(t.Class,str), "CENTER",4)
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
			tooltip:SetCell(headLine, col, ClassColorise(vars.db.Toons[toon].Class, select(1, strsplit(" - ", toon))), tooltip:GetHeaderFont(), "CENTER", 4)
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
	-- finishing up, with hints
	if TableLen(instancerow) == 0 then
		local noneLine = tooltip:AddLine()
		tooltip:SetCell(noneLine, 1, GRAYFONT .. NO_RAID_INSTANCES_SAVED .. FONTEND, "LEFT", tooltip:GetColumnCount())
	end
	if vars.db.Tooltip.ShowHints then
		tooltip:AddSeparator(8,0,0,0,0)
		local hintLine, hintCol
		hintLine, hintCol = tooltip:AddLine()
		tooltip:SetCell(hintLine, hintCol, L["|cffffff00Left-click|r to show Blizzard's Raid Information"], "LEFT", tooltip:GetColumnCount())
		hintLine, hintCol = tooltip:AddLine()
		tooltip:SetCell(hintLine, hintCol, L["|cffffff00Right-click|r to configure SavedInstances"], "LEFT", tooltip:GetColumnCount())
		hintLine, hintCol = tooltip:AddLine()
		tooltip:SetCell(hintLine, hintCol, L["Hover mouse on indicator for details"], "LEFT", tooltip:GetColumnCount())
		if not showall then
		  hintLine, hintCol = tooltip:AddLine()
		  tooltip:SetCell(hintLine, hintCol, L["Hold Alt to show all data"], "LEFT", math.max(1,tooltip:GetColumnCount()-4))
		  if tooltip:GetColumnCount() < 5 then
		    tooltip:AddLine(addonName.." version "..addon.version)
		  else
		    tooltip:SetCell(hintLine, tooltip:GetColumnCount()-3, addon.version, "RIGHT", 4)
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
		tooltip:SetAutoHideDelay(0.1, anchorframe)
		tooltip:SmartAnchorTo(anchorframe)
		tooltip:Show()
        end
end

function core:UpdateLDBText()
	if db.History and TableLen(db.History) >= 2 then
		-- do the stuff :)
		-- SavedInstances.launcher.text = format(L["%s instances"], number)
		-- SavedInstances.launcher.text = format(L["%s instances"], number)
	else
		vars.dataobject.text = ""
	end	
end
