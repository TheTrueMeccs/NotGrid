-- Run from the addon directory with: lua5.1 tests/proximity.lua
local file = assert(io.open("proximity.lua", "rb"))
local source = file:read("*a")
file:close()
source = string.gsub(source, "in self.UnitFrames do", "in pairs(self.UnitFrames) do")
function AceLibrary() return {new = function() return {} end} end
NotGrid = {o = {usemapdistances = false, ooralpha = 0.4, proximityleeway = 4}, ProximityVars = {}}
assert(loadstring(source))()

local units = {player = true, party1 = true, raid1 = true}
local interact, targeting, canTarget, target, actionRange, mapDistance = false, false, false, false, 0, nil
function UnitExists(unit) return units[unit] end
function UnitIsVisible() return true end
function UnitIsUnit(unit, other) return unit == other or (other == "target" and target) end
function CheckInteractDistance() return interact end
function SpellIsTargeting() return targeting end
function SpellCanTargetUnit() return canTarget end
function IsActionInRange() return actionRange end
function GetTime() return 10 end
WorldMapFrame = {IsVisible = function() return false end}
function NotGrid:GetWorldDistance() return mapDistance end

UnitXP = nil
interact = true
assert(NotGrid:CheckProximity("player") == 1)
assert(NotGrid:CheckProximity("party1") == 1)

-- Reproduce the screenshot: native UnitXP accepts unit IDs, not extension commands.
local calls = 0
UnitXP = function(unit)
	calls = calls + 1
	if not units[unit] then error("Unknown unit name: " .. tostring(unit)) end
	return 1234
end
for i = 1, 20 do assert(NotGrid:CheckProximity("party1") == 1) end
assert(calls == 1, "Probe an unsupported API once, rather than every range update")

-- Preserve interaction, targeting, action-bar and map fallbacks.
interact, targeting, canTarget = false, true, true
assert(NotGrid:CheckProximity("party1") == 1)
canTarget = false
assert(NotGrid:CheckProximity("party1") == 2)
targeting, target, actionRange, NotGrid.ProximityVars.spell40slot = false, true, 1, 3
assert(NotGrid:CheckProximity("party1") == 1)
actionRange = 0
assert(NotGrid:CheckProximity("party1") == 2)
target, NotGrid.o.usemapdistances, NotGrid.ProximityVars.mapFileName, mapDistance = false, true, "TestZone", 25
assert(NotGrid:CheckProximity("party1") == 1)
mapDistance = 60
assert(NotGrid:CheckProximity("party1") == 2)
mapDistance = nil
assert(NotGrid:CheckProximity("party1") == nil)
assert(calls == 1)

-- A function returning XP numbers must not be mistaken for extended support.
UnitXP = function() return 1234 end
interact = true
assert(NotGrid:CheckProximity("party1") == 1)

local sight, distance, failSight, failDistance = true, 30, false, false
local extensionCalls = 0
UnitXP = function(command, from, to)
	extensionCalls = extensionCalls + 1
	assert(from == "player")
	if from == to then return command == "inSight" and true or 0 end
	if command == "inSight" then
		if failSight then error("unit unavailable") end
		return sight
	elseif command == "distanceBetween" then
		if failDistance then error("distance unavailable") end
		return distance
	end
	error("unexpected command")
end
interact = false
assert(NotGrid:CheckProximity("party1") == 1)
distance = 40
assert(NotGrid:CheckProximity("party1") == 1)
distance = 41
interact = true
assert(NotGrid:CheckProximity("party1") == 2, "Confirmed distance takes precedence over approximate fallbacks")
sight = false
assert(NotGrid:CheckProximity("party1") == 2)
sight = nil
assert(NotGrid:CheckProximity("party1") == 1, "Unknown line of sight must fall back instead of fading a unit")
sight = true
for _, invalid in ipairs({"unknown", -1, math.huge, 0/0}) do
	distance = invalid
	assert(NotGrid:CheckProximity("party1") == 1)
end
distance = nil
assert(NotGrid:CheckProximity("party1") == 1)
failSight = true
assert(NotGrid:CheckProximity("party1") == 1)
failSight, failDistance = false, true
assert(NotGrid:CheckProximity("party1") == 1)
failDistance, distance = false, 30
assert(NotGrid:CheckProximity("party1") == 1, "A temporary per-unit failure must not disable the extension for other units")
local before = extensionCalls
assert(NotGrid:CheckProximity("player") == 1 and extensionCalls == before)
assert(NotGrid:CheckProximity("missing") == nil and extensionCalls == before)

-- The scheduled frame pass must also survive an unsupported client's UnitXP.
calls = 0
UnitXP = function(unit) calls = calls + 1; error("Unknown unit name: " .. tostring(unit)) end
local function frame(unit, visible)
	return {unit = unit, lastseen = 0, IsVisible = function() return visible end, SetAlpha = function(self, alpha) self.alpha = alpha end}
end
NotGrid.UnitFrames = {player = frame("player", true), party1 = frame("party1", true), raid1 = frame("raid1", false)}
NotGrid:UNIT_PROXIMITY()
assert(NotGrid.UnitFrames.player.alpha == 1 and NotGrid.UnitFrames.party1.alpha == 1)
assert(NotGrid.UnitFrames.raid1.alpha == nil and calls == 1)
interact = false
NotGrid:UNIT_PROXIMITY()
assert(NotGrid.UnitFrames.party1.alpha == 1, "Unconfirmed range must keep the existing leeway")
NotGrid.UnitFrames.party1.lastseen = 0
NotGrid:UNIT_PROXIMITY()
assert(NotGrid.UnitFrames.party1.alpha == 0.4 and calls == 1)
print("PASS: native/absent/unsupported UnitXP, cached detection, valid extension results, nil/invalid/error fallbacks, range boundaries, scheduled updates and leeway fading.")
