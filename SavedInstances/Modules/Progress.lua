local SI, L = unpack((select(2, ...)))
local Module = SI:NewModule('Progress', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local floor, ipairs, strmatch, type, tostring, wipe = floor, ipairs, strmatch, type, tostring, wipe

-- WoW API / Variables
local C_QuestLog_IsOnQuest = C_QuestLog.IsOnQuest
local C_QuestLog_IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local C_TaskQuest_IsActive = C_TaskQuest.IsActive
local C_UIWidgetManager_GetTextWithStateWidgetVisualizationInfo = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo
local C_WeeklyRewards_CanClaimRewards = C_WeeklyRewards.CanClaimRewards
local C_WeeklyRewards_GetConquestWeeklyProgress = C_WeeklyRewards.GetConquestWeeklyProgress
local C_WeeklyRewards_HasAvailableRewards = C_WeeklyRewards.HasAvailableRewards
local GetQuestObjectiveInfo = GetQuestObjectiveInfo
local GetQuestProgressBarPercent = GetQuestProgressBarPercent
local UnitLevel = UnitLevel

local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE
local READY_CHECK_READY_TEXTURE = READY_CHECK_READY_TEXTURE
local READY_CHECK_WAITING_TEXTURE = READY_CHECK_WAITING_TEXTURE
local READY_CHECK_NOT_READY_TEXTURE = READY_CHECK_NOT_READY_TEXTURE

local function KeepProgress(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end
  local prev = t.Progress[index]
  t.Progress[index] = {
    unlocked = prev.unlocked,
    isComplete = false,
    isFinish = prev.isFinish and not prev.isComplete,
    objectiveType = prev.objectiveType,
    numFulfilled = prev.isComplete and 0 or prev.numFulfilled,
    numRequired = prev.numRequired,
  }
end

-- PvP Conquest (index 1)

local function ConquestUpdate(index)
  local data
  if UnitLevel("player") >= SI.maxLevel then
    local weeklyProgress = C_WeeklyRewards_GetConquestWeeklyProgress()
    if not weeklyProgress then return end

    local rewardWaiting = C_WeeklyRewards_HasAvailableRewards() and C_WeeklyRewards_CanClaimRewards()
    data = {
      unlocked = true,
      isComplete = weeklyProgress.progress >= weeklyProgress.maxProgress,
      isFinish = false,
      numFulfilled = weeklyProgress.progress,
      numRequired = weeklyProgress.maxProgress,
      unlocksCompleted = weeklyProgress.unlocksCompleted,
      maxUnlocks = weeklyProgress.maxUnlocks,
      rewardWaiting = rewardWaiting,
    }
  else
    data = {
      unlocked = false,
      isComplete = false,
      isFinish = false,
    }
  end
  SI.db.Toons[SI.thisToon].Progress[index] = data
end

local function ConquestShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end
  local data = t.Progress[index]
  local text
  if not data.unlocked then
    text = ""
  elseif data.isComplete then
    text = "\124T" .. READY_CHECK_READY_TEXTURE .. ":0|t"
  elseif data.isFinish then
    text = "\124T" .. READY_CHECK_WAITING_TEXTURE .. ":0|t"
  else
    text = data.numFulfilled .. "/" .. data.numRequired
  end
  if data.unlocksCompleted and data.maxUnlocks then
    text = text .. "(" .. data.unlocksCompleted .. "/" .. data.maxUnlocks .. ")"
  end
  if data.rewardWaiting then
    text = text .. "(\124T" .. READY_CHECK_WAITING_TEXTURE .. ":0|t)"
  end
  return text
end

local function ConquestReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  local prev = t.Progress[index]
  t.Progress[index] = {
    unlocked = prev.unlocked,
    isComplete = false,
    isFinish = false,
    numFulfilled = 0,
    numRequired = prev.numRequired,
    unlocksCompleted = 0,
    maxUnlocks = prev.maxUnlocks,
    rewardWaiting = prev.unlocksCompleted and prev.unlocksCompleted > 0,
  }
end

-- Horrific Vision (index 3)

local function HorrificVisionUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for i, questID in ipairs(Module.TrackedQuest[index].rewardQuestID) do
    SI.db.Toons[SI.thisToon].Progress[index][i] = C_QuestLog_IsQuestFlaggedCompleted(questID)
  end
  SI.db.Toons[SI.thisToon].Progress[index].unlocked = C_QuestLog_IsQuestFlaggedCompleted(58634) -- Opening the Gateway
end

local function HorrificVisionShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  if t.Progress[index].unlocked then
    local text = "-"
    for i, descText in ipairs(Module.TrackedQuest[index].rewardDesc) do
      if t.Progress[index][i] then
        text = descText[1]
      end
    end
    return text
  end
end

local function HorrificVisionReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  local unlocked = t.Progress[index].unlocked
  wipe(t.Progress[index])
  t.Progress[index].unlocked = unlocked
end

-- N'Zoth Assaults (index 4)

local function NZothAssaultUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    SI.db.Toons[SI.thisToon].Progress[index][questID] = C_TaskQuest_IsActive(questID)
  end
  SI.db.Toons[SI.thisToon].Progress[index].unlocked = C_QuestLog_IsQuestFlaggedCompleted(57362) -- Deeper Into the Darkness
end

local function NZothAssaultShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  if t.Progress[index].unlocked then
    local count = 0
    for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
      if t.Quests[questID] then
        count = count + 1
      end
    end
    return count == 0 and "" or tostring(count)
  end
end

local function NZothAssaultReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  local unlocked = t.Progress[index].unlocked
  wipe(t.Progress[index])
  t.Progress[index].unlocked = unlocked
end

-- Lesser Visions of N'Zoth (index 5)

local function LesserVisionUpdate(index)
  -- do nothing
end

local function LesserVisionShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end

  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if t.Quests[questID] then
      return "\124T" .. READY_CHECK_READY_TEXTURE .. ":0|t"
    end
  end
end

local function LesserVisionReset(toon, index)
  -- do nothing
end

-- Torghast Weekly (index 6)

local function TorghastUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  SI.db.Toons[SI.thisToon].Progress[index].unlocked = C_QuestLog_IsQuestFlaggedCompleted(60136) -- Into Torghast

  for i, data in ipairs(Module.TrackedQuest[index].widgetID) do
    local nameInfo = C_UIWidgetManager_GetTextWithStateWidgetVisualizationInfo(data[1])
    local levelInfo = C_UIWidgetManager_GetTextWithStateWidgetVisualizationInfo(data[2])

    if nameInfo and levelInfo then
      local available = nameInfo.shownState == 1
      local levelText = strmatch(levelInfo.text, '|cFF00FF00.-(%d+).+|r')

      SI.db.Toons[SI.thisToon].Progress[index]['Available' .. i] = available
      SI.db.Toons[SI.thisToon].Progress[index]['Level' .. i] = levelText
    end
  end
end

local function TorghastShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  if t.Progress[index].unlocked then
    local result = ""
    for i in ipairs(Module.TrackedQuest[index].widgetID) do
      if t.Progress[index]['Available' .. i] then
        local first = (#result == 0)
        result = result .. (first and '' or ' / ') .. t.Progress[index]['Level' .. i]
      end
    end
    return result
  end
end

local function TorghastReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  local unlocked = t.Progress[index].unlocked
  wipe(t.Progress[index])
  t.Progress[index].unlocked = unlocked
end

-- Covenant Assaults (index 7)

local function CovenantAssaultUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    SI.db.Toons[SI.thisToon].Progress[index][questID] = C_TaskQuest_IsActive(questID)
  end
  SI.db.Toons[SI.thisToon].Progress[index].unlocked = C_QuestLog_IsQuestFlaggedCompleted(64556) -- In Need of Assistance
end

local function CovenantAssaultShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  if t.Progress[index].unlocked then
    local count = 0
    for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
      if t.Quests[questID] then
        count = count + 1
      end
    end
    return count == 0 and "" or tostring(count)
  end
end

local function CovenantAssaultReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  local unlocked = t.Progress[index].unlocked
  wipe(t.Progress[index])
  t.Progress[index].unlocked = unlocked
end

-- Profession Treatise
local function ProfessionTreatiseUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    SI.db.Toons[SI.thisToon].Progress[index][questID] = C_QuestLog_IsQuestFlaggedCompleted(questID)
  end
end

local function ProfessionTreatiseShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  local totalDone = 0
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if t.Progress[index][questID] then
      totalDone = totalDone + 1
    end
  end
  if totalDone >= 2 then 
   return "\124T" .. READY_CHECK_READY_TEXTURE .. ":0|t"
   else
   return string.format("%d/%d", totalDone, "2")
   end
end

local function ProfessionTreatiseReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  wipe(t.Progress[index])
end

-- Profession Quests
local function ProfessionQuestsUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    SI.db.Toons[SI.thisToon].Progress[index][questID] = C_QuestLog_IsQuestFlaggedCompleted(questID)
  end
end

local function ProfessionQuestsShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  local totalDone = 0
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if t.Progress[index][questID] then
      totalDone = totalDone + 1
    end
  end
  
  local totalToDo = 0
  if t.Profession1Name == "Alchemy" or t.Profession1Name == "Enchanting" then
   totalToDo = totalToDo + 2
  elseif t.Profession1Name == "Herbalism" or t.Profession1Name == "Mining" or t.Profession1Name == "Skinning" then
   totalToDo = totalToDo + 1
  else totalToDo = totalToDo + 3
  end
  if t.Profession2Name == "Alchemy" or t.Profession2Name == "Enchanting" then
   totalToDo = totalToDo + 2
  elseif t.Profession2Name == "Herbalism" or t.Profession2Name == "Mining" or t.Profession2Name == "Skinning" then
   totalToDo = totalToDo + 1
  else totalToDo = totalToDo + 3
  end
  totalToDo = totalToDo + 1 --Add 1 for "Show Your Mettle" quest that every profession gets
  
  if totalDone >= totalToDo then 
   return "\124T" .. READY_CHECK_READY_TEXTURE .. ":0|t"
   else
   return string.format("%d/%d", totalDone, totalToDo)
   end
end

local function ProfessionQuestsReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  wipe(t.Progress[index])
end

-- Profession Lootables
local function ProfessionLootablesUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    SI.db.Toons[SI.thisToon].Progress[index][questID] = C_QuestLog_IsQuestFlaggedCompleted(questID)
  end
end

local function ProfessionLootablesShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end
  
  local profIndex = {
    "Alchemy",
	"Alchemy",
	"Alchemy",
	"Alchemy",
	"Alchemy",
    "Blacksmithing",
	"Blacksmithing",
	"Blacksmithing",
	"Blacksmithing",
	"Blacksmithing",
    "Enchanting",
	"Enchanting",
	"Enchanting",
	"Enchanting",
	"Enchanting",
	"Engineering",
	"Engineering",
	"Engineering",
	"Engineering",
	"Engineering",
	"Herbalism",
	"Herbalism",
	"Herbalism",
	"Herbalism",
	"Herbalism",
	"Herbalism",
	"Herbalism",
	"Inscription",
	"Inscription",
	"Inscription",
	"Inscription",
	"Inscription",
	"Jewelcrafting",
	"Jewelcrafting",
	"Jewelcrafting",
	"Jewelcrafting",
	"Jewelcrafting",
	"Leatherworking",
	"Leatherworking",
	"Leatherworking",
	"Leatherworking",
	"Leatherworking",
	"Mining",
	"Mining",
	"Mining",
	"Mining",
	"Mining",
	"Mining",
	"Mining",
	"Skinning",
	"Skinning",
	"Skinning",
	"Skinning",
	"Skinning",
	"Skinning",
	"Skinning",
	"Tailoring",
	"Tailoring",
	"Tailoring",
	"Tailoring",
	"Tailoring",
  }
  
  local totalDone1 = 0
  for i, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if t.Profession1Name == profIndex[i] and t.Progress[index][questID] then
      totalDone1 = totalDone1 + 1
    end
  end
  local totalDone2 = 0
  for i, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if t.Profession2Name == profIndex[i] and t.Progress[index][questID] then
      totalDone2 = totalDone2 + 1
    end
  end
  
  local totalDone = totalDone1 + totalDone2
  
  local totalToDo = 0
  if t.Profession1Name == "Herbalism" or t.Profession1Name == "Mining" or t.Profession1Name == "Skinning" then
   totalToDo = totalToDo + 7
  else totalToDo = totalToDo + 5
  end
  if t.Profession2Name == "Herbalism" or t.Profession2Name == "Mining" or t.Profession2Name == "Skinning" then
   totalToDo = totalToDo + 7
  else totalToDo = totalToDo + 5
  end
  if totalDone >= totalToDo then 
   return "\124T" .. READY_CHECK_READY_TEXTURE .. ":0|t"
   else
   return string.format("%d/%d", totalDone, totalToDo)
   end
end

local function ProfessionLootablesReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  wipe(t.Progress[index])
end

-- Timewalking
local function TimewalkingUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  local result = SI.db.Toons[SI.thisToon].Progress[index]

  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if C_QuestLog_IsQuestFlaggedCompleted(questID) then
      result.unlocked = true
      result.isComplete = true

      break
    elseif C_QuestLog_IsOnQuest(questID) then
      result.unlocked = true
      result.isComplete = false

      local showText
      local allFinished = true
      local leaderboardCount = C_QuestLog.GetNumQuestObjectives(questID)
      for i = 1, leaderboardCount do
        local text, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, i, false)
        result[i] = text
        allFinished = allFinished and finished

        local objectiveText
        if objectiveType == 'progressbar' then
          objectiveText = floor((numFulfilled or 0) / numRequired * 100) .. "%"
        else
          objectiveText = numFulfilled .. "/" .. numRequired
        end

        if i == 1 then
          showText = objectiveText
        else
          showText = showText .. ' ' .. objectiveText
        end
      end

      result.leaderboardCount = leaderboardCount
      result.isFinish = allFinished
      result.text = showText
      break
    end
  end
end

local function TimewalkingShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  if t.Progress[index].isComplete then
    return "\124T" .. READY_CHECK_READY_TEXTURE .. ":0|t"
  elseif t.Progress[index].isFinish then
    return "\124T" .. READY_CHECK_WAITING_TEXTURE .. ":0|t"
  end

  return t.Progress[index].text
end

local function TimewalkingReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  if t.Progress[index].isComplete then
    wipe(t.Progress[index])
  end
end

-- Dragonflight Renown (index 11)
local function DragonflightRenownUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})

  local majorFactionIDs = C_MajorFactions.GetMajorFactionIDs(LE_EXPANSION_DRAGONFLIGHT)
  for _, factionID in ipairs(majorFactionIDs) do
    local data = C_MajorFactions.GetMajorFactionData(factionID)
    SI.db.Toons[SI.thisToon].Progress[index][factionID] =
      data and {data.renownLevel, data.renownReputationEarned, data.renownLevelThreshold}
  end
