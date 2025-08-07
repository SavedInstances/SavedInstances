local SI, L = unpack((select(2, ...)))
local Module = SI:NewModule("Currency", "AceEvent-3.0", "AceTimer-3.0", "AceBucket-3.0")

-- Lua functions
local ipairs, pairs = ipairs, pairs

-- WoW API / Variables
local C_Covenants_GetActiveCovenantID = C_Covenants.GetActiveCovenantID
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local C_QuestLog_IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local C_Item_GetItemCount = C_Item.GetItemCount
local GetMoney = GetMoney

local currency = {
  81, -- Epicurean Award
  515, -- Darkmoon Prize Ticket
  2588, -- Riders of Azeroth Badge

  -- Wrath of the Lich King
  241, -- Champion's Seal

  -- Cataclysm
  391, -- Tol Barad Commendation
  416, -- Mark of the World Tree

  -- Mists of Pandaria
  402, -- Ironpaw Token
  697, -- Elder Charm of Good Fortune
  738, -- Lesser Charm of Good Fortune
  752, -- Mogu Rune of Fate
  776, -- Warforged Seal
  777, -- Timeless Coin
  789, -- Bloody Coin

  -- Warlords of Draenor
  823, -- Apexis Crystal
  824, -- Garrison Resources
  994, -- Seal of Tempered Fate
  1101, -- Oil
  1129, -- Seal of Inevitable Fate
  1149, -- Sightless Eye
  1155, -- Ancient Mana
  1166, -- Timewarped Badge

  -- Legion
  1220, -- Order Resources
  1226, -- Nethershards
  1273, -- Seal of Broken Fate
  1275, -- Curious Coin
  1299, -- Brawler's Gold
  1314, -- Lingering Soul Fragment
  1342, -- Legionfall War Supplies
  1501, -- Writhing Essence
  1508, -- Veiled Argunite
  1533, -- Wakening Essence

  -- Battle for Azeroth
  1710, -- Seafarer's Dubloon
  1580, -- Seal of Wartorn Fate
  1560, -- War Resources
  1587, -- War Supplies
  1716, -- Honorbound Service Medal
  1717, -- 7th Legion Service Medal
  1718, -- Titan Residuum
  1721, -- Prismatic Manapearl
  1719, -- Corrupted Memento
  1755, -- Coalescing Visions
  1803, -- Echoes of Ny'alotha

  -- Shadowlands
  1754, -- Argent Commendation
  1191, -- Valor
  1602, -- Conquest
  1792, -- Honor
  1822, -- Renown
  1767, -- Stygia
  1828, -- Soul Ash
  1810, -- Redeemed Soul
  1813, -- Reservoir Anima
  1816, -- Sinstone Fragments
  1819, -- Medallion of Service
  1820, -- Infused Ruby
  1885, -- Grateful Offering
  1889, -- Adventure Campaign Progress
  1904, -- Tower Knowledge
  1906, -- Soul Cinders
  1931, -- Cataloged Research
  1977, -- Stygian Ember
  1979, -- Cyphers of the First Ones
  2009, -- Cosmic Flux
  2000, -- Motes of Fate

  -- Dragonflight
  2003, -- Dragon Isles Supplies
  2245, -- Flightstones
  2123, -- Bloody Tokens
  2797, -- Trophy of Strife
  2045, -- Dragon Glyph Embers
  2118, -- Elemental Overflow
  2122, -- Storm Sigil
  2409, -- Whelpling Crest Fragment Tracker [DNT]
  2410, -- Drake Crest Fragment Tracker [DNT]
  2411, -- Wyrm Crest Fragment Tracker [DNT]
  2412, -- Aspect Crest Fragment Tracker [DNT]
  2413, -- 10.1 Professions - Personal Tracker - S2 Spark Drops (Hidden)
  2533, -- Renascent Shadowflame
  2594, -- Paracausal Flakes
  2650, -- Emerald Dewdrop
  2651, -- Seedbloom
  2777, -- Dream Infusion
  2796, -- Renascent Dream
  2706, -- Whelpling's Dreaming Crest
  2707, -- Drake's Dreaming Crest
  2708, -- Wyrm's Dreaming Crest
  2709, -- Aspect's Dreaming Crest
  2774, -- 10.2 Professions - Personal Tracker - S3 Spark Drops (Hidden)
  2657, -- Mysterious Fragment
  2912, -- Renascent Awakening
  2806, -- Whelpling's Awakened Crest
  2807, -- Drake's Awakened Crest
  2809, -- Wyrm's Awakened Crest
  2812, -- Aspect's Awakened Crest
  2800, -- 10.2.6 Professions - Personal Tracker - S4 Spark Drops (Hidden)
  3010, -- 10.2.6 Rewards - Personal Tracker - S4 Dinar Drops (Hidden)
  2778, -- Bronze

  -- The War Within
  3089, -- Residual Memories
  2803, -- Undercoin
  2815, -- Resonance Crystals
  3028, -- Restored Coffer Key
  3056, -- Kej
  3008, -- Valorstones
  2813, -- Harmonized Silk
  2914, -- Weathered Harbinger Crest
  2915, -- Carved Harbinger Crest
  2916, -- Runed Harbinger Crest
  2917, -- Gilded Harbinger Crest
  3023, -- 11.0 Professions - Personal Tracker - S1 Spark Drops (Hidden)
  3100, -- Bronze Celebration Token
  3090, -- Flame-Blessed Iron
  3218, -- Empty Kaja'Cola Can
  3220, -- Vintage Kaja'Cola Can
  3226, -- Market Research
  3116, -- Essence of Kaja'mite
  3107, -- Weathered Undermine Crest
  3108, -- Carved Undermine Crest
  3109, -- Runed Undermine Crest
  3110, -- Gilded Undermine Crest
  3132, -- 11.1 Professions - Personal Tracker - S2 Spark Drops (Hidden)
  3149, -- Displaced Corrupted Mementos
  3278, -- Ethereal Strands
  3303, -- Untethered Coin
  3356, -- Untainted Mana-Crystals
  3269, -- Ethereal Voidsplinter
  3284, -- Weathered Ethereal Crest
  3286, -- Carved Ethereal Crest
  3288, -- Runed Ethereal Crest
  3290, -- Gilded Ethereal Crest
  3141, -- Starlight Spark Dust
}
SI.currency = currency

