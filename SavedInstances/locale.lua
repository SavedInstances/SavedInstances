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

if locale == "frFR" then
  --@localization(locale="frFR", format="lua_additive_table", table-name="La")@
elseif locale == "deDE" then
  --@localization(locale="deDE", format="lua_additive_table", table-name="La")@
elseif locale == "koKR" then
  --@localization(locale="koKR", format="lua_additive_table", table-name="La")@
    La["EoA"] = "아즈"
    La["DHT"] = "어숲"
    La["BRH"] = "검까"
    La["HoV"] = "용맹"
    La["Nelt"] = "넬타"
    La["VotW"] = "감시관"
    La["MoS"] = "아귀"
    La["Arc"] = "비전로"
    La["CoS"] = "별궁"
    La["L Kara"] = "하층"
    La["CoEN"] = "대성당"
    La["U Kara"] = "상층"
    La["SotT"] = "삼두정"
elseif locale == "esMX" then
  --@localization(locale="esMX", format="lua_additive_table", table-name="La")@
elseif locale == "ruRU" then
  --@localization(locale="ruRU", format="lua_additive_table", table-name="La")@
elseif locale == "zhCN" then
  --@localization(locale="zhCN", format="lua_additive_table", table-name="La")@
elseif locale == "esES" then
  --@localization(locale="esES", format="lua_additive_table", table-name="La")@
elseif locale == "zhTW" then
  --@localization(locale="zhTW", format="lua_additive_table", table-name="La")@
elseif locale == "ptBR" then
  --@localization(locale="ptBR", format="lua_additive_table", table-name="La")@
elseif locale == "itIT" then
  --@localization(locale="itIT", format="lua_additive_table", table-name="La")@
end
