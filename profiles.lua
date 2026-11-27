local L = AceLibrary("AceLocale-2.2"):new("NotGrid")

function NotGrid:InitializeProfiles()
	if type(NotGridOptions) ~= "table" then NotGridOptions = {} end
	if type(NotGridProfiles) ~= "table" then NotGridProfiles = {} end
	if type(NotGridProfiles.profiles) ~= "table" then NotGridProfiles.profiles = {} end
	if type(NotGridProfiles.characters) ~= "table" then NotGridProfiles.characters = {} end
	self.profileDB = NotGridProfiles
	local character,realm = UnitName("player"),GetRealmName()
	if not character or character == "" or not realm or realm == "" then
		-- Do not put unidentified characters into a shared placeholder profile.
		self.profileInitializationPending = true
		self.o = NotGridOptions
		self:SetDefaultOptions()
		return
	end
	self.profileInitializationPending = nil
	self.characterKey = character .. " - " .. realm
	local name = self.profileDB.characters[self.characterKey]
	if type(name) ~= "string" or type(self.profileDB.profiles[name]) ~= "table" then
		-- Import each character's existing setup once, without overwriting another profile.
		name = self.characterKey
		local suffix = 2
		while self.profileDB.profiles[name] ~= nil do
			name = self.characterKey .. " (" .. suffix .. ")"
			suffix = suffix + 1
		end
		self.profileDB.profiles[name] = self:CopyOptions(NotGridOptions)
	end
	self.profileName = name
	self.profileDB.characters[self.characterKey] = name
	NotGridOptions = self.profileDB.profiles[name]
	self.o = NotGridOptions
	self:SetDefaultOptions()
end

function NotGrid:GetProfileNames()
	local names = {}
	for name,settings in pairs(self.profileDB.profiles) do
		if type(name) == "string" and type(settings) == "table" then table.insert(names, name) end
	end
	table.sort(names)
	return names
end

function NotGrid:UseProfile(name)
	if type(self.profileDB.profiles[name]) ~= "table" then return false, L["Profile not found."] end
	self.profileName = name
	self.profileDB.characters[self.characterKey] = name
	NotGridOptions = self.profileDB.profiles[name]
	self.o = NotGridOptions
	self:SetDefaultOptions()
	self.o.configmode = false
	ReloadUI()
	return true
end

function NotGrid:CreateProfile(name)
	if type(name) ~= "string" then return false, L["Enter a profile name (1-80 characters)."] end
	name = string.gsub(name, "^%s*(.-)%s*$", "%1")
	if name == "" or string.len(name) > 80 then return false, L["Enter a profile name (1-80 characters)."] end
	if self.profileDB.profiles[name] ~= nil then return false, L["A profile with that name already exists."] end
	self.profileDB.profiles[name] = self:CopyOptions(self.o)
	return self:UseProfile(name)
end

function NotGrid:CopyFromProfile(name)
	if type(self.profileDB.profiles[name]) ~= "table" then return false, L["Profile not found."] end
	if name == self.profileName then return false, L["Select a different profile."] end
	self.profileDB.profiles[self.profileName] = self:CopyOptions(self.profileDB.profiles[name])
	return self:UseProfile(self.profileName)
end

function NotGrid:ResetProfile()
	self.profileDB.profiles[self.profileName] = {}
	return self:UseProfile(self.profileName)
end

function NotGrid:IsProfileInUse(name)
	for _,selected in pairs(self.profileDB.characters) do
		if selected == name then return true end
	end
	return false
end

function NotGrid:DeleteProfile(name)
	if type(self.profileDB.profiles[name]) ~= "table" then return false, L["Profile not found."] end
	if self:IsProfileInUse(name) then return false, L["This profile is in use by a character."] end
	self.profileDB.profiles[name] = nil
	return true
end

function NotGrid:RefreshProfilesPanel()
	local f = NotGridProfilesPanel
	f.names = self:GetProfileNames()
	if not self.profileDB.profiles[f.selected] then f.selected = self.profileName end
	f.offset = math.max(0, math.min(f.offset, math.max(0, table.getn(f.names) - 8)))
	f.current:SetText(string.format(L["Current profile: %s"], self.profileName))
	for i,button in ipairs(f.rows) do
		local name = f.names[f.offset + i]
		button.profile = name
		if name then
			button.text:SetText((name == f.selected and "|cff00ff00> |r" or "  ") .. name)
			button:Show()
		else button:Hide() end
	end
	f.page:SetText(string.format("%d-%d / %d", f.offset + 1, math.min(f.offset + 8, table.getn(f.names)), table.getn(f.names)))
	local different = f.selected ~= self.profileName
	if different then f.use:Enable(); f.copy:Enable() else f.use:Disable(); f.copy:Disable() end
	if self:IsProfileInUse(f.selected) then f.delete:Disable() else f.delete:Enable() end
end

