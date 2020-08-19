-- my custom locale file - more streamlined than AceLocale and no lib dependency

-- To help with missing translations please go here:
local url = "http://www.wowace.com/addons/saved_instances/localization/"

local addonName, addon = ...
local Ld, La = {}, {}
local locale = GAME_LOCALE or GetLocale()
if locale == "enGB" then locale = "enUS" end

-- Lua functions
local print, format, rawget = print, format, rawget

addon.L = setmetatable({},{
  __index = function(t, s)
    if locale ~= "enUS" and Ld[s] and
      not La[s] and url and not addon.locale_warning then
      addon.locale_warning = true
      print(format("*** %s needs help translating to your language! (%s)", addonName, locale))
      print("*** If you speak English, you can contribute by visiting:")
      print("*** "..url)
    end
    return La[s] or Ld[s] or rawget(t,s) or s
  end
})

--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="english", table-name="Ld")@

if locale == "frFR" then
  --@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "deDE" then
  --@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "koKR" then
  --@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "esMX" then
  --@localization(locale="esMX", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "ruRU" then
  --@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "zhCN" then
  --@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "esES" then
  --@localization(locale="esES", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "zhTW" then
  --@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "ptBR" then
  --@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
elseif locale == "itIT" then
  --@localization(locale="itIT", format="lua_additive_table", handle-unlocalized="english", table-name="La")@
end
