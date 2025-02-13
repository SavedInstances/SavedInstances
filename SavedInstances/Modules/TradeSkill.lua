local SI, L = unpack((select(2, ...)))
local Module = SI:NewModule("TradeSkill", "AceEvent-3.0", "AceTimer-3.0", "AceBucket-3.0")

-- Lua functions
local _G = _G
local abs, date, floor, format, ipairs = abs, date, floor, format, ipairs
local pairs, time, tonumber, type = pairs, time, tonumber, type

-- WoW API / Variables
local C_Item_GetItemCooldown = C_Item.GetItemCooldown
local C_Item_GetItemInfo = C_Item.GetItemInfo
local C_Spell_GetSpellLink = C_Spell.GetSpellLink
local C_Spell_GetSpellName = C_Spell.GetSpellName
local C_TradeSkillUI_GetAllRecipeIDs = C_TradeSkillUI.GetAllRecipeIDs
local C_TradeSkillUI_GetFilteredRecipeIDs = C_TradeSkillUI.GetFilteredRecipeIDs
local C_TradeSkillUI_GetRecipeCooldown = C_TradeSkillUI.GetRecipeCooldown
local C_TradeSkillUI_IsTradeSkillGuild = C_TradeSkillUI.IsTradeSkillGuild
local C_TradeSkillUI_IsTradeSkillLinked = C_TradeSkillUI.IsTradeSkillLinked

