local SI, L = unpack((select(2, ...)))
local Module = SI:NewModule('Professions', 'AceEvent-3.0')
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

---@class QuestSpecificEntry
---@field type "specific"
---@field expansion number?
---@field index number
---@field name string
---@field questID number[]
---@field unlockQuest number?
---@field reset "none" | "daily" | "weekly" | "darkmoon"
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

---@alias ProfessionsEntry SingleQuestEntry | AnyQuestEntry | QuestListEntry | CustomEntry

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

--@class professionListEntry
--@field skillLineID number

---@type table<string, string>
local professionList = {
  -- Alchemy
  [171] = {
      ["skillLineID"] = 2823,
    },
  -- Blacksmithing
  [164] = {
      ["skillLineID"] = 2822,
    },
  -- Enchanting
  [333] = {
      ["skillLineID"] = 2825,
    },
  -- Engineering
  [202] = {
      ["skillLineID"] = 2827,
    },
  -- Inscription
  [773] = {
      ["skillLineID"] = 2828,
    },
  -- Jewelcrafting
  [755] = {
      ["skillLineID"] = 2829,
    },
  -- Leatherworking
  [165] = {
      ["skillLineID"] = 2830,
    },
  -- Tailoring
  [197] = {
      ["skillLineID"] = 2831,
    },
  -- Herbalism
  [182] = {
      ["skillLineID"] = 2832,
    },
  -- Mining
  [186] = {
      ["skillLineID"] = 2833,
    },
  -- Skinning
  [393] = {
      ["skillLineID"] = 2834,
    },
}

