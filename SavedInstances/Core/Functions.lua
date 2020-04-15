local SI, L = unpack(select(2, ...))

-- Get these functions from WeakAuras 2
function SI:GetUnitAura(unit, spell, filter)
  if filter and not filter:upper():find('FUL') then
    filter = filter .. '|HELPFUL'
  end
  for i = 1, 255 do
    local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
    if not name then return end
    if spell == spellId or spell == name then
      return UnitAura(unit, i, filter)
    end
  end
end

function SI:GetUnitBuff(unit, spell, filter)
  filter = filter and filter .. '|HELPFUL' or 'HELPFUL'
  return SI:GetUnitAura(unit, spell, filter)
end

function SI:GetUnitDebuff(unit, spell, filter)
  filter = filter and filter .. '|HARMFUL' or 'HARMFUL'
  return SI:GetUnitAura(unit, spell, filter)
end
