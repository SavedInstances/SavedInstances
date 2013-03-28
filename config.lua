local addonName, vars = ...
local core = vars.core
local L = vars.L
local addon = vars
vars.config = core:NewModule("Config")
local module = vars.config

local Config = LibStub("AceConfig-3.0")

local db

addon.svnrev["config.lua"] = tonumber(("$Revision$"):match("%d+"))

-- local (optimal) references to Blizzard's strings
local COLOR = COLOR -- "Color"
local DELETE = DELETE -- "DELETE"
local DUNGEON_DIFFICULTY1 = DUNGEON_DIFFICULTY1 -- 5 man
local DUNGEON_DIFFICULTY2 = DUNGEON_DIFFICULTY2 -- 5 man (Heroic)
local EMBLEM_SYMBOL = EMBLEM_SYMBOL -- "Icon"
local EXPANSION_NAME0 = EXPANSION_NAME0 -- "Classic"
local EXPANSION_NAME1 = EXPANSION_NAME1 -- "The Burning Crusade"
local EXPANSION_NAME2 = EXPANSION_NAME2 -- "Wrath of the Lich King"
local EXPANSION_NAME3 = EXPANSION_NAME3 -- "Cataclysm"
local EXPANSION_NAME4 = EXPANSION_NAME4 -- "Mists of Pandaria"
local LFG_TYPE_DUNGEON = LFG_TYPE_DUNGEON -- "Dungeon"
local LFG_TYPE_RAID = LFG_TYPE_RAID -- "Raid"
local RAID_DIFFICULTY0 = EXPANSION_NAME0 .. " " .. LFG_TYPE_RAID
local RAID_DIFFICULTY1 = RAID_DIFFICULTY1 -- "10 man"
local RAID_DIFFICULTY2 = RAID_DIFFICULTY2 -- "25 man"
local RAID_DIFFICULTY3 = RAID_DIFFICULTY3 -- "10 man (Heroic)"
local RAID_DIFFICULTY4 = RAID_DIFFICULTY4 -- "25 man (Heroic)"
local FONTEND = FONT_COLOR_CODE_CLOSE
local GOLDFONT = NORMAL_FONT_COLOR_CODE

-- config global functions

function module:OnInitialize()
	db = vars.db
	module:SetupOptions()
	addon:SetupVersion()
end

BINDING_NAME_SAVEDINSTANCES = L["Show/Hide the SavedInstances tooltip"]
BINDING_HEADER_SAVEDINSTANCES = "SavedInstances"


-- general helper functions

function addon:idtext(instance,diff,info)
  if instance.WorldBoss then
    return L["World Boss"]
  elseif info.ID < 0 then 
    return RAID_FINDER
  elseif instance.Raid and instance.Expansion == 0 then
    return EXPANSION_NAME0 .. " " .. LFG_TYPE_RAID
  elseif instance.Raid then
    diff = diff - 2 
    return _G["RAID_DIFFICULTY"..diff]
  else
    return _G["DUNGEON_DIFFICULTY"..diff]
  end
