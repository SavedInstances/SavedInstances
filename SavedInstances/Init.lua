local addon, Engine = ...
local SI = LibStub('AceAddon-3.0'):NewAddon(addon, 'AceEvent-3.0', 'AceTimer-3.0', 'AceBucket-3.0')

Engine[1] = SI
Engine[2] = {}

_G.SavedInstances = Engine

SI.Libs = {}
SI.Libs.QTip = LibStub('LibQTip-1.0')
SI.Libs.LDB = LibStub('LibDataBroker-1.1', true)
SI.Libs.LDBI = SI.Libs.LDB and LibStub('LibDBIcon-1.0', true)

SI.ScanTooltip = CreateFrame('GameTooltip', 'SavedInstancesScanTooltip', _G.UIParent, 'GameTooltipTemplate')
