-- Run from the addon directory with: lua5.1 tests/menu.lua
local function read(path)
	local file = assert(io.open(path, "rb"))
	local source = file:read("*a")
	file:close()
	return source
end

local methods = {}
function CreateFrame(kind, name, parent)
	if name and parent then name = string.gsub(name, "%$parent", parent.name) end
	local f = setmetatable({name = name, parent = parent, kind = kind, shown = true, scripts = {}}, {__index = methods})
	if name then _G[name] = f end
	return f
end
function methods:CreateFontString(name) return CreateFrame("FontString", name, self) end
function methods:CreateTexture(name) return CreateFrame("Texture", name, self) end
function methods:SetText(text)
	assert(type(text) == "string" or type(text) == "number", (self.name or self.kind) .. ":SetText requires text")
	self.text = text
end
function methods:GetText() return self.text end
function methods:SetScript(event, handler) self.scripts[event] = handler end
local function fire(f, event)
	local previous = this
	this = f
	if f.scripts[event] then f.scripts[event]() end
	this = previous
end
function methods:Hide()
	local changed = self.shown
	self.shown = false
	if changed then fire(self, "OnHide") end
end
function methods:Show()
	local changed = not self.shown
	self.shown = true
	if changed then fire(self, "OnShow") end
end
function methods:GetFrameLevel() return 1 end
function methods:SetValue(value) assert(type(value) == "number"); self.value = value end
for _, name in ipairs({"SetWidth", "SetHeight", "SetPoint", "ClearAllPoints", "SetTexture", "SetStatusBarTexture", "SetFrameStrata", "SetClampedToScreen", "EnableMouse", "SetBackdrop", "SetBackdropColor", "SetFontObject", "SetAutoFocus", "SetMaxLetters", "SetMinMaxValues", "SetStatusBarColor", "SetHighlightTexture", "SetAllPoints", "SetMovable", "RegisterForDrag", "EnableMouseWheel", "SetBackdropBorderColor", "SetVertexColor", "Disable", "Enable", "SetOwner", "SetDisabledTexture", "SetAlpha", "SetValueStep", "EnableKeyboard", "ClearFocus", "SetFrameLevel"}) do
	methods[name] = function() end
end
getglobal, getn = function(name) return _G[name] end, table.getn
function UnitClass() return "Priest", "PRIEST" end
function GetCVar() return nil end
function UnitName() return "Player" end
function GetRealmName() return "Test Realm" end
SlashCmdList = {}
local translations, language = {}, "enUS"
local locale = setmetatable({CombatEvents = {}}, {__index = function(_, key)
	local value = translations[language][key]
	if value == nil then value = translations.enUS[key] end
	assert(value ~= nil, "Missing translation: " .. key)
	return value == true and key or value
end})
function locale:RegisterTranslations(code, factory) translations[code] = factory() end
function AceLibrary(name)
	return {new = function() return name == "AceLocale-2.2" and locale or {} end}
end
assert(loadfile("localization.lua"))()
local source = string.gsub(read("core.lua"), "in L.CombatEvents do", "in pairs(L.CombatEvents) do")
assert(loadstring(source))()
source = string.gsub(read("options.lua"), "in DefaultOptions do", "in pairs(DefaultOptions) do")
assert(loadstring(source))()
assert(loadfile("profiles.lua"))()
local menuSource = string.gsub(read("menus.lua"), "in menuarray do", "in ipairs(menuarray) do")
menuSource = string.gsub(menuSource, "in {up = f.upb, down = f.downb, left = f.leftb, right = f.rightb} do", "in pairs({up = f.upb, down = f.downb, left = f.leftb, right = f.rightb}) do")

-- Run actual OnEnable -> DoDropDown -> every menu constructor, with the same
-- absent APPLY global as the user's client and strict SetText validation.
for _, code in ipairs({"enUS", "ruRU"}) do
	language = code
	UIParent, GameTooltip = CreateFrame("Frame", "UIParent"), CreateFrame("GameTooltip", "GameTooltip")
	APPLY = nil
	NotGridOptions = {}
	NotGridProfiles = nil
	assert(loadstring(menuSource))()
	local configured, refreshed, registered = false, false, {}
	function NotGrid:ConfigUnitFrames() configured = true end
	function NotGrid:RestoreProfilePosition() end
	function NotGrid:RefreshUnitFrames() refreshed = true end
	function NotGrid:RegisterEvent(event) registered[event] = true end
	function NotGrid:ScheduleRepeatingEvent() end
	NotGrid:OnEnable()
	assert(configured and refreshed and registered.PLAYER_ENTERING_WORLD, "Menu construction must allow startup to finish")
	local picker = NotGridMenuTexturePicker
	assert(picker.apply.text == (code == "ruRU" and "Применить" or "Apply"))
	assert(not picker.shown and table.getn(picker.buttons) == 5)
	NotGridOptionsMenu:Show()
	local anchorRow, growthRow, profilesRow
	for _, f in pairs(_G) do
		if type(f) == "table" and f.choice then
			if f.choice.key == "debuffanchor" then anchorRow = f end
			if f.choice.key == "debuffgrowth" then growthRow = f end
		end
		if type(f) == "table" and f.profiles == true then profilesRow = f end
	end
	assert(anchorRow and growthRow)
	assert(profilesRow)
	local showProfiles, opened = NotGrid.ShowProfiles, 0
	function NotGrid:ShowProfiles() opened = opened + 1 end
	fire(profilesRow, "OnClick")
	SlashCmdList.NOTGRID("profiles")
	assert(opened == 2, "Profiles must be reachable from the menu and slash command")
	NotGrid.ShowProfiles = showProfiles
	fire(anchorRow, "OnEnter")
	assert(NotGridMenuChoicePicker.shown and NotGridMenuChoicePicker.key == "debuffanchor")
	fire(growthRow, "OnEnter")
	assert(NotGridMenuChoicePicker.shown and NotGridMenuChoicePicker.key == "debuffgrowth")
	NotGrid:ScrollHandler()
	assert(not NotGridMenuChoicePicker.shown)
end
print("PASS: complete menu initialization and OnEnable completion without APPLY, strict SetText/slider values, English/Russian labels, selector wiring and menu scrolling.")