local tradeSpells = {
  -- Alchemy
  -- Classic Alchemy
  [11479] = "310", -- Transmute: Iron to Gold
  [11480] = "310", -- Transmute: Mithril to Truesilver
  [17559] = "310", -- Transmute: Air to Fire
  [17560] = "310", -- Transmute: Fire to Earth
  [17561] = "310", -- Transmute: Earth to Water
  [17562] = "310", -- Transmute: Water to Air
  [17563] = "310", -- Transmute: Undeath to Water
  [17564] = "310", -- Transmute: Water to Undeath
  [17565] = "310", -- Transmute: Life to Earth
  [17566] = "310", -- Transmute: Earth to Life
  -- Outland Alchemy
  [28566] = "2355", -- Transmute: Primal Air to Fire
  [28567] = "2355", -- Transmute: Primal Earth to Water
  [28568] = "2355", -- Transmute: Primal Fire to Earth
  [28569] = "2355", -- Transmute: Primal Water to Air
  [28580] = "2355", -- Transmute: Primal Shadow to Water
  [28581] = "2355", -- Transmute: Primal Water to Shadow
  [28582] = "2355", -- Transmute: Primal Mana to Fire
  [28583] = "2355", -- Transmute: Primal Fire to Mana
  [28584] = "2355", -- Transmute: Primal Life to Earth
  [28585] = "2355", -- Transmute: Primal Earth to Life
  -- Northrend Alchemy
  [53771] = "2356", -- Transmute: Eternal Life to Shadow
  [53773] = "2356", -- Transmute: Eternal Life to Fire
  [53774] = "2356", -- Transmute: Eternal Fire to Water
  [53775] = "2356", -- Transmute: Eternal Fire to Life
  [53776] = "2356", -- Transmute: Eternal Air to Water
  [53777] = "2356", -- Transmute: Eternal Air to Earth
  [53779] = "2356", -- Transmute: Eternal Shadow to Earth
  [53780] = "2356", -- Transmute: Eternal Shadow to Life
  [53781] = "2356", -- Transmute: Eternal Earth to Air
  [53782] = "2356", -- Transmute: Eternal Earth to Shadow
  [53783] = "2356", -- Transmute: Eternal Water to Air
  [53784] = "2356", -- Transmute: Eternal Water to Fire
  [54020] = "2356", -- Transmute: Eternal Might
  [60893] = true, -- Northrend Alchemy Research
  [66658] = "2356", -- Transmute: Ametrine
  [66659] = "2356", -- Transmute: Cardinal Ruby
  [66660] = "2356", -- Transmute: King's Amber
  [66662] = "2356", -- Transmute: Dreadstone
  [66663] = "2356", -- Transmute: Majestic Zircon
  [66664] = "2356", -- Transmute: Eye of Zul
  -- Cataclysm Alchemy
  [78866] = "2357", -- Transmute: Living Elements
  [80244] = "2357", -- Transmute: Pyrium Bar
  -- Pandaria Alchemy
  [114780] = true, -- Transmute: Living Steel
  -- Draenor Alchemy
  [156587] = "1477", -- Alchemical Catalyst
  [156588] = "1477", -- Alchemical Catalyst - Fireweed
  [156589] = "1477", -- Alchemical Catalyst - Flytrap
  [156590] = "1477", -- Alchemical Catalyst - Starflower
  [156592] = "1477", -- Alchemical Catalyst - Orchid
  [156593] = "1477", -- Alchemical Catalyst - Lotus
  [168042] = true, -- Alchemical Catalyst
  [175880] = true, -- Secrets of Draenor Alchemy
  [181643] = true, -- Transmute: Savage Blood
  -- Legion Alchemy
  [188800] = "1479", -- Wild Transmutation
  [188801] = "1479", -- Wild Transmutation
  [188802] = "1479", -- Wild Transmutation
  [213248] = "1199", -- Transmute: Ore to Cloth
  [213249] = "1199", -- Transmute: Cloth to Skins
  [213250] = "1199", -- Transmute: Skins to Ore
  [213251] = "1199", -- Transmute: Ore to Herbs
  [213252] = "1199", -- Transmute: Cloth to Herbs
  [213253] = "1199", -- Transmute: Skins to Herbs
  [213254] = "1199", -- Transmute: Fish to Gems
  [213255] = "1199", -- Transmute: Meat to Pants
  [213256] = "1199", -- Transmute: Meat to Pet
  [213257] = "1199", -- Transmute: Blood of Sargeras
  [247701] = "1199", -- Transmute: Primal Sargerite
  -- Kul Tiran Alchemy
  [251305] = "1199", -- Transmute: Herbs to Ore
  [251306] = "1199", -- Transmute: Herbs to Cloth
  [251309] = "1199", -- Transmute: Ore to Herbs
  [251310] = "1199", -- Transmute: Ore to Cloth
  [251311] = "1199", -- Transmute: Ore to Gems
  [251314] = "1199", -- Transmute: Cloth to Skins
  [251808] = "1199", -- Transmute: Meat to Pet
  [251822] = "1199", -- Transmute: Fish to Gems
  [251832] = "1199", -- Transmute: Expulsom
  [286547] = "1199", -- Transmute: Herbs to Anchors
  -- Shadowlands Alchemy
  [307142] = "1902", -- Shadowghast Ingot
  [307143] = "1199", -- Shadestone
  [307144] = "1902", -- Stones to Ore
  -- Dragon Isles Alchemy
  [370707] = "2038", -- Transmute: Awakened Fire
  [370708] = "2038", -- Transmute: Awakened Frost
  [370710] = "2038", -- Transmute: Awakened Earth
  [370711] = "2038", -- Transmute: Awakened Air
  [370714] = "2038", -- Transmute: Decay to Elements
  [370715] = "2038", -- Transmute: Order to Elements
  [370743] = "2034", -- Basic Potion Experimentation
  [370745] = "2034", -- Advanced Potion Experimentation
  [370746] = "2034", -- Basic Phial Experimentation
  [370747] = "2034", -- Advanced Phial Experimentation
  [405847] = "2038", -- Transmute: Dracothyst
  -- Khaz Algar Alchemy
  [430345] = true, -- Meticulous Experimentation
  [430618] = "2216", -- Mercurial Blessings
  [430619] = "2216", -- Mercurial Storms
  [430620] = "2216", -- Volatile Weaving
  [430621] = "2216", -- Volatile Stone
  [430622] = "2216", -- Ominous Call
  [430623] = "2216", -- Ominous Gloom
  [449571] = "2216", -- Mercurial Herbs
  [449572] = "2216", -- Ominous Herbs
  [449573] = "2216", -- Mercurial Coalescence
  [449574] = "2216", -- Ominous Coalescence
  [449575] = "2216", -- Volatile Coalescence
  [449938] = "2216", -- Gleaming Chaos

  -- Blacksmithing
  -- Pandaria Blacksmithing
  [138646] = true, -- Lightning Steel Ingot
  [143255] = true, -- Balanced Trillium Ingot
  -- Draenor Blacksmithing
  [171690] = true, -- Truesteel Ingot
  [176090] = true, -- Secrets of Draenor Blacksmithing
  -- Khaz Algar Blacksmithing
  [453727] = true, -- Everburning Ignition

  -- Engineering
  -- Pandaria Engineering
  [139176] = true, -- Jard's Peculiar Energy Source
  -- Draenor Engineering
  [169080] = true, -- Gearspring Parts
  [177054] = true, -- Secrets of Draenor Engineering
  [178242] = true, -- Gearspring Parts
  -- Dragon Isles Engineering
  [382354] = true, -- Suspiciously Ticking Crate
  [382358] = true, -- Suspiciously Silent Crate
  -- Khaz Algar Engineering
  [447312] = true, -- Invent
  [447374] = true, -- Box o' Booms

  -- Jewelcrafting
  -- Outland Jewelcrafting
  [32866] = "1154", -- Powerful Earthstorm Diamond
  [32867] = "1154", -- Bracing Earthstorm Diamond
  [32868] = "1154", -- Tenacious Earthstorm Diamond
  [32869] = "1154", -- Brutal Earthstorm Diamond
  [32870] = "1154", -- Insightful Earthstorm Diamond
  [32871] = "1154", -- Destructive Skyfire Diamond
  [32872] = "1154", -- Mystical Skyfire Diamond
  [32873] = "1154", -- Swift Skyfire Diamond
  [32874] = "1154", -- Enigmatic Skyfire Diamond
  [39961] = "1154", -- Relentless Earthstorm Diamond
  [39963] = "1154", -- Thundering Skyfire Diamond
  [44794] = "1154", -- Chaotic Skyfire Diamond
  [46597] = "1154", -- Eternal Earthstorm Diamond
  [46601] = "1154", -- Ember Skyfire Diamond
  [47280] = true, -- Brilliant Glass
  -- Cataclysm Jewelcrafting
  [73478] = true, -- Fire Prism
  -- Pandaria Jewelcrafting
  [131593] = "1409", -- River's Heart
  [131686] = "1409", -- Primordial Ruby
  [131688] = "1409", -- Wild Jade
  [131690] = "1409", -- Vermilion Onyx
  [131691] = "1409", -- Imperial Amethyst
  [131695] = "1409", -- Sun's Radiance
  [140050] = true, -- Serpent's Heart
  -- Draenor Jewelcrafting
  [170700] = true, -- Taladite Crystal
  [176087] = true, -- Secrets of Draenor Jewelcrafting
  -- Dragon Isles Jewelcrafting
  [374546] = true, -- Queen's Gift
  [374547] = true, -- Dreamer's Vision
  [374548] = true, -- Keeper's Glory
  [374549] = true, -- Earthwarden's Prize
  [374550] = true, -- Timewatcher's Patience
  [374551] = true, -- Jeweled Dragon's Heart
  -- Khaz Algar Jewelcrafting
  [435337] = true, -- Algari Amber Prism
  [435338] = true, -- Algari Emerald Prism
  [435339] = true, -- Algari Ruby Prism
  [435369] = true, -- Algari Onyx Prism
  [435370] = true, -- Algari Sapphire Prism

  -- Leatherworking
  -- Pandaria Leatherworking
  [140040] = "1434", -- Magnificence of Leather
  [140041] = "1434", -- Magnificence of Scales
  [142976] = true, -- Hardened Magnificent Hide
  -- Draenor Leatherworking
  [171391] = true, -- Burnished Leather
  [171713] = true, -- Burnished Leather
  [176089] = true, -- Secrets of Draenor Leatherworking

  -- Tailoring
  -- Northrend Tailoring
  [56005] = true, -- Glacial Bag
  -- Cataclysm Tailoring
  [75141] = true, -- Dream of Skywall
  [75142] = true, -- Dream of Deepholm
  [75144] = true, -- Dream of Hyjal
  [75145] = true, -- Dream of Ragnaros
  [75146] = true, -- Dream of Azshara
  -- Pandaria Tailoring
  [125557] = true, -- Imperial Silk
  [143011] = true, -- Celestial Cloth
  -- Draenor Tailoring
  [168835] = true, -- Hexweave Cloth
  [169669] = true, -- Hexweave Cloth
  [176058] = true, -- Secrets of Draenor Tailoring
  -- Dragon Isles Tailoring
  [376556] = true, -- Azureweave Bolt
  [376557] = true, -- Chronocloth Bolt
  -- Khaz Algar Tailoring
  [446927] = true, -- Duskweave Bolt
  [446928] = true, -- Dawnweave Bolt

  -- Enchanting
  -- Outland Enchanting
  [28027] = "1174", -- Prismatic Sphere
  [28028] = "1174", -- Void Sphere
  -- Pandaria Enchanting
  [116499] = true, -- Sha Crystal
  -- Draenor Enchanting
  [169092] = true, -- Temporal Crystal
  [177043] = true, -- Secrets of Draenor Enchanting
  [178241] = true, -- Temporal Crystal

  -- Inscription
  -- Cataclysm Inscription
  [86654] = "1267", -- Forged Documents
  [89244] = "1267", -- Forged Documents
  -- Pandaria Inscription
  [112996] = true, -- Scroll of Wisdom
  -- Draenor Inscription
  [169081] = true, -- War Paints
  [176513] = true, -- Draenor Merchant Order
  [177045] = true, -- Secrets of Draenor Inscription
  [178240] = true, -- War Paints

  -- Cooking
  -- Dragon Isles Cooking
  [378302] = true, -- Ooey-Gooey Chocolate

  -- Item
  [54710] = "item", -- MOLL-E
  [67826] = "item", -- Jeeves
  [126459] = "item", -- Blingtron 4000
  [161414] = "item", -- Blingtron 5000
  [200061] = "item", -- Rechargeable Reaves Battery
  [261602] = "item", -- Katy's Stampwhistle
  [298926] = "item", -- Blingtron 7000
  -- Wormhole
  [67833] = "item", -- Wormhole Generator: Northrend
  [126755] = "item", -- Wormhole Generator: Pandaria
  [163830] = "item", -- Wormhole Centrifuge (Draenor)
  [250796] = "item", -- Wormhole Generator: Argus
  [299083] = "item", -- Wormhole Generator: Kul Tiras
  [299084] = "item", -- Wormhole Generator: Zandalar
  [324031] = "item", -- Wormhole Generator: Shadowlands
  [386379] = "item", -- Wyrmhole Generator
  [448126] = "item", -- Wormhole Generator: Khaz Algar
  -- Transporter
  [23453] = "item", -- Ultrasafe Transporter: Gadgetzhan
  [36941] = "item", -- Ultrasafe Transporter: Toshley's Station
  -- Skinning
  [382134] = "item", -- Elusive Creature Bait
  [442680] = "item", -- Elusive Creature Lure
}

