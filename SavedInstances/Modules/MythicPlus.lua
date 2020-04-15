local SI, L = unpack(select(2, ...))
local MP = SI:NewModule('MythicPlus', 'AceEvent-3.0')

-- Lua functions
local strsplit, tonumber, select, time = strsplit, tonumber, select, time

-- WoW API / Variables
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_MythicPlus_GetWeeklyChestRewardLevel = C_MythicPlus.GetWeeklyChestRewardLevel
local C_MythicPlus_IsWeeklyRewardAvailable = C_MythicPlus.IsWeeklyRewardAvailable
local C_MythicPlus_RequestRewards = C_MythicPlus.RequestRewards
local GetContainerItemID = GetContainerItemID
local GetContainerItemLink = GetContainerItemLink
local GetContainerNumSlots = GetContainerNumSlots
local GetItemQualityColor = GetItemQualityColor

local KeystoneAbbrev = {
  [244] = L["AD"],    -- Atal'Dazar
  [245] = L["FH"],    -- Freehold
  [246] = L["TD"],    -- Tol Dagor
  [247] = L["ML"],    -- The MOTHERLODE!!
  [248] = L["WM"],    -- Waycrest Manor
  [249] = L["KR"],    -- Kings' Rest
  [250] = L["TOS"],   -- Temple of Sethraliss
  [251] = L["UNDR"],  -- The Underrot
  [252] = L["SOTS"],  -- Shrine of the Storm
  [353] = L["SIEGE"], -- Siege of Boralus
  [369] = L["YARD"],  -- Operation: Mechagon - Junkyard
  [370] = L["WORK"],  -- Operation: Mechagon - Workshop
}
SI.KeystoneAbbrev = KeystoneAbbrev

function MP:OnEnable()
  self:RegisterEvent("BAG_UPDATE", "RefreshMythicKeyInfo")
  self:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE", "RefreshMythicKeyInfo")
  self:RefreshMythicKeyInfo()
end

function MP:RefreshMythicKeyInfo(event)
  -- This event is fired after the rewards data was requested, causing yet another refresh if not checked for
  if (event ~= "CHALLENGE_MODE_MAPS_UPDATE") then C_MythicPlus_RequestRewards() end

  local t = SI.db.Toons[SI.thisToon]
  t.MythicKey = {}
  for bagID = 0, 4 do
    for invID = 1, GetContainerNumSlots(bagID) do
      local itemID = GetContainerItemID(bagID, invID)
      if itemID and itemID == 158923 then
        local keyLink = GetContainerItemLink(bagID, invID)
        local KeyInfo = {strsplit(':', keyLink)}
        local mapID = tonumber(KeyInfo[3])
        local mapLevel = tonumber(KeyInfo[4])
        local color
        if KeyInfo[4] == "0" then
          color = select(4, GetItemQualityColor(0))
        elseif mapLevel >= 10 then
          color = select(4, GetItemQualityColor(4))
        elseif mapLevel >= 7 then
          color = select(4, GetItemQualityColor(3))
        elseif mapLevel >= 4 then
          color = select(4, GetItemQualityColor(2))
        else
          color = select(4, GetItemQualityColor(1))
        end
        -- SI:Debug("Mythic Keystone: %s", gsub(keyLink, "\124", "\124\124"))
        t.MythicKey.name = C_ChallengeMode_GetMapUIInfo(mapID)
        t.MythicKey.mapID = mapID
        t.MythicKey.color = color
        t.MythicKey.level = mapLevel
        t.MythicKey.ResetTime = SI:GetNextWeeklyResetTime()
        t.MythicKey.link = keyLink
      end
    end
  end
  if t.MythicKeyBest and (t.MythicKeyBest.ResetTime or 0) < time() then -- dont know weekly reset function will run early or not
    if t.MythicKeyBest.level and t.MythicKeyBest.level > 0 then
      t.MythicKeyBest.LastWeekLevel = t.MythicKeyBest.level
  end
  end
  t.MythicKeyBest = t.MythicKeyBest or {}
  t.MythicKeyBest.ResetTime = SI:GetNextWeeklyResetTime()
  t.MythicKeyBest.level = C_MythicPlus_GetWeeklyChestRewardLevel()
  t.MythicKeyBest.WeeklyReward = C_MythicPlus_IsWeeklyRewardAvailable()
end

function MythicPlusModule:Keys()
  local target = addon.db.Tooltip.KeystoneReportTarget
  addon.debug("Key report target: %s", target)

  if target == 'EXPORT' then
    self:ExportKeys()
  else
    local dialog = StaticPopup_Show("SAVEDINSTANCES_REPORT_KEYS", target, nil, target)
  end
end

function MythicPlusModule:KeyData(action)
  local cpairs = addon.cpairs

  for toon, t in cpairs(addon.db.Toons, true) do
    if t.MythicKey and t.MythicKey.link then
      local toonname
      if addon.db.Tooltip.ShowServer then
        toonname = toon
      else
        local tname, tserver = toon:match('^(.*) [-] (.*)$')
        toonname = tname
      end

      action(toonname, t.MythicKey.link)
    end
  end
end

function MythicPlusModule:ReportKeys(target)
  self:KeyData(function(toon, key) SendChatMessage(toon .. ' - '.. key, target) end)
end

function MythicPlusModule:ExportKeys()
  local keys = ""

  self:KeyData(function(toon, key) keys = keys .. toon .. ' - ' .. key .. '\n' end)

  if not self.SavedInstancesKeyExport then
    local f = CreateFrame("Frame", nil, UIParent, "DialogBoxFrame")
    f:SetSize(700, 450)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    self.SavedInstancesKeyExport = f

    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOP", 0, -16)
    sf:SetPoint("BOTTOM", f, "BOTTOM", 0, 50)
    sf:SetPoint("LEFT", 16, 0)
    sf:SetPoint("RIGHT", -36, 0)
    self.SavedInstancesKeyExportScroll = sf

    local st = CreateFrame("EditBox", nil, sf)
    st:SetSize(sf:GetSize())
    st:SetMultiLine(true)
    st:SetFontObject("ChatFontNormal")
    st:SetScript("OnEscapePressed", function()
      f:Hide()
    end)
    sf:SetScrollChild(st)
    self.SavedInstancesKeyExportScrollText = st
  end

  self.SavedInstancesKeyExportScrollText:SetText(keys)
  self.SavedInstancesKeyExportScrollText:HighlightText()

  self.SavedInstancesKeyExport:Show()
  self.SavedInstancesKeyExportScroll:Show()
  self.SavedInstancesKeyExportScrollText:Show()
end