---@type table<string, ProfessionsEntry>
local presets = {
  -- Show Your Mettle
  ['show-your-mettle'] = {
    type = 'single',
    expansion = 9,
    index = 1,
    name = L["Show Your Mettle"],
    questID = 70221,
    reset = 'weekly',
    presists = false,
    fullObjective = false,
  },
  -- Darkmoon Faire Quests List
  ['prof-darkmoon-quests'] = {
    type = 'specific',
    expansion = 9,
    index = 2,
    name = L["Darkmoon Faire Quests"],
    reset = 'darkmoon',
    persists = true,
    fullObjective = false,
    onlyOnOrCompleted = false,
    threshold = 2,
    questID = {},
    questIDList = {
      [171] = {
	29506, -- A Fizzy Fusion
      },
      [164] = {
	  29508, -- Baby Needs Two Pair of Shoes
      },
      -- Enchanting
      [333] = {
	  29510, -- Putting Trash to Good Use
      },
      -- Engineering
      [202] = {
          29511, -- Talkin' Tonks
      },
      -- Inscription
      [773] = {
          29515, -- Writing the Future
      },
      -- Jewelcrafting
      [755] = {
          29516, -- Keeping the Faire Sparkling
      },
      -- Leatherworking
      [165] = {
          29517, -- Eyes on the Prizes
      },
      -- Tailoring
      [197] = {
          29520, -- Banners, Banners Everywhere!
      },
      -- Herbalism
      [182] = {
          29514, -- Herbs for Healing
      },
      -- Mining
      [186] = {
          29518, -- Rearm, Reuse, Recycle
      },
      -- Skinning
      [393] = {
          29519, -- Tan My Hide
      },
      --[[
      -- Archaeology
      [794] = {
          29507, -- Fun for the Little Ones
      },
      -- Cooking
      [185] = {
          29509, -- Putting the Crunch in the Frog
      },
      -- Fishing
      [356] = {
          29513, -- Spoilin' for Salty Sea Dogs
      },
      ]]--
    },
  },
  -- Profession Trainer Weekly Quests
  ['prof-trainer-weekly-quests'] = {
    type = 'specific',
    expansion = 9,
    index = 2,
    name = L["Profession Trainer Weekly Quests"],
    reset = 'weekly',
    persists = false,
    fullObjective = false,
    onlyOnOrCompleted = true,
    threshold = 2,
    questID = {},
    questIDList = {
      -- Alchemy
      [171] = {
	70530, -- Examination Week
	70531, -- Mana Markets
	70532, -- Aiding the Raiding
	70533, -- Draught, Oiled Again
      },
      -- Blacksmithing
      [164] = {
	  70211, -- Stomping Explorers
	  70233, -- Axe Shortage
	  70234, -- All this Hammering
	  70235, -- Repair Bill
      },
      -- Enchanting
      [333] = {
	  72155, -- Spread the Enchantment
	  72172, -- Essence, Shards, and Chromatic Dust
	  72173, -- Braced for Enchantment
	  72175, -- A Scept-acular Time
      },
      -- Engineering
      [202] = {
          70539, -- And You Thought They Did Nothing
          70540, -- An Engineer's Best Friend
          70545, -- Blingtron 8000...?
          70557, -- No Scopes
      },
      -- Inscription
      [773] = {
          70558, -- Disillusioned Illusions
          70559, -- Quill You Help?
          70560, -- The Most Powerful Tool: Good Documentation
          70561, -- A Scribe's Tragedy
      },
      -- Jewelcrafting
      [755] = {
          70562, -- The Plumbers, Mason
          70563, -- The Exhibition
          70564, -- Spectacular
          70565, -- Separation by Saturation
      },
      -- Leatherworking
      [165] = {
          70567, -- When You Give Bakar a Bone
          70568, -- Tipping the Scales
          70569, -- For Trisket, a Task Kit
          70571, -- Drums Here!
      },
      -- Tailoring
      [197] = {
          70572, -- The Cold Does Bother Them, Actually
          70582, -- Weave Well Enough Alone
          70586, -- Sew Many Cooks
          70587, -- A Knapsack Problem
      },
      -- Herbalism
      [182] = {
          70613, -- Get Their Bark Before They Bite
          70614, -- Bubble Craze
          70615, -- The Case of the Missing Herbs
          70616, -- How Many??
      },
      -- Mining
      [186] = {
          70617, -- All Mine, Mine, Mine
          70618, -- The Call of the Forge
          72156, -- A Fiery Flight
          72157, -- The Weight of Earth
      },
      -- Skinning
      [393] = {
          70619, -- A Study of Leather
          70620, -- Scaling Up
          72159, -- Scaling Down
          72158, -- A Dense Delivery
      },
    },
  },
  -- Consortium Weekly Quests
  ['prof-consortium-quests'] = {
    type = 'specific',
    expansion = 9,
    index = 4,
    name = L["Consortium Weekly Quests"],
    reset = 'weekly',
    persists = false,
    fullObjective = false,
    onlyOnOrCompleted = true,
    threshold = 2,
    questID = {},
    questIDList = {
      -- Alchemy
      [171] = {
          66937, -- Decaying News
          66938, -- Mammoth Marrow
          66940, -- Elixir Experiment
          72427, -- Animated Infusion
	  75363, -- Deepflayer Dust
	  75371, -- Fascinating Fungi
	  77932, -- Warmth of Life
	  77933, -- Bubbling Discoveries
      },
      -- Blacksmithing
      [164] = {
          66517, -- A New Source of Weapons
          66897, -- Fuel for the Forge
          66941, -- Tremendous Tools
          72398, -- Rock and Stone
	  75569, -- Blacksmith, Black Dragon
	  75148, -- Ancient Techniques
	  77935, -- A-Sword-ed Needs
	  77936, -- A Warm Harvest
      },
      -- Enchanting
      [333] = {
          66884, -- Fireproof Gear
          66900, -- Enchanted Relics
          66935, -- Crystal Quill Pens
          72423, -- Weathering the Storm
	  75865, -- Relic Rustler
	  75150, -- Incandescence
	  77910, -- Enchanted Shrubbery
	  77937, -- Forbidden Sugar
      },
      -- Engineering
      [202] = {
          66890, -- Stolen Tools
          66891, -- Explosive Ash
          66942, -- Enemy Engineering
          72396, -- Horns of Plenty
	  75575, -- Ballistae Bits
	  75608, -- Titan Trash or Titan Treasure?
	  77891, -- Fixing the Dream
	  77938, -- An Unlikely Engineer
      },
      -- Inscription
      [773] = {
          66943, -- Wood for Writing
          66944, -- Peacock Pigments
          66945, -- Icy Ink
          72438, -- Tarasek Intentions
	  75573, -- Proclamation Reclamation
	  75149, -- Obsidian Essays
	  77889, -- A Fiery Proposal
	  77914, -- Burning Runes
      },
      -- Jewelcrafting
      [755] = {
          66516, -- Mundane Gems, I Think Not!
          66949, -- Trinket Bandits
          66950, -- Heart of a Giant
          72428, -- Hornswog Hoarders
	  75362, -- Cephalo-crystalization
	  75602, -- Chips off the Old Crystal Block
	  77912, -- Unmodern Jewelry
	  77892, -- Pearls of Great Value
      },
      -- Leatherworking
      [165] = {
          66363, -- Basilisk Bucklers
          66364, -- To Fly a Kite
          66951, -- Population Control
          72407, -- Soaked in Success
	  75354, -- Mycelium Mastery
	  75368, -- Stones and Scales
	  77945, -- Boots on the Ground
	  77946, -- Fibrous Thread
      },
      -- Tailoring
      [197] = {
          66899, -- Fuzzy Legs
          66952, -- The Gnoll's Clothes
          66953, -- All Things Fluffy
          72410, -- Pincers and Needles
	  75407, -- Silk Scavenging
	  75600, -- Silk's Silk
	  77947, -- Primalist Fashion
	  77949, -- Fashion Feathers
      },
    },
  },
  -- Profession Orders
  ['prof-orders'] = {
    type = 'specific',
    expansion = 9,
    index = 3,
    name = L["Profession Orders"],
    reset = 'weekly',
    persists = false,
    fullObjective = false,
    onlyOnOrCompleted = true,
    threshold = 2,
    questID = {},
    questIDList = {
      -- Blacksmithing
      [164] = {
	70589, -- Blacksmithing Services Requested
      },
      -- Engineering
      [202] = {
	70591, -- Engineering Services Requested
      },
      -- Inscription
      [773] = {
	70592, -- Inscription Services Requested
      },
      -- Jewelcrafting
      [755] = {
	70593, -- Jewelcrafting Services Requested
      },
      -- Leatherworking
      [165] = {
	70594, -- Leatherworking Services Requested
      },
      -- Tailoring
      [197] = {
	70595, -- Tailoring Services Requested
      },
    },

  },
  -- Profession Treatises
  ['prof-treatises'] = {
    type = 'specific',
    expansion = 9,
    index = 5,
    name = L["Profession Treatises"],
    reset = 'weekly',
    persists = false,
    fullObjective = false,
    questID = {},
    onlyOnOrCompleted = true,
    threshold = 2,
    questIDList = {
      -- Alchemy
      [171] = {
	74108, -- Alchemy
      },
      -- Blacksmithing
      [164] = {
	74109, -- Blacksmithing
      },
      -- Enchanting
      [333] = {
	74110, -- Enchanting
      },
      -- Engineering
      [202] = {
	74111, -- Engineering
      },
      -- Inscription
      [773] = {
	74105, -- Inscription
      },
      -- Jewelcrafting
      [755] = {
	74112, -- Jewelcrafting
      },
      -- Leatherworking
      [165] = {
	74113, -- Leatherworking
      },
      -- Tailoring
      [197] = {
	74115, -- Tailoring
      },
      -- Herbalism
      [182] = {
	74107, -- Herbalism
      },
      -- Mining
      [186] = {
	74106, -- Mining
      },
      -- Skinning
      [393] = {
	74114, -- Skinning
      },
    },
  },
  -- Barter Bricks
  ['barter-bricks'] = {
    type = 'list',
    expansion = 9,
    index = 6,
    name = L["Barter Bricks"],
    reset = 'weekly',
    persists = false,
    fullObjective = false,
    onlyOnOrCompleted = true,
    threshold = 2,
    unlockQuest = 75721, -- Bartering 101
    questID = {
      75286, -- Blacksmith's Back
      75288, -- Enchanted Tales with Topuiz
      75289, -- Ink Master
      75301, -- Mistie's Mix Magic
      75304, -- I Need... a Tailor
      75307, -- Road to Season City
      75308, -- Scrybbil Engineering
      75309, -- If a Gem Isn't Pretty
      75351, -- Keep a Leather Eye Open
    },
  },
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
    local leaderboardCount = C_QuestLog.GetNumQuestObjectives(questID)
    for i = 1, leaderboardCount do
      local text, objectiveType, _, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, i, false)
      ---@cast text string
      ---@cast objectiveType "item"|"object"|"monster"|"reputation"|"log"|"event"|"player"|"progressbar"
      ---@cast _ boolean
      ---@cast numFulfilled number
      ---@cast numRequired number

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
    store.isFinish = C_QuestLog.IsComplete(questID)
    store.leaderboardCount = leaderboardCount
    store.text = showText

    return true
  end
