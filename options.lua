local L = AceLibrary("AceLocale-2.2"):new("NotGrid")

local DefaultOptions = {
	["version"] = 1.132, -- will be the commit number from now on.
	["versionchecking"] = true,

	["unitwidth"] = 36,
	["unitheight"] = 36,
	["unitborder"] = 2,
	["unitpadding"] = 2,
	["unitbgcolor"] = {0,0,0,0.4},
	["unitbordercolor"] = {0,0,0,0.8},
	["unithealthorientation"] = 1,
	["unithealthbartexture"] = "Interface\\AddOns\\NotGrid\\media\\Striped",
	["unithealthbarcolor"] = {39/255,186/255,42/255,1},
	["unithealthbarbgcolor"] = {0,0,0,0.1},
	["unithealthbarbgtexture"] = "Interface\\Buttons\\WHITE8X8",
	["unitfont"] = "Fonts\\FRIZQT__.TTF",
	["unitnamehealthtextcolor"] = {1,1,1,1},
	["unitnamehealthtextsize"] = 12,
	["unitnamehealthtextoutline"] = false,
	["unithealcommbarcolor"] = {32/255,112/255,11/255,1},
	["unithealcommtextcolor"] = {39/255,186/255,42/255,1},
	["unithealcommtextsize"] = 10,
	["unithealcommtextoffx"] = 0,
	["unithealcommtextoffy"] = -10,
	["showdebufficons"] = true,
	["debuffborder"] = true,
	["debufficonsize"] = 10,
	["debuffmaxicons"] = 3,
	["debuffanchor"] = "TOPLEFT",
	["debuffgrowth"] = "DOWN",
	["debuffmarginleft"] = 1,
	["debuffmargintop"] = 1,
	["debuffspacing"] = 1,
	["debuffshowmagic"] = true,
	["debuffshowcurse"] = true,
	["debuffshowdisease"] = true,
	["debuffshowpoison"] = true,
	["debuffshowother"] = true,
	["unitnumberfont"] = "Fonts\\custom\\SF-Pro-Display-Medium.ttf",

	["showraidicon"] = true,
	["raidiconsize"] = 10,
	["raidiconoffx"] = 0,
	["raidiconoffy"] = 10,

	["showtankicon"] = true,
	["showhealericon"] = true,
	["showdpsicon"] = false,

	["showpowerbar"] = false,
	["powersize"] = 3, -- this will be width if the player chooses to make it Verical, or height if they make it Horizontal
	["powerposition"] = 3, -- 1=top,2=bottom,3=left,4=right
	["colorpowerbarbgbytype"] = false,
	["unitpowerbarbgcolor"] = {0,0,0,0.1},
	["trackaggro"] = true,
	["aggrowarningcolor"] = {150/255,10/255,10/255,0.8},
	["trackmana"] = true,
	["manawarningcolor"] = {42/255,69/255,117/255,0.8},

	["tracktarget"] = false,
	["targetcolor"] = {1,1,1,0.8},

	["containerpoint"] = "CENTER",
	["containeroffx"] = 0,
	["containeroffy"] = 0,

	["unitnamehealthoffx"] = 0,
	["unitnamehealthoffy"] = 0,


	["healththreshhold"] = 90,
	["manathreshhold"] = 20,
	["namelength"] = 3,

	["ooralpha"] = 0.8,

	["useproximity"] = true,
	["proximityrate"] = 1,
	["proximityleeway"] = 4,

	["colorunitnamehealthbyclass"] = true,
	["colorunithealthbarbyclass"] = true,
	["colorunithealthbarbgbyclass"] = false,
	["usetbcshamancolor"] = true,
	["usepetcolor"] = true,
	["petcolor"] = {1,0.74,0},


	["smartcenter"] = false,
	["showhealcommtext"] = true,
	["showhealcommbar"] = true,
	["usemapdistances"] = true,

	["showwhilesolo"] = true,
	["showinparty"] = true,
	["showpartyinraid"] = false,
	["showpets"] = false,
	["showpetsinraid"] = false,
	["showblizzframes"] = true,

	["growthdirection"] = 1, -- 1: Group Left to Right, 2: Group Right to Left, 3: Group Top to Bottom, 4: Group Bottom to Top, 5: Unit Top to Bottom.. etc

	["cliquehook"] = false, -- keep default false to avoid confusion from new users

	["configmode"] = false,
	["disablemouseoverincombat"] = false,

	["borderartwork"] = false,

	["draggable"] = false,
	["showmenuhint"] = true,
}

function NotGrid:CopyOptions(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key,item in pairs(value) do copy[key] = self:CopyOptions(item) end
	return copy
end

function NotGrid:SetDefaultOptions() -- this will run on initialization and make sure everything is set. We can also use it if we wipe the NotGridOptions table and want to load it up with defaults
	for key,value in DefaultOptions do
		if not NotGridOptions[key] and not (not NotGridOptions[key] and type(NotGridOptions[key]) == "boolean") then -- if this wasn't set from the saved variable load
			NotGridOptions[key] = self:CopyOptions(value)
		end
	end
	-- Drop retired aura-indicator settings while preserving current frame/debuff options.
	for key in pairs(NotGridOptions) do
		if type(key) == "string" and string.find(key, "^trackingicon%d+") then
			NotGridOptions[key] = nil
		end
	end
	NotGridOptions.unittrackingiconsize = nil
	NotGridOptions.unittrackingiconborder = nil
	NotGridOptions.unittrackingiconbordercolor = nil
	-- Reset settings affected by older format changes.
	if NotGridOptions.version < 1.106 and NotGridOptions.containerpoint ~= "CENTER" then -- means they used the old drag positioning and it will be set relative to TOPLEFT
		NotGridOptions.containerpoint = DefaultOptions.containerpoint
		NotGridOptions.containeroffx = DefaultOptions.containeroffx
		NotGridOptions.containeroffy = DefaultOptions.containeroffy
	end
	if NotGridOptions.version < 1.104 and type(NotGridOptions.unithealthorientation) ~= "number" then -- means they used the old editbox config and it will be set as "VERTICAL"/"HORIZONTAL"
		NotGridOptions.unithealthorientation = DefaultOptions.unithealthorientation
	end
	NotGridOptions.version = DefaultOptions.version --update the version
end

--------------------
-- Slash Commands --
--------------------

SLASH_NOTGRID1 = "/notgrid"
SLASH_NOTGRID2 =  "/ng"
function SlashCmdList.NOTGRID(msg, editbox)
	if msg == "reset" then
		NotGrid:ConfirmProfileAction("reset")
	elseif msg == "profiles" or msg == "profile" then
		NotGrid:ShowProfiles()
	elseif msg == "grid" then
		NotGrid.o.unithealthbartexture = "Interface\\AddOns\\NotGrid\\media\\GridGradient"
		NotGrid.o.unithealthbarbgtexture = "Interface\\AddOns\\NotGrid\\media\\GridGradient"
		NotGrid.o.unithealthbarcolor = {0,0,0,0.65}
		NotGrid.o.unithealthbarbgcolor = {0,0,0,1}
		NotGrid.o.colorunithealthbarbyclass = false
		NotGrid.o.colorunithealthbarbgbyclass = true
		ReloadUI()
	else
		NotGridOptionsMenu:Show()
	end
end
