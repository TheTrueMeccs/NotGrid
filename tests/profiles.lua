-- Run from the addon directory with: lua5.1 tests/profiles.lua
local function read(path)
	local file = assert(io.open(path, "rb"))
	local source = file:read("*a")
	file:close()
	return source
end
local translations, language = {}, "enUS"
local locale = setmetatable({CombatEvents = {}}, {__index = function(_, key)
	local value = translations[language][key] or translations.enUS[key]
	assert(value ~= nil, "Missing translation: " .. key)
	return value == true and key or value
end})
function locale:RegisterTranslations(code, factory) translations[code] = factory() end
function AceLibrary(name) return {new = function() return name == "AceLocale-2.2" and locale or {} end} end
local character, realm, reloads = "Ghostik", "Realm", 0
function UnitName() return character end
function GetRealmName() return realm end
function UnitClass() return "Priest", "PRIEST" end
function GetCVar() return nil end
function ReloadUI() reloads = reloads + 1 end
SlashCmdList = {}
assert(loadfile("localization.lua"))()
assert(loadfile("core.lua"))()
assert(loadstring(string.gsub(read("options.lua"), "in DefaultOptions do", "in pairs(DefaultOptions) do")))()
assert(loadfile("profiles.lua"))()
local function login(name, server, settings)
	character, realm = name, server
	NotGridOptions = NotGrid:CopyOptions(settings or {})
	NotGrid:InitializeProfiles()
end
local original = {unitwidth = 74, unitheight = 33, unitbordercolor = {0.8, 0.7, 0.6, 1}, showdebufficons = false, debuffmarginleft = 0, trackingicon1 = {"Old"}}
character = nil
NotGridOptions = {unitwidth = 57}
NotGrid:InitializeProfiles()
assert(NotGrid.profileInitializationPending and next(NotGridProfiles.characters) == nil)
assert(NotGrid.o.unitwidth == 57)
character = "Late Player"
NotGrid:InitializeProfiles()
assert(not NotGrid.profileInitializationPending and NotGrid.profileName == "Late Player - Realm" and NotGrid.o.unitwidth == 57)
login("Ghostik", "Realm", original)
local first = NotGrid.profileName
assert(first == "Ghostik - Realm" and NotGrid.o.unitwidth == 74)
assert(NotGrid.o.showdebufficons == false and NotGrid.o.debuffmarginleft == 0)
assert(NotGrid.o.trackingicon1 == nil and original.trackingicon1[1] == "Old")
assert(NotGridOptions == NotGridProfiles.profiles[first] and NotGrid.o == NotGridOptions)
assert(NotGrid:CreateProfile("  Raid UI  "))
assert(NotGrid.profileName == "Raid UI" and NotGridProfiles.characters["Ghostik - Realm"] == "Raid UI")
assert(NotGrid.o.unitbordercolor ~= NotGridProfiles.profiles[first].unitbordercolor)
NotGrid.o.unitbordercolor[1] = 0.9
assert(NotGridProfiles.profiles[first].unitbordercolor[1] == 0.8)
local before = reloads
assert(not NotGrid:CreateProfile("Raid UI") and not NotGrid:CreateProfile(" ") and not NotGrid:CreateProfile(string.rep("x", 81)))
assert(reloads == before)

login("Alt", "Realm", {unitwidth = 45, unitfont = "Custom.ttf"})
local altProfile = NotGrid.profileName
assert(altProfile == "Alt - Realm" and NotGrid.o.unitwidth == 45)
assert(NotGrid:CopyFromProfile("Raid UI"))
assert(NotGrid.profileName == altProfile and NotGrid.o.unitwidth == 74)
NotGrid.o.unitbordercolor[1] = 0.2
assert(NotGridProfiles.profiles["Raid UI"].unitbordercolor[1] == 0.9, "Copies must not share nested colors")
assert(not NotGrid:CopyFromProfile(altProfile) and not NotGrid:UseProfile("missing"))

