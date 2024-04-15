SWEP.PrintName 		= "Gman (Hands Teleporting Only)"

SWEP.Author 		= "Axel"
SWEP.Instructions 	= "Left Click - Disappear / Right Click - Reappear"
SWEP.Purpose 		= "why do you need this? is it a lore reason? are you stu-"
SWEP.Category		= "Gman Briefcase"

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.ViewModel = "models/weapons/v_hands.mdl"
SWEP.WorldModel = "models/weapons/w_suitcase_passenger.mdl"
SWEP.Slot = 4
SWEP.SlotPos = 6

SWEP.Base = "swep_gmanbriefcase"

function SWEP:Initialize()
	self:SetHoldType("normal")
	self:SetNextPrimaryFire(CurTime() + 0.5)
end

if CLIENT then
	function SWEP:DrawWorldModel(flags)
	end
elseif SERVER then
	local function EnableNoclip(ply)
		ply:SetNWBool("GMAN_BF", true)
		ply:SetNoDraw(true)
		ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		ply:SetNoTarget(true)
		ply.GMAN_AP = ply:GetAvoidPlayers()
		ply:SetAvoidPlayers(false)
	end

	local function DisableNoclip(ply)
		if ply:GetNWBool("GMAN_BF") then
			ply:SetNoDraw(false)
			ply:SetCollisionGroup(COLLISION_GROUP_NONE)
			ply:SetNoTarget(false)
			ply:SetAvoidPlayers(ply.GMAN_AP or true)
		end
		ply:SetNWBool("GMAN_BF", false)
	end

	function SWEP:PrimaryAttack()
		local owner = self:GetOwner()
		if not IsValid(owner) or owner:GetNWBool("GMAN_BF") then return end
		self:SetNextPrimaryFire(CurTime() + 3)
		self.LastGoodPos = owner:GetPos()

		local tr = util.QuickTrace(owner:GetPos() + Vector(0, 0, 5), Angle(0, owner:EyeAngles().y, 0):Forward() * 60, function() return false end)
		local a = ents.Create("anim_gmantele")
		a:SetPos(owner:GetPos())
		a:SetModel(owner:GetModel())
		a:SetPlayerColor(owner:GetPlayerColor())
		a:SetNoBrief(true)

		for k, v in pairs(owner:GetBodyGroups()) do
			a:SetBodygroup(v.id, owner:GetBodygroup(v.id))
		end
		a:SetSkin(owner:GetSkin())

		if tr.Hit then
			a:SetAngles(Angle(0, (-tr.HitNormal):Angle().y, 0))
		else
			a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		end
		a:Spawn()

		owner:SetNWEntity("GMAN_ANIM", a)
		owner:Flashlight(false)
		EnableNoclip(owner)

		timer.Simple(3, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetPos(a:GetPos())
				owner:SetNWEntity("GMAN_ANIM", NULL)
				SafeRemoveEntityDelayed(a, 4)
			end
		end)

		self:SetNextSecondaryFire(CurTime() + 8)
		self:SetNextPrimaryFire(CurTime() + 8)
	end

	function SWEP:SecondaryAttack()
		local owner = self:GetOwner()
		if not IsValid(owner) or not owner:GetNWBool("GMAN_BF") then return end
		self:SetNextSecondaryFire(CurTime() + 3)

		local tr = util.QuickTrace(owner:EyePos(), Angle(0, owner:EyeAngles().y, 0):Forward() * 60, {owner})
		if tr.Hit then return end
		tr = util.QuickTrace(owner:EyePos(), -owner:GetUp() * 128, {owner})
		self.LastGoodPos = owner:GetPos()

		local a = ents.Create("anim_gmantele_ex")
		a:SetPos(tr.Hit and tr.HitPos + Vector(0, 0, 0.5) or owner:GetPos())
		a:SetModel(owner:GetModel())
		a:SetPlayerColor(owner:GetPlayerColor())
		a:SetNoBrief(true)

		for k, v in pairs(owner:GetBodyGroups()) do
			a:SetBodygroup(v.id, owner:GetBodygroup(v.id))
		end
		a:SetSkin(owner:GetSkin())

		a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		a:Spawn()

		owner:SetNWEntity("GMAN_ANIM", a)

		timer.Simple(3.8, function()
			if IsValid(a) and IsValid(owner) and IsValid(self) then
				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
			end
		end)

		timer.Simple(4, function()
			if IsValid(a) and IsValid(owner) and IsValid(self) then
				owner:SetNWEntity("GMAN_ANIM", NULL)
				DisableNoclip(owner)

				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
				SafeRemoveEntityDelayed(a, 2)
			end
		end)

		self:SetNextSecondaryFire(CurTime() + 8)
		self:SetNextPrimaryFire(CurTime() + 8)
	end
end