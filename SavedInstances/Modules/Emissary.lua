local SI, L = unpack((select(2, ...)))
local Module = SI:NewModule("Emissary", "AceEvent-3.0")

-- Lua functions
local floor, ipairs, pairs, time = floor, ipairs, pairs, time

-- WoW API / Variables
local C_QuestLog_GetBountiesForMapID = C_QuestLog.GetBountiesForMapID
local C_QuestLog_GetQuestRewardCurrencies = C_QuestLog.GetQuestRewardCurrencies
local C_QuestLog_GetTitleForQuestID = C_QuestLog.GetTitleForQuestID
local C_QuestLog_IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local C_TaskQuest_GetQuestTimeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes
local GetNumQuestLogRewards = GetNumQuestLogRewards
local GetQuestLogRewardInfo = GetQuestLogRewardInfo
local GetQuestLogRewardMoney = GetQuestLogRewardMoney
local GetQuestObjectiveInfo = GetQuestObjectiveInfo

local QuestUtils_GetBestQualityItemRewardIndex = QuestUtils_GetBestQualityItemRewardIndex

local Emissaries = {
  [6] = {
    uiMapID = 627,
    questID = 43341,
  },
  [7] = {
    uiMapID = 876,
    questID = 51722,
  },
}

SI.Emissaries = Emissaries

-- [Alliance] = Horde
local _switching = {
  [50605] = 50606, -- Alliance War Effort / Horde War Effort
  [50601] = 50602, -- Storm's Wake / Talanji's Expedition
  [50599] = 50598, -- Proudmoore Admiralty / Zandalari Empire
  [50600] = 50603, -- Order of Embers / Voldunai
  [56119] = 56120, -- The Waveblade Ankoan / The Unshackled
}

-- Switching Table
-- [questID] = { ["Alliance"] = questID, ["Horde"] = questID }
local switching = {}
for k, v in pairs(_switching) do
  local data = {
    Alliance = k,
    Horde = v,
  }
  switching[k] = data
  switching[v] = data
end

function Module:OnEnable()
  self:RegisterEvent("QUEST_LOG_UPDATE")
end

function Module:QUEST_LOG_UPDATE()
  if SI.db.DailyResetTime < time() then
    -- daily reset not run yet
    return
  end

  local t = SI.db.Toons[SI.thisToon]
  if not t.Emissary then
    t.Emissary = {}
  end

  for expansionLevel, data in pairs(Emissaries) do
    if not t.Emissary[expansionLevel] then
      t.Emissary[expansionLevel] = {}
    end
    if not SI.db.Emissary.Expansion[expansionLevel] then
      SI.db.Emissary.Expansion[expansionLevel] = {}
    end
    local currExpansion = SI.db.Emissary.Expansion[expansionLevel]

    if C_QuestLog_IsQuestFlaggedCompleted(data.questID) then
      t.Emissary[expansionLevel].unlocked = true
      if not t.Emissary[expansionLevel].days then
        t.Emissary[expansionLevel].days = {}
      end
      for i = 1, 3 do
        if not t.Emissary[expansionLevel].days[i] then
          t.Emissary[expansionLevel].days[i] = {}
        end
        t.Emissary[expansionLevel].days[i].isComplete = true
      end

      local bounties = C_QuestLog_GetBountiesForMapID(data.uiMapID) or {}
      for _, info in ipairs(bounties) do
        local title = C_QuestLog_GetTitleForQuestID(info.questID)
        local timeleft = C_TaskQuest_GetQuestTimeLeftMinutes(info.questID)
        local _, _, isFinish, questDone, questNeed = GetQuestObjectiveInfo(info.questID, 1, false)
        local money = GetQuestLogRewardMoney(info.questID)
        local numQuestRewards = GetNumQuestLogRewards(info.questID)
        local currencyRewards = C_QuestLog_GetQuestRewardCurrencies(info.questID)
        if title then
          SI.db.Emissary.Cache[info.questID] = title -- cache quest name
          local day = floor((timeleft - 1) / 1440) + 1 -- [1, 2, 3]
          if not currExpansion[day] then
            currExpansion[day] = {}
          end
          if switching[info.questID] then
            currExpansion[day].questID = switching[info.questID]
          else
            currExpansion[day].questID = {
              Alliance = info.questID,
              Horde = info.questID,
            }
          end
          currExpansion[day].questNeed = questNeed
          currExpansion[day].expiredTime = timeleft * 60 + time()

          local store = t.Emissary[expansionLevel].days[day]
          store.isComplete = false
          store.isFinish = isFinish
          store.questDone = questDone
          -- Update Emissary Reward
          if money > 0 or numQuestRewards > 0 or #currencyRewards > 0 then
            store.questReward = {}
            if money > 0 then
              store.questReward.money = money
            elseif numQuestRewards > 0 then
              local itemIndex = QuestUtils_GetBestQualityItemRewardIndex(info.questID)
              local itemName, _, _, quality, _, _, itemLvl = GetQuestLogRewardInfo(itemIndex, info.questID)
              store.questReward.itemName = itemName
              store.questReward.quality = quality
              store.questReward.itemLvl = itemLvl
            else
              store.questReward.currencyID = currencyRewards[1].currencyID
              store.questReward.quantity = currencyRewards[1].totalRewardAmount
            end
          end
        end
      end
    else
      t.Emissary[expansionLevel] = nil
    end
  end
end
