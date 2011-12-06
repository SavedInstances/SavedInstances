local addonName, vars = ...
local core = vars.core
local L = vars.L
local addon = vars
vars.config = core:NewModule("Config")
module = vars.config

local Config = LibStub("AceConfig-3.0")

local db

addon.svnrev["config.lua"] = tonumber(("$Revision$"):match("%d+"))

-- local (optimal) references to Blizzard's strings
local COLOR = COLOR -- "Color"
local DEFAULTS = DEFAULTS -- "Defaults"
local DELETE = DELETE -- "DELETE"
local DUNGEON_DIFFICULTY1 = DUNGEON_DIFFICULTY1 -- 5 man
local DUNGEON_DIFFICULTY2 = DUNGEON_DIFFICULTY2 -- 5 man (Heroic)
local EMBLEM_SYMBOL = EMBLEM_SYMBOL -- "Icon"
local EXPANSION_NAME0 = EXPANSION_NAME0 -- "Classic"
local EXPANSION_NAME1 = EXPANSION_NAME1 -- "The Burning Crusade"
local EXPANSION_NAME2 = EXPANSION_NAME2 -- "Wrath of the Lich King"
local EXPANSION_NAME3 = EXPANSION_NAME3 -- "Cataclysm"
local LFG_TYPE_DUNGEON = LFG_TYPE_DUNGEON -- "Dungeon"
local LFG_TYPE_RAID = LFG_TYPE_RAID -- "Raid"
local RAID_DIFFICULTY0 = EXPANSION_NAME0 .. " " .. LFG_TYPE_RAID
local RAID_DIFFICULTY1 = RAID_DIFFICULTY1 -- "10 man"
local RAID_DIFFICULTY2 = RAID_DIFFICULTY2 -- "25 man"
local RAID_DIFFICULTY3 = RAID_DIFFICULTY3 -- "10 man (Heroic)"
local RAID_DIFFICULTY4 = RAID_DIFFICULTY4 -- "25 man (Heroic)"
local RESET_TO_DEFAULT = RESET_TO_DEFAULT -- "Reset to Default"
local FONTEND = FONT_COLOR_CODE_CLOSE
local GOLDFONT = NORMAL_FONT_COLOR_CODE

-- config global functions

function module:OnInitialize()
	db = vars.db
	module:SetupOptions()
	addon:SetupVersion()
end

-- general helper functions

local function TableLen(table)
	local i = 0
	for _, _ in pairs(table) do
		i = i + 1
	end
	return i
end

-- options functions below

local function IndicatorIconOptions(nextorder)
	return { order = nextorder, type = "select", width = "half", name = EMBLEM_SYMBOL, values = vars.Indicators }
end

local function IndicatorTextOptions(nextorder)
	return { order = nextorder, type = "input", name = L["Text"], multiline = false }
end

