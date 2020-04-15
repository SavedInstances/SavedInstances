local SI, L = unpack(select(2, ...))

do
  local GTToffset = time() - GetTime()
  function SI:GetTimeToTime(val)
    if not val then return end
    return val + GTToffset
  end
end