end

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
function module:BuildOptions() 
  local valueslist = { ["always"] = GREEN_FONT_COLOR_CODE..L["Always show"]..FONTEND,
 		       ["saved"] = L["Show when saved"],
      		       ["never"] = RED_FONT_COLOR_CODE..L["Never show"]..FONTEND,
     		      }
  local opts = {
	type = "group",
	name = "SavedInstances",
	handler = SavedInstances,
	args = {
		debug = { 
			name = "debug",
			cmdHidden = true,
			guiHidden = true,
			type = "execute",
			func = function() db.dbg = not db.dbg; addon.debug("Debug set to: "..(db.dbg and "true" or "false")) end,
		},
		config = { 
			name = L["Open config"],
			guiHidden = true,
			type = "execute",
			func = function() module:ShowConfig() end,
		},
		show = { 
			name = L["Show/Hide the SavedInstances tooltip"],
			guiHidden = true,
			type = "execute",
			func = function() addon:ToggleDetached() end,
		},
		General = {
			order = 1,
			type = "group",
			name = L["General settings"],
			get = function(info)
					return db.Tooltip[info[#info]]
			end,
			set = function(info, value)
					addon.debug(info[#info].." set to: "..tostring(value))
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
					order = 4,
				},
				ReportResets = {
					type = "toggle",
					name = L["Report instance resets to group"],
					order = 4.5,
				},
				LimitWarn = {
					type = "toggle",
					name = L["Warn about instance limit"],
					order = 4.7,
				},

				CharactersHeader = {
					order = 4.9, 
					type = "header",
					name = L["Characters"],
				},
				ShowServer = {
					type = "toggle",
					name = L["Show server name"],
					order = 5,
				},
				ServerSort = {
					type = "toggle",
					name = L["Sort by server"],
					order = 6,
				},
				ServerOnly = {
					type = "toggle",
					name = L["Show only current server"],
					order = 6.25,
				},
				SelfAlways = {
					type = "toggle",
					name = L["Show self always"],
					order = 6.5,
				},
				SelfFirst = {
					type = "toggle",
					name = L["Show self first"],
					order = 7,
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
				--	style = "radio",
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
			        RowHighlight = {
					type = "range",
					name = L["Row Highlight"],
					desc = L["Opacity of the tooltip row highlighting"],
					order = 18,
					min = 0,
					max = 0.5,
					bigStep = 0.1,
					isPercent = true,
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
				ShowHoliday = {
					type = "toggle",
					name = L["Show Holiday"],
					desc = L["Show holiday boss rewards"],
					order = 23.75,
				},
				ShowRandom = {
					type = "toggle",
					name = L["Show Random"],
					desc = L["Show random dungeon bonus reward"],
					order = 23.75,
				},
				MiscHeader = {
					order = 30, 
					type = "header",
					name = L["Miscellaneous"],
				},
				TrackDailyQuests = {
					type = "toggle",
					order = 33,
					name = L["Track Daily Quests"],
				},
				TrackWeeklyQuests = {
					type = "toggle",
					order = 34,
					name = L["Track Weekly Quests"],
				},
				TrackLFG = {
					type = "toggle",
					order = 34,
					width = "double",
					name = L["Track LFG dungeon cooldown"],
					desc = L["Show cooldown for characters to use LFG dungeon system"],
				},
				TrackDeserter = {
					type = "toggle",
					order = 35,
					width = "double",
					name = L["Track Battleground Deserter cooldown"],
					desc = L["Show cooldown for characters to use battleground system"],
				},
				CurrencyHeader = {
					order = 50, 
					type = "header",
					name = CURRENCY,
				},
				CurrencyMax = {
					type = "toggle",
					order = 50.2,
					name = L["Show currency max"]
				},
				CurrencyEarned = {
					type = "toggle",
					order = 50.4,
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

				BindHeader = {
					order = -0.6, 
					type = "header",
					name = "",
					cmdHidden = true,
				},
			  	
                                ToggleBind = {
      					desc = L["Bind a key to toggle the SavedInstances tooltip"],
     	 				type = "keybinding",
      					name = L["Show/Hide the SavedInstances tooltip"],
					width = "double",
      					cmdHidden = true,
      					order = -0.5,
      					set = function(info,val)
         					local b1, b2 = GetBindingKey("SAVEDINSTANCES")
         					if b1 then SetBinding(b1) end
         					if b2 then SetBinding(b2) end
         					SetBinding(val, "SAVEDINSTANCES")
         					SaveBindings(GetCurrentBindingSet())
      					end,
      					get = function(info) return GetBindingKey("SAVEDINSTANCES") end
    				},
			},
		},
		Indicators = {
			order = 2,
			type = "group",
			name = L["Indicators"],
			get = function(info)
			   if db.Indicators[info[#info]] ~= nil then -- tri-state boolean logic
			     return db.Indicators[info[#info]]
			   else
			     return vars.defaultDB.Indicators[info[#info]]
			   end
			end,
			set = function(info, value)
					addon.debug("Config set: "..info[#info].." = "..(value and "true" or "false"))
					db.Indicators[info[#info]] = value
			end,
			args = {
				Instructions = {
					order = 1,
					type = "description",
					name = L["You can combine icons and text in a single indicator if you wish. Simply choose an icon, and insert the word ICON into the text field. Anywhere the word ICON is found, the icon you chose will be substituted in."].." "..L["Similarly, the words KILLED and TOTAL will be substituted with the number of bosses killed and total in the lockout."],
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

			},
		},
		Instances = {
			order = 4,
			type = "group",
			name = L["Instance options"],
			childGroups = "select",
			width = "double",
			args = (function()
			  local ret = {}
			  for i,cat in ipairs(vars.OrderedCategories()) do
			    ret[cat] = {
			        order = i,
				type = "group",
				name = vars.Categories[cat],
				childGroups = "tree",
				args = (function()
				  local iret = {}
				  for j, inst in ipairs(addon:OrderedInstances(cat)) do
					iret[inst] = {
					  order = j,
					  name = inst,
				  	        type = "select",
						-- style = "radio",
				  		values = valueslist,
				  		get = function(info)
						        local val = db.Instances[inst].Show
				    			return (val and valueslist[val] and val) or "saved"
				  		end,
				  		set = function(info, value)
				   		 	db.Instances[inst].Show = value
				  		end,
				        }
				  end 
				  return iret
                                 end)(),
				} 
			  end
			  return ret
			end)(),
		},
		Characters = {
			order = 4,
			type = "group",
			name = L["Characters"],
			childGroups = "select",
			width = "double",
			args = (function ()
			  local toons = {} 
			  for toon, _ in pairs(db.Toons) do
			    local tn, ts = toon:match('^(.*) [-] (.*)$')
			    toons[ts] = toons[ts] or {}
			    toons[ts][tn] = toon
			  end
			  local ret = {}
			  ret.reset = {
			    order = 0.1,
			    name = L["Reset Characters"],
			    type = "execute",
			    func = function()
			    	StaticPopup_Show("SAVEDINSTANCES_RESET")
			    end
			  }
			  local scnt = 0;
			  for server, stoons in pairs(toons) do
			    scnt = scnt + 1;
			    ret[server] = {
			      order = (server == GetRealmName() and 0.5 or scnt),
			      type = "group",
			      name = server,
		  	      childGroups = "tree",
			      args = (function()
				local tret = {}
			        for tn, toon in pairs(stoons) do
				  tret[toon] = {
			            name = tn,
				    type = "select",
				    values = valueslist,
				    get = function(info)
				      return db.Toons[toon].Show or "saved"
				    end,
				    set = function(info, value)
				      db.Toons[toon].Show = value
				    end,
				  }
				end
				return tret
		              end)(),
			    }
			  end
			  return ret
			end)()
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
  core.Options = core.Options or {} -- allow option table rebuild
  for k,v in pairs(opts) do
    core.Options[k] = v
  end
  for i, curr in ipairs(addon.currency) do
    core.Options.args.General.args["Currency"..curr] = { 
	type = "toggle",
	order = 50+i,
	name = GetCurrencyInfo(curr),
    }
  end
end

-- global functions

local lockoutgroup
--function module:ShowLockoutWindow(lockout)
--	print(tostring(lockout))
--	module.selectedLockout = arg
--	InterfaceOptionsFrame_OpenToCategory(lockoutgroup)
--end

function module:table_clone(t)
  if not t then return nil end
  local r = {}
  for k,v in pairs(t) do
    local nk,nv = k,v
    if type(k) == "table" then
      nk = module:table_clone(k)
    end
    if type(v) == "table" then
      nv = module:table_clone(v)
    end
    r[nk] = nv
  end
  return r
end

local firstoptiongroup, lastoptiongroup
function module:ReopenConfigDisplay(f)
   if InterfaceOptionsFrame:IsShown() then
      InterfaceOptionsFrame:Hide();
      InterfaceOptionsFrame_OpenToCategory(lastoptiongroup)
      InterfaceOptionsFrame_OpenToCategory(firstoptiongroup)
      InterfaceOptionsFrame_OpenToCategory(f)
   end
end

function module:SetupOptions()
	local ACD = LibStub("AceConfigDialog-3.0")
	local namespace = "SavedInstances"
	module:BuildOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(namespace, core.Options, { "si", "savedinstances" })
        local fgen = ACD:AddToBlizOptions(namespace, nil, nil, "General")
	firstoptiongroup = fgen
        fgen.default = function() 
                       addon.debug("RESET: General")
                       db.Tooltip = module:table_clone(vars.defaultDB.Tooltip) 
                       db.MinimapIcon = module:table_clone(vars.defaultDB.MinimapIcon) 
                       module:ReopenConfigDisplay(fgen)
                    end
	local find = ACD:AddToBlizOptions(namespace, L["Indicators"], namespace, "Indicators")
        find.default = function() 
                       addon.debug("RESET: Indicators")
                       db.Indicators = module:table_clone(vars.defaultDB.Indicators) 
                       module:ReopenConfigDisplay(find)
                    end
	local finst = ACD:AddToBlizOptions(namespace, L["Instances"], namespace, "Instances")
        finst.default = function() 
                       addon.debug("RESET: Instances")
                       for _,i in pairs(db.Instances) do
                          i.Show = "saved"
                       end
                       module:ReopenConfigDisplay(finst)
                    end
	--ACD:AddToBlizOptions(namespace, L["Lockouts"], namespace, "Lockouts")
	local ftoon = ACD:AddToBlizOptions(namespace, L["Characters"], namespace, "Characters")
	lastoptiongroup = ftoon
	module.ftoon = ftoon
        ftoon.default = function() 
                       addon.debug("RESET: Toons")
                       for _,i in pairs(db.Toons) do
                          i.Show = "saved"
                       end
                       module:ReopenConfigDisplay(ftoon)
                    end
end

function module:ShowConfig()
   if InterfaceOptionsFrame:IsShown() then
        InterfaceOptionsFrame:Hide()
   else
	InterfaceOptionsFrame_OpenToCategory(lastoptiongroup)
	InterfaceOptionsFrame_OpenToCategory(firstoptiongroup)
   end
end

