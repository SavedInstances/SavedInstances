local SI, L = unpack(select(2, ...))

function SI:Debug(...)
  if not SI or not SI.db or SI.db.Tooltip.DebugMode then
    SI:ChatMsg(...)
  end
end

function SI:TimeDebug()
  SI:ChatMsg("Version: %s", SI.version)
  SI:ChatMsg("Realm: %s (%s)", GetRealmName(), SI:GetRegion())
  SI:ChatMsg("Zone: %s (%s)", GetRealZoneText(), SI:GetCurrentMapAreaID())
  SI:ChatMsg("time() = %s, GetTime() = %s", time(), GetTime())
  SI:ChatMsg("Local time: %s local", date("%Y/%m/%d %H:%M:%S"))
  SI:ChatMsg("GetGameTime: %s:%s server", GetGameTime())

  local t = C_DateAndTime.GetCurrentCalendarTime()
  SI:ChatMsg("C_DateAndTime.GetCurrentCalendarTime: %s/%s/%s server", t.year, t.month, t.monthDay)
  SI:ChatMsg("GetQuestResetTime: %s", SecondsToTime(GetQuestResetTime()))
  SI:ChatMsg(date("Daily reset: %Y/%m/%d %H:%M:%S local (based on GetQuestResetTime)", time() + GetQuestResetTime()))

  local offset = SI:GetServerOffset()
  SI:ChatMsg("Local to server offset: %d hours", offset)
  offset = offset * 60 * 60 -- offset in seconds

  t = SI:GetNextDailyResetTime()
  SI:ChatMsg(
    "Next daily reset: %s local, %s server",
    date("%Y/%m/%d %H:%M:%S", t), date("%Y/%m/%d %H:%M:%S", t + offset)
  )

  t = SI:GetNextWeeklyResetTime()
  SI:ChatMsg(
    "Next weekly reset: %s local, %s server",
    date("%Y/%m/%d %H:%M:%S", t), date("%Y/%m/%d %H:%M:%S", t + offset)
  )

  t = SI:GetNextDailySkillResetTime()
  SI:ChatMsg(
    "Next skill reset: %s local, %s server",
    date("%Y/%m/%d %H:%M:%S", t), date("%Y/%m/%d %H:%M:%S", t + offset)
  )

  t = SI:GetNextDarkmoonResetTime()
  SI:ChatMsg(
    "Next Darkmoon reset: %s local, %s server",
    date("%Y/%m/%d %H:%M:%S", t), date("%Y/%m/%d %H:%M:%S", t + offset)
  )
end

do
  local function questTableToString(t)
    local ret = ""
    local lvl = UnitLevel("player")
    for k,v in pairs(t) do
      ret = string.format("%s%s\124cffffff00\124Hquest:%s:%s\124h[%s]\124h\124r", ret, (#ret == 0 and "" or ", "),k,lvl,k)
    end
    return ret
  end

  function SI:QuestDebug(info)
    local t = SI.db.Toons[SI.thisToon]
    local ql = C_QuestLog.GetAllCompletedQuestIDs()

    local cmd = info.input
    cmd = cmd and strtrim(cmd:gsub("^%s*(%w+)%s*","")):lower()
    if t.completedquests and (cmd == "load" or not SI.completedquests) then
      SI:ChatMsg("Loaded quest list")
      SI.completedquests = t.completedquests
    elseif cmd == "load" then
      SI:ChatMsg("No saved quest list")
    elseif cmd == "save" then
      SI:ChatMsg("Saved quest list")
      t.completedquests = ql
    elseif cmd == "clear" then
      SI:ChatMsg("Cleared quest list")
      SI.completedquests = nil
      t.completedquests = nil
      return
    elseif cmd and #cmd > 0 then
      SI:ChatMsg("Quest command not understood: '"..cmd.."'")
      SI:ChatMsg("/si quest ([save|load|clear])")
      return
    end
    local cnt = #ql
    local add = {}
    local remove = {}
    SI:ChatMsg("Completed quests: "..cnt)
    if SI.completedquests then
      local prev, curr = 1, 1
      while true do
        if not SI.completedquests[prev] then
          while ql[curr] do
            add[ql[curr]] = true
            curr = curr + 1
          end
          break
        elseif not ql[curr] then
          while SI.completedquests[prev] do
            remove[SI.completedquests[prev]] = true
            prev = prev + 1
          end
          break
        elseif SI.completedquests[prev] > ql[curr] then
          while ql[curr] and SI.completedquests[prev] > ql[curr] do
            add[ql[curr]] = true
            curr = curr + 1
          end
        elseif SI.completedquests[prev] < ql[curr] then
          while SI.completedquests[prev] and SI.completedquests[prev] < ql[curr] do
            remove[SI.completedquests[prev]] = true
            prev = prev + 1
          end
        else -- SI.completedquests[prev] == ql[curr]
          prev = prev + 1
          curr = curr + 1
        end
      end
      if next(add) then SI:ChatMsg("Added IDs:   "..questTableToString(add)) end
      if next(remove) then SI:ChatMsg("Removed IDs: "..questTableToString(remove)) end
    end
    SI.completedquests = ql
  end
end
