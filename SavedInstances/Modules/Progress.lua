local SI, L = unpack((select(2, ...)))
local Module = SI:NewModule('Progress', 'AceEvent-3.0')
local Tooltip = SI:GetModule('Tooltip')

---@class SingleQuestEntry
---@field type "single"
---@field expansion number?
---@field index number
---@field name string
---@field questID number
---@field reset "none" | "daily" | "weekly"
---@field persists boolean
---@field fullObjective boolean

---@class AnyQuestEntry
---@field type "any"
---@field expansion number?
---@field index number
---@field name string
---@field questID number[]
---@field reset "none" | "daily" | "weekly"
---@field persists boolean
---@field fullObjective boolean

---@class QuestListEntry
---@field type "list"
---@field expansion number?
---@field index number
---@field name string
---@field questID number[]
---@field unlockQuest number?
---@field reset "none" | "daily" | "weekly"
---@field persists boolean
---@field threshold number?
---@field questAbbr table<number, string>?
---@field progress boolean
---@field onlyOnOrCompleted boolean
---@field questName table<number, string>?
---@field separateLines string[]?

---@class CustomEntry
---@field type "custom"
---@field expansion number?
---@field index number
---@field name string
---@field reset "none" | "daily" | "weekly"
---@field func fun(store: table, entry: CustomEntry): nil
---@field showFunc fun(store: table, entry: CustomEntry): string?
---@field resetFunc nil | fun(store: table, entry: CustomEntry): nil
---@field tooltipFunc nil | fun(store: table, entry: CustomEntry, toon: string): nil
---@field relatedQuest number[]?

---@alias ProgressEntry SingleQuestEntry | AnyQuestEntry | QuestListEntry | CustomEntry

---@class QuestStore
---@field show boolean?
---@field objectiveType string?
---@field isComplete boolean?
---@field isFinish boolean?
---@field numFulfilled number?
---@field numRequired number?
---@field leaderboardCount number?
---@field text string?
---@field [number] string?

---@class QuestListStore
---@field show boolean?
---@field [number] QuestStore?