local itemCDs = { -- [spellID] = itemID
  [54710] = 40768, -- MOLL-E
  [67826] = 49040, -- Jeeves
  [126459] = 87214, -- Blingtron 4000
  [161414] = 111821, -- Blingtron 5000
  [200061] = 144341, -- Rechargeable Reaves Battery
  [261602] = 156833, -- Katy's Stampwhistle
  [298926] = 168667, -- Blingtron 7000
  -- Wormhole
  [67833] = 48933, -- Wormhole Generator: Northrend
  [126755] = 87215, -- Wormhole Generator: Pandaria
  [163830] = 112059, -- Wormhole Centrifuge (Draenor)
  [250796] = 151652, -- Wormhole Generator: Argus
  [299083] = 168807, -- Wormhole Generator: Kul Tiras
  [299084] = 168808, -- Wormhole Generator: Zandalar
  [324031] = 172924, -- Wormhole Generator: Shadowlands
  [386379] = 198156, -- Wyrmhole Generator
  [448126] = 221966, -- Wormhole Generator: Shadowlands
  -- Transporter
  [23453] = 18986, -- Ultrasafe Transporter: Gadgetzhan
  [36941] = 30544, -- Ultrasafe Transporter: Toshley's Station
  -- Skinning
  [382134] = 193906, -- Elusive Creature Bait
  [442680] = 219007, -- Elusive Creature Lure
}