local currencySorted = {}
for _, idx in ipairs(currency) do
  table.insert(currencySorted, idx)
end
table.sort(currencySorted, function(c1, c2)
  local c1_name = C_CurrencyInfo_GetCurrencyInfo(c1).name
  local c2_name = C_CurrencyInfo_GetCurrencyInfo(c2).name
  return c1_name < c2_name
end)
SI.currencySorted = currencySorted

local hiddenCurrency = {}

local specialCurrency = {
  [1129] = { -- WoD - Seal of Tempered Fate
    weeklyMax = 3,
    earnByQuest = {
      36058, -- Seal of Dwarven Bunker
      -- Seal of Ashran quests
      36054,
      37454,
      37455,
      36056,
      37456,
      37457,
      36057,
      37458,
      37459,
      36055,
      37452,
      37453,
    },
  },
  [1273] = { -- LEG - Seal of Broken Fate
    weeklyMax = 3,
    earnByQuest = {
      43895,
      43896,
      43897,
      43892,
      43893,
      43894,
      43510, -- Order Hall
      47851, -- Mark of Honor x5
      47864, -- Mark of Honor x10
      47865, -- Mark of Honor x20
    },
  },
  [1580] = { -- BfA - Seal of Wartorn Fate
    weeklyMax = 2,
    earnByQuest = {
      52834, -- Gold
      52838, -- Piles of Gold
      52835, -- Marks of Honor
      52839, -- Additional Marks of Honor
      52837, -- War Resources
      52840, -- Stashed War Resources
    },
  },
  [1755] = { -- BfA - Coalescing Visions
    relatedItem = {
      id = 173363, -- Vessel of Horrific Visions
    },
  },
  [3028] = { -- Restored Coffer Key
    relatedItem = {
      id = 245653, -- Coffer Key Shard
    },
  },
}
SI.specialCurrency = specialCurrency

for _, tbl in pairs(specialCurrency) do
  if tbl.earnByQuest then
    for _, questID in ipairs(tbl.earnByQuest) do
      SI.QuestExceptions[questID] = "Regular" -- not show in Weekly Quest
    end
  end
end

Module.OverrideName = {
  [2409] = L["Loot Whelpling Crest Fragment"], -- Whelpling Crest Fragment Tracker [DNT]
  [2410] = L["Loot Drake Crest Fragment"], -- Drake Crest Fragment Tracker [DNT]
  [2411] = L["Loot Wyrm Crest Fragment"], -- Wyrm Crest Fragment Tracker [DNT]
  [2412] = L["Loot Aspect Crest Fragment"], -- Aspect Crest Fragment Tracker [DNT]
  [2413] = L["Loot Spark of Shadowflame"], -- 10.1 Professions - Personal Tracker - S2 Spark Drops (Hidden)
  [2774] = L["Loot Spark of Dreams"], -- 10.2 Professions - Personal Tracker - S3 Spark Drops (Hidden)
  [2800] = L["Loot Spark of Awakening"], -- 10.2.6 Professions - Personal Tracker - S4 Spark Drops (Hidden)
  [3010] = L["Loot Antique Bronze Bullion"], -- 10.2.6 Rewards - Personal Tracker - S4 Dinar Drops (Hidden)
  [3023] = L["Loot Spark of Omens"], -- 11.0 Professions - Personal Tracker - S1 Spark Drops (Hidden)
  [3132] = L["Loot Spark of Fortunes"], -- 11.1 Professions - Personal Tracker - S2 Spark Drops (Hidden)
}

