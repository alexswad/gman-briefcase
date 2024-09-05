DEFINE_BASECLASS("DFrame")

local PANEL = {}

local FrameBackColor = Color(0, 0, 0, 220)
function PANEL:Paint(w, h)
	draw.RoundedBox(4, 0, 0, w, h, FrameBackColor)
end

local DFormPaint = function(p, w, h)
	BaseClass.Paint(p, w , h)
end

function PANEL:Init()
	self:SetSize(600, 575)
	self:Center()
	self:MakePopup()
	self:SetTitle("Gman Briefcase")
	self:SetSizable(true)

	local modes = vgui.Create("DForm", self)
	self.ModeForm = modes
	modes:DockMargin(5, 5, 5, 0)
	modes:SetHeight(100)
	modes:Dock(TOP)
	modes:SetLabel("Weapon Mode")
	modes.Paint = DFormPaint

	self:CreateModeButtons({"Attack", "Noclip (Door)", "Noclip (Fade Away)", "Dimension Portal", "Linked Portals", "Teleport Player"})

	local options = vgui.Create("DForm", self)
	self.Options = options
	options:DockMargin(5, 5, 5, 0)
	local pad = {options:GetDockPadding()}
	pad[4] = 5
	options:DockPadding(unpack(pad))
	options:SetHeight(300)
	options:Dock(TOP)
	options:SetLabel("Weapon Options")
	options.Paint = DFormPaint

	///

	local god = options:CheckBox("Enable Godmode")
	god:SetDark(false)
	local vm = options:CheckBox("Disable Viewmodel", "cl_gman_disablevm")
	vm:SetDark(false)
	local pm = options:CheckBox("Change Playermodel to GMan")
	pm:SetDark(false)
	local save = options:CheckBox("Keep Dimensions after Weapon Removal")
	save:SetDark(false)

	local model, mlbl = options:ComboBox("Weapon Model")
	model:AddChoice("Citizen Suitcase", 1)
	if util.IsValidModel("models/gman_briefcase.mdl") then model:AddChoice("GMan Briefcase", 3) end
	if util.IsValidModel("models/sketchfab/quaz30/g_man_briefcase/skf_g_man_briefcase.mdl") then model:AddChoice("Black Mesa Briefcase", 4) end
	model:AddChoice("None", 2)
	mlbl:SetDark(false)

	self.Save = save
	self.PM = pm
	self.God = god
	self.Model = model
	self.Clear = clear

	///

	local slots = vgui.Create("DForm", self)
	self.Slots = slots
	slots:SetHeight(100)
	slots:Dock(TOP)
	slots:DockMargin(5, 5, 5, 0)
	slots:SetLabel("Portal Slots For Current Mode")
	slots.Paint = DFormPaint

	self:CreateSlotButtons(true)
end

function PANEL:CreateModeButtons(modes)
	self.Modes = modes

	local parent = vgui.Create("DPanel", self)
	self.ModeButtons = parent
	parent:SetHeight(100)
	parent:Dock(TOP)
	parent:DockMargin(0, 0, 0, 10)
	parent:DockPadding(0, 0, 0, 0)
	parent.Paint = function() end

	local mf = self.ModeForm
	for k, v in pairs(modes) do
		local button = vgui.Create("DButton", parent, "mode-button")
		button:SetText(v)
		button:Dock(LEFT)
		button:DockMargin(5, 5, 5, 10)
		button.ModeNumber = k
		function button:DoClick()
			/*net.Start("GMAN_MODE")
				net.WriteUInt(k, 3)
			net.SendToServer()*/
		end
	end
	mf:AddItem(parent)
	self:InvalidateLayout()
end

function PANEL:CreateSlotButtons(do_dim)
	local sf = self.Slots
	sf:Clear()

	sf:Help("Left Click Select / Right Click Clear"):SetDark(false)

	local slots = vgui.Create("DPanel", self)
	self.SlotButtons = slots
	slots:SetHeight(100)
	slots:Dock(TOP)
	slots:DockMargin(0, 0, 0, 0)
	slots:DockPadding(0, 0, 0, 0)
	slots.Paint = function() end

	for i = 1, 5, 1 do
		local button = vgui.Create("DButton", slots, "slot-button")
		button:SetText("Portal " .. i)
		button:Dock(LEFT)
		button:DockMargin(5, 5, 5, 10)
		button.SlotNumber = i
		function button:DoClick()

		end
	end
	sf:AddItem(slots)

	if not do_dim then return end

	local dim = vgui.Create("DPanel", self)
	self.DimButtons = dim
	dim:SetHeight(100)
	dim:Dock(TOP)
	dim:DockMargin(0, 0, 0, 5)
	dim:DockPadding(0, 0, 0, 0)
	dim.Paint = function() end

	for i = 1, 3, 1 do
		local button = vgui.Create("DButton", dim, "dim-button")
		button:SetText("Dimension " .. i)
		button:Dock(LEFT)
		button:DockMargin(5, 5, 5, 10)
		button.DimNumber = i
		function button:DoClick()

		end
	end
	sf:AddItem(dim)
end

function PANEL:PerformLayout(w, h)
	BaseClass.PerformLayout(self, w, h)
	local mb = self.ModeButtons
	if IsValid(mb) then
		mb:SetHeight(100)
		local children = mb:GetChildren()
		local count = table.Count(children)
		if w > 350 then
			for k, button in pairs(children) do
				button:Dock(LEFT)
				button:DockMargin(5, 5, 5, 10)
				button:SetWide((mb:GetWide() - 10 * count ) / count)
			end
		else
			local last
			for k, button in pairs(children) do
				last = button
				button:Dock(TOP)
				button:DockMargin(5, 5, 5, 5)
				button:SetTall(23)
			end
			mb:SetTall(select(2, last:GetPos()) + last:GetTall() + 10)
		end
	end

	local sb = self.SlotButtons
	if IsValid(sb) then
		sb:SetHeight(100)
		local children = sb:GetChildren()
		local count = table.Count(children)
		if w > 350 then
			for k, button in pairs(children) do
				button:Dock(LEFT)
				button:DockMargin(5, 5, 5, 5)
				button:SetWide((sb:GetWide() - 10 * count ) / count)
			end
		else
			local last
			for k, button in pairs(children) do
				last = button
				button:Dock(TOP)
				button:DockMargin(5, 5, 5, 5)
				button:SetTall(23)
			end
			sb:SetTall(select(2, last:GetPos()) + last:GetTall() + 10)
		end
	end

	local db = self.DimButtons
	if IsValid(db) then
		db:SetHeight(100)
		local children = db:GetChildren()
		local count = table.Count(children)
		if w > 350 then
			for k, button in pairs(children) do
				button:Dock(LEFT)
				button:DockMargin(5, 0, 5, 10)
				button:SetWide((db:GetWide() - 10 * count ) / count)
			end
		else
			local last
			for k, button in pairs(children) do
				last = button
				button:Dock(TOP)
				button:DockMargin(5, 5, 5, 5)
				button:SetTall(23)
			end
			db:SetTall(select(2, last:GetPos()) + last:GetTall() + 10)
		end
	end

	if IsValid(self.Slots) then
		self:SetHeight(select(2, self.Slots:GetPos()) + self.Slots:GetTall() + 20)
	end
end

vgui.Register("GmanBriefcase", PANEL, "DFrame")