local categoryNames = {
  ["310"] = C_Spell_GetSpellName(2259) .. ": " .. L["Transmute"],
  ["1154"] = C_Spell_GetSpellName(25229) .. ": " .. L["Outland Cut Jewel"],
  ["1174"] = C_Spell_GetSpellName(7411) .. ": " .. C_Spell_GetSpellName(28027),
  ["1199"] = C_Spell_GetSpellName(2259) .. ": " .. L["Legion Transmute"],
  ["1267"] = C_Spell_GetSpellName(45357) .. ": " .. C_Spell_GetSpellName(86654),
  ["1409"] = C_Spell_GetSpellName(25229) .. ": " .. L["Facets of Research"],
  ["1434"] = C_Spell_GetSpellName(2108) .. ": " .. C_Spell_GetSpellName(140040),
  ["1477"] = C_Spell_GetSpellName(2259) .. ": " .. C_Spell_GetSpellName(156587),
  ["1479"] = C_Spell_GetSpellName(2259) .. ": " .. L["Wild Transmute"],
  ["1902"] = C_Spell_GetSpellName(2259) .. ": " .. C_Spell_GetSpellName(307142),
  ["2034"] = C_Spell_GetSpellName(2259) .. ": " .. L["Dragonflight Experimentation"],
  ["2038"] = C_Spell_GetSpellName(2259) .. ": " .. L["Dragonflight Transmute"],
  ["2216"] = C_Spell_GetSpellName(2259) .. ": " .. L["Khaz Algar Transmute"],
  ["2355"] = C_Spell_GetSpellName(2259) .. ": " .. L["Outland Transmute"],
  ["2356"] = C_Spell_GetSpellName(2259) .. ": " .. L["Northrend Transmute"],
  ["2357"] = C_Spell_GetSpellName(2259) .. ": " .. L["Cataclysm Transmute"],
}

