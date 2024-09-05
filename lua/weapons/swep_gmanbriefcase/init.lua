AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("vgui.lua")
include("shared.lua")

local gman = GMANBF

local noclip = CreateConVar("gman_noclip", "0", {FCVAR_ARCHIVE}, "0=Collisions while Teleporting, 1=Noclipping", 0, 2)
gman.CV_Noclip = noclip

local DoorSounds = {
	"ambient/alarms/train_horn_distant1.wav",
	"ambient/alarms/apc_alarm_pass1.wav",
	"ambient/alarms/manhack_alert_pass1.wav",
	"ambient/alarms/scanner_alert_pass1.wav"
}

function SWEP:Deploy()
	if self.Mode then
		self:GetOwner():ChatPrint("Current Mode: [" .. self.Mode .. "] " .. self.Modes[self.Mode])
	end
end

GMAN = {}
// Helper functions
GMAN.DoGhostDoor()

local enterfunc = function(owner, type)
	local tr = util.QuickTrace(owner:GetPos() + Vector(0, 0, 5), Angle(0, owner:EyeAngles().y, 0):Forward() * 60, function() return false end)
	local a = ents.Create("anim_gmantele")
	a:SetPos(owner:GetPos())
	a:SetModel(owner:GetModel())
	a:SetPlayerColor(owner:GetPlayerColor())

	for k, v in pairs(owner:GetBodyGroups()) do
		a:SetBodygroup(v.id, owner:GetBodygroup(v.id))
	end
	a:SetSkin(owner:GetSkin())

	math.randomseed(SysTime() + a:GetCreationID())
	local snd = math.random(1, 20)

	if DoorSounds[snd] then
		a:EmitSound(DoorSounds[snd], 65, 96, 1, CHAN_AUTO, SND_NOFLAGS, 133)
	end

	if type then a:SetBriefType(type) end

	if tr.Hit then
		a:SetAngles(Angle(0, (-tr.HitNormal):Angle().y, 0))
	else
		a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
	end
	a:Spawn()

	owner:SetNWEntity("GMAN_ANIM", a)
	owner:Flashlight(false)
	EnableNoclip(owner)

	timer.Simple(4, function()
		if IsValid(a) and IsValid(owner) then
			owner:SetNWEntity("GMAN_ANIM", NULL)
			owner:SetEyeAngles(a:GetAngles())
			SafeRemoveEntityDelayed(a, 4)
		end
	end)

	return true
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
	if not IsValid(owner) then return end
	if owner:GetNWBool("GMAN_BF") then
		if not IsValid(self:GetDoor()) then return end
		owner:SetPos(self:GetDoor().interior:GetPos() - Vector(0, 0, 32))
		self:GetDoor():PlayerEnter(owner, true)
		return
	end
	if self.Mode == 0 then
		self.LastGoodPos = owner:GetPos()

		if enterfunc(owner, self.BriefType) then
			self:SetNextSecondaryFire(CurTime() + 4)
			self:SetNextPrimaryFire(CurTime() + 5)
		end
		owner:ChatPrint("\nLeft Click - Teleport to White Room (If Available) / Reload - Teleport to Exit Door / Right Click - Reappear")
	elseif self.Mode == 1 then
		self:SetHoldType("melee")
		timer.Simple(0.1, function()
			owner:SetAnimation(PLAYER_ATTACK1)
		end)
		timer.Create("gman_resetholdtype_" .. owner:EntIndex(), 0.7, 1, function()
			if not IsValid(self) then return end
			self:SetHoldType("normal")
		end)
		owner:ViewPunch(Angle(5, 1, 0))

		local tr = util.QuickTrace(owner:GetShootPos(), owner:GetAimVector() * 100, owner)
		if tr.Hit then
			local melee = {
				Attacker = owner,
				Damage = 50,
				Force = 20,
				Distance = 110,
				HullSize = 1,
				Src = owner:GetShootPos(),
				Dir = owner:GetAimVector(),
				Num = 1,
				Spread = Vector(0, 0, 0)
			}
			self:FireBullets(melee)
			owner:EmitSound(self.Hit)
			if IsValid(tr.Entity) then
				owner:EmitSound("npc/zombie/claw_strike3")
			end
		else
			owner:EmitSound(self.Miss)
		end
	elseif self.Mode == 2 then
		self:SetNextSecondaryFire(CurTime() + 1)
		local tr = util.QuickTrace(owner:GetShootPos(), owner:GetAimVector() * 500, owner)
		if not IsValid(self:GetDoor()) and tr.Hit and tr.HitWorld and tr.HitNormal:IsEqualTol(Vector(0, 0, 1), 0.5) then
			local door = ents.Create("gman_exterior")
			local pos = tr.HitPos + tr.HitNormal * 2
			door:SetAngles(Angle(0, (owner:GetPos() - pos):Angle().y, 0))
			door:SetPos(pos)
			Doors:SetupOwner(door, owner)
			door:Spawn()
			door:Activate()
			door:SetOpen(true)
			self:SetDoor(door)
			self:DeleteOnRemove(door)
			owner:ChatPrint("Door Opened")
			door:EmitSound("doors/metal_move1.wav")
		elseif IsValid(self:GetDoor()) then
			local door = self:GetDoor()
			door:SetOpen(not door:GetOpen())
			if door:GetOpen() then
				door:EmitSound("doors/metal_move1.wav")
				door.interior:GetChildren()[1]:EmitSound("doors/metal_move1.wav")
				owner:ChatPrint("Door Opened")
			else
				door:EmitSound("doors/door_metal_rusty_move1.wav")
				door.interior:GetChildren()[1]:EmitSound("doors/door_metal_rusty_move1.wav")
				owner:ChatPrint("Door Closed")
			end
		end
	end
