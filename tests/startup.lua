-- Run from the addon directory with: lua5.1 tests/startup.lua
local function read(path)
	local file = assert(io.open(path, "rb"))
	local source = file:read("*a")
	file:close()
	return source
end

local locale = {CombatEvents = {}}
function AceLibrary(name)
	return {new = function() return name == "AceLocale-2.2" and locale or {} end}
end
SlashCmdList = {}
function UnitClass() return "Priest", "PRIEST" end
function GetCVar() return nil end
-- Adapt only Vanilla's table iterator shorthand for standard Lua 5.1.
local source = string.gsub(read("core.lua"), "in L.CombatEvents do", "in pairs(L.CombatEvents) do")
assert(loadstring(source))()
source = string.gsub(read("frames.lua"), "in self.UnitFrames do", "in pairs(self.UnitFrames) do")
assert(loadstring(source))()
source = string.gsub(read("options.lua"), "in DefaultOptions do", "in pairs(DefaultOptions) do")
assert(loadstring(source))()

NotGrid.Compost = {Acquire = function(_, ...) return {...} end, Reclaim = function() end}
NotGrid.IdenticalUnits = {}
NotGrid.UnitFrames = {}
NotGrid.Container = {
	ClearAllPoints = function(self) self.anchor = nil end,
	SetPoint = function(self, ...) self.anchor = {...} end,
}
local units, partyCount, raidCount, registered = {}, 0, 0, {}
function UnitExists(unit) return units[unit] ~= nil end
function UnitName(unit) return units[unit] and units[unit].name end
function GetNumPartyMembers() return partyCount end
function GetNumRaidMembers() return raidCount end
function GetRaidRosterInfo(index)
	local unit = units["raid" .. index]
	if unit then return unit.name, 0, unit.group end
end
local function frame(unit, index)
	return {
		unit = unit, raidindex = index, shown = false,
		Show = function(self) self.shown = true end,
		Hide = function(self) self.shown = false end,
		ClearAllPoints = function(self) self.anchor = nil end,
		SetPoint = function(self, ...) self.anchor = {...} end,
	}
end
for i = 1, 40 do NotGrid.UnitFrames["raid" .. i] = frame("raid" .. i, i) end
for i = 1, 4 do
	NotGrid.UnitFrames["party" .. i] = frame("party" .. i)
	NotGrid.UnitFrames["partypet" .. i] = frame("partypet" .. i)
end
NotGrid.UnitFrames.player, NotGrid.UnitFrames.pet = frame("player"), frame("pet")
function getglobal(name) return _G[name] end
for i = 1, 4 do _G["PartyMemberFrame" .. i] = frame("party" .. i) end

-- Mock rendering and services, while using the actual startup handlers,
-- unit alias rebuilding, default migration and PositionFrames visibility logic.
function NotGrid:RegisterEvent(event, handler) registered[event] = handler or event end
function NotGrid:ScheduleRepeatingEvent() end
function NotGrid:DoDropDown() end
function NotGrid:ConfigUnitFrames()
	for _, f in pairs(self.UnitFrames) do f.configured = true end
end
function NotGrid:UNIT_MAIN(unit)
	assert(self.UnitFrames[unit].configured, "Frames must be configured before being populated")
	self.UnitFrames[unit].name = UnitName(unit)
end
function NotGrid:UNIT_AURA(unit) self.UnitFrames[unit].aurasUpdated = true end
function NotGrid:UNIT_RAID_TARGET(unit) self.UnitFrames[unit].raidTargetUpdated = true end
function NotGrid:UpdateProximityMapVars() self.mapUpdated = true end
local blizzFrameHandler = NotGrid.BlizzFrameHandler
function NotGrid:BlizzFrameHandler()
	self.blizzUpdated = true
	blizzFrameHandler(self)
end

local function expectShown(expected)
	for unit, f in pairs(NotGrid.UnitFrames) do
		assert(f.shown == (expected[unit] or false), "Wrong visibility for " .. unit)
		if expected[unit] then
			assert(f.anchor and f.name == UnitName(unit), "Missing initial position/name for " .. unit)
			assert(f.aurasUpdated and f.raidTargetUpdated, "Missing initial indicators for " .. unit)
		end
	end
end
local function hideAndClear()
	for _, f in pairs(NotGrid.UnitFrames) do
		f.shown, f.anchor, f.name, f.aurasUpdated, f.raidTargetUpdated = false, nil, nil, nil, nil
	end
end
local function enable()
	NotGridOptions = {versionchecking = false, showblizzframes = false}
	hideAndClear()
	NotGrid:OnEnable()
	assert(registered.PLAYER_ENTERING_WORLD == "PLAYER_ENTERING_WORLD")
end

-- No RosterLib callbacks are fired in these tests.
units.player = {name = "Player"}
enable()
expectShown({player = true})
hideAndClear()
NotGrid:PLAYER_ENTERING_WORLD()
expectShown({player = true})
assert(NotGrid.mapUpdated and NotGrid.blizzUpdated)

-- OnEnable can run before units become available; world entry must recover.
units = {}
enable()
expectShown({})
units.player = {name = "Player"}
NotGrid:PLAYER_ENTERING_WORLD()
expectShown({player = true})

partyCount = 1
units.party1, units.pet, units.partypet1 = {name = "Friend"}, {name = "Pet"}, {name = "FriendPet"}
enable()
expectShown({player = true, party1 = true})
assert(not PartyMemberFrame1.shown, "Startup must hide Blizzard party frames when disabled")
NotGrid.o.showblizzframes = true
NotGrid:RefreshUnitFrames()
assert(PartyMemberFrame1.shown, "Keep Blizzard frames when explicitly enabled")
NotGrid.o.showblizzframes = false
NotGrid.o.showpets = true
NotGrid:PLAYER_ENTERING_WORLD()
expectShown({player = true, party1 = true, pet = true, partypet1 = true})
assert(not PartyMemberFrame1.shown, "World entry must reapply the Blizzard frame setting")

-- Reload while already in a raid: subgroups and aliases are available immediately.
raidCount = 2
units.raid1, units.raid2 = {name = "Player", group = 1}, {name = "Friend", group = 2}
enable()
expectShown({raid1 = true, raid2 = true})
assert(NotGrid.IdenticalUnits.player == "raid1" and NotGrid.IdenticalUnits.party1 == "raid2")
hideAndClear()
NotGrid:PLAYER_ENTERING_WORLD()
expectShown({raid1 = true, raid2 = true})

-- Returning to solo also removes stale raid frames and unit aliases.
partyCount, raidCount, units = 0, 0, {player = {name = "Player"}}
NotGrid:PLAYER_ENTERING_WORLD()
expectShown({player = true})
assert(next(NotGrid.IdenticalUnits) == nil)

-- Explicit saved visibility choices remain respected on reload and world entry.
NotGridOptions = {versionchecking = false, showwhilesolo = false, showinparty = false}
NotGrid:OnEnable()
expectShown({})
NotGrid:PLAYER_ENTERING_WORLD()
expectShown({})
partyCount, units.party1 = 1, {name = "Friend"}
NotGrid:PLAYER_ENTERING_WORLD()
expectShown({})
assert(NotGrid.o.configmode == false, "Startup must not require or enable Config Mode")
print("PASS: startup/reload/world-entry visibility, early unit availability, solo/party/raid/pets, aliases, stale-frame cleanup and saved visibility choices without roster callbacks.")
