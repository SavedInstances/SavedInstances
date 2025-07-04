local SI, L = unpack((select(2, ...)))
local Module = SI:NewModule("Quest")

-- Lua functions
local _G = _G
local pairs, strtrim = pairs, strtrim

-- WoW API / Variables
local C_Item_GetItemInfo = C_Item.GetItemInfo
local C_Map_GetMapInfo = C_Map.GetMapInfo
local C_Spell_GetSpellName = C_Spell.GetSpellName
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo
local LOOT = LOOT

local _specialQuests = {
  -- Isle of Thunder
  [32610] = { zid = 504, lid = 94221 }, -- Shan'ze Ritual Stone looted
  [32611] = { zid = 504, lid1 = 95350 }, -- Incantation of X looted
  [32626] = { zid = 504, lid = 94222 }, -- Key to the Palace of Lei Shen looted
  [32609] = { zid = 504, aid = 8104, aline = "Left5" }, -- Trove of the Thunder King (outdoor chest)

  -- Timeless Isle
  [32962] = { zid = 554, aid = 8743, daily = true }, -- Zarhym
  [32961] = { zid = 554, daily = true }, -- Scary Ghosts and Nice Sprites
  [32956] = { zid = 554, aid = 8727, acid = 2, aline = "Right7" }, -- Blackguard's Jetsam
  [32957] = { zid = 554, aid = 8727, acid = 1, aline = "Left7" }, -- Sunken Treasure
  [32970] = { zid = 554, aid = 8727, acid = 3, aline = "Left8" }, -- Gleaming Treasure Satchel
  [32968] = { zid = 554, aid = 8726, acid = 2, aline = "Right7" }, -- Rope-Bound Treasure Chest
  [32969] = { zid = 554, aid = 8726, acid = 1, aline = "Left7" }, -- Gleaming Treasure Chest
  [32971] = { zid = 554, aid = 8726, acid = 3, aline = "Left8" }, -- Mist-Covered Treasure Chest

  -- Garrison
  [37638] = { zone = GARRISON_LOCATION_TOOLTIP, aid = 9162 }, -- Bronze Defender
  [37639] = { zone = GARRISON_LOCATION_TOOLTIP, aid = 9164 }, -- Silver Defender
  [37640] = { zone = GARRISON_LOCATION_TOOLTIP, aid = 9165 }, -- Golden Defender
  [38482] = { zone = GARRISON_LOCATION_TOOLTIP, aid = 9826 }, -- Platinum Defender

  -- Tanaan Jungle
  [39287] = { zid = 534, daily = true }, -- Deathtalon
  [39288] = { zid = 534, daily = true }, -- Terrorfist
  [39289] = { zid = 534, daily = true }, -- Doomroller
  [39290] = { zid = 534, daily = true }, -- Vengeance

  -- Order Hall
  [42481] = { zid = 717, daily = true }, -- Warlock: Ritual of Doom
  [43763] = { zid = 695, lid = 141069 }, -- Warrior: Skyhold Chest of Riches
  [44707] = { zid = 719, daily = true, sid = 228651 }, -- Demon Hunter: Twisting Nether

  -- Mechagon
  [57081] = { name = L["Mechanized Chest"] }, -- Mechanized Chest
  [56139] = { daily = true, zid = 1462 }, -- Junkyard Treasures
  [55901] = { daily = true, zid = 1462 }, -- Rustbolt Rebellion
  [56141] = { daily = true, zid = 1462 }, -- Security First

  -- Assault Coffers
  [57628] = { name = L["Cursed Coffer"] }, -- Cursed Coffer
  [57214] = { name = L["Mogu Strongbox"] }, -- Mogu Strongbox
  [58137] = { name = L["Infested Strongbox"] }, -- Infested Strongbox
  [55692] = { name = L["Amathet Reliquary"] }, -- Amathet Reliquary
  [58770] = { name = L["Ambered Coffer"] }, -- Ambered Coffer

  -- Beastwarrens Hunts
  [63433] = { name = L["Hunt: Shadehounds"] }, -- Hunt: Shadehounds (63180 -> 63433 which tracks mount droping)
  [63194] = { name = L["Hunt: Winged Soul Eaters"] }, -- Hunt: Winged Soul Eaters
  [63198] = { name = L["Hunt: Death Elementals"] }, -- Hunt: Death Elementals
  [63199] = { name = L["Hunt: Soul Eaters"] }, -- Hunt: Soul Eaters

  -- Covenant Assaults
  [63543] = { zid = 1543 }, -- Necrolord Assault
  [63822] = { zid = 1543 }, -- Venthyr Assault
  [63823] = { zid = 1543 }, -- Night Fae Assault
  [63824] = { zid = 1543 }, -- Kyrian Assault

  -- Dragonflight
  [66419] = { zid = 2022 }, -- Allegiance to One
  [66133] = { zid = 2022 }, -- Keys of Loyalty (Warthion)
  [66805] = { zid = 2022 }, -- Keys of Loyalty (Sabellian)
  [70866] = { name = L["Siege on Dragonbane Keep"], zid = 2022 }, -- Siege on Dragonbane Keep
  [70906] = { name = L["Grand Hunts: Mythic Reward"] }, -- Grand Hunts: Mythic Reward
  [71136] = { name = L["Grand Hunts: Rare Reward"] }, -- Grand Hunts: Rare Reward
  [71137] = { name = L["Grand Hunts: Uncommon Reward"] }, -- Grand Hunts: Uncommon Reward
  [71033] = { name = L["Trial of Flood"] }, -- Trial of Flood
  [71995] = { name = L["Trial of Elements"] }, -- Trial of Elements
  [73162] = { name = L["Storm's Fury"] }, -- Storm's Fury
  [77836] = { name = L["Time Rift"] }, -- Time Rift Weekly Gear Token
  -- Draconic Treatise
  [74105] = { lid = 194699 }, -- Draconic Treatise on Inscription
  [74106] = { lid = 194708 }, -- Draconic Treatise on Mining
  [74107] = { lid = 194704 }, -- Draconic Treatise on Herbalism
  [74108] = { lid = 194697 }, -- Draconic Treatise on Alchemy
  [74109] = { lid = 198454 }, -- Draconic Treatise on Blacksmithing
  [74110] = { lid = 194702 }, -- Draconic Treatise on Enchanting
  [74111] = { lid = 198510 }, -- Draconic Treatise on Engineering
  [74112] = { lid = 194703 }, -- Draconic Treatise on Jewelcrafting
  [74113] = { lid = 194700 }, -- Draconic Treatise on Leatherworking
  [74114] = { lid = 201023 }, -- Draconic Treatise on Skinning
  [74115] = { lid = 194698 }, -- Draconic Treatise on Tailoring
  -- Dropping Profession Knowledge Items
  [70381] = { lid = 198837 }, -- Curious Hide Scraps
  [70383] = { lid = 198837 }, -- Curious Hide Scraps
  [70384] = { lid = 198837 }, -- Curious Hide Scraps
  [70385] = { lid = 198837 }, -- Curious Hide Scraps
  [70386] = { lid = 198837 }, -- Curious Hide Scraps
  [70389] = { lid = 198837 }, -- Curious Hide Scraps
  [70504] = { lid = 198963 }, -- Decaying Phlegm
  [70511] = { lid = 198964 }, -- Elementious Splinter
  [70512] = { lid = 198965 }, -- Primeval Earth Fragment
  [70513] = { lid = 198966 }, -- Molten Globule
  [70514] = { lid = 198967 }, -- Primordial Aether
  [70515] = { lid = 198968 }, -- Primalist Charm
  [70516] = { lid = 198969 }, -- Keeper's Mark
  [70517] = { lid = 198970 }, -- Infinitely Attachable Pair o' Docks
  [70518] = { lid = 198971 }, -- Curious Djaradin Rune
  [70519] = { lid = 198972 }, -- Draconic Glamour
  [70520] = { lid = 198973 }, -- Incandescent Curio
  [70521] = { lid = 198974 }, -- Elegantly Engraved Embellishment
  [70522] = { lid = 198975 }, -- Ossified Hide
  [70523] = { lid = 198976 }, -- Exceedingly Soft Skin
  [70524] = { lid = 198977 }, -- Ohn'arhan Weave
  [70525] = { lid = 198978 }, -- Stupidly Effective Stitchery
  [71857] = { lid = 200678 }, -- Dreambloom
  [71858] = { lid = 200678 }, -- Dreambloom
  [71859] = { lid = 200678 }, -- Dreambloom
  [71860] = { lid = 200678 }, -- Dreambloom
  [71861] = { lid = 200678 }, -- Dreambloom
  [71864] = { lid = 200678 }, -- Dreambloom
  [72160] = { lid = 201301 }, -- Iridescent Ore
  [72161] = { lid = 201301 }, -- Iridescent Ore
  [72162] = { lid = 201301 }, -- Iridescent Ore
  [72163] = { lid = 201301 }, -- Iridescent Ore
  [72164] = { lid = 201301 }, -- Iridescent Ore
  [72165] = { lid = 201301 }, -- Iridescent Ore
  -- Disturbed Dirt / Expedition Scout's Pack
  [66373] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(2259) }, -- Alchemy
  [66374] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(2259) }, -- Alchemy
  [66375] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(45357) }, -- Inscription
  [66376] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(45357) }, -- Inscription
  [66377] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(7411) }, -- Enchanting
  [66378] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(7411) }, -- Enchanting
  [66379] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(4036) }, -- Engineering
  [66380] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(4036) }, -- Engineering
  [66381] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(2018) }, -- Blacksmithing
  [66382] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(2018) }, -- Blacksmithing
  [66384] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(2108) }, -- Leatherworking
  [66385] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(2108) }, -- Leatherworking
  [66386] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(3908) }, -- Tailoring
  [66387] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(3908) }, -- Tailoring
  [66388] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(25229) }, -- Jewelcrafting
  [66389] = { name = L["Disturbed Dirt / Expedition Scout's Pack"] .. " - " .. C_Spell_GetSpellName(25229) }, -- Jewelcrafting

  -- TWW
  [81090] = { name = L["Alchemy Thaumaturgy"], daily = true }, -- Alchemy Thaumaturgy

  -- TWW Algari Treatise
  [83727] = { lid = 222550 }, -- Algari Treatise on Enchanting
  [83728] = { lid = 222621 }, -- Algari Treatise on Engineering
  [83729] = { lid = 222552 }, -- Algari Treatise on Herbalism
  [83730] = { lid = 222548 }, -- Algari Treatise on Inscription
  [83731] = { lid = 222551 }, -- Algari Treatise on Jewelcrafting
  [83732] = { lid = 222549 }, -- Algari Treatise on Leatherworking
  [83733] = { lid = 222553 }, -- Algari Treatise on Mining
  [83734] = { lid = 222649 }, -- Algari Treatise on Skinning
  [83735] = { lid = 222547 }, -- Algari Treatise on Tailoring

  -- Old Vanilla Bosses during Anniversary Event
  [47461] = { daily = true, name = L["Lord Kazzak"] }, -- Lord Kazzak
  [47462] = { daily = true, name = L["Azuregos"] }, -- Azuregos
  [47463] = { daily = true, name = L["Dragon of Nightmare"] }, -- Dragon of Nightmare
  [60214] = { daily = true, name = L["Doomwalker"] }, -- Doomwalker
}

