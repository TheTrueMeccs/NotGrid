-- Run from the addon directory with: lua5.1 tests/debuffs.lua
local function read(path)
	local file = assert(io.open(path, "rb"))
	local source = file:read("*a")
	file:close()
	return source
end

local locale = setmetatable({}, {__index = function(_, key) return key end})
function AceLibrary(name)
	return {new = function() if name == "AceLocale-2.2" then return locale end return {} end}
end
function UnitClass() return "Priest", "PRIEST" end
function GetCVar() return nil end
SlashCmdList = {}
assert(loadfile("core.lua"))()
assert(loadfile("frames.lua"))()

-- Vanilla allows tables as generic-for iterators; standard Lua 5.1 needs pairs.
local source = string.gsub(read("options.lua"), "in DefaultOptions do", "in pairs(DefaultOptions) do")
local defaults = assert(loadstring(source .. "\nreturn DefaultOptions"))()
NotGridOptions = {trackingicon3 = {"Magic"}, unitfont = "Custom.ttf"}
NotGrid.o = NotGridOptions
NotGrid:SetDefaultOptions()
assert(NotGridOptions.unitfont == "Custom.ttf")
assert(NotGridOptions.trackingicon3[1] == "Magic")
assert(NotGridOptions.showdebufficons and NotGridOptions.debuffborder)
NotGridOptions.debuffshowpoison = false
NotGridOptions.debuffmarginleft = 0
NotGridOptions.debuffmargintop = -3
NotGridOptions.debuffspacing = 0
NotGrid:SetDefaultOptions()
assert(NotGridOptions.debuffshowpoison == false, "An explicit filter choice must survive initialization")
assert(NotGridOptions.debuffmarginleft == 0 and NotGridOptions.debuffmargintop == -3 and NotGridOptions.debuffspacing == 0, "Saved margins and zero spacing must survive initialization")
NotGridOptions.debuffshowpoison = true
NotGridOptions.debuffmarginleft, NotGridOptions.debuffmargintop, NotGridOptions.debuffspacing = 1, 1, 1
local o = NotGridOptions

local methods = {}
local function object()
	return setmetatable({shown = false, level = 1}, {__index = methods})
end
function CreateFrame(_, _, parent) local f = object(); f.parent = parent; return f end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function methods:EnableMouse(enabled) self.mouse = enabled end
function methods:SetPoint(...) self.anchor = {...} end
function methods:ClearAllPoints() self.anchor = nil end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return self.level end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetTexCoord() end
function methods:SetTexture(texture) self.texturePath = texture end
function methods:SetText(text) self.text = text end
function methods:SetTextColor() end
function methods:SetFont(path, size, flags) self.font = {path, size, flags}; return true end
function methods:GetFont() if self.font then return unpack(self.font) end end
function methods:SetFontObject() self.font = {"Fonts\\FRIZQT__.TTF", 10, ""} end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetBackdropBorderColor(...) self.color = {...} end
function methods:SetVertexColor(...) self.color = {...} end

DebuffTypeColor = {
	Magic = {r = 0.2, g = 0.6, b = 1}, Curse = {r = 0.6, g = 0, b = 1},
	Disease = {r = 0.6, g = 0.4, b = 0}, Poison = {r = 0, g = 0.6, b = 0},
	none = {r = 0.8, g = 0, b = 0},
}
local units = {player = {name = "Player", exists = true, buffs = {}, debuffs = {}}}
local target, aggro, mana = nil, false, 100
function UnitExists(unit) return units[unit] and units[unit].exists end
function UnitName(unit) if unit == "Target" then return target end return units[unit].name end
function UnitMana() return mana end
function UnitManaMax() return 100 end
function UnitPowerType() return 0 end
function UnitIsDeadOrGhost() return false end
function UnitBuff(unit, index)
	local aura = units[unit].buffs[index]
	if aura then return aura.texture end
end
function UnitDebuff(unit, index)
	local aura = units[unit].debuffs[index]
	if aura then return aura.texture, aura.stacks or 1, aura.type end