function Module:OnEnable()
  self:RegisterBucketEvent("TRADE_SKILL_LIST_UPDATE", 1)
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function Module:ScanItemCDs()
  for spellID, itemID in pairs(itemCDs) do
    local start, duration = C_Item_GetItemCooldown(itemID)
    if start and duration and start > 0 then
      self:RecordSkill(spellID, SI:GetTimeToTime(start + duration))
    end
  end
end

function Module:RecordSkill(spellID, expires)
  if not spellID then
    return
  end
  local info = tradeSpells[spellID]
  if not info then
    self.missingWarned = self.missingWarned or {}
    if expires and expires > 0 and not self.missingWarned[spellID] then
      self.missingWarned[spellID] = true
      SI:BugReport("Unrecognized trade skill cd " .. (C_Spell_GetSpellName(spellID) or "??") .. " (" .. spellID .. ")")
    end
    return
  end

  local t = SI.db.Toons[SI.thisToon]
  t.Skills = t.Skills or {}

  local index = spellID
  local spellName = C_Spell_GetSpellName(spellID)
  local title = spellName
  local link = nil
  if info == "item" then
    if not expires then
      self:ScheduleTimer("ScanItemCDs", 2) -- theres a delay for the item to go on cd
      return
    elseif expires - time() < 6 then
      -- might be global cooldowns, #509
      return
    end
    if itemCDs[spellID] then
      -- use item name as some item spellnames are ambiguous or wrong
      title, link = C_Item_GetItemInfo(itemCDs[spellID])
      title = title or spellName
    end
  elseif type(info) == "string" then
    index = info
    title = categoryNames[info] or title
  elseif expires ~= 0 then
    local slink = C_Spell_GetSpellLink(spellID)
    if slink and #slink > 0 then -- tt scan for the full name with profession
      link = "\124cffffd000\124Henchant:" .. spellID .. "\124h[X]\124h\124r"
      SI.ScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
      SI.ScanTooltip:SetHyperlink(link)
      SI.ScanTooltip:Show()
      local line = _G[SI.ScanTooltip:GetName() .. "TextLeft1"]
      line = line and line:GetText()
      if line and #line > 0 then
        title = line
        link = link:gsub("X", line)
      else
        link = nil
      end
    end
  end

  if expires == 0 then
    if t.Skills[index] then -- a cd ended early
      SI:Debug("Clearing Trade skill cd: %s (%s)", spellName, spellID)
    end
    t.Skills[index] = nil
    return
  elseif not expires then
    expires = SI:GetNextDailySkillResetTime()
    if not expires then
      return
    end -- ticket 127
    if type(info) == "number" then -- over a day, make a rough guess
      expires = expires + (info - 1) * 24 * 60 * 60
    end
  end
  expires = floor(expires)

  local skillInfo = t.Skills[index] or {}
  t.Skills[index] = skillInfo
  local change = expires - (skillInfo.Expires or 0)
  if abs(change) > 180 then -- updating expiration guess (more than 3 min update lag)
    SI:Debug(
      "Trade skill cd: "
        .. (link or title)
        .. " ("
        .. spellID
        .. ") "
        .. (skillInfo.Expires and format("%d", change) .. " sec" or "(new)")
        .. " Local time: "
        .. date("%c", expires)
    )
  end
  skillInfo.Title = title
  skillInfo.Link = link
  skillInfo.Expires = expires

  return true