local function IndicatorColorOptions(nextorder, indicatortype)
	return { order = nextorder, type = "color", width = "half", hasAlpha = false, name = COLOR,
		disabled = function()
			return db.Indicators[indicatortype .. "ClassColor"]
		end,
		get = function(info)
		        db.Indicators[info[#info]] = db.Indicators[info[#info]] or vars.defaultDB.Indicators[info[#info]]
			local r = db.Indicators[info[#info]][1]
			local g = db.Indicators[info[#info]][2]
			local b = db.Indicators[info[#info]][3]
			return r, g, b, nil
		end,
		set = function(info, r, g, b, ...)
			db.Indicators[info[#info]][1] = r
			db.Indicators[info[#info]][2] = g
			db.Indicators[info[#info]][3] = b
		end,
	}
end

local function IndicatorClassColorOption(nextorder)
	return { order = nextorder, type = "toggle", name = L["Use class color"] }
end

local function GroupListGUI(order, name, list)
	local total = TableLen(list)
	local group = {
		type = "group",
		inline = true,
		name = name,
		order = order,
		args = {
			item1 = {
				type = "description",
				name = L["List is empty"],
			},
		},
	}
	for i = 1, total do
		group.args["item" .. i] = {
			type = "description",
			name = list[i],
			order = i,
		}
	end
	return group
end

-- options table below

core.Options = {
	type = "group",
	name = "SavedInstances",
	handler = SavedInstances,
	args = {
		General = {
			order = 1,
			type = "group",
			name = L["General settings"],
			get = function(info)
					return db.Tooltip[info[#info]]
			end,
			set = function(info, value)
					db.Tooltip[info[#info]] = value
			end,
			args = {
				ver = {
					order = 0.5,
					type = "description",
					name = function() return "Version: SavedInstances "..addon.version end,
				},
				intro = {
					order = 1,
					type = "description",
					name = L["Track the instance IDs saved against your characters"],
				},
				GeneralHeader = {
					order = 2, 
					type = "header",
					name = L["General settings"],
				},
				MinimapIcon = {
					type = "toggle",
					name = L["Show minimap button"],
					desc = L["Show the SavedInstances minimap button"],
					order = 3,
					hidden = function() return not vars.icon end,
					get = function(info) return not db.MinimapIcon.hide end,
					set = function(info, value)
						db.MinimapIcon.hide = not value
						if value then vars.icon:Show("SavedInstances") else vars.icon:Hide("SavedInstances") end
					end,
				},
				ShowHints = {
					type = "toggle",
					name = L["Show tooltip hints"],
					width = "full",
					order = 4,
				},
				
				CategoriesHeader = {
					order = 11, 
					type = "header",
					name = L["Categories"],
				},
				ShowCategories = {
					type = "toggle",
					name = L["Show category names"],
					desc = L["Show category names in the tooltip"],
					order = 12,
				},
				ShowSoloCategory = {
					type = "toggle",
					name = L["Single category name"],
					desc = L["Show name for a category when all displayed instances belong only to that category"],
					order = 13,
					disabled = function()
						return not db.Tooltip.ShowCategories
					end,
				},
				CategorySpaces = {
					type = "toggle",
					name = L["Space between categories"],
					desc = L["Display instances with space inserted between categories"],
					order = 14,
				},
				CategorySort = {
					order = 15,
					type = "select",
					style = "radio",
					name = L["Sort categories by"],
					values = {
						["EXPANSION"] = L["Expansion"],
						["TYPE"] = L["Type"],
					},
				},
				NewFirst = {
					type = "toggle",
					name = L["Most recent first"],
					desc = L["List categories from the current expansion pack first"],
					order = 16,
				},
				RaidsFirst = {
					type = "toggle",
					name = L["Raids before dungeons"],
					desc = L["List raid categories before dungeon categories"],
					order = 17,
				},
				
				
				InstancesHeader = {
					order = 20, 
					type = "header",
					name = L["Instances"],
				},
				ReverseInstances = {
					type = "toggle",
					name = L["Reverse ordering"],
					desc = L["Display instances in order of recommended level from lowest to highest"],
					order = 23,
				},
				ShowExpired = {
					type = "toggle",
					name = L["Show Expired"],
					desc = L["Show expired instance lockouts"],
					order = 23.5,
				},
				TrackLFG = {
					type = "toggle",
					order = 24,
					width = "double",
					name = L["Track LFG dungeon cooldown"],
					desc = L["Show cooldown for characters to use LFG dungeon system"],
				},
				TrackDeserter = {
					type = "toggle",
					order = 25,
					width = "double",
					name = L["Track Battleground Deserter cooldown"],
					desc = L["Show cooldown for characters to use battleground system"],
				},
				CurrencyHeader = {
					order = 50, 
					type = "header",
					name = CURRENCY,
				},
				Currency395 = { -- Justice Points
					type = "toggle",
					order = 51,
					name = L["Track"].." "..GetCurrencyInfo(395),
				},
				Currency396 = { -- Valor Points
					type = "toggle",
					order = 52,
					name = L["Track"].." "..GetCurrencyInfo(396),
				},
				Currency392 = { -- Honor Points
					type = "toggle",
					order = 53,
					name = L["Track"].." "..GetCurrencyInfo(392),
				},
				Currency390 = { -- Conquest Points
					type = "toggle",
					order = 54,
					name = L["Track"].." "..GetCurrencyInfo(390),
				},
				CurrencyMax = {
					type = "toggle",
					order = 55,
					name = L["Show currency max"]
				},
				CurrencyEarned = {
					type = "toggle",
					order = 56,
					name = L["Show currency earned"]
				},
				
				ToonHeader = {
					order = 31, 
					type = "header",
					name = L["Characters"],
					hidden = true,
				},
				ColumnStyle = {
					order = 32,
					type = "select",
					width = "double",
					style = "radio",
					hidden = true,
					disabled = true,
					name = L["Character column style"],
					values = {
						["ALTERNATING"] = L["Alternating columns are colored differently"],
						["CLASS"] = L["Columns are colored according to the characters class"],
						["NORMAL"] = L["Columns are the same color as the whole tooltip"],
					},
				},
				AltColumnColor = { 
					order = 33,
					type = "color",
					width = "half",
					hasAlpha = true,
					name = COLOR,
					hidden = true,
--					hidden = function()
--						return not (db.Tooltip.ColumnStyle == "ALTERNATING")
--					end,
					disabled = true,
--					disabled = function()
--						return not (db.Tooltip.ColumnStyle == "ALTERNATING")
--					end,
					get = function(info)
						local r = db.Tooltip[info[#info]][1]
						local g = db.Tooltip[info[#info]][2]
						local b = db.Tooltip[info[#info]][3]
						local a = db.Tooltip[info[#info]][4]
						return r, g, b, a
					end,
					set = function(info, r, g, b, a)
						db.Tooltip[info[#info]][1] = r
						db.Tooltip[info[#info]][2] = g
						db.Tooltip[info[#info]][3] = b
						db.Tooltip[info[#info]][4] = a
					end,
				},
				
				HistoryHeader = {
					order = 41, 
					type = "header",
					hidden = true,
					name = L["Recent instance activity"],
				},
				HistoryHelp = {
					order = 42,
					type = "description",
					hidden = true,
					name = L["Blizzard currently imposes a limit of 5 instances per hour per account. This feature will show you how many different instances you have entered in the last hour (if you have been in more than two). Once you have reached the limit, you will be shown how much time you must wait until you will be allowed to enter a new instance."],
				},
				BrokerHistory = {
					type = "toggle",
					hidden = true,
					width = "full",
					name = L["Show history in Broker data feed"],
					order = 43,
					get = function(info) return db.Broker.HistoryText end,
					set = function(info, value)
						db.Broker.HistoryText = value
						UpdateLDBTextMode()
					end,
				},
				RecentHistory = {
					type = "toggle",
					hidden = true,
					width = "full",
					name = L["Show history in tooltip"],
					order = 44,
				},
				
				DefaultsHeader = {
					order = -2, 
					type = "header",
					name = DEFAULTS,
				},
				ResetButton = {
					order = -1,
					type = "execute",
					name = RESET_TO_DEFAULT,
					func = function()
						db.Tooltip = vars.defaultDB.Tooltip
						db.Broker = vars.defaultDB.Broker
						db.MinimapIcon = vars.defaultDB.MinimapIcon
					end,
				},

			},
		},
		Indicators = {
			order = 2,
			type = "group",
			name = L["Indicators"],
			get = function(info)
					return db.Indicators[info[#info]] or vars.defaultDB.Indicators[info[#info]]
			end,
			set = function(info, value)
					db.Indicators[info[#info]] = value
			end,
			args = {
				Instructions = {
					order = 1,
					type = "description",
					name = L["You can combine icons and text in a single indicator if you wish. Simply choose an icon, and insert the word ICON into the text field. Anywhere the word ICON is found, the icon you chose will be substituted in."],
				},

				D1 = {
					type = "group",
					name = DUNGEON_DIFFICULTY1,
					order = 2,
					args = {
						D1Indicator = IndicatorIconOptions(1),
						D1Text = IndicatorTextOptions(2),
						D1Color = IndicatorColorOptions(3, "D1"),
						D1ClassColor = IndicatorClassColorOption(4),
					},
				},	
				
				D2 = {
					type = "group",
					name = DUNGEON_DIFFICULTY2,
					order = 3,
					args = {
						D2Indicator = IndicatorIconOptions(1),
						D2Text = IndicatorTextOptions(2),
						D2Color = IndicatorColorOptions(3, "D2"),
						D2ClassColor = IndicatorClassColorOption(4),
					},
				},
				
				R0 = {
					type = "group",
					order = 3.5,
					name = RAID_DIFFICULTY0,
					args = {
						R0Indicator = IndicatorIconOptions(1),
						R0Text = IndicatorTextOptions(2),
						R0Color = IndicatorColorOptions(3, "R0"),
						R0ClassColor = IndicatorClassColorOption(4),
					},
				},

				R1 = {
					type = "group",
					order = 4,
					name = RAID_DIFFICULTY1,
					args = {
						R1Indicator = IndicatorIconOptions(1),
						R1Text = IndicatorTextOptions(2),
						R1Color = IndicatorColorOptions(3, "R1"),
						R1ClassColor = IndicatorClassColorOption(4),
					},
				},

				R2 = {
					type = "group",
					order = 5,
					name = RAID_DIFFICULTY2,
					args = {
						R2Indicator = IndicatorIconOptions(1),
						R2Text = IndicatorTextOptions(2),
						R2Color = IndicatorColorOptions(3, "R2"),
						R2ClassColor = IndicatorClassColorOption(4),
					},
				},
				
				R3 = {
					type = "group",
					order = 6,
					name = RAID_DIFFICULTY3,
					args = {
						R3Indicator = IndicatorIconOptions(1),
						R3Text = IndicatorTextOptions(2),
						R3Color = IndicatorColorOptions(3, "R3"),
						R3ClassColor = IndicatorClassColorOption(4),
					},
				},

				R4 = {
					type = "group",
					order = 7,
					name = RAID_DIFFICULTY4,
					args = {
						R4Indicator = IndicatorIconOptions(1),
						R4Text = IndicatorTextOptions(2),
						R4Color = IndicatorColorOptions(3, "R4"),
						R4ClassColor = IndicatorClassColorOption(4),
					},
				},

				ResetButton = {
					order = -1,
					type = "execute",
					name = RESET_TO_DEFAULT,
					func = function()
						db.Indicators = vars.defaultDB.Indicators
					end,
				},
			},
		},
		Instances = {
			order = 4,
			type = "group",
			name = L["Instance options"],
			childGroups = "tab",
			args = {
				SelectedCategory = {
					order = 1,
					type = "select",
					name = L["Selected category"],
					disabled = false,
					get = function(info)
						if not module.selectedCategory then return end
						local index
						for i, v in ipairs(vars.OrderedCategories()) do
							if v == module.selectedCategory then
								index = i
								break
							end
						end
						return index
					end,
					set = function(info, index)
						local categories = vars.OrderedCategories()
						module.selectedCategory = categories[index]
						module.selectedInstance = nil
						module.selectedEncounter = nil
						--GenerateEncountersListGUI(3)
					end,
					values = function()
						local table = { }
						for i, v in ipairs(vars.OrderedCategories()) do
							table[i] = vars.Categories[v]
						end
						return table
					end,
				},
				SelectedInstance = {
					order = 2,
					type = "select",
					name = L["Selected instance"],
					disabled = function()
						return (module.selectedCategory == nil) or
							(addon:CategorySize(module.selectedCategory) == 0)
					end,
					get = function(info)
						if not module.selectedCategory or not module.selectedInstance then return end
						for i, v in ipairs(addon:OrderedInstances(module.selectedCategory)) do
							if v == module.selectedInstance then
								index = i
								break
							end
						end
						return index
					end,
					set = function(info, index)
						local instances = addon:OrderedInstances(module.selectedCategory)
						module.selectedInstance = instances[index]
						module.selectedEncounter = nil
						--GenerateEncountersListGUI(3)
					end,
					values = function()
						if module.selectedCategory == nil then return { } end
						return addon:OrderedInstances(module.selectedCategory)
					end,
				},

				DetailsGroup = {
					order = 4, 
					type = "group",
					name = L["Instance details"],
					disabled = function()
						return not module.selectedInstance or (addon:InstanceCategory(module.selectedInstance) ~= module.selectedCategory)
					end,
					args = {
						Expansion = {
							order = 1,
							type = "select",
							name = L["Expansion"],
							get = function(info)
								if module.selectedInstance then
									return db.Instances[module.selectedInstance].Expansion
								end
							end,
							set = function(info, expansion)
								local instance = db.Instances[module.selectedInstance]
								instance.Expansion = expansion
								instance.Raid = instance.Raid or false
								module.selectedCategory = addon:InstanceCategory(module.selectedInstance)
							end,
							values = {
								[0] = EXPANSION_NAME0,
								[1] = EXPANSION_NAME1,
								[2] = EXPANSION_NAME2,
								[3] = EXPANSION_NAME3,
							},
						},
						--[[
						LFDID = {
							order = 2,
							type = "select",
							width = "double",
							name = L["Dungeon Finder ID"],
							get = function(info)
								local instance = db.Instances[module.selectedInstance]
								local index = 0
								local found = false
								for id, details in pairs(vars.instanceDB) do
									if id > 0 and details[8] == instance.Expansion then
										index = index + 1
										if id == db.Instances[module.selectedInstance].LFDID then
											found = true
											break
										end
									end
								end
								if not found then return nil end
								return index
							end,
							set = function(info, index)
								local instance = db.Instances[module.selectedInstance]
								local counter = 0
								local LFDID
								for id, details in pairs(vars.instanceDB) do
									if id > 0 and details[8] == instance.Expansion then
										counter = counter + 1
										if counter == index then
											LFDID = id
											break
										end
									end
								end
								instance.LFDID = LFDID
								instance.LFDupdated = select(2, GetBuildInfo())
								instance.Expansion = vars.instanceDB[LFDID][8]
								module.selectedCategory = addon:InstanceCategory(module.selectedInstance)
							end,
							values = function()
								local instance = db.Instances[module.selectedInstance]
								local table = { }
								for id, details in pairs(vars.instanceDB) do
									if id > 0 and details[8] == instance.Expansion then
										table[1+#table] = strjoin(" ", id, details[1], details[5])
									end
								end
								return table
							end,
						},
						LFDLevels = {
							order = 3,
							type = "description",
							name = function()
								local LFDID = vars.db.Instances[module.selectedInstance].LFDID
								if not LFDID then return L["No Dungeon Finder ID assigned"] end
								local details = vars.instanceDB[LFDID]
								if not details then return L["No data found for this Dungeon Finder ID"] end
								return format("Levels: %d-%d; Recommended levels: %d-%d, Recommended level: %d", details[3], details[4], details[6], details[7], details[5])
							end
						},
						--]]
						AlwaysShow = {
							order = 4,
							type = "toggle",
							width = "full",
							name = L["Show when not saved"],
							get = function(info)
								if module.selectedInstance then
									return db.Instances[module.selectedInstance].Show
								end
							end,
							set = function(info, value)
								db.Instances[module.selectedInstance].Show = value
							end,
						},
						--[[
						ForgetLFDID = {
							order = -2,
							type = "execute",
							name = L["Forget ID"],
							func = function()
								vars.db.Instances[module.selectedInstance].LFDID = nil
								vars.db.Instances[module.selectedInstance].LFDupdated = nil
							end,
						},
						--]]
						DeleteButton = {
							order = -1,
							type = "execute",
							name = DELETE,
							func = function()
								local instance = module.selectedInstance
								module.selectedInstance = nil
								db.Instances[instance] = nil
							end,
						},
					},
				},
				
			},
		},
		Characters = {
			order = 4,
			type = "group",
			name = L["Characters"],
			childGroups = "tab",
			disabled = function()
				return module.selectedToon == nil
			end,
			args = {
				SelectedToon = {
					order = 1,
					type = "select",
					width = "double",
					name = L["Selected character"],
					disabled = false,
					get = function(info, toon)
						return module.selectedToon
					end,
					set = function(info, toon)
						module.selectedToon = toon
					end,
					values = function()
						local table = { }
						for toon, t in pairs(db.Toons) do
							table[toon] = toon
						end
						return table
					end,
				},
				
				DetailsGroup = {
					order = 2, 
					type = "group",
					name = L["Character details"],
					args = {
						AlwaysShow = {
							order = 1,
							type = "toggle",
							width = "full",
							name = L["Show when not saved"],
							get = function(info)
								if module.selectedToon then
									return db.Toons[module.selectedToon].AlwaysShow
								end
							end,
							set = function(info, value)
								db.Toons[module.selectedToon].AlwaysShow = value
							end,
						},
						DeleteButton = {
							order = 4,
							type = "execute",
							name = DELETE,
							func = function()
								local toon = module.selectedToon
								module.selectedToon = nil
								db.Toons[toon] = nil
							end,
						},
					},
				},
			},
		},
		--[[
		Lockouts = {
			order = 5,
			type = "group",
			childGroups = "tab",
			name = L["Lockouts"],
			disabled = function()
				return module.selectedLockout == nil
			end,
			args = {
				SelectedToon = {
					order = 1,
					type = "select",
					width = "double",
					name = L["Selected lockout"],
					disabled = function()
						return TableLen(db.Lockouts) == 0
					end,
					get = function(info)
						return module.selectedLockout
					end,
					set = function(info, value)
						module.selectedLockout = value
					end,
					values = function()
						local table = { }
						for lockout, l in pairs(db.Lockouts) do
							table[lockout] = lockout .. " " .. l.Name
						end
						return table
					end,
				},
				LockoutNote = {
					order = 2,
					type = "input",
					width = "double",
					name = L["Note"],
					get = function()
						if not module.selectedLockout then return end
						return db.Lockouts[module.selectedLockout].Note
					end,
					set = function(info, value)
						db.Lockouts[module.selectedLockout].Note = value
					end,
				},
			},
		},
		--]]
	},
}

-- global functions

local lockoutgroup
--function module:ShowLockoutWindow(lockout)
--	print(tostring(lockout))
--	module.selectedLockout = arg
--	InterfaceOptionsFrame_OpenToCategory(lockoutgroup)
--end

local firstoptiongroup, lastoptiongroup
function module:SetupOptions()
	local ACD = LibStub("AceConfigDialog-3.0")
	local namespace = "SavedInstances"
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(namespace, core.Options)
	firstoptiongroup = ACD:AddToBlizOptions(namespace, nil, nil, "General")
	ACD:AddToBlizOptions(namespace, L["Indicators"], namespace, "Indicators")
	ACD:AddToBlizOptions(namespace, L["Instances"], namespace, "Instances")
	--ACD:AddToBlizOptions(namespace, L["Lockouts"], namespace, "Lockouts")
	lastoptiongroup = ACD:AddToBlizOptions(namespace, L["Characters"], namespace, "Characters")
end

function module:ShowConfig()
	InterfaceOptionsFrame_OpenToCategory(lastoptiongroup)
	InterfaceOptionsFrame_OpenToCategory(firstoptiongroup)
end