end
local currentName, acquired, reclaimed = nil, 0, 0
NotGrid.Gratuity = {
	SetUnitBuff = function(_, unit, index) currentName = units[unit].buffs[index].name end,
	SetUnitDebuff = function(_, unit, index) currentName = units[unit].debuffs[index].name end,
	GetLine = function() return currentName end,
}
NotGrid.Compost = {
	Acquire = function() acquired = acquired + 1; return {} end,
	Reclaim = function() reclaimed = reclaimed + 1 end,
}
NotGrid.Banzai = {GetUnitAggroByUnitId = function() return aggro end}
NotGrid.UnitFrames = {}
local function createUnit(unit)
	local f = object()
	f.healthbar, f.incheal, f.border = object(), object(), object()
	f.border.middleart = object()
	for i = 1, 11 do f.healthbar["trackingicon" .. i] = object() end
	NotGrid:CreateDebuffIcons(f)
	NotGrid:ConfigDebuffIcons(f)
	NotGrid.UnitFrames[unit] = f
	return f
end
local f = createUnit("player")
assert(#f.debuffIcons == 8 and f.debuffIconLimit == 3)
for i, icon in ipairs(f.debuffIcons) do
	assert(icon.mouse == false, "Debuffs must not intercept targeting/click casting")
	assert(icon.anchor[1] == "TOPLEFT" and icon.anchor[2] == f.healthbar)
	assert(icon.anchor[4] == 1 and icon.anchor[5] == -1 - (i - 1) * 11)
end
local function shown(frame)
	local count = 0
	for _, icon in ipairs(frame.debuffIcons) do if icon.shown then count = count + 1 end end
	return count
end
local function matches(color, expected)
	return color[1] == (expected.r or expected[1]) and color[2] == (expected.g or expected[2]) and color[3] == (expected.b or expected[3])
end
local function update() NotGrid:UNIT_AURA("player") end
units.player.buffs = {{name = "Rejuvenation", texture = "HoT"}, {name = "Power Word: Fortitude", texture = "Fortitude"}}
update()
assert(shown(f) == 0 and matches(f.border.color, o.unitbordercolor))
assert(f.healthbar.trackingicon1.shown and f.healthbar.trackingicon9.shown)

units.player.debuffs = {
	{name = "Magic spell", texture = "MagicIcon", type = "Magic", stacks = 3},
	{name = "Poison spell", texture = "PoisonIcon", type = "Poison"},
	{name = "Curse spell", texture = "CurseIcon", type = "Curse"},
	{name = "Disease spell", texture = "DiseaseIcon", type = "Disease"},
}
update()
assert(shown(f) == 3 and f.debuffType == "Magic")
assert(f.debuffIcons[1].texture.texturePath == "MagicIcon" and f.debuffIcons[1].count.text == 3)
assert(f.debuffIcons[2].count.text == "")
assert(matches(f.border.color, DebuffTypeColor.Magic))
assert(matches(f.debuffIcons[1].color, DebuffTypeColor.Magic))
assert(matches(f.border.middleart.color, DebuffTypeColor.Magic))
assert(not f.healthbar.trackingicon3.shown, "Do not duplicate debuffs in legacy corners")
o.debuffshowmagic = false
update()
assert(shown(f) == 3 and f.debuffType == "Poison")
assert(f.debuffIcons[1].texture.texturePath == "PoisonIcon" and f.debuffIcons[1].count.text == "")
assert(matches(f.border.color, DebuffTypeColor.Poison))
for _, key in ipairs({"debuffshowpoison", "debuffshowcurse", "debuffshowdisease", "debuffshowother"}) do o[key] = false end
update()
assert(shown(f) == 0 and f.debuffType == nil and matches(f.border.color, o.unitbordercolor))

-- A selected debuff overrides other highlights; those highlights resume on removal.
o.debuffshowmagic, o.tracktarget, target, aggro = true, true, "Player", true
update()
assert(matches(f.border.color, DebuffTypeColor.Magic))
o.debuffborder = false
update()
assert(shown(f) == 1 and matches(f.border.color, o.targetcolor))
o.debuffborder = true
units.player.debuffs = {}
update()
assert(matches(f.border.color, o.targetcolor))
target = nil
update()
assert(matches(f.border.color, o.aggrowarningcolor))
aggro, mana = false, 5
update()
assert(matches(f.border.color, o.manawarningcolor))
mana = 100
update()
assert(matches(f.border.color, o.unitbordercolor))

-- Test every filter individually, including physical/unknown debuff types.
for _, case in ipairs({{"Magic", "debuffshowmagic"}, {"Curse", "debuffshowcurse"}, {"Disease", "debuffshowdisease"}, {"Poison", "debuffshowpoison"}, {"Enrage", "debuffshowother"}, {false, "debuffshowother"}}) do
	units.player.debuffs = {{name = "Debuff", texture = "Icon", type = case[1] or nil}}
	o[case[2]] = true
	update()
	assert(shown(f) == 1 and matches(f.border.color, NotGrid:GetDebuffTypeColor(case[1])))
	o[case[2]] = false
	update()
	assert(shown(f) == 0 and f.debuffType == nil)
end

-- Count limits, frame resizing and a very small frame must never overflow.
for _, layout in ipairs({{36, 36, 10, 3}, {80, 24, 10, 8}, {100, 100, 10, 8}, {8, 8, 30, 8}}) do
	o.unitwidth, o.unitheight, o.debufficonsize, o.debuffmaxicons = unpack(layout)
	NotGrid:ConfigDebuffIcons(f)
	assert(f.debuffIconLimit <= layout[4] and f.debuffIconLimit <= 8)
	local last = f.debuffIcons[f.debuffIconLimit]
	assert(-last.anchor[5] + last.height <= layout[2] - 1)
	assert(last.width <= layout[1] - 2)
end
-- Margins and spacing affect the whole column, including count fitting.
for _, layout in ipairs({{4, 5, 3}, {0, 0, 0}, {-5, -4, 2}, {50, 50, 10}}) do
	o.unitwidth, o.unitheight, o.debufficonsize, o.debuffmaxicons = 36, 36, 10, 8
	o.debuffmarginleft, o.debuffmargintop, o.debuffspacing = unpack(layout)
	NotGrid:ConfigDebuffIcons(f)
	local left, top = math.min(layout[1], 34), math.min(layout[2], 34)
	local first, last = f.debuffIcons[1], f.debuffIcons[f.debuffIconLimit]
	assert(first.anchor[4] == left and first.anchor[5] == -top)
	assert(f.debuffIcons[2].anchor[5] == -top - first.height - layout[3])
	assert(left + first.width <= 35 and -last.anchor[5] + last.height <= 35)
	assert(f.debuffIconLimit == math.min(8, math.floor((35 - top + layout[3]) / (first.height + layout[3]))))
end
o.debuffmarginleft, o.debuffmargintop, o.debuffspacing = 1, 1, 1
o.unitwidth, o.unitheight, o.debufficonsize, o.debuffmaxicons = 36, 36, 10, 1
NotGrid:ConfigDebuffIcons(f)
o.debuffshowmagic = true
units.player.debuffs = {{name = "One", texture = "One", type = "Magic"}, {name = "Two", texture = "Two", type = "Magic"}}
update()
assert(shown(f) == 1)
NotGrid.inCombat = true
update()
assert(shown(f) == 1 and not f.healthbar.trackingicon9.shown)
NotGrid.inCombat = false
update()
assert(f.healthbar.trackingicon9.shown)

-- Per-unit state must not leak when a raid slot disappears or changes occupants.
units.party1 = {name = "Other", exists = true, buffs = {}, debuffs = {}}
local other = createUnit("party1")
NotGrid:UNIT_AURA("party1")
assert(shown(other) == 0 and other.debuffType == nil and f.debuffType == "Magic")
units.player.exists = false
update()
assert(shown(f) == 0 and f.debuffType == nil and matches(f.border.color, o.unitbordercolor))
units.player.exists, units.player.debuffs = true, {}
update()
assert(shown(f) == 0 and f.debuffType == nil)
NotGrid:UNIT_AURA("unknown")

o.showdebufficons = false
units.player.debuffs = {{name = "Mortal Strike", texture = "MS", type = "Magic"}}
update()
assert(shown(f) == 0 and f.debuffType == nil)
assert(f.healthbar.trackingicon3.shown and f.healthbar.trackingicon7.shown, "Legacy tracking must be restored when disabled")
assert(acquired == reclaimed, "Aura tables must always be reclaimed")

-- Config Mode shows sample debuffs even on party/raid frames with no real unit.
units.raid40 = {name = "Empty raid slot", exists = false, buffs = {}, debuffs = {}}
o.configmode, o.showdebufficons, o.debuffborder = true, true, true
for _, key in ipairs({"debuffshowmagic", "debuffshowpoison", "debuffshowcurse", "debuffshowdisease", "debuffshowother"}) do o[key] = true end
o.unitheight, o.debuffmaxicons = 100, 5
local preview = createUnit("raid40")
NotGrid:UNIT_AURA("raid40")
assert(shown(preview) == 5 and preview.debuffType == "Magic")
assert(preview.debuffIcons[1].count.text == 2 and preview.debuffIcons[5].count.text == 3)
assert(matches(preview.border.color, DebuffTypeColor.Magic))
assert(matches(preview.debuffIcons[5].color, DebuffTypeColor.none))
o.debuffmarginleft, o.debuffmargintop, o.debuffspacing = 4, 6, 3
NotGrid:ConfigDebuffIcons(preview)
NotGrid:UNIT_AURA("raid40")
assert(shown(preview) == 5)
assert(preview.debuffIcons[1].anchor[4] == 4 and preview.debuffIcons[1].anchor[5] == -6)
assert(preview.debuffIcons[5].anchor[5] == -58)
o.debuffmarginleft, o.debuffmargintop, o.debuffspacing = 1, 1, 1
NotGrid:ConfigDebuffIcons(preview)
NotGrid:UNIT_AURA("raid40")
o.debuffshowmagic = false
NotGrid:UNIT_AURA("raid40")
assert(shown(preview) == 4 and preview.debuffType == "Poison")
assert(matches(preview.border.color, DebuffTypeColor.Poison))
for _, key in ipairs({"debuffshowpoison", "debuffshowcurse", "debuffshowdisease", "debuffshowother"}) do o[key] = false end
NotGrid:UNIT_AURA("raid40")
assert(shown(preview) == 0 and preview.debuffType == nil)
o.debuffshowmagic, o.debuffshowpoison, o.debuffborder = true, true, false
o.debuffmaxicons = 2
NotGrid:ConfigDebuffIcons(preview)
NotGrid:UNIT_AURA("raid40")
assert(shown(preview) == 2 and matches(preview.border.color, o.unitbordercolor))
o.configmode, o.debuffborder = false, true
NotGrid:UNIT_AURA("raid40")
assert(shown(preview) == 0 and preview.debuffType == nil)
NotGrid:UNIT_AURA("player")
assert(f.debuffIcons[1].texture.texturePath == "MS", "Leaving Config Mode must restore real debuffs")
o.unitheight, o.debuffmaxicons = 36, 3

-- Audit menu wiring and registered labels without needing the game's options UI.
local menu = assert(loadstring(read("menus.lua") .. "\nreturn menuarray"))()
local controls = 0
for _, entry in ipairs(menu) do
	if entry.slider then assert(type(defaults[entry.slider.key]) == "number", entry.slider.key) end
	local key = entry.toggle or (entry.slider and entry.slider.key)
	if key and (string.find(key, "^debuff") or key == "showdebufficons") then
		controls = controls + 1
		assert(defaults[key] ~= nil)
	end
end
assert(controls == 12)
local translations = {}
function locale:RegisterTranslations(language, factory) translations[language] = factory() end
assert(loadfile("localization.lua"))()
for _, key in ipairs({"Show Debuff Icons", "Debuff Type Border", "Debuff Icon Size", "Debuff Icon Count", "Debuff Left Margin", "Debuff Top Margin", "Debuff Icon Spacing", "Show Magic Debuffs", "Show Curse Debuffs", "Show Disease Debuffs", "Show Poison Debuffs", "Show Other Debuffs"}) do
	assert(translations.enUS[key] and translations.ruRU[key], key)
end
-- Existing auras must be populated on enable/reload, before another aura event.
source = read("core.lua")
local start = assert(string.find(source, "function NotGrid:OnEnable()", 1, true))
local finish = assert(string.find(source, "function NotGrid:UNIT_RAID_TARGET", start, true))
source = string.sub(source, start, finish - 1)
source = string.gsub(source, "in L.CombatEvents do", "in pairs(L.CombatEvents) do")
locale.CombatEvents = {}
assert(loadstring('local L = AceLibrary("AceLocale-2.2"):new("NotGrid")\n' .. source))()
function NotGrid:RegisterEvent() end
function NotGrid:ScheduleRepeatingEvent() end
function NotGrid:DoDropDown() end
function NotGrid:ConfigUnitFrames()
	for _, frame in pairs(self.UnitFrames) do self:ConfigDebuffIcons(frame) end
end
o.showdebufficons, o.debuffborder, o.debuffshowmagic = true, true, true
NotGrid:OnEnable()
assert(shown(f) == 1 and f.debuffType == "Magic" and matches(f.border.color, DebuffTypeColor.Magic))
print("PASS: debuff textures/stacks, all type filters, border priority/restoration, downward layout, fitting/count limits, combat, unit removal/reuse, Config Mode previews and cleanup, legacy buffs, defaults and menu wiring.")
