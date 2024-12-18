AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("vgui.lua")
AddCSLuaFile("meta.lua")
include("shared.lua")
include("meta.lua")

//local noclip = SWEP.CV_Noclip

function SWEP:Deploy()
	if self.Mode then
		self:GetOwner():ChatPrint("Current Mode: [" .. self.Mode .. "] " .. (self.Modes[self.Mode] or "UNK"))
	end
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
	if self.Mode == 1 then
		self.LastGoodPos = owner:GetPos()

		if self:DoPlayerGhostDoor(owner, false, self.BriefType) then
			self:SetNextSecondaryFire(CurTime() + 4)
			self:SetNextPrimaryFire(CurTime() + 5)
		end
		owner:ChatPrint("\nLeft Click - Teleport to White Room (If Available) / Reload - Teleport to Exit Door / Right Click - Reappear")
	elseif self.Mode == 2 then
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
	elseif self.Mode == 3 then
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

function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
	if not IsValid(owner) then return end
	if self.Mode == 1 then
		if not owner:GetNWBool("GMAN_BF") then return end
		self.LastGoodPos = owner:GetPos()

		if self:DoPlayerGhostDoor(owner, true, self.BriefType) then
			self:SetNextSecondaryFire(CurTime() + 6)
			self:SetNextPrimaryFire(CurTime() + 6)
		end
	elseif self.Mode == 2 then
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
	elseif self.Mode == 3 then
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
		self.NoclipPlayer(owner, false)
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
		self.Mode = 1
	end
	self:SetMode(self.Mode)
	self:GetOwner():ChatPrint("Mode set to: [" .. self.Mode .. "] " .. self.Modes[self.Mode])
	self.NextMode = CurTime() + 0.5
end

function SWEP:OnRemove()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:Alive() and owner:GetNWBool("GMAN_BF") then
		owner:SetNWEntity("GMAN_ANIM", NULL)
		self.NoclipPlayer(owner, false)
		owner:SetPos(self.LastGoodPos or owner:GetPos())
	end
end

local NoclipPlayer = SWEP.NoclipPlayer
hook.Add("PlayerSpawn", "GMAN_SPAWN", function(ply)
	ply:SetNWEntity("GMAN_ANIM", NULL)
	NoclipPlayer(ply, false)
end)