-- Serialize and reload separate account/character SavedVariables as WoW does.
local function serialize(value)
	if type(value) == "string" then return string.format("%q", value) end
	if type(value) ~= "table" then return tostring(value) end
	local parts = {}
	for key,item in pairs(value) do table.insert(parts, "[" .. serialize(key) .. "]=" .. serialize(item)) end
	return "{" .. table.concat(parts, ",") .. "}"
end
NotGridProfiles = assert(loadstring("return " .. serialize(NotGridProfiles)))()
login("Ghostik", "Realm", {unitwidth = 999})
assert(NotGrid.profileName == "Raid UI" and NotGrid.o.unitwidth == 74, "Account profile wins over a stale character snapshot")
assert(NotGrid:UseProfile(altProfile))
NotGrid.o.unitheight = 62
login("Alt", "Realm")
assert(NotGrid.profileName == altProfile and NotGrid.o.unitheight == 62, "Shared profiles must include future edits")
assert(not NotGrid:DeleteProfile(altProfile))
assert(NotGrid:DeleteProfile(first), "Unused profiles can be deleted")
assert(not NotGrid:DeleteProfile("missing"))

login("Alt", "Other Realm", {unitwidth = 81})
assert(NotGrid.profileName == "Alt - Other Realm" and NotGrid.o.unitwidth == 81)
NotGridProfiles.profiles["Clash - Realm"] = {unitwidth = 12}
login("Clash", "Realm", {unitwidth = 88})
assert(NotGrid.profileName == "Clash - Realm (2)" and NotGrid.o.unitwidth == 88)
assert(NotGridProfiles.profiles["Clash - Realm"].unitwidth == 12)
assert(NotGrid:ResetProfile())
assert(NotGrid.o.unitwidth == 36 and NotGrid.o.configmode == false)
NotGrid.o.unitbordercolor[1] = 0.3
login("Fresh", "Realm")
assert(NotGrid.o.unitbordercolor[1] == 0, "Default color tables must be independent across profiles")

-- Strict UI mocks exercise the real profile window and its buttons.
local methods = {}
function CreateFrame(kind, name, parent)
	if name and parent then name = string.gsub(name, "%$parent", parent.name) end
	local f = setmetatable({name = name, kind = kind, parent = parent, shown = true, enabled = true, scripts = {}}, {__index = methods})
	if name then _G[name] = f end
	return f
end
function methods:CreateFontString(name) return CreateFrame("FontString", name, self) end
function methods:SetText(text) assert(type(text) == "string" or type(text) == "number"); self.text = text end
function methods:GetText() return self.text or "" end
function methods:SetPoint(...) self.anchor = {...} end
function methods:ClearAllPoints() self.anchor = nil end
function methods:GetCenter() if self.center then return unpack(self.center) end end
function methods:SetScript(event, action) self.scripts[event] = action end
local function fire(f, event)
	assert(f.scripts[event], event)
	local previous = this
	this = f
	f.scripts[event]()
	this = previous
end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false; if self.scripts.OnHide then fire(self, "OnHide") end end
function methods:Enable() self.enabled = true end
function methods:Disable() self.enabled = false end
function methods:ClearFocus() self.focus = false end
for _, name in ipairs({"SetWidth", "SetHeight", "SetJustifyH", "SetFrameStrata", "SetClampedToScreen", "EnableMouse", "SetBackdrop", "SetBackdropColor", "SetHighlightTexture", "EnableMouseWheel", "SetFontObject", "SetAutoFocus", "SetMaxLetters"}) do methods[name] = function() end end
UIParent = CreateFrame("Frame", "UIParent")
UIParent.center = {500, 400}
NotGrid.Container = CreateFrame("Frame", "Container", UIParent)
NotGrid.Container.center = {830, 470}
NotGrid:SaveProfilePosition()
assert(NotGrid.o.containerpoint == "CENTER" and NotGrid.o.containeroffx == 330 and NotGrid.o.containeroffy == 70)
NotGrid:RestoreProfilePosition()
assert(NotGrid.Container.anchor[1] == "CENTER" and NotGrid.Container.anchor[2] == 330 and NotGrid.Container.anchor[3] == 70)
NotGrid.Container.center = nil
NotGrid:SaveProfilePosition()
assert(NotGrid.o.containeroffx == 330, "Missing coordinates must not erase the saved position")
StaticPopupDialogs = {}
local popup
function StaticPopup_Show(which, message) popup = {which = which, message = message} end