end

---reset the progress of quest to the store
---@param store QuestStore
---@param persists boolean
local function ResetQuestStore(store, persists)
  if store.show or store.isComplete or not persists then
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
  local total = store.threshold or entry.threshold or #entry.questID

  for _, questID in ipairs(entry.questID) do
    if store[questID].isComplete then
      completed = completed + 1
    end
  end

  if completed == total then
    return SI.questCheckMark
  else
    return completed .. "/" .. total
  end
end

---show the progress of quest specific list
---@param store QuestListStore
---@param entry QuestListEntry
---@return string?
local function ShowQuestSpecificStore(store, entry, profs)
  if not store.show then
    return
  end

  if entry.questAbbr then
    for prof, profInfo in pairs(profs or {}) do
      for _, questID in ipairs(entry.questIDList[prof] or {}) do
	if store[questID] and store[questID].isComplete and entry.questAbbr[questID] then
	  return entry.questAbbr[questID]
	end
      end
    end
  end

  local completed = 0
  local kpExclude = 0
  local total = store.threshold or entry.threshold or #entry.questIDList

  for prof, profInfo in pairs(profs or {}) do
    if entry.questIDList[prof] and ((not profInfo.finishedKP) or entry.reset == 'darkmoon') then
      for _, questID in ipairs(entry.questIDList[prof]) do
	if store[questID] and store[questID].isComplete then
	  completed = completed + 1
	end
      end
    else
      total = total - 1
      if profInfo.finishedKP then
        kpExclude = kpExclude + 1
      end
    end
  end

  if completed == total then
    return SI.questCheckMark
  else
    return completed .. "/" .. total
  end
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
  local total = store.threshold or entry.threshold or #entry.questID

  for _, questID in ipairs(entry.questID) do
    if store[questID].isComplete then
      completed = completed + 1
    end
  end

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
	  store[questID].text
        )
      end

      tip:AddLine(questName or questID, questText or "")
    end
  end

  tip:Show()