Module.OverrideTexture = {
  [2413] = 5088829, -- 10.1 Professions - Personal Tracker - S2 Spark Drops (Hidden)
  [2774] = 5341573, -- 10.2 Professions - Personal Tracker - S3 Spark Drops (Hidden)
  [2800] = 4693222, -- 10.2.6 Professions - Personal Tracker - S4 Spark Drops (Hidden)
  [3010] = 4555657, -- 10.2.6 Rewards - Personal Tracker - S4 Dinar Drops (Hidden)
  [3023] = 5929759, -- 11.0 Professions - Personal Tracker - S1 Spark Drops (Hidden)
  [3132] = 5929757, -- 11.1 Professions - Personal Tracker - S2 Spark Drops (Hidden)
}

function Module:OnEnable()
  self:RegisterEvent("PLAYER_MONEY", "UpdateCurrency")
  self:RegisterBucketEvent("CURRENCY_DISPLAY_UPDATE", 0.25, "UpdateCurrency")
  self:RegisterEvent("BAG_UPDATE_DELAYED", "UpdateCurrencyItem")
end

function Module:UpdateCurrency()
  if SI.logout then
    return
  end -- currency is unreliable during logout

  local t = SI.db.Toons[SI.thisToon]
  t.Money = GetMoney()
  t.currency = t.currency or {}

  local covenantID = C_Covenants_GetActiveCovenantID()
  for _, idx in ipairs(currency) do
    local data = C_CurrencyInfo_GetCurrencyInfo(idx)
    if not data.discovered and not hiddenCurrency[idx] then
      t.currency[idx] = nil
    else
      local ci = t.currency[idx] or {}
      ci.amount = data.quantity
      ci.totalMax = data.maxQuantity
      ci.earnedThisWeek = data.quantityEarnedThisWeek
      ci.weeklyMax = data.maxWeeklyQuantity
      if data.useTotalEarnedForMaxQty then
        ci.totalEarned = data.totalEarned
      end
      -- handle special currency
      if specialCurrency[idx] then
        local tbl = specialCurrency[idx]
        if tbl.weeklyMax then
          ci.weeklyMax = tbl.weeklyMax
        end
        if tbl.earnByQuest then
          ci.earnedThisWeek = 0
          for _, questID in ipairs(tbl.earnByQuest) do
            if C_QuestLog_IsQuestFlaggedCompleted(questID) then
              ci.earnedThisWeek = ci.earnedThisWeek + 1
            end
          end
        end
        if tbl.relatedItem then
          ci.relatedItemCount = C_Item_GetItemCount(tbl.relatedItem.id)
        end
      elseif idx == 1822 then -- Renown
        -- plus one to amount and totalMax
        ci.amount = ci.amount + 1
        ci.totalMax = ci.totalMax + 1
        if covenantID > 0 then
          ci.covenant = ci.covenant or {}
          ci.covenant[covenantID] = ci.amount
        end
      elseif idx == 1810 or idx == 1813 then -- Redeemed Soul and Reservoir Anima
        if covenantID > 0 then
          ci.covenant = ci.covenant or {}
          ci.covenant[covenantID] = ci.amount
        end
      end
      -- don't store useless info
      if ci.weeklyMax == 0 then
        ci.weeklyMax = nil
      end
      if ci.totalMax == 0 then
        ci.totalMax = nil
      end
      if ci.earnedThisWeek == 0 then
        ci.earnedThisWeek = nil
      end
      if ci.totalEarned == 0 then
        ci.totalEarned = nil
      end
      t.currency[idx] = ci
    end
  end
end

function Module:UpdateCurrencyItem()
  if not SI.db.Toons[SI.thisToon].currency then
    return
  end

  for currencyID, tbl in pairs(specialCurrency) do
    if tbl.relatedItem and SI.db.Toons[SI.thisToon].currency[currencyID] then
      SI.db.Toons[SI.thisToon].currency[currencyID].relatedItemCount = C_Item_GetItemCount(tbl.relatedItem.id)
    end
  end
end