---@type table<string, ProgressEntry>
local presets = {
  -- Great Vault (Raid)
  ['great-vault-raid'] = {
    type = 'custom',
    index = 1,
    name = RAIDS,
    reset = 'weekly',
    func = function(store, entry)
      wipe(store)

      if SI.playerLevel < SI.maxLevel then
        store.unlocked = false
      else
        store.unlocked = true

        local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Raid)
        sort(activities, entry.activityCompare)

        for i, activityInfo in ipairs(activities) do
          if activityInfo.progress >= activityInfo.threshold then
            store[i] = activityInfo.level
          end
        end

        local rewardWaiting = C_WeeklyRewards.HasAvailableRewards() and C_WeeklyRewards.CanClaimRewards()
        store.rewardWaiting = rewardWaiting
      end
    end,
    showFunc = function(store, entry)
      if not store.unlocked then
        return
      end
      local text
      for index = 1, #store do
        if store[index] then
          text = (index > 1 and (text .. " / ") or "") .. (entry.difficultyNames[store[index]] or GetDifficultyInfo(store[index]))
        end
      end
      if store.rewardWaiting then
        if not text then
          text = SI.questTurnin
        else
          text = text .. "(" .. SI.questTurnin .. ")"
        end
      end
      return text
    end,
    resetFunc = function(store)
      local unlocked = store.unlocked
      local rewardWaiting = not not store[1]
      wipe(store)

      store.unlocked = unlocked
      store.rewardWaiting = rewardWaiting
    end,
    -- addition info
    activityCompare = function(left, right)
      return left.index < right.index
    end,
    difficultyNames = {
      [17] = 'L',
      [14] = 'N',
      [15] = 'H',
      [16] = 'M',
    },
  },
  -- Great Vault (PvP)
  ['great-vault-pvp'] = {
    type = 'custom',
    index = 2,
    name = PVP,
    reset = 'weekly',
    func = function(store)
      wipe(store)

      if SI.playerLevel < SI.maxLevel then
        store.unlocked = false
        store.isComplete = false
      else
        local weeklyProgress = C_WeeklyRewards.GetConquestWeeklyProgress()
        local rewardWaiting = C_WeeklyRewards.HasAvailableRewards() and C_WeeklyRewards.CanClaimRewards()

        store.unlocked = true
        store.isComplete = weeklyProgress.progress >= weeklyProgress.maxProgress
        store.numFulfilled = weeklyProgress.progress
        store.numRequired = weeklyProgress.maxProgress
        store.unlocksCompleted = weeklyProgress.unlocksCompleted
        store.maxUnlocks = weeklyProgress.maxUnlocks
        store.rewardWaiting = rewardWaiting
      end
    end,
    showFunc = function(store)
      local text
      if not store.unlocked then
        return
      elseif store.isComplete then
        text = SI.questCheckMark
      else
        text = store.numFulfilled .. "/" .. store.numRequired
      end
      if store.unlocksCompleted and store.maxUnlocks then
        text = text .. "(" .. store.unlocksCompleted .. "/" .. store.maxUnlocks .. ")"
      end
      if store.rewardWaiting then
        text = text .. "(" .. SI.questTurnin .. ")"
      end
      return text
    end,
    resetFunc = function(store)
      local unlocked = store.unlocked
      local numRequired = store.numRequired
      local maxUnlocks = store.maxUnlocks
      local rewardWaiting = store.unlocksCompleted and store.unlocksCompleted > 0
      wipe(store)

      store.unlocked = unlocked
      store.isComplete = false
      store.numFulfilled = 0
      store.numRequired = numRequired
      store.unlocksCompleted = 0
      store.maxUnlocks = maxUnlocks
      store.rewardWaiting = rewardWaiting
    end,
  },
  -- The World Awaits
  ['the-world-awaits'] = {
    type = 'single',
    index = 3,
    name = L["The World Awaits"],
    questID = 72728,
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Emissary of War
  ['emissary-of-war'] = {
    type = 'single',
    index = 4,
    name = L["Emissary of War"],
    questID = 72722,
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Timewalking
  ['timewalking'] = {
    type = 'any',
    index = 5,
    name = L["Timewalking Weekend Event"],
    questID = {
      72727, -- A Burning Path Through Time - TBC Timewalking
      72726, -- A Frozen Path Through Time - WLK Timewalking
      72810, -- A Shattered Path Through Time - CTM Timewalking
      72725, -- A Shrouded Path Through Time - MOP Timewalking
      72724, -- A Savage Path Through Time - WOD Timewalking
      72719, -- A Fel Path Through Time - LEG Timewalking
    },
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Island Expedition
  ['bfa-island'] = {
    type = 'any',
    expansion = 7,
    index = 1,
    name = ISLANDS_HEADER,
    questID = {
      53436, -- Alliance
      53435, -- Horde
    },
    reset = 'weekly',
    persists = true,
    fullObjective = false,
  },
  -- Horrific Vision
  ['bfa-horrific-vision'] = {
    type = 'list',
    expansion = 7,
    index = 2,
    name = SPLASH_BATTLEFORAZEROTH_8_3_0_FEATURE1_TITLE,
    questID = {
      57848,
      57844,
      57847,
      57843,
      57846,
      57842,
      57845,
      57841,
    },
    unlockQuest = 58634, -- Opening the Gateway
    reset = 'weekly',
    persists = false,
    questAbbr = {
      [57848] = "5 + 5",
      [57844] = "5 + 4",
      [57847] = "5 + 3",
      [57843] = "5 + 2",
      [57846] = "5 + 1",
      [57842] = "5 + 0",
      [57845] = "3 + 0",
      [57841] = "1 + 0",
    },
    progress = false,
    onlyOnOrCompleted = false,
    questName = {
      [57848] = L["Full Clear + 5 Masks"],
      [57844] = L["Full Clear + 4 Masks"],
      [57847] = L["Full Clear + 3 Masks"],
      [57843] = L["Full Clear + 2 Masks"],
      [57846] = L["Full Clear + 1 Mask"],
      [57842] = L["Full Clear No Masks"],
      [57845] = L["Vision Boss + 2 Bonus Objectives"],
      [57841] = L["Vision Boss Only"],
    },
  },
  -- N'Zoth Assaults
  ['bfa-nzoth-assault'] = {
    type = 'list',
    expansion = 7,
    index = 3,
    name = WORLD_MAP_THREATS,
    questID = {
      -- Uldum
      57157, -- Assault: The Black Empire
      55350, -- Assault: Amathet Advance
      56308, -- Assault: Aqir Unearthed
      -- Vale of Eternal Blossoms
      56064, -- Assault: The Black Empire
      57008, -- Assault: The Warring Clans
      57728, -- Assault: The Endless Swarm
    },
    unlockQuest = 57362, -- Deeper Into the Darkness
    reset = 'weekly',
    persists = false,
    threshold = 3,
    progress = true,
    onlyOnOrCompleted = true,
  },
  -- Lesser Visions of N'Zoth
  ['bfa-lesser-vision'] = {
    type = 'any',
    expansion = 7,
    index = 4,
    name = L["Lesser Visions of N'Zoth"],
    questID = {
      58151, -- Minions of N'Zoth
      58155, -- A Hand in the Dark
      58156, -- Vanquishing the Darkness
      58167, -- Preventative Measures
      58168, -- A Dark, Glaring Reality
    },
    reset = 'daily',
    persists = false,
    fullObjective = false,
  },
  -- Covenant Assaults
  ['sl-covenant-assault'] = {
    type = 'any',
    expansion = 8,
    index = 1,
    name = L["Covenant Assaults"],
    questID = {
      63823, -- Night Fae Assault
      63822, -- Venthyr Assault
      63824, -- Kyrian Assault
      63543, -- Necrolord Assault
    },
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Patterns Within Patterns
  ['sl-patterns-within-patterns'] = {
    type = 'single',
    expansion = 8,
    index = 2,
    name = L["Patterns Within Patterns"],
    questID = 66042,
    reset = 'weekly',
    persists = true,
    fullObjective = false,
  },
  -- Dragonflight Renown
  ['df-renown'] = {
    type = 'custom',
    expansion = 9,
    index = 1,
    name = L["Dragonflight Renown"],
    reset = 'none',
    func = function(store)
      wipe(store)
      local majorFactionIDs = C_MajorFactions.GetMajorFactionIDs(LE_EXPANSION_DRAGONFLIGHT)
      for _, factionID in ipairs(majorFactionIDs) do
        local data = C_MajorFactions.GetMajorFactionData(factionID)
        store[factionID] = data and {data.renownLevel, data.renownReputationEarned, data.renownLevelThreshold}
      end
    end,
    showFunc = function(store, entry)
      local text
      local majorFactionIDs = C_MajorFactions.GetMajorFactionIDs(LE_EXPANSION_DRAGONFLIGHT)

      local factionIDs = entry.factionIDs
      for _, factionID in ipairs(entry.factionIDs) do
        if not text then
          text = store[factionID] and store[factionID][1] or '0'
        else
          text = text .. ' / ' .. (store[factionID] and store[factionID][1] or '0')
        end
      end

      for _, factionID in ipairs(majorFactionIDs) do
        if not tContains(factionIDs, factionID) then
          if not text then
            text = store[factionID] and store[factionID][1] or '0'
          else
            text = text .. ' / ' .. (store[factionID] and store[factionID][1] or '0')
          end
        end
      end

      return text
    end,
    tooltipFunc = function(store, entry, toon)
      local tip = Tooltip:AcquireIndicatorTip(2, 'LEFT', 'RIGHT')
      tip:AddHeader(SI:ClassColorToon(toon), L["Dragonflight Renown"])

      local majorFactionIDs = C_MajorFactions.GetMajorFactionIDs(LE_EXPANSION_DRAGONFLIGHT)

      local factionIDs = entry.factionIDs
      for _, factionID in ipairs(factionIDs) do
        if store[factionID] then
          tip:AddLine(
            C_MajorFactions.GetMajorFactionData(factionID).name,
            format("%s %s (%s/%s)", COVENANT_SANCTUM_TAB_RENOWN, unpack(store[factionID]))
          )
        else
          tip:AddLine(C_MajorFactions.GetMajorFactionData(factionID).name, LOCKED)
        end
      end

      for _, factionID in ipairs(majorFactionIDs) do
        if not tContains(factionIDs, factionID) then
          if store[factionID] then
            tip:AddLine(
              C_MajorFactions.GetMajorFactionData(factionID).name,
              format("%s %s (%s/%s)", COVENANT_SANCTUM_TAB_RENOWN, unpack(store[factionID]))
            )
          else
            tip:AddLine(C_MajorFactions.GetMajorFactionData(factionID).name, LOCKED)
          end
        end
      end

      tip:Show()
    end,
    -- addition info
    factionIDs = {
      2564, -- Loamm Niffen
      2507, -- Dragonscale Expedition
      2503, -- Maruuk Centaur
      2511, -- Iskaara Tuskarr
      2510, -- Valdrakken Accord
    },
  },
  -- Aiding the Accord
  ['df-aiding-the-accord'] = {
    type = 'any',
    expansion = 9,
    index = 2,
    name = L["Aiding the Accord"],
    questID = {
      70750, -- Aiding the Accord
      72068, -- Aiding the Accord: A Feast For All
      72373, -- Aiding the Accord: The Hunt is On
      72374, -- Aiding the Accord: Dragonbane Keep
      72375, -- Aiding the Accord: The Isles Call
      75259, -- Aiding the Accord: Zskera Vault
      75859, -- Aiding the Accord: Sniffenseeking
      75860, -- Aiding the Accord: Researchers Under Fire
      75861, -- Aiding the Accord: Suffusion Camp
      77254, -- Aiding the Accord: Time Rift
      77976, -- Aiding the Accord: Dreamsurge
    },
    reset = 'weekly',
    persists = true,
    fullObjective = true,
  },
  -- Community Feast
  ['df-community-feast'] = {
    type = 'single',
    expansion = 9,
    index = 3,
    name = L["Community Feast"],
    questID = 70893,
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Siege on Dragonbane Keep
  ['df-siege-on-dragonbane-keep'] = {
    type = 'single',
    expansion = 9,
    index = 4,
    name = L["Siege on Dragonbane Keep"],
    questID = 70866,
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Grand Hunt
  ['df-grand-hunt'] = {
    type = 'list',
    expansion = 9,
    index = 5,
    name = L["Grand Hunt"],
    questID = {
      70906, -- Epic
      71136, -- Rare
      71137, -- Uncommon
    },
    reset = 'weekly',
    persists = false,
    progress = false,
    onlyOnOrCompleted = false,
    questName = {
      [70906] = MAW_BUFF_QUALITY_STRING_EPIC, -- Epic
      [71136] = MAW_BUFF_QUALITY_STRING_RARE, -- Rare
      [71137] = MAW_BUFF_QUALITY_STRING_UNCOMMON, -- Uncommon
    },
  },
  -- Trial of Elements
  ['df-trial-of-elements'] = {
    type = 'single',
    expansion = 9,
    index = 6,
    name = L["Trial of Elements"],
    questID = 71995,
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Trial of Flood
  ['df-trial-of-flood'] = {
    type = 'single',
    expansion = 9,
    index = 7,
    name = L["Trial of Flood"],
    questID = 71033,
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Primal Storms Core
  ['df-primal-storms-core'] = {
    type = 'list',
    expansion = 9,
    index = 8,
    name = L["Primal Storms Core"],
    questID = {
      73162, -- Storm's Fury
      72686, -- Storm Surge
      70723, -- Earth
      70752, -- Water
      70753, -- Air
      70754, -- Fire
    },
    reset = 'weekly',
    persists = false,
    progress = false,
    onlyOnOrCompleted = false,
    questName = {
      [73162] = L["Storm's Fury"], -- Storm's Fury
      [72686] = L["Storm Surge"], -- Storm Surge
      [70723] = YELLOW_FONT_COLOR_CODE .. L["Earth Core"] .. FONT_COLOR_CODE_CLOSE, -- Earth
      [70752] = "|cff42a4f5" .. L["Water Core"] .. FONT_COLOR_CODE_CLOSE, -- Water
      [70753] = "|cffe4f2f5" .. L["Air Core"] .. FONT_COLOR_CODE_CLOSE, -- Air
      [70754] = ORANGE_FONT_COLOR_CODE .. L["Fire Core"] .. FONT_COLOR_CODE_CLOSE, -- Fire
    },
  },
  -- Primal Storms Elementals
  ['df-primal-storms-elementals'] = {
    type = 'list',
    expansion = 9,
    index = 9,
    name = L["Primal Storms Elementals"],
    questID = {
      73991, -- Emblazion -- Fire
      74005, -- Infernum
      74006, -- Kain Firebrand
      74016, -- Neela Firebane
      73989, -- Crystalus -- Water
      73993, -- Frozion
      74027, -- Rouen Icewind
      74009, -- Iceblade Trio
      73986, -- Bouldron -- Earth
      73998, -- Gravlion
      73999, -- Grizzlerock
      74039, -- Zurgaz Corebreaker
      73995, -- Gaelzion -- Air
      74007, -- Karantun
      74022, -- Pipspark Thundersnap
      74038, -- Voraazka
    },
    reset = 'daily',
    persists = false,
    progress = false,
    onlyOnOrCompleted = false,
    questName = {
      [73991] = ORANGE_FONT_COLOR_CODE .. L["Emblazion"] .. FONT_COLOR_CODE_CLOSE, -- Emblazion -- Fire
      [74005] = ORANGE_FONT_COLOR_CODE .. L["Infernum"] .. FONT_COLOR_CODE_CLOSE, -- Infernum
      [74006] = ORANGE_FONT_COLOR_CODE .. L["Kain Firebrand"] .. FONT_COLOR_CODE_CLOSE, -- Kain Firebrand
      [74016] = ORANGE_FONT_COLOR_CODE .. L["Neela Firebane"] .. FONT_COLOR_CODE_CLOSE, -- Neela Firebane
      [73989] = "|cff42a4f5" .. L["Crystalus"] .. FONT_COLOR_CODE_CLOSE, -- Crystalus -- Water
      [73993] = "|cff42a4f5" .. L["Frozion"] .. FONT_COLOR_CODE_CLOSE, -- Frozion
      [74027] = "|cff42a4f5" .. L["Rouen Icewind"] .. FONT_COLOR_CODE_CLOSE, -- Rouen Icewind
      [74009] = "|cff42a4f5" .. L["Iceblade Trio"] .. FONT_COLOR_CODE_CLOSE, -- Iceblade Trio
      [73986] = YELLOW_FONT_COLOR_CODE .. L["Bouldron"] .. FONT_COLOR_CODE_CLOSE, -- Bouldron -- Earth
      [73998] = YELLOW_FONT_COLOR_CODE .. L["Gravlion"] .. FONT_COLOR_CODE_CLOSE, -- Gravlion
      [73999] = YELLOW_FONT_COLOR_CODE .. L["Grizzlerock"] .. FONT_COLOR_CODE_CLOSE, -- Grizzlerock
      [74039] = YELLOW_FONT_COLOR_CODE .. L["Zurgaz Corebreaker"] .. FONT_COLOR_CODE_CLOSE, -- Zurgaz Corebreaker
      [73995] = "|cffe4f2f5" .. L["Gaelzion"] .. FONT_COLOR_CODE_CLOSE, -- Gaelzion -- Air
      [74007] = "|cffe4f2f5" .. L["Karantun"] .. FONT_COLOR_CODE_CLOSE, -- Karantun
      [74022] = "|cffe4f2f5" .. L["Pipspark Thundersnap"] .. FONT_COLOR_CODE_CLOSE, -- Pipspark Thundersnap
      [74038] = "|cffe4f2f5" .. L["Voraazka"] .. FONT_COLOR_CODE_CLOSE, -- Voraazka
    },
    separateLines = {
      [1] = ORANGE_FONT_COLOR_CODE .. L["Fire"] .. FONT_COLOR_CODE_CLOSE,
      [5] = "|cff42a4f5" .. L["Water"] .. FONT_COLOR_CODE_CLOSE,
      [9] = YELLOW_FONT_COLOR_CODE .. L["Earth"] .. FONT_COLOR_CODE_CLOSE,
      [13] = "|cffe4f2f5" .. L["Air"] .. FONT_COLOR_CODE_CLOSE,
    },
  },
  -- Sparks of Life
  ['df-sparks-of-life'] = {
    type = 'any',
    expansion = 9,
    index = 10,
    name = L["Sparks of Life"],
    questID = {
      72646, -- The Waking Shores
      72647, -- Ohn'ahran Plains
      72648, -- The Azure Span
      72649, -- Thaldraszus
    },
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- A Worthy Ally: Loamm Niffen
  ['df-a-worthy-ally-loamm-niffen'] = {
    type = 'single',
    expansion = 9,
    index = 11,
    name = L["A Worthy Ally: Loamm Niffen"],
    questID = 75665,
    reset = 'weekly',
    persists = true,
    fullObjective = false,
  },
  -- Fighting is Its Own Reward
  ['df-fighting-is-its-own-reward'] = {
    type = 'single',
    expansion = 9,
    index = 12,
    name = L["Fighting is Its Own Reward"],
    questID = 76122,
    reset = 'weekly',
    persists = true,
    fullObjective = false,
  },
  -- Researchers Under Fire
  ['df-researchers-under-fire'] = {
    type = 'list',
    expansion = 9,
    index = 13,
    name = L["Researchers Under Fire"],
    questID = {
      75630, -- Epic
      75629, -- Rare
      75628, -- Uncommon
      75627, -- Common
    },
    reset = 'weekly',
    persists = false,
    progress = false,
    onlyOnOrCompleted = false,
    questName = {
      [75630] = MAW_BUFF_QUALITY_STRING_EPIC, -- Epic
      [75629] = MAW_BUFF_QUALITY_STRING_RARE, -- Rare
      [75628] = MAW_BUFF_QUALITY_STRING_UNCOMMON, -- Uncommon
      [75627] = MAW_BUFF_QUALITY_STRING_COMMON, -- Common
    },
  },
  -- Disciple of Fyrakk
  ['df-disciple-of-fyrakk'] = {
    type = 'single',
    expansion = 9,
    index = 14,
    name = L["Disciple of Fyrakk"],
    questID = 75467,
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Secured Shipment
  ['df-secured-shipment'] = {
    type = 'any',
    expansion = 9,
    index = 15,
    name = L["Secured Shipment"],
    questID = {
      75525,
      74526,
    },
    reset = 'weekly',
    persists = false,
    fullObjective = false,
  },
  -- Time Rift
  ['df-time-rift'] = {
    type = 'single',
    expansion = 9,
    index = 16,
    name = L["Time Rift"],
    questID = 77836,
    reset = 'weekly',
    persists = false,
    fullObjective = false
  },
  -- Dreamsurge
  ['df-dreamsurge'] = {
    type = 'single',
    expansion = 9,
    index = 17,
    name = L["Shaping the Dreamsurge"],
    questID = 77251,
    reset = 'weekly',
    persists = false,
    fullObjective = false
  }
}

---update the progress of quest to the store
---@param store QuestStore
---@param questID number
---@return boolean show is completed or on quest
local function UpdateQuestStore(store, questID)
  wipe(store)

  if C_QuestLog.IsQuestFlaggedCompleted(questID) then
    store.show = true
    store.isComplete = true

    return true
  elseif not C_QuestLog.IsOnQuest(questID) then
    store.show = false

    return false
  else
    local showText
    local allFinished = true
    local leaderboardCount = C_QuestLog.GetNumQuestObjectives(questID)
    for i = 1, leaderboardCount do
      local text, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, i, false)
      ---@cast text string
      ---@cast objectiveType "item"|"object"|"monster"|"reputation"|"log"|"event"|"player"|"progressbar"
      ---@cast finished boolean
      ---@cast numFulfilled number
      ---@cast numRequired number

      allFinished = allFinished and finished

      local objectiveText
      if objectiveType == 'progressbar' then
        numFulfilled = GetQuestProgressBarPercent(questID)
        numRequired = 100
        objectiveText = floor(numFulfilled or 0) .. "%"
      else
        objectiveText = numFulfilled .. "/" .. numRequired
      end

      store[i] = text
      if i == 1 then
        store.objectiveType = objectiveType
        store.numFulfilled = numFulfilled
        store.numRequired = numRequired
        showText = objectiveText
      else
        showText = showText .. ' ' .. objectiveText
      end
    end

    store.show = true
    store.isComplete = false
    store.isFinish = allFinished
    store.leaderboardCount = leaderboardCount
    store.text = showText

    return true
  end
end

---reset the progress of quest to the store
---@param store QuestStore
---@param persists boolean
local function ResetQuestStore(store, persists)
  if not store.show or store.isComplete or not persists then
    -- the store should be wiped if any of the following conditions are met:
    -- 1. is not on quest
    -- 2. is completed
    -- 3. is not persistent

    wipe(store)

    store.show = false
  end
end

---show the progress of quest
---@param store QuestStore
---@param entry SingleQuestEntry|AnyQuestEntry
---@return string?
local function ShowQuestStore(store, entry)
  if not store.show then
    return
  elseif store.isComplete then
    return SI.questCheckMark
  elseif store.isFinish then
    return SI.questTurnin
  elseif entry.fullObjective then
    return store.text
  elseif store.objectiveType == 'progressbar' and store.numFulfilled then
    return store.numFulfilled .. "%"
  elseif store.numFulfilled and store.numRequired then
    return store.numFulfilled .. "/" .. store.numRequired
  end
end

---show the progress of quest list
---@param store QuestListStore
---@param entry QuestListEntry
---@return string?
local function ShowQuestListStore(store, entry)
  if not store.show then
    return
  end

  if entry.questAbbr then
    for _, questID in ipairs(entry.questID) do
      if store[questID].isComplete and entry.questAbbr[questID] then
        return entry.questAbbr[questID]
      end
    end
  end

  local completed = 0
  local total = entry.threshold or #entry.questID

  for _, questID in ipairs(entry.questID) do
    if store[questID].isComplete then
      completed = completed + 1
    end
  end

  return completed .. "/" .. total
end

---handle tooltip of quest
local function TooltipQuestStore(_, arg)
  local store, entry, toon = unpack(arg)
  ---@cast store QuestStore
  ---@cast entry SingleQuestEntry|AnyQuestEntry
  ---@cast toon string

  local tip = Tooltip:AcquireIndicatorTip(2, 'LEFT', 'RIGHT')
  tip:AddHeader(SI:ClassColorToon(toon), entry.name)

  if store.isComplete then
    tip:AddLine(SI.questCheckMark)
  elseif store.isFinish then
    tip:AddLine(SI.questTurnin)
  elseif store.leaderboardCount and store.leaderboardCount > 0 then
    for i = 1, store.leaderboardCount do
      tip:AddLine("")
      tip:SetCell(i + 1, 1, store[i], nil, 'LEFT', 2)
    end
  end

  tip:Show()
end

---handle tooltip of quest list
local function TooltipQuestListStore(_, arg)
  local store, entry, toon = unpack(arg)
  ---@cast store QuestListStore
  ---@cast entry QuestListEntry
  ---@cast toon string

  local tip = Tooltip:AcquireIndicatorTip(2, 'LEFT', 'RIGHT')
  tip:AddHeader(SI:ClassColorToon(toon), entry.name)

  local completed = 0
  local total = entry.threshold or #entry.questID

  for _, questID in ipairs(entry.questID) do
    if store[questID].isComplete then
      completed = completed + 1
    end
  end

  tip:AddLine("", completed .. "/" .. total)

  for i, questID in ipairs(entry.questID) do
    if entry.separateLines and entry.separateLines[i] then
      tip:AddLine(entry.separateLines[i])
    end

    if not entry.onlyOnOrCompleted or store[questID].show then
      local questName = entry.questName and entry.questName[questID] or SI:QuestInfo(questID)
      local questText
      if entry.progress then
        if not store.show then
          -- do nothing
        elseif store[questID].isComplete then
          questText = SI.questCheckMark
        elseif store[questID].isFinish then
          questText = SI.questTurnin
        elseif store[questID].objectiveType == 'progressbar' and store[questID].numFulfilled then
          questText = store[questID].numFulfilled .. "%"
        elseif store[questID].numFulfilled and store[questID].numRequired then
          questText = store[questID].numFulfilled .. "/" .. store[questID].numRequired
        end
      else
        questText = (
          store[questID].isComplete and
          (RED_FONT_COLOR_CODE .. CRITERIA_COMPLETED .. FONT_COLOR_CODE_CLOSE) or
          (GREEN_FONT_COLOR_CODE .. AVAILABLE .. FONT_COLOR_CODE_CLOSE)
        )
      end

      tip:AddLine(questName or questID, questText or "")
    end
  end

  tip:Show()
end

---wrap tooltip of custom entry
local function TooltipCustomEntry(_, arg)
  local store, entry, toon = unpack(arg)
  ---@cast store table
  ---@cast entry CustomEntry
  ---@cast toon string

  if entry.tooltipFunc then
    entry.tooltipFunc(store, entry, toon)
  end
end

function Module:OnInitialize()
  if not SI.db.Progress then
    SI.db.Progress = {
      Enable = {},
      Order = {},
      User = {},
    }
  end

  for key in pairs(presets) do
    if type(SI.db.Progress.Enable[key]) ~= 'boolean' then
      SI.db.Progress.Enable[key] = true
    end

    if type(SI.db.Progress.Order[key]) ~= 'number' then
      SI.db.Progress.Order[key] = 50
    end
  end

  for key in pairs(SI.db.Progress.User) do
    if type(SI.db.Progress.Enable[key]) ~= 'boolean' then
      SI.db.Progress.Enable[key] = true
    end

    if type(SI.db.Progress.Order[key]) ~= 'number' then
      SI.db.Progress.Order[key] = 50
    end
  end

  local map = {
    [1] = 'great-vault-pvp', -- PvP Conquest
    [2] = 'bfa-island', -- Island Expedition
    [3] = 'bfa-horrific-vision', -- Horrific Vision
    [4] = 'bfa-nzoth-assault', -- N'Zoth Assaults
    [5] = 'bfa-lesser-vision', -- Lesser Visions of N'Zoth
    [7] = 'sl-covenant-assault', -- Covenant Assaults
    [8] = 'the-world-awaits', -- The World Awaits
    [9] = 'emissary-of-war', -- Emissary of War
    [10] = 'sl-patterns-within-patterns', -- Patterns Within Patterns
    [11] = 'df-renown', -- Dragonflight Renown
    [12] = 'df-aiding-the-accord', -- Aiding the Accord
    [13] = 'df-community-feast', -- Community Feast
    [14] = 'df-siege-on-dragonbane-keep', -- Siege on Dragonbane Keep
    [15] = 'df-grand-hunt', -- Grand Hunt
    [16] = 'df-trial-of-elements', -- Trial of Elements
    [17] = 'df-trial-of-flood', -- Trial of Flood
    [18] = 'df-primal-storms-core', -- Primal Storms Core
    [19] = 'df-primal-storms-elementals', -- Primal Storms Elementals
    [20] = 'df-sparks-of-life', -- Sparks of Life
    [21] = 'df-a-worthy-ally-loamm-niffen', -- A Worthy Ally: Loamm Niffen
    [22] = 'df-fighting-is-its-own-reward', -- Fighting is Its Own Reward
  }

  for i = 1, 22 do
    -- enable status migration
    if SI.db.Tooltip['Progress' .. i] ~= nil and map[i] then
      SI.db.Progress.Enable[map[i]] = SI.db.Tooltip['Progress' .. i]
    end
    SI.db.Tooltip['Progress' .. i] = nil
  end

  for _, db in pairs(SI.db.Toons) do
    if db.Progress then
      -- old database migration
      for oldKey, newKey in pairs(map) do
        if db.Progress[oldKey] then
          db.Progress[newKey] = db.Progress[oldKey]
          db.Progress[oldKey] = nil
        end
      end

      -- database cleanup
      for key in pairs(db.Progress) do
        if not presets[key] and not SI.db.Progress.User[key] then
          db.Progress[key] = nil
        else
          -- check store type
          local entry = presets[key] or SI.db.Progress.User[key]
          local store = db.Progress[key]

          if type(store) ~= 'nil' then
            -- store contains somethings
            if entry.type == 'list' then
              ---@cast entry QuestListEntry
              if type(store) ~= 'table' then
                -- broken store, should be table
                db.Progress[key] = {}
              end

              for _, questID in ipairs(entry.questID) do
                if store[questID] == true then
                  -- simple boolean for list entry
                  store[questID] = {
                    show = true,
                  }
                elseif type(store[questID]) ~= 'table' then
                  -- broken store or false, should be table or nil
                  store[questID] = nil
                end
              end
            elseif entry.type ~= 'custom' then
              ---@cast entry SingleQuestEntry|AnyQuestEntry
              if type(store) ~= 'table' then
                -- broken store, should be table
                db.Progress[key] = {}
              end
            end
          end
        end
      end
    end
  end

  self.display = {}
  self.displayAll = {}
  self:BuildDisplayOrder()
end

function Module:OnEnable()
  self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateAll')
  self:RegisterEvent('QUEST_LOG_UPDATE', 'UpdateAll')

  self:UpdateAll()
end

---sort entry
---@param left string
---@param right string
---@return boolean
local function sortDisplay(left, right)
  -- sort display by order, then presets over user, then expansion, then index, then key
  local leftOrder = SI.db.Progress.Order[left] or 50
  local rightOrder = SI.db.Progress.Order[right] or 50
  if leftOrder ~= rightOrder then
    return leftOrder < rightOrder
  end

  local leftPreset = not not presets[left]
  local rightPreset = not not presets[right]

  if leftPreset ~= rightPreset then
    return leftPreset
  end

  local leftEntry = presets[left] or SI.db.Progress.User[left]
  local rightEntry = presets[right] or SI.db.Progress.User[right]

  if (leftEntry.expansion or -1) ~= (rightEntry.expansion or -1) then
    return (leftEntry.expansion or -1) < (rightEntry.expansion or -1)
  end

  if (leftEntry.index or 0) ~= (rightEntry.index or 0) then
    return (leftEntry.index or 0) < (rightEntry.index or 0)
  end

  return left < right
end

function Module:BuildDisplayOrder()
  wipe(self.display)
  wipe(self.displayAll)

  for key in pairs(presets) do
    if SI.db.Progress.Enable[key] then
      tinsert(self.display, key)
    end
    tinsert(self.displayAll, key)
  end

  for key in pairs(SI.db.Progress.User) do
    if SI.db.Progress.Enable[key] then
      tinsert(self.display, key)
    end
    tinsert(self.displayAll, key)
  end

  sort(self.display, sortDisplay)
  sort(self.displayAll, sortDisplay)
end

---update progress entry
---@param key string
---@param entry ProgressEntry
function Module:UpdateEntry(key, entry)
  local db = SI.db.Toons[SI.thisToon].Progress
  if not db[key] then
    db[key] = {}
  end
  local store = db[key]

  if entry.type == 'single' then
    ---@cast entry SingleQuestEntry
    ---@cast store QuestStore

    UpdateQuestStore(store, entry.questID)
  elseif entry.type == 'any' then
    ---@cast entry AnyQuestEntry
    ---@cast store QuestStore
    for _, questID in ipairs(entry.questID) do
      local show = UpdateQuestStore(store, questID)
      if show then
        break
      end
    end
  elseif entry.type == 'list' then
    ---@cast entry QuestListEntry
    ---@cast store QuestListStore
    wipe(store)

    if entry.unlockQuest then
      store.show = C_QuestLog.IsQuestFlaggedCompleted(entry.unlockQuest)
    else
      store.show = true
    end

    for _, questID in ipairs(entry.questID) do
      store[questID] = {}
      UpdateQuestStore(store[questID], questID)
    end
  elseif entry.type == 'custom' then
    ---@cast entry CustomEntry
    entry.func(store, entry)
  end
end

function Module:UpdateAll()
  for key, entry in pairs(presets) do
    self:UpdateEntry(key, entry)
  end

  for key, entry in pairs(SI.db.Progress.User) do
    self:UpdateEntry(key, entry)
  end
end

---reset progress entry
---@param key string
---@param entry ProgressEntry
---@param toon string
function Module:ResetEntry(key, entry, toon)
  local store = SI.db.Toons[toon].Progress and SI.db.Toons[toon].Progress[key]
  if not store then return end

  if entry.type == 'single' then
    ---@cast entry SingleQuestEntry
    ---@cast store QuestStore

    ResetQuestStore(store, entry.persists)
  elseif entry.type == 'any' then
    ---@cast entry AnyQuestEntry
    ---@cast store QuestStore

    ResetQuestStore(store, entry.persists)
  elseif entry.type == 'list' then
    ---@cast entry QuestListEntry
    ---@cast store QuestListStore

    for _, questID in ipairs(entry.questID) do
      if store[questID] then
        ResetQuestStore(store[questID], entry.persists)
      end
    end
  elseif entry.type == 'custom' then
    ---@cast entry CustomEntry
    if entry.resetFunc then
      entry.resetFunc(store, entry)
    end
  end
end

function Module:OnDailyReset(toon)
  for key, entry in pairs(presets) do
    if entry.reset == 'daily' then
      self:ResetEntry(key, entry, toon)
    end
  end

  for key, entry in pairs(SI.db.Progress.User) do
    if entry.reset == 'daily' then
      self:ResetEntry(key, entry, toon)
    end
  end
end

function Module:OnWeeklyReset(toon)
  for key, entry in pairs(presets) do
    if entry.reset == 'weekly' then
      self:ResetEntry(key, entry, toon)
    end
  end

  for key, entry in pairs(SI.db.Progress.User) do
    if entry.reset == 'weekly' then
      self:ResetEntry(key, entry, toon)
    end
  end
end

do
  local randomSource = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
    'u', 'v', 'w', 'x', 'y', 'z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  }
  local randomUID = function()
    local result = ''
    for _ = 1, 11 do
      result = result .. randomSource[random(1, #randomSource)]
    end
    return result
  end

  local orderValidate = function(_, value)
    if strfind(value, '^%s*[0-9]?[0-9]?[0-9]%s*$') then
      return true
    else
      local err = L["Order must be a number in [0 - 999]"]
      SI:ChatMsg(err)
      return err
    end
  end

  local options

  ---Add user entry to option
  ---@param key string
  ---@param entry ProgressEntry
  local function AddUserEntryToOption(key, entry)
    options.args.Enable.args.User.args[key] = {
      order = entry.index,
      type = 'toggle',
      name = entry.name,
    }
    options.args.Sorting.args[key] = {
      order = function() return tIndexOf(Module.displayAll, key) end,
      type = 'input',
      name = entry.name,
      desc = L["Sort Order"],
      validate = orderValidate,
    }
    options.args.User.args[key] = {
      order = entry.index,
      type = 'group',
      name = entry.name,
      get = function(info) return SI.db.Progress.User[key][info[#info]] end,
      set = function(info, value) SI.db.Progress.User[key][info[#info]] = value end,
      args = {
        name = {
          order = 1,
          type = 'input',
          name = L["Quest Name"],
        },
        questID = {
          order = 2,
          type = 'input',
          name = L["Quest ID"],
          validate = function(info, value)
            local number = tonumber(value)
            return number and number == floor(number)
          end,
          get = function(info)
            return tostring(SI.db.Progress.User[key][info[#info]])
          end,
          set = function(info, value)
            SI.db.Progress.User[key][info[#info]] = tonumber(value) or 0

            Module:CleanUserEntryStore(key)
            Module:UpdateEntry(key, SI.db.Progress.User[key])
          end,
        },
        reset = {
          order = 3,
          type = 'select',
          name = L["Quest Reset Type"],
          values = {
              ['none'] = NONE,
              ['daily'] = DAILY,
              ['weekly'] = WEEKLY,
          },
        },
        persists = {
          order = 4,
          type = 'toggle',
          name = L["Progress Persists"],
        },
        fullObjective = {
          order = 5,
          type = 'toggle',
          name = L["Full Objective"],
        },
        space = {
          order = 6,
          type = 'description',
          name = '',
        },
        DeleteEntry = {
          order = 7,
          type = 'execute',
          name = L["Delete Entry"],
          func = function() Module:DeleteUserEntry(key) end,
        },
      },
    }
  end

  ---Clean store of user entry
  ---@param key string
  function Module:CleanUserEntryStore(key)
    for _, db in pairs(SI.db.Toons) do
      if db.Progress and db.Progress[key] then
        db.Progress[key] = nil
      end
    end
  end

  ---Add user entry
  ---@param entry ProgressEntry
  ---@return string key
  function Module:AddUserEntry(entry)
    local maxIndex = 0
    for _, oldEntry in pairs(SI.db.Progress.User) do
      if oldEntry.index > maxIndex then
        maxIndex = oldEntry.index
      end
    end

    local data = CopyTable(entry)
    data.index = maxIndex + 1

    local key = 'user-' .. randomUID()
    while SI.db.Progress.User[key] do
      key = 'user-' .. randomUID()
    end

    SI.db.Progress.User[key] = data
    SI.db.Progress.Order[key] = 50
    SI.db.Progress.Enable[key] = true

    AddUserEntryToOption(key, data)

    Module:BuildDisplayOrder()
    Module:UpdateEntry(key, data)

    return key
  end

  ---Delete user entry
  ---@param key string
  function Module:DeleteUserEntry(key)
    -- clean up database
    SI.db.Progress.User[key] = nil
    SI.db.Progress.Order[key] = nil
    SI.db.Progress.Enable[key] = nil

    Module:CleanUserEntryStore(key)

    -- remove from options
    options.args.Enable.args.User.args[key] = nil
    options.args.Sorting.args[key] = nil
    options.args.User.args[key] = nil

    Module:BuildDisplayOrder()
  end

  function Module:BuildOptions(order)
    ---@type SingleQuestEntry
    local userSingleEntry = {
      type = 'single',
      name = '',
      questID = 0,
      reset = "none",
      persists = false,
      fullObjective = false,
    }

    local userSingleEntryValidate = function()
      if #(userSingleEntry.name) > 0 and userSingleEntry.questID and userSingleEntry.questID > 0 then
        return true
      end
    end

    options = {
      order = order,
      type = 'group',
      childGroups = 'tab',
      name = L["Quest progresses"],
      args = {
        Enable = {
          order = 1,
          type = 'group',
          name = ENABLE,
          get = function(info) return SI.db.Progress.Enable[info[#info]] end,
          set = function(info, value) SI.db.Progress.Enable[info[#info]] = value; Module:BuildDisplayOrder() end,
          args = {
            Presets = {
              order = 1,
              type = 'group',
              name = L["Presets"],
              guiInline = true,
              args = {
                General = {
                  order = 0,
                  type = 'header',
                  name = GENERAL,
                },
              },
            },
            User = {
              order = 2,
              type = 'group',
              name = L["User"],
              hidden = function() return not next(SI.db.Progress.User) end,
              guiInline = true,
              args = {},
            },
          },
        },
        Sorting = {
          order = 2,
          type = 'group',
          name = L["Sorting"],
          get = function(info) return tostring(SI.db.Progress.Order[info[#info]]) end,
          set = function(info, value) SI.db.Progress.Order[info[#info]] = tonumber(value) or 50; Module:BuildDisplayOrder() end,
          args = {},
        },
        User = {
          order = 3,
          type = 'group',
          name = L["User"],
          args = {
            New = {
              order = -1,
              type = 'group',
              name = L["New Single Quest"],
              get = function(info) return userSingleEntry[info[#info]] end,
              set = function(info, value) userSingleEntry[info[#info]] = value end,
              args = {
                name = {
                  order = 1,
                  type = 'input',
                  name = L["Quest Name"],
                },
                questID = {
                  order = 2,
                  type = 'input',
                  name = L["Quest ID"],
                  validate = function(info, value)
                    local number = tonumber(value)
                    return number and number == floor(number)
                  end,
                  get = function(info) return tostring(userSingleEntry[info[#info]]) end,
                  set = function(info, value) userSingleEntry[info[#info]] = tonumber(value) or 0 end,
                },
                reset = {
                  order = 3,
                  type = 'select',
                  name = L["Quest Reset Type"],
                  values = {
                      ['none'] = NONE,
                      ['daily'] = DAILY,
                      ['weekly'] = WEEKLY,
                  },
                },
                persists = {
                  order = 4,
                  type = 'toggle',
                  name = L["Progress Persists"],
                },
                fullObjective = {
                  order = 5,
                  type = 'toggle',
                  name = L["Full Objective"],
                },
                space = {
                  order = 6,
                  type = 'description',
                  name = '',
                },
                AddEntry = {
                  order = 7,
                  type = 'execute',
                  name = L["Add Entry"],
                  disabled = function() return not userSingleEntryValidate() end,
                  func = function() Module:AddUserEntry(userSingleEntry) end,
                },
                CleanEntry = {
                  order = 8,
                  type = 'execute',
                  name = L["Clean Entry"],
                  func = function()
                    userSingleEntry.name = ''
                    userSingleEntry.questID = 0
                    userSingleEntry.reset = 'none'
                    userSingleEntry.persists = false
                    userSingleEntry.fullObjective = false
                  end,
                },
              },
            },
          },
        },
      },
    }

    for key, entry in pairs(presets) do
      if entry.expansion then
        if not options.args.Enable.args.Presets.args['Expansion' .. entry.expansion .. 'Header'] then
          options.args.Enable.args.Presets.args['Expansion' .. entry.expansion .. 'Header'] = {
            order = (entry.expansion + 1) * 100,
            type = 'header',
            name = _G['EXPANSION_NAME' .. entry.expansion],
          }
        end
      end
      options.args.Enable.args.Presets.args[key] = {
        order = ((entry.expansion or -1) + 1) * 100 + entry.index,
        type = 'toggle',
        name = entry.name,
      }
      options.args.Sorting.args[key] = {
        order = function() return tIndexOf(Module.displayAll, key) end,
        type = 'input',
        name = entry.name,
        desc = L["Sort Order"],
        validate = orderValidate,
      }
    end

    for key, entry in pairs(SI.db.Progress.User) do
      AddUserEntryToOption(key, entry)
    end

    return options
  end
end

---reset progress entry
---@param entry ProgressEntry
---@param questID number
function Module:IsEntryContainsQuest(entry, questID)
  if entry.type == 'single' then
    ---@cast entry SingleQuestEntry
    return entry.questID == questID
  elseif entry.type == 'list' or entry.type == 'list' then
    ---@cast entry AnyQuestEntry|QuestListEntry
    return tContains(entry.questID, questID)
  elseif entry.type == 'custom' and entry.relatedQuest then
    ---@cast entry CustomEntry
    return tContains(entry.relatedQuest, questID)
  end
end

function Module:QuestEnabled(questID)
  for key, entry in pairs(presets) do
    if SI.db.Progress.Enable[key] and self:IsEntryContainsQuest(entry, questID) then
      return true
    end
  end

  for key, entry in pairs(SI.db.Progress.User) do
    if SI.db.Progress.Enable[key] and self:IsEntryContainsQuest(entry, questID) then
      return true
    end
  end
end

function Module:ShowTooltip(tooltip, columns, showall, preshow)
  local cpairs = SI.cpairs
  local first = true
  for _, key in ipairs(showall and self.displayAll or self.display) do
    local entry = presets[key] or SI.db.Progress.User[key]
    local show = false
    for _, t in cpairs(SI.db.Toons, true) do
      local store = t.Progress and t.Progress[key]
      if (
        showall or
        (entry.type ~= 'custom' and store and store.show) or
        (entry.type == 'custom' and store and entry.showFunc(store, entry))
      ) then
        show = true
        break
      end
    end

    if show then
      if first then
        preshow()
        first = false
      end
      local line = tooltip:AddLine(NORMAL_FONT_COLOR_CODE .. entry.name .. FONT_COLOR_CODE_CLOSE)
      for toon, t in cpairs(SI.db.Toons, true) do
        local store = t.Progress and t.Progress[key]
        -- check if current toon is showing
        -- don't add columns
        if store and columns[toon .. 1] then
          ---@cast store table|QuestStore|QuestListStore
          local text, hoverFunc, hoverArg
          if entry.type == 'custom' then
            ---@cast entry CustomEntry
            ---@cast store table
            text = entry.showFunc(store, entry)
            if entry.tooltipFunc then
              hoverFunc = TooltipCustomEntry
              hoverArg = {store, entry, toon}
            end
          elseif entry.type == 'single' or entry.type == 'any' then
            ---@cast entry SingleQuestEntry|AnyQuestEntry
            ---@cast store QuestStore
            text = ShowQuestStore(store, entry)
            if entry.fullObjective then
              hoverFunc = TooltipQuestStore
              hoverArg = {store, entry, toon}
            end
          elseif entry.type == 'list' then
            ---@cast entry QuestListEntry
            ---@cast store QuestListStore
            text = ShowQuestListStore(store, entry)
            hoverFunc = TooltipQuestListStore
            hoverArg = {store, entry, toon}
          end
          if text then
            local col = columns[toon .. 1]
            tooltip:SetCell(line, col, text, 'CENTER', 4)
            if hoverFunc then
              tooltip:SetCellScript(line, col, 'OnEnter', hoverFunc, hoverArg)
              tooltip:SetCellScript(line, col, 'OnLeave', Tooltip.CloseIndicatorTip)
            end
          end
        end
      end
    end
  end
end