end

---handle tooltip of quest specific list
local function TooltipQuestSpecificStore(_, arg)
  local store, entry, toon, profs = unpack(arg)
  ---@cast store QuestListStore
  ---@cast entry QuestListEntry
  ---@cast toon string

  local tip = Tooltip:AcquireIndicatorTip(2, 'LEFT', 'RIGHT')
  tip:AddHeader(SI:ClassColorToon(toon), entry.name)

  local completed = 0
  local total = store.threshold or entry.threshold or #entry.questIDList

  for prof, profInfo in pairs(profs or {}) do
    local needPlaceholder = entry.questIDList[prof] and ((not profInfo.finishedKP) or entry.reset == 'darkmoon')
    for i, questID in ipairs(entry.questIDList[prof] or {}) do
      if store[questID] then
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
	      store[questID].text or
	      (GREEN_FONT_COLOR_CODE .. AVAILABLE .. FONT_COLOR_CODE_CLOSE)
	    )
	  end

	  tip:AddLine(questName or profInfo.name, questText or "")
	  needPlaceholder = false
	end
      end
    end

    if needPlaceholder then
      tip:AddLine(profInfo.name, (GREEN_FONT_COLOR_CODE .. AVAILABLE .. FONT_COLOR_CODE_CLOSE))
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
  if not SI.db.Professions then
    SI.db.Professions = {
      Enable = {},
      Order = {},
    }
  end

  for key in pairs(presets) do
    if type(SI.db.Professions.Enable[key]) ~= 'boolean' then
      SI.db.Professions.Enable[key] = true
    end

    if type(SI.db.Professions.Order[key]) ~= 'number' then
      SI.db.Professions.Order[key] = 50
    end
  end

  -- [oldKey] = newKey
  local map = {
    [1] = 'show-your-mettle', -- Show Your Mettle
    [2] = 'prof-weekly-quests', -- Weekly Profession Knowledge Quests (Consortium & Trainer)
    [3] = 'prof-orders', -- Profession Orders Quests
    [4] = 'prof-treatises', -- Profession Treatises
    [5] = 'barter-bricks', -- Barter Bricks Quests (Kayann)
  }

  for i = 1, 5 do
    -- enable status migration
    if SI.db.Tooltip['Professions' .. i] ~= nil and map[i] then
      SI.db.Professions.Enable[map[i]] = SI.db.Tooltip['Professions' .. i]
    end
    SI.db.Tooltip['Professions' .. i] = nil
  end

  for _, db in pairs(SI.db.Toons) do
    if db.Professions then
      -- old database migration
      for oldKey, newKey in pairs(map) do
        if db.Professions[oldKey] then
          db.Professions[newKey] = db.Professions[oldKey]
          db.Professions[oldKey] = nil
        end
      end

      -- database cleanup
      for key in pairs(db.Professions) do
        if not presets[key] and not (key == "charProfessions") then
          db.Professions[key] = nil
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
  local leftOrder = SI.db.Professions.Order[left] or 50
  local rightOrder = SI.db.Professions.Order[right] or 50
  if leftOrder ~= rightOrder then
    return leftOrder < rightOrder
  end

  local leftPreset = not not presets[left]
  local rightPreset = not not presets[right]

  if leftPreset ~= rightPreset then
    return leftPreset
  end

  local leftEntry = presets[left]
  local rightEntry = presets[right]

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
    if SI.db.Professions.Enable[key] then
      tinsert(self.display, key)
    end
    tinsert(self.displayAll, key)
  end

  sort(self.display, sortDisplay)
  sort(self.displayAll, sortDisplay)