function SI:specialQuests()
  for qid, qinfo in pairs(_specialQuests) do
    qinfo.quest = qid

    if not qinfo.name and (qinfo.lid or qinfo.lid1) then
      local itemname, itemlink = C_Item_GetItemInfo(qinfo.lid or qinfo.lid1)
      if itemlink and qinfo.lid then
        qinfo.name = itemlink .. " (" .. LOOT .. ")"
      elseif itemname and qinfo.lid1 then
        local name = itemname:match("^[^%s]+")
        if name and #name > 0 then
          qinfo.name = name .. " (" .. LOOT .. ")"
        end
      end
    elseif not qinfo.name and qinfo.aid and qinfo.acid then
      local l = GetAchievementCriteriaInfo(qinfo.aid, qinfo.acid)
      if l then
        qinfo.name = l:gsub("%p$", "")
      end
    elseif not qinfo.name and qinfo.aid then
      SI.ScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
      SI.ScanTooltip:SetAchievementByID(qinfo.aid)
      SI.ScanTooltip:Show()
      local l = _G[SI.ScanTooltip:GetName() .. "Text" .. (qinfo.aline or "Left1")]
      l = l and l:GetText()
      if l then
        qinfo.name = l:gsub("%p$", "")
      end
    elseif not qinfo.name and qinfo.sid then
      qinfo.name = C_Spell_GetSpellName(qinfo.sid)
    end
    if not qinfo.name or #qinfo.name == 0 then
      local title, link = SI:QuestInfo(qid)
      if title then
        title = title:gsub("%p?%s*[Tt]racking%s*[Qq]uest", "")
        title = strtrim(title)
        qinfo.name = title
      end
    end

    if not qinfo.zone and qinfo.zid then
      qinfo.zone = C_Map_GetMapInfo(qinfo.zid)
    end
  end

  return _specialQuests