end

local exitfunc = function(owner, type)
	local tr = util.QuickTrace(owner:EyePos(), Angle(0, owner:EyeAngles().y, 0):Forward() * 60, {owner})
	if tr.Hit then return end
	tr = util.QuickTrace(owner:EyePos(), -owner:GetUp() * 200, {owner})

	local a = ents.Create("anim_gmantele_ex")
	a:SetPos(tr.Hit and tr.HitPos + Vector(0, 0, 0.5) or owner:GetPos())
	a:SetModel(owner:GetModel())
	a:SetPlayerColor(owner:GetPlayerColor())

	for k, v in pairs(owner:GetBodyGroups()) do
		a:SetBodygroup(v.id, owner:GetBodygroup(v.id))
	end
	a:SetSkin(owner:GetSkin())

	math.randomseed(CurTime() + a:GetCreationID())
	local snd = math.random(1, 20)

	if DoorSounds[snd] then
		a:EmitSound(DoorSounds[snd], 65, 96, 1, CHAN_AUTO, SND_NOFLAGS, 133)
	end

	if type then a:SetBriefType(type) end

	a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
	a:Spawn()

	owner:SetNWEntity("GMAN_ANIM", a)

	timer.Simple(2.8, function()
		if IsValid(a) and IsValid(owner) then
			owner:SetPos(a:GetPos())
			owner:SetEyeAngles(a:GetAngles())
		end
	end)

	timer.Simple(3, function()
		if IsValid(a) and IsValid(owner) then
			owner:SetNWEntity("GMAN_ANIM", NULL)
			DisableNoclip(owner)

			owner:SetPos(a:GetPos())
			owner:SetEyeAngles(a:GetAngles())
			SafeRemoveEntityDelayed(a, 2)
		end
	end)
	return true
end