for _, code in ipairs({"enUS", "ruRU"}) do
	language = code
	NotGridProfilesPanel = nil
	for i = 1, 20 do NotGridProfiles.profiles["Unused " .. i] = {unitwidth = 36} end
	NotGrid:ShowProfiles()
	local f = NotGridProfilesPanel
	assert(f.shown and f.selected == NotGrid.profileName and not f.use.enabled and not f.copy.enabled and not f.delete.enabled)
	local originalWidth = NotGrid.o.unitwidth
	fire(f.rows[1], "OnClick")
	local source = f.selected
	assert(source ~= NotGrid.profileName and f.copy.enabled)
	fire(f.copy, "OnClick")
	assert(popup.which == "NOTGRID_PROFILE_CONFIRM")
	StaticPopupDialogs.NOTGRID_PROFILE_CONFIRM.OnCancel()
	assert(NotGrid.o.unitwidth == originalWidth)
	fire(f.copy, "OnClick")
	StaticPopupDialogs.NOTGRID_PROFILE_CONFIRM.OnAccept()
	assert(NotGrid.o.unitwidth == NotGridProfiles.profiles[source].unitwidth)
	fire(f.use, "OnClick")
	assert(NotGrid.profileName == source)
	NotGrid:RefreshProfilesPanel()
	assert(not f.use.enabled and not f.copy.enabled)
	local offset = f.offset
	fire(NotGridProfilesPanelDown, "OnClick")
	assert(f.offset > offset)
	fire(NotGridProfilesPanelUp, "OnClick")
	assert(f.offset == 0)
	arg1 = -1
	fire(f, "OnMouseWheel")
	assert(f.offset == 1)
	arg1 = nil
	f.edit:SetText(" ")
	fire(NotGridProfilesPanelCreate, "OnClick")
	assert(f.status.text ~= "")
	f.edit:SetText("Created " .. code)
	fire(NotGridProfilesPanelCreate, "OnClick")
	assert(NotGrid.profileName == "Created " .. code)
	NotGrid.o.unitwidth = 99
	fire(NotGridProfilesPanelReset, "OnClick")
	StaticPopupDialogs.NOTGRID_PROFILE_CONFIRM.OnAccept()
	assert(NotGrid.o.unitwidth == 36)
	f.selected = "Unused 1"
	NotGrid:RefreshProfilesPanel()
	assert(f.delete.enabled)
	fire(f.delete, "OnClick")
	StaticPopupDialogs.NOTGRID_PROFILE_CONFIRM.OnAccept()
	assert(NotGridProfiles.profiles["Unused 1"] == nil)
	NotGrid:ShowProfiles()
	f.edit.focus = true
	fire(NotGridProfilesPanelClose, "OnClick")
	assert(not f.shown and f.edit.focus == false)
end
local toc = read("notgrid.toc")
assert(string.find(toc, "## SavedVariables: NotGridProfiles", 1, true))
assert(string.find(toc, "## SavedVariablesPerCharacter: NotGridOptions", 1, true))
assert(string.find(toc, "profiles.lua", 1, true))
print("PASS: per-character migration, account persistence, realm/name collisions, shared and independent profiles, nested defaults, position saving, reset/delete protection, confirmations, English/Russian profile controls and scrolling.")
