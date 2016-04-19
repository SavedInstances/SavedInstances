-- my custom locale file - more streamlined than AceLocale and no lib dependency

-- To help with missing translations please go here:
local url = "http://www.wowace.com/addons/saved_instances/localization/"

local addonName, vars = ...
local Ld, La = {}, {}
local locale = GAME_LOCALE or GetLocale()
if locale == "enGB" then locale = "enUS" end

vars.L = setmetatable({},{
    __index = function(t, s) 
      if locale ~= "enUS" and Ld[s] and
         not La[s] and url and not vars.locale_warning then
        vars.locale_warning = true
        print(string.format("*** %s needs help translating to your language! (%s)", addonName, locale))
	print("*** If you speak English, you can contribute by visiting:")
	print("*** "..url)
      end
      return La[s] or Ld[s] or rawget(t,s) or s 
    end
})

--@localization(locale="enUS", format="lua_additive_table", table-name="Ld")@

if locale == "frFR" then do end
--@localization(locale="frFR", format="lua_additive_table", table-name="La")@
elseif locale == "deDE" then do end
--@localization(locale="deDE", format="lua_additive_table", table-name="La")@
elseif locale == "koKR" then do end
--@localization(locale="koKR", format="lua_additive_table", table-name="La")@
elseif locale == "esMX" then do end
--@localization(locale="esMX", format="lua_additive_table", table-name="La")@
elseif locale == "ruRU" then do end
--@localization(locale="ruRU", format="lua_additive_table", table-name="La")@
elseif locale == "zhCN" then do end
--@localization(locale="zhCN", format="lua_additive_table", table-name="La")@
elseif locale == "esES" then do end
--@localization(locale="esES", format="lua_additive_table", table-name="La")@
elseif locale == "zhTW" then do end
--@localization(locale="zhTW", format="lua_additive_table", table-name="La")@
elseif locale == "ptBR" then do end
--@localization(locale="ptBR", format="lua_additive_table", table-name="La")@
elseif locale == "itIT" then do end
--@localization(locale="itIT", format="lua_additive_table", table-name="La")@
end