end

local QuestExceptions = {
  -- Expansion
  -- MoP
  [32640] = "Weekly", -- Champions of the Thunder King
  [32641] = "Weekly", -- Champions of the Thunder King
  [32718] = "Regular", -- Mogu Runes of Fate -- ticket 142: outdated quest flag still shows up
  [32719] = "Regular", -- Mogu Runes of Fate
  [33133] = "Regular", -- Warforged Seals outdated quests, no longer weekly
  [33134] = "Regular", -- Warforged Seals
  [33338] = "Weekly", -- Empowering the Hourglass
  [33334] = "Weekly", -- Strong Enough to Survive

  -- LEG
  -- Order Hall
  [44226] = "Regular", -- Order Hall: DH
  [44235] = "Regular", -- Order Hall: Druid
  [44236] = "Regular", -- Order Hall: Druid?
  [44212] = "Regular", -- Order Hall: Hunter
  [44208] = "Regular", -- Order Hall: Mage
  [44238] = "Regular", -- Order Hall: Monk
  [44219] = "Regular", -- Order Hall: Paladin
  [44230] = "Regular", -- Order Hall: Priest
  [44204] = "Regular", -- Order Hall: Rogue
  [44205] = "Regular", -- Order Hall: Shaman
  -- Argus
  [48910] = "Weekly", -- Supplying Krokuun
  [48911] = "Weekly", -- Void Inoculation
  [48912] = "Weekly", -- Supplying the Antoran Campaign
  [48634] = "Regular", -- Further Supplying Krokuun
  [48635] = "Regular", -- More Void Inoculation
  [48636] = "Regular", -- Fueling the Antoran Campaign

  -- BfA
  -- Island Expeditions (Moved to Progress.lua)
  [53435] = "Weekly", -- Azerite for the Horde
  [53436] = "Weekly", -- Azerite for the Alliance
  -- Warfront (Moved to Warfront.lua)
  [53414] = "Regular", -- Stromgarde Alliance
  [53416] = "Regular", -- Stromgarde Horde
  [53992] = "Regular", -- Darkshore Alliance
  [53955] = "Regular", -- Darkshore Horde
  -- Call to Arms: Weekly World PvP Quest
  [52944] = "Weekly", -- Call to Arms: Drustvar (Alliance)
  [52958] = "Weekly", -- Call to Arms: Drustvar (Horde)
  [52949] = "Weekly", -- Call to Arms: Nazmir (Alliance)
  [52954] = "Weekly", -- Call to Arms: Nazmir (Horde)
  [52782] = "Weekly", -- Call to Arms: Stormsong Valley (Alliance)
  [52957] = "Weekly", -- Call to Arms: Stormsong Valley (Horde)
  [52948] = "Weekly", -- Call to Arms: Tiragarde Sound (Alliance)
  [52956] = "Weekly", -- Call to Arms: Tiragarde Sound (Horde)
  [52950] = "Weekly", -- Call to Arms: Vol'dun (Alliance)
  [52953] = "Weekly", -- Call to Arms: Vol'dun (Horde)
  [52951] = "Weekly", -- Call to Arms: Zuldazar (Alliance)
  [52952] = "Weekly", -- Call to Arms: Zuldazar (Horde)
  [56648] = "Weekly", -- Call to Arms: Nazjatar (Alliance)
  [56148] = "Weekly", -- Call to Arms: Nazjatar (Horde)
  [56649] = "Weekly", -- Call to Arms: Mechagon (Alliance)
  [56650] = "Weekly", -- Call to Arms: Mechagon (Horde)
  [59018] = "Weekly", -- Call to Arms: Vale of Eternal Blossoms (Alliance)
  [59017] = "Weekly", -- Call to Arms: Vale of Eternal Blossoms (Horde)
  [59019] = "Weekly", -- Call to Arms: Uldum (Alliance)
  [59016] = "Weekly", -- Call to Arms: Uldum (Horde)
  -- BfA Zone Invasions
  [51982] = "Daily", -- Storm's Rage
  [53701] = "Daily", -- A Drust Cause
  [53711] = "Daily", -- A Sound Defense
  [53883] = "Daily", -- Shores of Zuldazar
  [53885] = "Daily", -- Isolated Victory
  [53939] = "Daily", -- Breaching Boralus
  [54132] = "Daily", -- Horde of Heroes
  [54134] = "Daily", -- Many Fine Heroes
  [54135] = "Daily", -- Romp in the Swamp
  [54136] = "Daily", -- March on the Marsh
  [54137] = "Daily", -- In Every Dark Corner
  [54138] = "Daily", -- Ritual Rampage
  -- Nazjatar
  [55121] = "Weekly", -- The Laboratory of Mardivas
  [56969] = "Weekly", -- Ancient Reefwalker Bark
  [56050] = "Weekly", -- PvP Event: Battle for Nazjatar
  -- Mechagon
  [56116] = "Regular", -- Even More Recycling
  -- Assaults
  [57157] = "Weekly", -- Assault: The Black Empire (Uldum)
  [56064] = "Weekly", -- Assault: The Black Empire (Vale of Eternal Blossoms)
  [55350] = "Weekly", -- Assault: Amathet Advance (Uldum)
  [57008] = "Weekly", -- Assault: The Warring Clans (Vale of Eternal Blossoms)
  [57728] = "Weekly", -- Assault: The Endless Swarm (Vale of Eternal Blossoms)
  [56308] = "Weekly", -- Assault: Aqir Unearthed (Uldum)
  -- Lesser Visions of N'Zoth
  [58168] = "Daily", -- A Dark, Glaring Reality
  [58155] = "Daily", -- A Hand in the Dark
  [58151] = "Daily", -- Minions of N'Zoth
  [58167] = "Daily", -- Preventative Measures
  [58156] = "Daily", -- Vanquishing the Darkness

  -- SL
  -- "Trading Favors" Heroic Dungeon Weekly
  [60242] = "Weekly", -- Trading Favors: Necrotic Wake
  [60243] = "Weekly", -- Trading Favors: Sanguine Depths
  [60244] = "Weekly", -- Trading Favors: Halls of Atonement
  [60245] = "Weekly", -- Trading Favors: The Other Side
  [60246] = "Weekly", -- Trading Favors: Tirna Scithe
  [60247] = "Weekly", -- Trading Favors: Theater of Pain
  [60248] = "Weekly", -- Trading Favors: Plaguefall
  [60249] = "Weekly", -- Trading Favors: Spires of Ascension
  -- "A Valuable Find" Mythic Dungeon Weekly
  [60250] = "Weekly", -- A Valuable Find: Theater of Pain
  [60251] = "Weekly", -- A Valuable Find: Plaguefall
  [60252] = "Weekly", -- A Valuable Find: Spires of Ascension
  [60253] = "Weekly", -- A Valuable Find: Necrotic Wake
  [60254] = "Weekly", -- A Valuable Find: Tirna Scithe
  [60255] = "Weekly", -- A Valuable Find: The Other Side
  [60256] = "Weekly", -- A Valuable Find: Halls of Atonement
  [60257] = "Weekly", -- A Valuable Find: Sanguine Depths
  -- "Observing" PvP Weekly
  [62284] = "Weekly", -- Observing Battle
  [62285] = "Weekly", -- Observing War
  [62286] = "Weekly", -- Observing Skirmishes
  [62287] = "Weekly", -- Observing Arenas
  [62288] = "Weekly", -- Observing Teamwork
  [62289] = "Weekly", -- Observing Conflict
  -- Ve'nari Weekly (Daily after Patch 9.1)
  [60622] = "Daily", -- Eye of the Scryer
  [60646] = "Daily", -- Misery Business
  [60762] = "Daily", -- Death Motes
  [60775] = "Daily", -- A Suitable Demise
  [61075] = "Daily", -- A Spark of Light
  [61079] = "Daily", -- The Jailer's Share
  [61088] = "Daily", -- Dust to Dust
  [61103] = "Daily", -- Disrupting the Cycle
  [61104] = "Daily", -- Grathalax, the Extractor
  [61765] = "Daily", -- Words of Warding
  [62214] = "Daily", -- Forces of Perdition
  [62234] = "Daily", -- Power of the Colossus
  [63206] = "Daily", -- Soulless Husks
  [64541] = "Weekly", -- The Cost of Death
  -- Queen's Conservatory
  [62441] = "Weekly", -- Fair Exchange for a Soul
  [62445] = "Weekly", -- A Spirit's Pride
  [62449] = "Weekly", -- A Spirit's Duty
  [62450] = "Weekly", -- A Spirit's Heart
  [62452] = "Weekly", -- A Spirit's Might
  -- Korthia
  [64522] = "Weekly", -- Stolen Korthian Supplies

  -- DF
  -- Aiding the Accord
  [70750] = "Weekly", -- Aiding the Accord
  [72068] = "Regular", -- Aiding the Accord: A Feast For All
  [72373] = "Regular", -- Aiding the Accord: The Hunt is On
  [72374] = "Regular", -- Aiding the Accord: Dragonbane Keep
  [72375] = "Regular", -- Aiding the Accord: The Isles Call
  [75259] = "Regular", -- Aiding the Accord: Zskera Vault
  [75859] = "Regular", -- Aiding the Accord: Sniffenseeking
  [75860] = "Regular", -- Aiding the Accord: Researchers Under Fire
  [75861] = "Regular", -- Aiding the Accord: Suffusion Camp
  [77254] = "Regular", -- Aiding the Accord: Time Rift
  [77976] = "Regular", -- Aiding the Accord: Dreamsurge
  [78446] = "Regular", -- Aiding the Accord: Superbloom
  [78447] = "Regular", -- Aiding the Accord: Emerald Bounty
  [78861] = "Regular", -- Aiding the Accord
  [80385] = "Regular", -- Last Hurrah: Dragon Isles
  [80386] = "Regular", -- Last Hurrah: Zaralek Caverns and Time Rifts
  [80388] = "Regular", -- Last Hurrah: Emerald Dream
  [80389] = "Regular", -- Last Hurrah
  -- Fishing Weeklies
  [70199] = "Weekly", -- Catch and Release: Scalebelly Mackerel
  [70200] = "Weekly", -- Catch and Release: Thousandbite Piranha
  [70201] = "Weekly", -- Catch and Release: Aileron Seamoth
  [70202] = "Weekly", -- Catch and Release: Cerulean Spinefish
  [70203] = "Weekly", -- Catch and Release: Temporal Dragonhead
  [70935] = "Weekly", -- Catch and Release: Islefin Dorado
  -- Professions Weeklies
  [66363] = "Weekly", -- Basilisk Bucklers
  [66364] = "Weekly", -- To Fly a Kite
  [66516] = "Weekly", -- Mundane Gems, I Think Not!
  [66517] = "Weekly", -- A New Source of Weapons
  [66884] = "Weekly", -- Fireproof Gear
  [66890] = "Weekly", -- Stolen Tools
  [66891] = "Weekly", -- Explosive Ash
  [66897] = "Weekly", -- Fuel for the Forge
  [66900] = "Weekly", -- Enchanted Relics
  [66937] = "Weekly", -- Decaying News
  [66940] = "Weekly", -- Elixir Experiment
  [66942] = "Weekly", -- Enemy Engineering
  [66943] = "Weekly", -- Wood for Writing
  [66944] = "Weekly", -- Peacock Pigments
  [66950] = "Weekly", -- Heart of a Giant
  [66951] = "Weekly", -- Population Control
  [66952] = "Weekly", -- The Gnoll's Clothes
  [70233] = "Weekly", -- Axe Shortage
  [70235] = "Weekly", -- Repair Bill
  [70530] = "Weekly", -- Examination Week
  [70531] = "Weekly", -- Mana Markets
  [70532] = "Weekly", -- Aiding the Raiding
  [70533] = "Weekly", -- Draught, Oiled Again
  [70540] = "Weekly", -- An Engineer's Best Friend
  [70557] = "Weekly", -- No Scopes
  [70558] = "Weekly", -- Disillusioned Illusions
  [70559] = "Weekly", -- Quill You Help?
  [70560] = "Weekly", -- The Most Powerful Tool: Good Documentation
  [70561] = "Weekly", -- A Scribe's Tragedy
  [70563] = "Weekly", -- The Exhibition
  [70564] = "Weekly", -- Spectacular
  [70565] = "Weekly", -- Separation by Saturation
  [70568] = "Weekly", -- Tipping the Scales
  [70569] = "Weekly", -- For Trisket, a Task Kit
  [70571] = "Weekly", -- Drums Here!
  [70582] = "Weekly", -- Weave Well Enough Alone
  [70586] = "Weekly", -- Sew Many Cooks
  [70587] = "Weekly", -- A Knapsack Problem
  [70589] = "Weekly", -- Blacksmithing Services Requested
  [70591] = "Weekly", -- Engineering Services Requested
  [70592] = "Weekly", -- Inscription Services Requested
  [70593] = "Weekly", -- Jewelcrafting Services Requested
  [70594] = "Weekly", -- Leatherworking Services Requested
  [70595] = "Weekly", -- Tailoring Services Requested
  [70613] = "Weekly", -- Get Their Bark Before They Bite
  [70616] = "Weekly", -- How Many??
  [70617] = "Weekly", -- All Mine, Mine, Mine
  [70618] = "Weekly", -- The Call of the Forge
  [70620] = "Weekly", -- Scaling Up
  [72157] = "Weekly", -- The Weight of Earth
  [72159] = "Weekly", -- Scaling Down
  [72172] = "Weekly", -- Essence, Shards, and Chromatic Dust
  [72173] = "Weekly", -- Braced for Enchantment
  [72175] = "Weekly", -- A Scept-acular Time
  [72407] = "Weekly", -- Soaked in Success
  [72410] = "Weekly", -- Pincers and Needles
  [72423] = "Weekly", -- Weathering the Storm
  [72427] = "Weekly", -- Animated Infusion
  [72428] = "Weekly", -- Hornswog Hoarders
  [66938] = "Weekly", -- Mammoth Marrow
  [70572] = "Weekly", -- The Cold Does Bother Them, Actually
  [66941] = "Weekly", -- Tremendous Tools
  [66935] = "Weekly", -- Crystal Quill Pens
  [70619] = "Weekly", -- A Study of Leather
  [70614] = "Weekly", -- Bubble Craze
  [72438] = "Weekly", -- Tarasek Intentions
  [70562] = "Weekly", -- The Plumbers, Mason
  [66953] = "Weekly", -- All Things Fluffy
  [70234] = "Weekly", -- All this Hammering
  [66945] = "Weekly", -- Icy Ink
  [72158] = "Weekly", -- A Dense Delivery
  [72156] = "Weekly", -- A Fiery Flight
  [66949] = "Weekly", -- Trinket Bandits
  [70211] = "Weekly", -- Stomping Explorers
  [70567] = "Weekly", -- When You Give Bakar a Bone
  [70615] = "Weekly", -- The Case of the Missing Herbs
  [70545] = "Weekly", -- Blingtron 8000...?
  [72155] = "Weekly", -- Spread the Enchantment
  -- Primalist Invasions
  [70723] = "Weekly", -- Shattering the Earth Primalists
  [70752] = "Weekly", -- Vaporizing the Water Primalists
  [70754] = "Weekly", -- Extinguishing the Fire Primalists
  [70753] = "Weekly", -- Dissipating the Air Primalists
  [72686] = "Weekly", -- Storm Surge
  -- Revival Catalyst
  [72528] = "AccountWeekly", -- Revival Catalyst
  -- Zaralek Cavern Professions
  [75286] = "Weekly", -- Blacksmith's Back
  [75288] = "Weekly", -- Enchanted Tales with Topuiz
  [75289] = "Weekly", -- Ink Master
  [75301] = "Weekly", -- Mistie's Mix Magic
  [75304] = "Weekly", -- I Need... a Tailor
  [75307] = "Weekly", -- Road to Season City
  [75308] = "Weekly", -- Scrybbil Engineering
  [75309] = "Weekly", -- If a Gem Isn't Pretty
  [75351] = "Weekly", -- Keep a Leather Eye Open
  -- Other Weeklies
  [75665] = "Weekly", -- A Worthy Ally: Loamm Niffen
  [76122] = "Weekly", -- Fighting is Its Own Reward
  [77236] = "AccountWeekly", -- When Time Needs Mending
  [78319] = "Weekly", -- The Superbloom
  [78427] = "Weekly", -- Great Crates!
  [78428] = "Weekly", -- Crate of the Art
  [78444] = "Weekly", -- A Worthy Ally: Dream Wardens
  [78821] = "Weekly", -- Blooming Dreamseeds
  [79226] = "Weekly", -- The Big Dig: Traitor's Rest

  -- TWW
  -- Lesser Keyflame
  [76169] = "Weekly", -- Glow in the Dark
  [76394] = "Weekly", -- Shadows of Flavor
  [76600] = "Weekly", -- Right Between the Gyros-Optics
  [76733] = "Weekly", -- Tater Trawl
  [76997] = "Weekly", -- Lost in Shadows
  [78656] = "Weekly", -- Hose It Down
  [78915] = "Weekly", -- Squashing the Threat
  [78933] = "Weekly", -- The Sweet Eclipse
  [78972] = "Weekly", -- Harvest Havoc
  [79158] = "Weekly", -- Seeds of Salvation
  [79173] = "Weekly", -- Supply the Effort
  [79216] = "Weekly", -- Web of Manipulation
  [79346] = "Weekly", -- Chew On That
  [80004] = "Weekly", -- Crab Grab
  [80562] = "Weekly", -- Blossoming Delight
  [81574] = "Weekly", -- Sporadic Growth
  [81632] = "Weekly", -- Lizard Looters
  -- PvP
  [47148] = "Weekly", -- Something Different
  [80184] = "Weekly", -- Preserving in Battle
  [80185] = "Weekly", -- Preserving Solo
  [80186] = "Weekly", -- Preserving in War
  [80187] = "Weekly", -- Preserving in Skirmishes
  [80188] = "Weekly", -- Preserving in Arenas
  [80189] = "Weekly", -- Preserving Teamwork
  -- World PvP
  [81793] = "Weekly", -- Sparks of War: Isle of Dorn
  [81794] = "Weekly", -- Sparks of War: The Ringing Deeps
  [81795] = "Weekly", -- Sparks of War: Hallowfall
  [81796] = "Weekly", -- Sparks of War: Azj-Kahet
  -- The Severed Threads
  [80592] = "AccountWeekly", -- Forge a Pact
  [80670] = "Weekly", -- Eyes of the Weaver
  [80671] = "Weekly", -- Blade of the General
  [80672] = "Weekly", -- Hand of the Vizier
  -- Hallowfall Fishing Derby
  [83529] = "Weekly", -- Hallowfall Fishing Derby
  [83530] = "Weekly", -- Hallowfall Fishing Derby
  [83531] = "Weekly", -- Hallowfall Fishing Derby
  [83532] = "Weekly", -- Hallowfall Fishing Derby
  [82778] = "Weekly", -- Hallowfall Fishing Derby
  -- Special Assignments
  [82355] = "Weekly", -- Special Assignment: Cinderbee Surge (Completing)
  [81649] = "Weekly", -- Special Assignment: Titanic Resurgence (Completing)
  [81691] = "Weekly", -- Special Assignment: Shadows Below (Completing)
  [83229] = "Weekly", -- Special Assignment: When the Deeps Stir (Completing)
  [82852] = "Weekly", -- Special Assignment: Lynx Rescue (Completing)
  [82787] = "Weekly", -- Special Assignment: Rise of the Colossals (Completing)
  [82414] = "Weekly", -- Special Assignment: A Pound of Cure (Completing)
  [82531] = "Weekly", -- Special Assignment: Bombs from Behind (Completing)
  [85487] = "Weekly", -- Special Assignment: Boom! Headshot! (Completing)
  [85488] = "Weekly", -- Special Assignment: Security Detail (Completing)
  -- Other Weeklies
  [82449] = "Weekly", -- The Call of the Worldsoul
  [83240] = "Weekly", -- The Theater Troupe
  [84370] = "AccountWeekly", -- The Key to Success
  [83333] = "Weekly", -- Gearing Up for Trouble
  [82946] = "Weekly", -- Rollin' Down in the Deeps
  -- Worldsoul Weeklies
  [82482] = "Weekly", -- Worldsoul: Snuffling
  [82516] = "Weekly", -- Worldsoul: Forging a Pact
  [82483] = "Weekly", -- Worldsoul: Spreading the Light
  [82453] = "Weekly", -- Worldsoul: Encore!
  [82489] = "Weekly", -- Worldsoul: The Dawnbreaker
  [82659] = "Weekly", -- Worldsoul: Nerub-ar Palace
  [87417] = "Weekly", -- Worldsoul: Dungeons
  [87419] = "Weekly", -- Worldsoul: Delves
  [82490] = "Weekly", -- Worldsoul: Priory of the Sacred Flame
  [82491] = "Weekly", -- Worldsoul: Ara-Kara, City of Echoes
  [82492] = "Weekly", -- Worldsoul: City of Threads
  [82493] = "Weekly", -- Worldsoul: The Dawnbreaker
  [82494] = "Weekly", -- Worldsoul: Ara-Kara, City of Echoes
  [82496] = "Weekly", -- Worldsoul: City of Threads
  [82497] = "Weekly", -- Worldsoul: The Stonevault
  [82498] = "Weekly", -- Worldsoul: Darkflame Cleft
  [82499] = "Weekly", -- Worldsoul: Priory of the Sacred Flame
  [82500] = "Weekly", -- Worldsoul: The Rookery
  [82501] = "Weekly", -- Worldsoul: The Dawnbreaker
  [82502] = "Weekly", -- Worldsoul: Ara-Kara, City of Echoes
  [82503] = "Weekly", -- Worldsoul: Cinderbrew Meadery
  [82504] = "Weekly", -- Worldsoul: City of Threads
  [82505] = "Weekly", -- Worldsoul: The Stonevault
  [82506] = "Weekly", -- Worldsoul: Darkflame Cleft
  [82507] = "Weekly", -- Worldsoul: Priory of the Sacred Flame
  [82508] = "Weekly", -- Worldsoul: The Rookery
  [82509] = "Weekly", -- Worldsoul: Nerub-ar Palace
  [82510] = "Weekly", -- Worldsoul: Nerub-ar Palace
  [82511] = "Weekly", -- Worldsoul: Awakening Machine
  [89514] = "Weekly", -- Worldsoul: Horrific Visions Revisited
  [82512] = "Weekly", -- Worldsoul: World Boss
  [87423] = "Weekly", -- Worldsoul: Undermine Explorer
  [87424] = "Weekly", -- Worldsoul: World Bosses
  [82488] = "Weekly", -- Worldsoul: Darkflame Cleft
  [82487] = "Weekly", -- Worldsoul: The Stonevault
  [82486] = "Weekly", -- Worldsoul: The Rookery
  [82485] = "Weekly", -- Worldsoul: Cinderbrew Meadery
  [82452] = "Weekly", -- Worldsoul: World Quests
  [87422] = "Weekly", -- Worldsoul: Undermine World Quests
  [82495] = "Weekly", -- Worldsoul: Cinderbrew Meadery
  [89502] = "Weekly", -- Worldsoul: Nightfall
  [82679] = "Weekly", -- Archives: Seeking History
  [82678] = "Weekly", -- Archives: The First Disc
  [82708] = "Weekly", -- Delves: Nerubian Menace
  [82707] = "Weekly", -- Delves: Earthen Defense
  [82706] = "Weekly", -- Delves: Worldwide Research
  [82709] = "Weekly", -- Delves: Percussive Archaeology
  [82710] = "Weekly", -- Delves: Empire-ical Exploration
  [82711] = "Weekly", -- Delves: Lost and Found
  [82712] = "Weekly", -- Delves: Trouble Up and Down Khaz Algar
  [82746] = "Weekly", -- Delves: Breaking Tough to Loot Stuff
  -- TWW Profession Services
  [84133] = "Weekly", -- Alchemy Services Requested
  [84127] = "Weekly", -- Blacksmithing Services Requested
  [84128] = "Weekly", -- Engineering Services Requested
  [84129] = "Weekly", -- Inscription Services Requested
  [84130] = "Weekly", -- Jewelcrafting Services Requested
  [84131] = "Weekly", -- Leatherworking Services Requested
  [84132] = "Weekly", -- Tailoring Services Requested

  -- General
  -- Darkmoon Faire
  [7905] = "Regular", -- Darkmoon Faire referral -- old addon versions misidentified this as monthly
  [7926] = "Regular", -- Darkmoon Faire referral
  [37819] = "Regular", -- Darkmoon Faire races referral
  [47767] = "Darkmoon", -- Death Metal Knight

  -- Blingtron
  -- update `ShowQuestTooltip` in SavedInstances.lua when updating Blingtron quest list
  [31752] = "AccountDaily", -- Blingtron 4000
  [34774] = "AccountDaily", -- Blingtron 5000
  [40753] = "AccountDaily", -- Blingtron 6000
  [56042] = "AccountDaily", -- Blingtron 7000

  -- Pet Battle Dungeons
  [45539] = "AccountWeekly", -- Pet Battle Challenge: Wailing Caverns
  [46292] = "AccountWeekly", -- Pet Battle Challenge: Deadmines
  [54186] = "AccountWeekly", -- Pet Battle Challenge: Gnomeregan
  [56492] = "AccountWeekly", -- Pet Battle Challenge: Stratholme
  [58458] = "AccountWeekly", -- Pet Battle Challenge: Blackrock Depths

  -- Weekend Event
  [83363] = "Weekly", -- A Burning Path Through Time - TBC Timewalking
  [83365] = "Weekly", -- A Frozen Path Through Time - WLK Timewalking
  [83359] = "Weekly", -- A Shattered Path Through Time - CTM Timewalking
  [83362] = "Weekly", -- A Shrouded Path Through Time - MOP Timewalking
  [83364] = "Weekly", -- A Savage Path Through Time - WOD Timewalking
  [83360] = "Weekly", -- A Fel Path Through Time - LEG Timewalking
  [86731] = "Weekly", -- An Original Path Through Time - CLA Timewalking
  [88805] = "Weekly", -- A Scarred Path Through Time - BFA Timewalking
  [83345] = "Weekly", -- A Call to Battle - Battlegrounds
  [83347] = "Weekly", -- Emissary of War - Mythic Dungeons
  [83357] = "AccountWeekly", -- The Very Best - PvP Pet Battles
  [83358] = "Weekly", -- The Arena Calls - Arena Skirmishes
  [83366] = "Weekly", -- The World Awaits - World Quests
  [84776] = "Weekly", -- A Call to Delves - Delves
}
SI.QuestExceptions = QuestExceptions

-- Timewalking Dungeon final boss drops
-- [questID] = LFDID,
local TimewalkingItemQuest = {
  [40168] = 744, -- The Swirling Vial - TBC Timewalking
  [40173] = 995, -- The Unstable Prism - WLK Timewalking
  [40786] = 1146, -- The Smoldering Ember - CTM Timewalking - Horde
  [40787] = 1146, -- The Smoldering Ember - CTM Timewalking - Alliance
  [45563] = 1453, -- The Shrouded Coin - MOP Timewalking
  [55498] = 1971, -- The Shimmering Crystal - WOD Timewalking - Alliance
  [55499] = 1971, -- The Shimmering Crystal - WOD Timewalking - Horde
  [64710] = 2274, -- Whispering Felflame Crystal - LEG Timewalking
  [83285] = 2634, -- The Ancient Scroll - CLA Timewalking
  [89222] = 2874, -- Remnant of Azeroth - BFA Timewalking - Alliance
  [89223] = 2874, -- Remnant of Azeroth - BFA Timewalking - Horde
}

for questID, tbl in pairs(TimewalkingItemQuest) do
  QuestExceptions[questID] = "Weekly"
end

SI.TimewalkingItemQuest = TimewalkingItemQuest