end

local function DragonflightRenownShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  local text
  local majorFactionIDs = C_MajorFactions.GetMajorFactionIDs(LE_EXPANSION_DRAGONFLIGHT)

  local factionIDs = Module.TrackedQuest[index].factionIDs
  for _, factionID in ipairs(factionIDs) do
    if not text then
      text = t.Progress[index][factionID] and t.Progress[index][factionID][1] or '0'
    else
      text = text .. ' / ' .. (t.Progress[index][factionID] and t.Progress[index][factionID][1] or '0')
    end
  end

  for _, factionID in ipairs(majorFactionIDs) do
    if not tContains(factionIDs, factionID) then
      if not text then
        text = t.Progress[index][factionID] and t.Progress[index][factionID][1] or '0'
      else
        text = text .. ' / ' .. (t.Progress[index][factionID] and t.Progress[index][factionID][1] or '0')
      end
    end
  end

  return text
end

local function DragonflightRenownReset(toon, index)
  -- do nothing
end

-- Aiding the Accord
local function AidingTheAccordUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  local result = SI.db.Toons[SI.thisToon].Progress[index]

  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if C_QuestLog_IsQuestFlaggedCompleted(questID) then
      result.unlocked = true
      result.isComplete = true

      break
    elseif C_QuestLog_IsOnQuest(questID) then
      result.unlocked = true
      result.isComplete = false

      local showText
      local allFinished = true
      local leaderboardCount = C_QuestLog.GetNumQuestObjectives(questID)
      for i = 1, leaderboardCount do
        local text, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, i, false)
        result[i] = text
        allFinished = allFinished and finished

        local objectiveText
        if objectiveType == 'progressbar' then
          objectiveText = floor((numFulfilled or 0) / numRequired * 100) .. "%"
        else
          objectiveText = numFulfilled .. "/" .. numRequired
        end

        if i == 1 then
          showText = objectiveText
        else
          showText = showText .. ' ' .. objectiveText
        end
      end

      result.leaderboardCount = leaderboardCount
      result.isFinish = allFinished
      result.text = showText
      break
    end
  end