end

function Module:RescanTradeSkill(spellID)
  local count = self:ScanTradeSkill()

  if count == 0 or not self.cooldownFound or not self.cooldownFound[spellID] then
    -- scan failed, probably because the skill is hidden - try again
    local rescanCount = self:ScanTradeSkill(true)
    SI:Debug("Rescan: " .. (rescanCount == count and "Failed" or "Success"))
  end
end

function Module:ScanTradeSkill(isAll)
  if C_TradeSkillUI_IsTradeSkillLinked() or C_TradeSkillUI_IsTradeSkillGuild() then
    return
  end

  local count = 0
  local data = isAll and C_TradeSkillUI_GetAllRecipeIDs() or C_TradeSkillUI_GetFilteredRecipeIDs()
  for _, spellID in ipairs(data) do
    local cooldown, isDayCooldown = C_TradeSkillUI_GetRecipeCooldown(spellID)
    if
      cooldown
      and isDayCooldown -- GetRecipeCooldown often returns WRONG answers for daily cds
      and not tonumber(tradeSpells[spellID]) -- daily flag incorrectly set for some multi-day cds (Northrend Alchemy Research)
    then
      cooldown = SI:GetNextDailySkillResetTime()
    elseif cooldown then
      cooldown = time() + cooldown -- on cooldown
    else
      cooldown = 0 -- off cooldown or no cooldown
    end

    self:RecordSkill(spellID, cooldown)
    if cooldown then
      self.cooldownFound = self.cooldownFound or {}
      self.cooldownFound[spellID] = true
      count = count + 1
    end
  end

  return count
end

function Module:TRADE_SKILL_LIST_UPDATE()
  self:ScanTradeSkill()
end

function Module:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, spellID)
  if unit ~= "player" or not tradeSpells[spellID] then
    return
  end

  SI:Debug("UNIT_SPELLCAST_SUCCEEDED: %s (%s)", C_Spell_GetSpellLink(spellID), spellID)

  if not self:RecordSkill(spellID) then
    return
  end
  self:ScheduleTimer("RescanTradeSkill", 0.5, spellID)
end