function NotGrid:ShowProfiles()
	if self.profileInitializationPending then
		self:InitializeProfiles()
		if self.profileInitializationPending then return end
	end
	local f = NotGridProfilesPanel
	if not f then
		f = CreateFrame("Frame", "NotGridProfilesPanel", UIParent)
		f:SetWidth(500)
		f:SetHeight(520)
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		f:SetFrameStrata("DIALOG")
		f:SetClampedToScreen(true)
		if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "NotGridProfilesPanel") end
		f:EnableMouse(true)
		f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
		f:SetBackdropColor(0, 0, 0, 1)
		local function label(text, x, y, width, height, font)
			local fs = f:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
			fs:SetPoint("TOPLEFT", x, y)
			fs:SetWidth(width)
			fs:SetHeight(height)
			fs:SetJustifyH("LEFT")
			fs:SetText(text)
			return fs
		end
		local function button(name, text, x, y, width, action)
			local b = CreateFrame("Button", "$parent" .. name, f, "UIPanelButtonTemplate")
			b:SetWidth(width)
			b:SetHeight(24)
			b:SetPoint("TOPLEFT", x, y)
			b:SetText(text)
			b:SetScript("OnClick", action)
			return b
		end
		label(L["Profiles"], 14, -14, 420, 24, "GameFontNormalLarge")
		f.current = label("", 14, -44, 464, 32, "GameFontNormal")
		label(L["Use Profile shares settings. Copy From makes an independent copy into your current profile. Changes apply after a UI reload."], 14, -80, 464, 38)
		local close = CreateFrame("Button", "$parentClose", f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", 0, 0)
		close:SetScript("OnClick", function() f:Hide() end)
		f.rows = {}
		for i = 1, 8 do
			local row = CreateFrame("Button", "$parentRow" .. i, f)
			row:SetWidth(432)
			row:SetHeight(24)
			row:SetPoint("TOPLEFT", 14, -126 - (i - 1) * 24)
			row:SetHighlightTexture("Interface/Buttons/UI-Listbox-Highlight", "ADD")
			row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			row.text:SetPoint("LEFT", 0, 0)
			row.text:SetWidth(426)
			row.text:SetHeight(20)
			row.text:SetJustifyH("LEFT")
			row:SetScript("OnClick", function()
				f.selected = this.profile
				f.status:SetText("")
				self:RefreshProfilesPanel()
			end)
			f.rows[i] = row
		end
		local function scroll(amount)
			f.offset = f.offset + amount
			self:RefreshProfilesPanel()
		end
		button("Up", "^", 458, -126, 24, function() scroll(-8) end)
		button("Down", "v", 458, -294, 24, function() scroll(8) end)
		f:EnableMouseWheel(true)
		f:SetScript("OnMouseWheel", function() scroll(-arg1) end)
		f.page = label("", 14, -322, 420, 18)
		f.use = button("Use", L["Use Profile"], 14, -350, 144, function()
			local ok,message = self:UseProfile(f.selected)
			if not ok then f.status:SetText(message) end
		end)
		f.copy = button("Copy", L["Copy From"], 174, -350, 144, function() self:ConfirmProfileAction("copy", f.selected) end)
		f.delete = button("Delete", L["Delete Profile"], 334, -350, 144, function() self:ConfirmProfileAction("delete", f.selected) end)
		label(L["New profile name"], 14, -390, 460, 20)
		f.edit = CreateFrame("EditBox", "$parentName", f, "InputBoxTemplate")
		f.edit:SetFontObject("GameFontHighlightSmall")
		f.edit:SetWidth(266)
		f.edit:SetHeight(24)
		f.edit:SetPoint("TOPLEFT", 20, -414)
		f.edit:SetAutoFocus(false)
		f.edit:SetMaxLetters(80)
		local function create()
			local ok,message = self:CreateProfile(f.edit:GetText())
			if not ok then f.status:SetText(message) end
		end
		button("Create", L["Create From Current"], 304, -414, 174, create)
		f.edit:SetScript("OnEnterPressed", create)
		f.edit:SetScript("OnEscapePressed", function() f.edit:ClearFocus() end)
		button("Reset", L["Reset Current Profile"], 14, -480, 174, function() self:ConfirmProfileAction("reset") end)
		f.status = label("", 204, -454, 274, 52)
		f:SetScript("OnHide", function() f.edit:ClearFocus() end)
	end
	f.selected, f.offset = self.profileName, 0
	f.edit:SetText("")
	f.status:SetText("")
	self:RefreshProfilesPanel()
	f:Show()
end

function NotGrid:RestoreProfilePosition()
	self.Container:ClearAllPoints()
	self.Container:SetPoint(self.o.containerpoint, self.o.containeroffx, self.o.containeroffy)
end

function NotGrid:SaveProfilePosition()
	local x,y = self.Container:GetCenter()
	local centerX,centerY = UIParent:GetCenter()
	if x and y and centerX and centerY then
		self.o.containerpoint = "CENTER"
		self.o.containeroffx, self.o.containeroffy = x - centerX, y - centerY
	end
end

function NotGrid:ConfirmProfileAction(action, name)
	if self.profileInitializationPending then
		self:InitializeProfiles()
		if self.profileInitializationPending then return end
	end
	if action ~= "copy" and action ~= "reset" and action ~= "delete" then return end
	if action ~= "reset" and type(name) ~= "string" then return end
	self.pendingProfileAction = {action = action, name = name}
	StaticPopupDialogs.NOTGRID_PROFILE_CONFIRM = {
		text = "%s", button1 = L["Confirm"], button2 = L["Cancel"],
		timeout = 0, whileDead = 1, hideOnEscape = 1,
		OnAccept = function()
			local pending = self.pendingProfileAction
			self.pendingProfileAction = nil
			if not pending then return end
			local ok,message
			if pending.action == "copy" then ok,message = self:CopyFromProfile(pending.name)
			elseif pending.action == "reset" then ok,message = self:ResetProfile()
			else ok,message = self:DeleteProfile(pending.name) end
			if NotGridProfilesPanel then
				NotGridProfilesPanel.status:SetText(message or "")
				self:RefreshProfilesPanel()
			end
		end,
		OnCancel = function() self.pendingProfileAction = nil end,
	}
	local message
	if action == "copy" then message = string.format(L["Copy '%s' over current profile '%s'? Characters using the current profile will also receive these settings."], name, self.profileName)
	elseif action == "reset" then message = string.format(L["Reset profile '%s' to defaults? Characters using this profile will also be affected."], self.profileName)
	else message = string.format(L["Delete unused profile '%s'?"], name) end
	StaticPopup_Show("NOTGRID_PROFILE_CONFIRM", message)
end