end

---update progress entry
---@param key string
---@param entry ProfessionsEntry
function Module:UpdateEntry(key, entry)
  local db = SI.db.Toons[SI.thisToon].Professions
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
  elseif entry.type == 'specific' then
    local darkmoonEnd = SI:GetNextDarkmoonResetTime() -- returns the (approximate) end of the current month's faire
    local darkmoonStart = darkmoonEnd - 8 * 24 * 3600 -- the (approximate) start of the current month's faire
    local darkmoonNow = darkmoonStart < time() and time() < darkmoonEnd

    wipe(store)

    if not db.charProfessions then
      store.show = false
    elseif entry.unlockQuest then
      store.show = C_QuestLog.IsQuestFlaggedCompleted(entry.unlockQuest)
    elseif entry.reset == 'darkmoon' then
      store.show = darkmoonNow
    else
      store.show = true
    end

    if store.show then
      for prof, profInfo in pairs(db.charProfessions) do
	if entry.questIDList[prof] then
	  for _, questID in ipairs(entry.questIDList[prof]) do
	    store[questID] = {}
	    local saved = UpdateQuestStore(store[questID], questID)
	    if saved and entry.reset == 'darkmoon' then
	      SI:Debug(questID.." reset-"..entry.reset..(saved and " (saved)" or " (not saved)").." darkmoonNow-"..(darkmoonNow and "true" or "false"))
	      if entry.reset == 'darkmoon' and darkmoonNow and saved then
		store[questID].resetTime = darkmoonEnd
	      end
	    end
	  end
	end
      end
    end
  elseif entry.type == 'custom' then
    ---@cast entry CustomEntry
    entry.func(store, entry)
  end
end

local function checkKP(nodeID, configID)
  local nodeState = C_ProfSpecs.GetStateForPath(nodeID, configID)
  
  if nodeState ~= 2 then  -- state 2 is completed; anything else is not finished
    return false
  end

  local childIDs = C_ProfSpecs.GetChildrenForPath(nodeID)
  for _, childNode in ipairs(childIDs) do
    if not checkKP(childNode, configID) then
      return false
    end
  end

  return true
end

function Module:UpdateAll()
  local db = SI.db.Toons[SI.thisToon].Professions
  if not db then
    db = {}
  end

  db['charProfessions'] = {}
  local p1, p2 = GetProfessions()

  for _, profID in ipairs({ p1, p2 }) do
    if profID then
      local pname, _, _, _, _, _, baseSkillLine = GetProfessionInfo(profID)

      -- check KP
      local finishedKP = true
      if UnitLevel("player") < 60 then  -- haven't hit DF - no KP
        finishedKP = false
      else
	local tabs = C_ProfSpecs.GetSpecTabIDsForSkillLine(professionList[baseSkillLine].skillLineID)
	local configID = C_ProfSpecs.GetConfigIDForSkillLine(professionList[baseSkillLine].skillLineID)

	for _, tab in ipairs(tabs) do
	  local node = C_ProfSpecs.GetRootPathForTab(tab)
	  if not checkKP(node, configID) then
	    finishedKP = false
	    break
	  end
	end
      end

      db['charProfessions'][baseSkillLine] = { name = pname, baseSkillLine = baseSkillLine, finishedKP = finishedKP }
    end
  end

  for key, entry in pairs(presets) do
    self:UpdateEntry(key, entry)
  end