end

local function AidingTheAccordShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  if t.Progress[index].isComplete then
    return "\124T" .. READY_CHECK_READY_TEXTURE .. ":0|t"
  elseif t.Progress[index].isFinish then
    return "\124T" .. READY_CHECK_WAITING_TEXTURE .. ":0|t"
  end

  return t.Progress[index].text
end

local function AidingTheAccordReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  if t.Progress[index].isComplete then
    wipe(t.Progress[index])
  end
end

-- Grand Hunt
local function GrandHuntUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    SI.db.Toons[SI.thisToon].Progress[index][questID] = C_QuestLog_IsQuestFlaggedCompleted(questID)
  end
end

local function GrandHuntShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  local totalDone = 0
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if t.Progress[index][questID] then
      totalDone = totalDone + 1
    end
  end
  return string.format("%d/%d", totalDone, #Module.TrackedQuest[index].relatedQuest)
end

local function GrandHuntReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  wipe(t.Progress[index])
end

-- Primal Storms Core
local function PrimalStormsCoreUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    SI.db.Toons[SI.thisToon].Progress[index][questID] = C_QuestLog_IsQuestFlaggedCompleted(questID)
  end
end

local function PrimalStormsCoreShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  local totalDone = 0
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if t.Progress[index][questID] then
      totalDone = totalDone + 1
    end
  end
  return string.format("%d/%d", totalDone, #Module.TrackedQuest[index].relatedQuest)
end

local function PrimalStormsCoreReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  wipe(t.Progress[index])
end

-- Sparks of Life
local function SparksOfLifeUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  local result = SI.db.Toons[SI.thisToon].Progress[index]
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if C_TaskQuest_IsActive(questID) then
      local _, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, 1, false)
      result.objectiveType = objectiveType
      result.isFinish = finished
      result.numFulfilled = numFulfilled
      result.numRequired = numRequired
      if C_QuestLog_IsQuestFlaggedCompleted(questID) then
        result.unlocked = true
        result.isComplete = true
      else
        local isOnQuest = C_QuestLog_IsOnQuest(questID)
        result.unlocked = isOnQuest
        result.isComplete = false
      end
      break
    end
    if C_QuestLog_IsQuestFlaggedCompleted(questID) then
      result.unlocked = true
      result.isComplete = true
      break
    end
  end
end

local function SparksOfLifeReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  wipe(t.Progress[index])
end

-- Primal Storms Elementals
local function PrimalStormsElementalsUpdate(index)
  SI.db.Toons[SI.thisToon].Progress[index] = wipe(SI.db.Toons[SI.thisToon].Progress[index] or {})
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    SI.db.Toons[SI.thisToon].Progress[index][questID] = C_QuestLog_IsQuestFlaggedCompleted(questID)
  end
end

local function PrimalStormsElementalsShow(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Quests then return end
  if not t or not t.Progress or not t.Progress[index] then return end

  local totalDone = 0
  for _, questID in ipairs(Module.TrackedQuest[index].relatedQuest) do
    if t.Progress[index][questID] then
      totalDone = totalDone + 1
    end
  end
  return string.format("%d/%d", totalDone, #Module.TrackedQuest[index].relatedQuest)
end

local function PrimalStormsElementalsReset(toon, index)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress or not t.Progress[index] then return end

  wipe(t.Progress[index])
end

Module.TrackedQuest = {
  -- Conquest
  {
    name = PVP_CONQUEST,
    func = ConquestUpdate,
    weekly = true,
    showFunc = ConquestShow,
    resetFunc = ConquestReset,
  },
  -- Island Expedition
  {
    name = ISLANDS_HEADER,
    quest = {
      ["Alliance"] = 53436,
      ["Horde"]    = 53435,
    },
    weekly = true,
    resetFunc = KeepProgress,
    relatedQuest = {53435, 53436},
  },
  -- Horrific Vision
  {
    name = SPLASH_BATTLEFORAZEROTH_8_3_0_FEATURE1_TITLE,
    weekly = true,
    func = HorrificVisionUpdate,
    showFunc = HorrificVisionShow,
    resetFunc = HorrificVisionReset,
    tooltipKey = 'ShowHorrificVisionTooltip',
    -- addition info
    rewardQuestID = {
      57841,
      57845,
      57842,
      57846,
      57843,
      57847,
      57844,
      57848,
    },
    rewardDesc = {
      {"1 + 0", L["Vision Boss Only"]},
      {"3 + 0", L["Vision Boss + 2 Bonus Objectives"]},
      {"5 + 0", L["Full Clear No Masks"]},
      {"5 + 1", L["Full Clear + 1 Mask"]},
      {"5 + 2", L["Full Clear + 2 Masks"]},
      {"5 + 3", L["Full Clear + 3 Masks"]},
      {"5 + 4", L["Full Clear + 4 Masks"]},
      {"5 + 5", L["Full Clear + 5 Masks"]},
    },
  },
  -- N'Zoth Assaults
  {
    name = WORLD_MAP_THREATS,
    weekly = true,
    func = NZothAssaultUpdate,
    showFunc = NZothAssaultShow,
    resetFunc = NZothAssaultReset,
    tooltipKey = 'ShowNZothAssaultTooltip',
    relatedQuest = {
      -- Uldum
      57157, -- Assault: The Black Empire
      55350, -- Assault: Amathet Advance
      56308, -- Assault: Aqir Unearthed
      -- Vale of Eternal Blossoms
      56064, -- Assault: The Black Empire
      57008, -- Assault: The Warring Clans
      57728, -- Assault: The Endless Swarm
    },
    -- addition info
    assaultQuest = {
      [57157] = { -- The Black Empire in Uldum
        57008, -- Assault: The Warring Clans
        57728, -- Assault: The Endless Swarm
      },
      [56064] = { -- The Black Empire in Vale of Eternal Blossoms
        55350, -- Assault: Amathet Advance
        56308, -- Assault: Aqir Unearthed
      },
    },
  },
  -- Lesser Visions of N'Zoth
  {
    name = L["Lesser Visions of N'Zoth"],
    func = LesserVisionUpdate,
    showFunc = LesserVisionShow,
    resetFunc = LesserVisionReset,
    relatedQuest = {
      58151, -- Minions of N'Zoth
      58155, -- A Hand in the Dark
      58156, -- Vanquishing the Darkness
      58167, -- Preventative Measures
      58168, -- A Dark, Glaring Reality
    },
  },
  -- Torghast Weekly
  {
    name = L["Torghast"],
    weekly = true,
    func = TorghastUpdate,
    showFunc = TorghastShow,
    resetFunc = TorghastReset,
    tooltipKey = 'ShowTorghastTooltip',
    widgetID = {
      {2925, 2930}, -- Fracture Chambers
      {2926, 2932}, -- Skoldus Hall
      {2924, 2934}, -- Soulforges
      {2927, 2936}, -- Coldheart Interstitia
      {2928, 2938}, -- Mort'regar
      {2929, 2940}, -- The Upper Reaches
    },
  },
  -- Covenant Assaults
  {
    name = L["Covenant Assaults"],
    weekly = true,
    func = CovenantAssaultUpdate,
    showFunc = CovenantAssaultShow,
    resetFunc = CovenantAssaultReset,
    tooltipKey = 'ShowCovenantAssaultTooltip',
    relatedQuest = {
      63823, -- Night Fae Assault
      63822, -- Venthyr Assault
      63824, -- Kyrian Assault
      63543, -- Necrolord Assault
    },
  },
  -- Profession Treatise
  {
    name = L["Profession Treatise"],
    weekly = true,
    func = ProfessionTreatiseUpdate,
    showFunc = ProfessionTreatiseShow,
    resetFunc = ProfessionTreatiseReset,
    relatedQuest = {
      74108, -- Alchemy
      74109, -- Blacksmithing
      74110, -- Enchanting
	  74111, -- Engineering
	  74107, -- Herbalism
	  74105, -- Inscription
	  74112, -- Jewelcrafting
	  74113, -- Leatherworking
	  74106, -- Mining
	  74114, -- Skinning
	  74115, -- Tailoring
    },
    tooltipKey = 'ShowProfessionTreatiseTooltip',
  },
  -- Profession Quests
  {
    name = L["Profession Quests"],
    weekly = true,
    func = ProfessionQuestsUpdate,
    showFunc = ProfessionQuestsShow,
    resetFunc = ProfessionQuestsReset,
    relatedQuest = {
      --Show Your Mettle
	   70221,
	  -- Alchemy
	   -- Trainer
	   70530, -- Examination Week
	   70531, -- Mana Markets
	   70532, -- Aiding the Raiding
	   70533, -- Draught, Oiled Again
	   -- Consortium
	   66937, -- Decaying News
	   66938, -- Mammoth Marrow
	   66940, -- Elixir Experiment
	   72427, -- Animated Infusion
	   
	  -- Blacksmithing
	   70589, -- Blacksmithing Services Requested
	   -- Trainer
	   70211, -- Stomping Explorers
	   70233, -- Axe Shortage
	   70234, -- All this Hammering
	   70235, -- Repair Bill
	   -- Consortium
	   66517, -- A New Source of Weapons
	   66897, -- Fuel for the Forge
	   66941, -- Tremendous Tools
	   72398, -- Rock and Stone
	   
	  -- Enchanting
	   -- Trainer
	   72155, -- Spread the Enchantment
	   72172, -- Essence, Shards, and Chromatic Dust
	   72173, -- Braced for Enchantment
	   72175, -- A Scept-acular Time
	   -- Consortium
	   66884, -- Fireproof Gear
	   66900, -- Enchanted Relics
	   66935, -- Crystal Quill Pens
	   72423, -- Weathering the Storm
	   
	  -- Engineering
	   70591, -- Engineering Services Requested
	   -- Trainer
	   70539, -- And You Thought They Did Nothing
	   70540, -- An Engineer's Best Friend
	   70545, -- Blingtron 8000...?
	   70557, -- No Scopes
	   -- Consortium
	   66890, -- Stolen Tools
	   66891, -- Explosive Ash
	   66942, -- Enemy Engineering
	   72396, -- Horns of Plenty
	   
	  -- Herbalism
	   -- Trainer
	   70613, -- Get Their Bark Before They Bite
	   70614, -- Bubble Craze
	   70615, -- The Case of the Missing Herbs
	   70616, -- How Many??
	   
	  -- Inscription
	   70592, -- Inscription Services Requested
	   -- Trainer
	   70558, -- Disillusioned Illusions
	   70559, -- Quill You Help?
	   70560, -- The Most Powerful Tool: Good Documentation
	   70561, -- A Scribe's Tragedy
	   -- Consortium
	   66943, -- Wood for Writing
	   66944, -- Peacock Pigments
	   66945, -- Icy Ink
	   72438, -- Tarasek Intentions
	   
	  -- Jewelcrafting
	   70593, -- Jewelcrafting Services Requested
	   -- Trainer
	   70562, -- The Plumbers, Mason
	   70563, -- The Exhibition
	   70564, -- Spectacular
	   70565, -- Separation by Saturation
	   -- Consortium
	   66516, -- Mundane Gems, I Think Not!
	   66949, -- Trinket Bandits
	   66950, -- Heart of a Giant
	   72428, -- Hornswog Hoarders
	   
	  -- Leatherworking
	   70594, -- Leatherworking Services Requested
	   -- Trainer
	   70567, -- When You Give Bakar a Bone
	   70568, -- Tipping the Scales
	   70569, -- For Trisket, a Task Kit
	   70571, -- Drums Here!
	   -- Consortium
	   66363, -- Basilisk Bucklers
	   66364, -- To Fly a Kite
	   66951, -- Population Control
	   72407, -- Soaked in Success
	   
	  -- Mining
	   -- Trainer
	   70617, -- All Mine, Mine, Mine
	   70618, -- The Call of the Forge
	   72156, -- A Fiery Flight
	   72157, -- The Weight of Earth
	   
	  -- Skinning
	   -- Trainer
	   70619, -- A Study of Leather
	   70620, -- Scaling Up
	   72158, -- A Dense Delivery
	   72159, -- Scaling Down
	   
	  --Tailoring
	   70595, -- Tailoring Services Requested
	   -- Trainer
	   70572, -- The Cold Does Bother Them, Actually
	   70582, -- Weave Well Enough Alone
	   70586, -- Sew Many Cooks
	   70587, -- A Knapsack Problem
	   -- Consortium
	   66899, -- Fuzzy Legs
	   66952, -- The Gnoll's Clothes
	   66953, -- All Things Fluffy
	   72410, -- Pincers and Needles
    },
    tooltipKey = 'ShowProfessionQuestsTooltip',
  },
  -- Profession Lootables
  {
    name = L["Profession Lootables"],
    weekly = true,
    func = ProfessionLootablesUpdate,
    showFunc = ProfessionLootablesShow,
    resetFunc = ProfessionLootablesReset,
    relatedQuest = {
      -- Alchemy
	   -- Pack/Dirt
	   66373, -- Experimental Substance
	   66374, -- Reawakened Catalyst
	   -- Drops
	   70511, -- Elementious Splinter
	   70504, -- Decaying Phlegm
	   74935, -- Blazehoof Ashes
	   
	  -- Blacksmithing
	   -- Pack/Dirt
	   66381, -- Valdrakken Weapon Chain
	   66382, -- Draconium Blade Sharpener
	   -- Drops
	   70512, -- Primeval Earth Fragment
	   70513, -- Molten Globule
	   74931, -- Dense Seaforged Javelin
	   
	  -- Enchanting
	   -- Pack/Dirt
	   66377, -- Prismatic Focusing Shard
	   66378, -- Primal Dust
	   -- Drops
	   70514, -- Primordial Aether
	   70515, -- Primalist Charm
	   74927, -- Speck of Arcane Awareness
	   
	  -- Engineering
	   -- Pack/Dirt
	   66379, -- Eroded Titan Gizmo
	   66380, -- Watcher Power Core
	   -- Drops
	   70516, -- Keeper's Mark
	   70517, -- Infinitely Attachable Pair o' Docks
	   74934, -- Everflowing Antifreeze
	   
	  -- Herbalism
	   -- Drops
	   71857, -- Dreambloom
	   71858, -- Dreambloom
	   71859, -- Dreambloom
	   71860, -- Dreambloom
	   71861, -- Dreambloom
	   71864, -- Dreambloom
	   74933, -- Undigested Hochenblume Petal
	   
	  -- Inscription
	   -- Pack/Dirt
	   66375, -- Phoenix Feather Quill
	   66376, -- Iskaaran Trading Ledger
	   -- Drops
	   70518, -- Curious Djaradin Rune
	   70519, -- Draconic Glamour
	   74932, -- Glimmering Rune of Arcantrix
	   
	  -- Jewelcrafting
	   -- Pack/Dirt
	   66388, -- Ancient Gem Fragments
	   66389, -- Chipped Tyrstone
	   -- Drops
	   70520, -- Incandescent Curio
	   70521, -- Elegantly Engraved Embellishment
	   74936, -- Conductive Ametrine Shard
	   
	  -- Leatherworking
	   -- Pack/Dirt
	   66384, -- Molted Dragon Scales
	   66385, -- Preserved Animal Parts
	   -- Drops
	   70522, -- Ossified Hide
	   70523, -- Exceedingly Soft Skin
	   74928, -- Slyvern Alpha Claw
	   
	  -- Mining
	   -- Drops
	   72160, -- Iridescent Ore
	   72161, -- Iridescent Ore
	   72162, -- Iridescent Ore
	   72163, -- Iridescent Ore
	   72164, -- Iridescent Ore
	   72165, -- Iridescent Ore
	   74926, -- Impenetrable Elemental Core
	   
	  -- Skinning
	   -- Drops
	   70381, -- Curious Hides
	   70383, -- Curious Hides
	   70384, -- Curious Hides
	   70385, -- Curious Hides
	   70386, -- Curious Hides
	   70389, -- Curious Hides
	   74930, -- Kingly Sheepskin Pelt
	   
	  --Tailoring
	   -- Pack/Dirt
	   66386, -- Umbral Bone Needle
	   66387, -- Primvalweave Spindle
	   -- Drops
	   70524, -- Ohn'arhan Weave
	   70525, -- Stupidly Effective Stitchery
	   74929, -- Perfect Wildfeather
    },
    tooltipKey = 'ShowProfessionLootablesTooltip',
  },
  -- The World Awaits
  {
    name = L["The World Awaits"],
    weekly = true,
    quest = 72728,
    relatedQuest = {72728},
  },
  -- Emissary of War
  {
    name = L["Emissary of War"],
    weekly = true,
    quest = 72722,
    relatedQuest = {72722},
  },
  -- Timewalking
  {
    name = L["Timewalking"],
    weekly = true,
	func = TimewalkingUpdate,
    showFunc = TimewalkingShow,
	resetFunc = TimewalkingReset,
	tooltipKey = 'ShowTimewalkingTooltip',
    relatedQuest = {
	 72810, -- TBC
	 72726, -- Wrath
	 72810, -- Cata
	 72725, -- MoP
	 72724, -- WoD
	 72719, -- Legion
	},
  },
  -- Patterns Within Patterns
  {
    name = L["Patterns Within Patterns"],
    weekly = true,
    quest = 66042,
    resetFunc = KeepProgress,
    relatedQuest = {66042},
  },
  -- Dragonflight Renown
  {
    name = L["Dragonflight Renown"],
    func = DragonflightRenownUpdate,
    showFunc = DragonflightRenownShow,
    resetFunc = DragonflightRenownReset,
    tooltipKey = 'ShowDragonflightRenownTooltip',
    factionIDs = {
      2507, -- Dragonscale Expedition
      2503, -- Maruuk Centaur
      2511, -- Iskaara Tuskarr
      2510, -- Valdrakken Accord
    },
  },
  -- Aiding the Accord
  {
    name = L["Aiding the Accord"],
    weekly = true,
    func = AidingTheAccordUpdate,
    showFunc = AidingTheAccordShow,
    resetFunc = AidingTheAccordReset,
    tooltipKey = 'ShowAidingTheAccordTooltip',
    relatedQuest = {
      70750, -- Aiding the Accord
      72068, -- Aiding the Accord: A Feast For All
      72373, -- Aiding the Accord: The Hunt is On
      72374, -- Aiding the Accord: Dragonbane Keep
      72375, -- Aiding the Accord: The Isles Call
      75259, -- Aiding the Accord: Zskera Vault
    },
  },
  --Community Feast
  {
    name = L["Community Feast"],
    weekly = true,
    quest = 70893,
    relatedQuest = {70893},
  },
  -- Siege on Dragonbane Keep
  {
    name = L["Siege on Dragonbane Keep"],
    weekly = true,
    quest = 70866,
    relatedQuest = {70866},
  },
  -- Grand Hunt
  {
    name = L["Grand Hunt"],
    weekly = true,
    func = GrandHuntUpdate,
    showFunc = GrandHuntShow,
    resetFunc = GrandHuntReset,
    relatedQuest = {
      70906, -- Epic
      71136, -- Rare
      71137, -- Uncommon
    },
    tooltipKey = 'ShowGrandHuntTooltip',
  },
  -- Trial of Elements
  {
    name = L["Trial of Elements"],
    weekly = true,
    quest = 71995,
    relatedQuest = {71995},
  },
  -- Trial of Flood
  {
    name = L["Trial of Flood"],
    weekly = true,
    quest = 71033,
    relatedQuest = {71033},
  },
  -- Primal Storms Core
  {
    name = L["Primal Storms Core"],
    weekly = true,
    func = PrimalStormsCoreUpdate,
    showFunc = PrimalStormsCoreShow,
    resetFunc = PrimalStormsCoreReset,
    relatedQuest = {
      73162, -- Storm's Fury
      72686, -- Storm Surge
      70723, -- Earth
      70752, -- Water
      70753, -- Air
      70754, -- Fire
    },
    tooltipKey = 'ShowPrimalStormsCoreTooltip',
  },
  -- Primal Storms Elementals
  {
    name = L["Primal Storms Elementals"],
    daily = true,
    func = PrimalStormsElementalsUpdate,
    showFunc = PrimalStormsElementalsShow,
    resetFunc = PrimalStormsElementalsReset,
    relatedQuest = {
      73991, --Emblazion -- Fire
      74005, --Infernum
      74006, --Kain Firebrand
      74016, --Neela Firebane
      73989, --Crystalus -- Water
      73993, --Frozion
      74027, --Rouen Icewind
      74009, --Iceblade Trio
      73986, --Bouldron -- Earth
      73998, --Gravlion
      73999, --Grizzlerock
      74039, --Zurgaz Corebreaker
      73995, --Gaelzion -- Air
      74007, --Karantun
      74022, --Pipspark Thundersnap
      74038, --Voraazka
    },
    tooltipKey = 'ShowPrimalStormsElementalsTooltip',
  },
  -- Sparks of Life
  {
    name = L["Sparks of Life"],
    weekly = true,
    func = SparksOfLifeUpdate,
    resetFunc = SparksOfLifeReset,
    relatedQuest = {
      72646, -- The Waking Shores
      72647, -- Ohn'ahran Plains
      72648, -- The Azure Span
      72649, -- Thaldraszus
    },
  }
}

function Module:OnEnable()
  self:UpdateAll()

  self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateAll')
  self:RegisterEvent('QUEST_LOG_UPDATE', 'UpdateAll')
end

function Module:UpdateAll()
  local t = SI.db.Toons[SI.thisToon]
  if not t.Progress then t.Progress = {} end
  for i, tbl in ipairs(self.TrackedQuest) do
    if tbl.func then
      tbl.func(i)
    elseif tbl.quest then
      local questID = tbl.quest
      if type(questID) ~= "number" then
        questID = questID[t.Faction]
      end
      if questID then
        -- no questID on Neutral Pandaren or first login
        local result = {}
        local _, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, 1, false)
        if objectiveType == 'progressbar' then
          numFulfilled = GetQuestProgressBarPercent(questID)
          numRequired = 100
        end
        result.objectiveType = objectiveType
        result.isFinish = finished
        result.numFulfilled = numFulfilled
        result.numRequired = numRequired
        if C_QuestLog_IsQuestFlaggedCompleted(questID) then
          result.unlocked = true
          result.isComplete = true
        else
          local isOnQuest = C_QuestLog_IsOnQuest(questID)
          result.unlocked = isOnQuest
          result.isComplete = false
        end
        t.Progress[i] = result
      end
    end
  end
end

function Module:OnDailyReset(toon)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress then return end
  for i, tbl in ipairs(self.TrackedQuest) do
    if tbl.daily then
      if tbl.resetFunc then
        tbl.resetFunc(toon, i)
      else
        local prev = t.Progress[i]
        t.Progress[i] = {
          unlocked = prev.unlocked,
          isComplete = false,
          isFinish = false,
          numFulfilled = 0,
          numRequired = prev.numRequired,
        }
      end
    end
  end
end

function Module:OnWeeklyReset(toon)
  local t = SI.db.Toons[toon]
  if not t or not t.Progress then return end
  for i, tbl in ipairs(self.TrackedQuest) do
    if tbl.weekly then
      if tbl.resetFunc then
        tbl.resetFunc(toon, i)
      else
        local prev = t.Progress[i]
        if prev then
          t.Progress[i] = {
            unlocked = prev.unlocked,
            isComplete = false,
            isFinish = false,
            numFulfilled = 0,
            numRequired = prev.numRequired,
          }
        end
      end
    end
  end
end

function Module:BuildOptions(order)
  local option = {}
  for index, tbl in ipairs(self.TrackedQuest) do
    option["Progress" .. index] = {
      type = "toggle",
      order = order + index * 0.01,
      name = tbl.name,
    }
  end
  return option
end

function Module:QuestEnabled(questID)
  if not self.questMap then
    self.questMap = {}
    for index, tbl in ipairs(self.TrackedQuest) do
      if tbl.relatedQuest then
        for _, quest in ipairs(tbl.relatedQuest) do
          self.questMap[quest] = index
        end
      end
    end
  end
  if self.questMap[questID] then
    return SI.db.Tooltip["Progress" .. self.questMap[questID]]
  end
end

-- Use addon global function in future
local function CloseTooltips()
  _G.GameTooltip:Hide()
  if SI.indicatortip then
    SI.indicatortip:Hide()
  end
end

function Module:ShowTooltip(tooltip, columns, showall, preshow)
  local cpairs = SI.cpairs
  local first = true
  for index, tbl in ipairs(self.TrackedQuest) do
    if SI.db.Tooltip["Progress" .. index] or showall then
      local show
      for toon, t in cpairs(SI.db.Toons, true) do
        if (
          showall or
          (t.Progress and t.Progress[index] and t.Progress[index].unlocked) or
          (tbl.showFunc and tbl.showFunc(toon, index))
        ) then
          show = true
          break
        end
      end
      if show then
        if first == true then
          preshow()
          first = false
        end
        local line = tooltip:AddLine(NORMAL_FONT_COLOR_CODE .. tbl.name .. FONT_COLOR_CODE_CLOSE)
        for toon, t in cpairs(SI.db.Toons, true) do
          local value = t.Progress and t.Progress[index]
          local text
          if tbl.showFunc then
            text = tbl.showFunc(toon, index)
          elseif value then
            if not value.unlocked then
              -- do nothing
            elseif value.isComplete then
              text = "\124T" .. READY_CHECK_READY_TEXTURE .. ":0|t"
            elseif value.isFinish then
              text = "\124T" .. READY_CHECK_WAITING_TEXTURE .. ":0|t"
            else
              if value.objectiveType == 'progressbar' then
                text = floor((value.numFulfilled or 0) / value.numRequired * 100) .. "%"
              else
                -- Note: no idea why .numRequired is nil rarely (#325)
                -- protect this now to stop lua error
                text = (value.numFulfilled or "?") .. "/" .. (value.numRequired or "?")
              end
            end
          end
          local col = columns[toon .. 1]
          if col and text then
            -- check if current toon is showing
            -- don't add columns
            -- showFunc may return nil, or tbl.unlocked is nil, don't :SetCell and :SetCellScript in this case
            tooltip:SetCell(line, col, text, "CENTER", 4)
            if tbl.tooltipKey then
              tooltip:SetCellScript(line, col, "OnEnter", SI.hoverTooltip[tbl.tooltipKey], {toon, index})
              tooltip:SetCellScript(line, col, "OnLeave", CloseTooltips)
            end
          end
        end
      end
    end
  end
end