function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
	if not IsValid(owner) then return end
	if self.Mode == 0 then
		if not owner:GetNWBool("GMAN_BF") then return end
		self.LastGoodPos = owner:GetPos()

		if exitfunc(owner, self.BriefType) then
			self:SetNextSecondaryFire(CurTime() + 6)
			self:SetNextPrimaryFire(CurTime() + 6)
		end
	elseif self.Mode == 1 then
		self:SetHoldType("melee")
		timer.Simple(0.1, function()
			owner:SetAnimation(PLAYER_ATTACK1)
		end)
		timer.Create("gman_resetholdtype_" .. owner:EntIndex(), 0.7, 1, function()
			if not IsValid(self) then return end
			self:SetHoldType("normal")
		end)

		owner:ViewPunch(Angle(9, 1, 0))

		local tr = util.QuickTrace(owner:GetShootPos(), owner:GetAimVector() * 100, owner)
		if tr.Hit then
			local melee = {
				Attacker = owner,
				Damage = 500,
				Force = 999,
				Distance = 110,
				HullSize = 1,
				Src = owner:GetShootPos(),
				Dir = owner:GetAimVector(),
				Num = 1,
				Spread = Vector(0, 0, 0)
			}
			self:FireBullets(melee)
			owner:EmitSound(self.Hit)
			if IsValid(tr.Entity) then
				owner:EmitSound("npc/zombie/claw_strike1.wav")
			end
		else
			owner:EmitSound(self.MissSecond)
		end
	elseif self.Mode == 2 then
		self:SetNextPrimaryFire(CurTime() + 0.2)
		self:SetNextSecondaryFire(CurTime() + 0.2)
		local tr = util.QuickTrace(owner:GetShootPos(), owner:GetAimVector() * 1000, owner)
		if not tr.Hit or not tr.HitNormal:IsEqualTol(Vector(0, 0, 1), 0.5) then return end
		if not tr.HitWorld and (not IsValid(tr.Entity) or IsValid(tr.Entity) and tr.Entity:GetClass() ~= "gman_interior" or tr.Entity.exterior == self:GetDoor()) then return end

		if not IsValid(self:GetDoor()) then
			local door = ents.Create("gman_exterior")
			local pos = tr.HitPos + tr.HitNormal * 2
			door:SetAngles(Angle(0, (owner:GetPos() - pos):Angle().y, 0))
			door:SetPos(pos)
			Doors:SetupOwner(door, owner)
			self:DeleteOnRemove(door)
			door:Spawn()
			door:Activate()
			self:SetDoor(door)
			owner:ChatPrint("Door Position Set!")
		else
			local door = self:GetDoor()
			if door:GetOpen() then
				owner:ChatPrint("Door Must Be Closed!")
				return
			end
			local pos = tr.HitPos + tr.HitNormal * 2
			door:SetAngles(Angle(0, (owner:GetPos() - pos):Angle().y, 0))
			door:SetPos(pos)
			owner:ChatPrint("Door Position Set!")
		end
	end
end

function SWEP:OnDrop()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:Alive() and owner:GetNWBool("GMAN_BF") then
		owner:SetNWEntity("GMAN_ANIM", NULL)
		DisableNoclip(owner)
		owner:SetPos(self.LastGoodPos or owner:GetPos())
	end
end

SWEP.Modes = {
	[1] = "Ghost Self (Left Click - Disappear / Right Click - Reappear)",
	[2] = "Attack (Left Click & Right Click - Melee Attack)",
	[3] = "White Room Portal (Left Click - Open & Cloor Door / Right Click - Set Door Entrance)",
	[4] = "Linked Doors (Left Click - Set Door 1 / Right Click - Set Door 2 / Alt - Open & Close Doors)"
}

if not wp then
	SWEP.Modes[2] = nil
	SWEP.Modes[3] = nil
end

function SWEP:Reload()
	local owner = self:GetOwner()
	if not IsValid(owner) or self.NextMode and self.NextMode > CurTime() then return end

	if owner:GetNWBool("GMAN_BF") then
		if not IsValid(self:GetDoor()) then return end
		owner:SetPos(self:GetDoor():GetPos())
		self:GetDoor():PlayerExit(owner, true)
		self.NextMode = CurTime() + 4
		return
	end

	self.Mode = self.Mode + 1
	if not self.Modes[self.Mode] then
		self.Mode = 0
	end
	self:SetMode(self.Mode)
	self:GetOwner():ChatPrint("Mode set to: [" .. self.Mode .. "] " .. self.Modes[self.Mode])
	self.NextMode = CurTime() + 0.5
end

function SWEP:OnRemove()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:Alive() and owner:GetNWBool("GMAN_BF") then
		owner:SetNWEntity("GMAN_ANIM", NULL)
		DisableNoclip(owner)
		owner:SetPos(self.LastGoodPos or owner:GetPos())
	end
end

hook.Add("PlayerSpawn", "GMAN_SPAWN", function(ply)
	ply:SetNWEntity("GMAN_ANIM", NULL)
	DisableNoclip(ply)
end)