end

---reset progress entry
---@param key string
---@param entry ProfessionsEntry
---@param toon string
function Module:ResetEntry(key, entry, toon)
  local store = SI.db.Toons[toon].Professions and SI.db.Toons[toon].Professions[key]
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
  elseif entry.type == 'specific' then
    if entry.reset == 'darkmoon' then
	local darkmoonEnd = SI:GetNextDarkmoonResetTime() -- returns the (approximate) end of the current month's faire
	local darkmoonStart = darkmoonEnd - 8 * 24 * 3600 -- the (approximate) start of the current month's faire
	local darkmoonNow = darkmoonStart < time() and time() < darkmoonEnd
	store.show = darkmoonNow
    end
    for prof, profInfo in pairs(store.charProfessions or professionList or {}) do
      if entry.questIDList[prof] then
        for _, questID in ipairs(entry.questIDList[prof]) do
	  if store[questID] and not (store[questID].resetTime and store[questID].resetTime > time()) then
	    --SI:Debug(toon..": Profession Quest Resetting: "..(GetQuestLink(questID) or questID).." (expires: "..(store[questID].resetTime or "none")..")")
	    ResetQuestStore(store[questID], entry.persists)
	  end
	end
      end
    end
  elseif entry.type == 'custom' then
    if entry.resetFunc then
      entry.resetFunc(store, entry)
    end
  end
end

function Module:OnDailyReset(toon)
  for key, entry in pairs(presets) do
    if entry.reset == 'daily' or entry.reset == 'darkmoon' then
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
      name = L['Quest progresses'],
      args = {
        Enable = {
          order = 1,
          type = 'group',
          name = ENABLE,
          get = function(info) return SI.db.Professions.Enable[info[#info]] end,
          set = function(info, value) SI.db.Professions.Enable[info[#info]] = value; Module:BuildDisplayOrder() end,
          args = {
            Presets = {
              order = 1,
              type = 'group',
              name = L['Presets'],
              guiInline = true,
              args = {
                General = {
                  order = 0,
                  type = 'header',
                  name = GENERAL,
                },
              },
            },
          },
        },
        Sorting = {
          order = 2,
          type = 'group',
          name = L["Sorting"],
          get = function(info) return tostring(SI.db.Professions.Order[info[#info]]) end,
          set = function(info, value) SI.db.Professions.Order[info[#info]] = tonumber(value) or 50; Module:BuildDisplayOrder() end,
          args = {},
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

    return options
  end
end

---reset progress entry
---@param entry ProfessionsEntry
---@param questID number
function Module:IsEntryContainsQuest(entry, questID)
  if entry.type == 'single' then
    ---@cast entry SingleQuestEntry
    return entry.questID == questID
  elseif entry.type == 'list' then
    ---@cast entry AnyQuestEntry|QuestListEntry
    return tContains(entry.questID, questID)
  elseif entry.type == 'specific' then
    for prof, questIDs in pairs(entry.questIDList) do
      if tContains(questIDs, questID) then return true end
    end
  elseif entry.type == 'custom' and entry.relatedQuest then
    ---@cast entry CustomEntry
    return tContains(entry.relatedQuest, questID)
  end
end

function Module:QuestEnabled(questID)
  for key, entry in pairs(presets) do
    if SI.db.Professions.Enable[key] and self:IsEntryContainsQuest(entry, questID) then
      return true
    end
  end
end

function Module:ShowTooltip(tooltip, columns, showall, preshow)
  local cpairs = SI.cpairs
  local first = true
  for _, key in ipairs(showall and self.displayAll or self.display) do
    local entry = presets[key]
    local show = false
    for _, t in cpairs(SI.db.Toons, true) do
      local store = t.Professions and t.Professions[key]
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
        local store = t.Professions and t.Professions[key]
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
	  elseif entry.type == 'specific' then
	    text = ShowQuestSpecificStore(store, entry, t.Professions.charProfessions)
	    hoverFunc = TooltipQuestSpecificStore
	    hoverArg = {store, entry, toon, t.Professions.charProfessions}
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
