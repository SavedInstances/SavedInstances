local SI, L = unpack(select(2, ...))
local Module = SI:NewModule('Tooltip', 'AceEvent-3.0')
local QTip = SI.Libs.QTip

local tooltip
local indicatorTip
local detachframe

local function clearTooltip()
  if tooltip then
    tooltip.elapsed = nil
    tooltip.anchorframe = nil
  end
  tooltip = nil
end

local function clearIndicatorTip()
  indicatorTip = nil
end

local headerFont
local function getHeaderFont()
  if not headerFont then
    headerFont = CreateFont('SavedInstancedTooltipHeaderFont')

    local temp = QTip:Acquire('SavedInstancesHeaderTooltip', 1, 'LEFT')
    local hFont = temp:GetHeaderFont()
    local hFontPath, hFontSize = hFont:GetFont()

    headerFont:SetFont(hFontPath, hFontSize, 'OUTLINE')

    QTip:Release(temp)
  end

  return headerFont
end

function Module:AcquireTooltip()
  if tooltip then
    QTip:Release(tooltip)
  end

  tooltip = QTip:Acquire('SavedInstancesTooltip', 1, 'LEFT')
  tooltip:SetHeaderFont(getHeaderFont())
  tooltip.OnRelease = clearTooltip -- extra-safety: update our variable on auto-release
  return tooltip
end

function Module:AcquireIndicatorTip(...)
  indicatorTip = QTip:Acquire('SavedInstancesIndicatorTooltip', ...)
  indicatorTip:Clear()
  indicatorTip:SetHeaderFont(getHeaderFont())
  indicatorTip:SetScale(SI.db.Tooltip.Scale)
  indicatorTip.OnRelease = clearIndicatorTip -- extra-safety: update our variable on auto-release

  if tooltip then
    indicatorTip:SetAutoHideDelay(0.1, tooltip)
    indicatorTip:SmartAnchorTo(tooltip)
  end
  indicatorTip:SetFrameLevel(150) -- ensure visibility when forced to overlap main tooltip

  SI:SkinFrame(indicatorTip, 'SavedInstancesIndicatorTooltip')

  return indicatorTip
end

function Module:ReleaseTooltip()
  if tooltip then
    QTip:Release(tooltip)
    tooltip = nil
  end
end

function Module:IsTooltipShown()
  return tooltip and tooltip:IsShown()
end

function Module.CloseIndicatorTip()
  _G.GameTooltip:Hide()
  if indicatorTip then
    indicatorTip:Hide()
  end
end

function Module:IsDetached()
  return detachframe and detachframe:IsShown()
end

function Module:HideDetached()
  if detachframe then
    detachframe:Hide()
  end
end

function Module:ToggleDetached()
  if Module:IsDetached() then
    Module:HideDetached()
  else
    Module:ShowDetached()
  end
end

function Module:ShowDetached()
  if not detachframe then
    local frame = CreateFrame('Frame', 'SavedInstancesDetachHeader', UIParent, 'BasicFrameTemplate, BackdropTemplate')
    frame:SetMovable(true)
    frame:SetFrameStrata('TOOLTIP')
    frame:SetFrameLevel(100) -- prevent weird interlacings with other tooltips
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetUserPlaced(true)
    frame:SetAlpha(0.5)
    if SI.db.Tooltip.posx and SI.db.Tooltip.posy then
      frame:SetPoint('TOPLEFT', SI.db.Tooltip.posx, -SI.db.Tooltip.posy)
    else
      frame:SetPoint('CENTER')
    end
    frame:SetScript('OnMouseDown', function(self)
      self:StartMoving()
    end)
    frame:SetScript('OnMouseUp', function(self)
      self:StopMovingOrSizing()
      SI.db.Tooltip.posx = self:GetLeft()
      SI.db.Tooltip.posy = UIParent:GetTop() - (self:GetTop() * self:GetScale())
    end)
    frame:SetScript('OnHide', Module.ReleaseTooltip)
    frame:SetScript('OnUpdate', function(self)
      if not tooltip then
        self:Hide()
        return
      end
      local w,h = tooltip:GetSize()
	    self:SetSize(
        w * tooltip:GetEffectiveScale() / UIParent:GetEffectiveScale(),
        h * tooltip:GetEffectiveScale() / UIParent:GetEffectiveScale() + 20
      )
    end)
    frame:SetScript('OnKeyDown', function(self, key)
      if key == 'ESCAPE' then
        self:SetPropagateKeyboardInput(false)
        self:Hide()
      end
    end)
    frame:EnableKeyboard(true)
    SI:SkinFrame(frame, 'SavedInstancesDetachHeader')
    detachframe = frame
  end

  if tooltip then
    tooltip:Hide()
  end

  detachframe:Show()
  detachframe:SetPropagateKeyboardInput(true)
  SI:ShowTooltip(detachframe)
end

function Module:GetDetachedFrame()
  return detachframe
end
