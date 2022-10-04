local SI, L = unpack(select(2, ...))
local Module = SI:NewModule('Currency', 'AceEvent-3.0', 'AceTimer-3.0', 'AceBucket-3.0')

-- Lua functions
local ipairs, pairs, wipe = ipairs, pairs, wipe

-- WoW API / Variables
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local GetItemCount = GetItemCount
local GetMoney = GetMoney
local IsQuestFlaggedCompleted = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted

local currency = {
  81, -- Epicurean Award
  241, -- Champion's Seal
  391, -- Tol Barad Commendation
  402, -- Ironpaw Token
  416, -- Mark of the World Tree
  515, -- Darkmoon Prize Ticket
  697, -- Elder Charm of Good Fortune
  738, -- Lesser Charm of Good Fortune
  752, -- Mogu Rune of Fate
  776, -- Warforged Seal
  777, -- Timeless Coin
  789, -- Bloody Coin
}
SI.currency = currency

local currencySorted = {}
for _, idx in ipairs(currency) do
  table.insert(currencySorted, idx)
end
table.sort(currencySorted, function (c1, c2)
  local c1_name = C_CurrencyInfo_GetCurrencyInfo(c1).name
  local c2_name = C_CurrencyInfo_GetCurrencyInfo(c2).name
  return c1_name < c2_name
end)
SI.currencySorted = currencySorted

local specialCurrency = {

}
SI.specialCurrency = specialCurrency

for _, tbl in pairs(specialCurrency) do
  if tbl.earnByQuest then
    for _, questID in ipairs(tbl.earnByQuest) do
      SI.QuestExceptions[questID] = "Regular" -- not show in Weekly Quest
    end
  end
end

function Module:OnEnable()
  self:RegisterBucketEvent("CURRENCY_DISPLAY_UPDATE", 0.25, "UpdateCurrency")
  self:RegisterEvent("BAG_UPDATE", "UpdateCurrencyItem")
end

function Module:UpdateCurrency()
  if SI.logout then return end -- currency is unreliable during logout
  local t = SI.db.Toons[SI.thisToon]
  t.Money = GetMoney()
  t.currency = t.currency or {}
  for _,idx in ipairs(currency) do
    local data = C_CurrencyInfo_GetCurrencyInfo(idx)
    if not data.discovered then
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
        if tbl.weeklyMax then ci.weeklyMax = tbl.weeklyMax end
        if tbl.earnByQuest then
          ci.earnedThisWeek = 0
          for _, questID in ipairs(tbl.earnByQuest) do
            if IsQuestFlaggedCompleted(questID) then
              ci.earnedThisWeek = ci.earnedThisWeek + 1
            end
          end
        end
        if tbl.relatedItem then
          ci.relatedItemCount = GetItemCount(tbl.relatedItem.id)
        end
      end
      -- don't store useless info
      if ci.weeklyMax == 0 then ci.weeklyMax = nil end
      if ci.totalMax == 0 then ci.totalMax = nil end
      if ci.earnedThisWeek == 0 then ci.earnedThisWeek = nil end
      if ci.totalEarned == 0 then ci.totalEarned = nil end
      t.currency[idx] = ci
    end
  end
end

function Module:UpdateCurrencyItem()
  if not SI.db.Toons[SI.thisToon].currency then return end

  for currencyID, tbl in pairs(specialCurrency) do
    if tbl.relatedItem and SI.db.Toons[SI.thisToon].currency[currencyID] then
      SI.db.Toons[SI.thisToon].currency[currencyID].relatedItemCount = GetItemCount(tbl.relatedItem.id)
    end
  end
end
