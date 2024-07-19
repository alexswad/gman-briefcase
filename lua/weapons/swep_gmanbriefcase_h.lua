SWEP.PrintName 		= "G-Man Hands"

SWEP.Author 		= "Axel"
SWEP.Instructions 	= "Left Click - Disappear / Right Click - Reappear"
SWEP.Purpose 		= ""
SWEP.Category		= "G-Man Briefcase"

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.ViewModel = "models/weapons/v_hands.mdl"
SWEP.WorldModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"
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
	local noclip
	local function EnableNoclip(ply)
		noclip = noclip or GetConVar("gman_noclip")
		if noclip:GetBool() then
			ply:SetMoveType(MOVETYPE_NOCLIP)
		end
		ply:SetNWBool("GMAN_BF", true)
		ply:SetNoDraw(true)
		ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		ply:SetNoTarget(true)
		ply.GMAN_AP = ply:GetAvoidPlayers()
		ply:SetAvoidPlayers(false)
	end

	local function DisableNoclip(ply)
		if ply:GetNWBool("GMAN_BF") then
			ply:SetNoDraw(false)
			ply:SetMoveType(MOVETYPE_WALK)
			ply:SetCollisionGroup(COLLISION_GROUP_NONE)
			ply:SetNoTarget(false)
			ply:SetAvoidPlayers(ply.GMAN_AP or true)
		end
		ply:SetNWBool("GMAN_BF", false)
	end

	local enterfunc = function(owner)
		local tr = util.QuickTrace(owner:GetPos() + Vector(0, 0, 5), Angle(0, owner:EyeAngles().y, 0):Forward() * 60, function() return false end)
		local a = ents.Create("anim_gmantele")
		a:SetPos(owner:GetPos())
		a:SetModel(owner:GetModel())
		a:SetPlayerColor(owner:GetPlayerColor())
		a:SetBriefType(1)

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
		if not IsValid(owner) or owner:GetNWBool("GMAN_BF") then return end
		self.LastGoodPos = owner:GetPos()

		if enterfunc(owner) then
			self:SetNextSecondaryFire(CurTime() + 6)
			self:SetNextPrimaryFire(CurTime() + 6)
		end
	end

	local exitfunc = function(owner)
		local tr = util.QuickTrace(owner:EyePos(), Angle(0, owner:EyeAngles().y, 0):Forward() * 60, {owner})
		if tr.Hit then return end
		tr = util.QuickTrace(owner:EyePos(), -owner:GetUp() * 128, {owner})

		local a = ents.Create("anim_gmantele_ex")
		a:SetPos(tr.Hit and tr.HitPos + Vector(0, 0, 0.5) or owner:GetPos())
		a:SetModel(owner:GetModel())
		a:SetPlayerColor(owner:GetPlayerColor())
		a:SetBriefType(1)

		for k, v in pairs(owner:GetBodyGroups()) do
			a:SetBodygroup(v.id, owner:GetBodygroup(v.id))
		end
		a:SetSkin(owner:GetSkin())

		a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		a:Spawn()

		owner:SetNWEntity("GMAN_ANIM", a)

		timer.Simple(3.2, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
			end
		end)

		timer.Simple(3.5, function()
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
		self:SetNextSecondaryFire(CurTime() + 0.5)
		if not IsValid(owner) or not owner:GetNWBool("GMAN_BF") then return end
		self.LastGoodPos = owner:GetPos()

		if exitfunc(owner) then
			self:SetNextSecondaryFire(CurTime() + 6)
			self:SetNextPrimaryFire(CurTime() + 6)
		end
	end

	local admin = CreateConVar("gman_admin", "2", {FCVAR_ARCHIVE}, "0=Everyone, 1=Admins, 2=Superadmins", 0, 2)
	concommand.Add("gman_enter", function(ply)
		if not IsValid(ply) or ply:GetNWBool("GMAN_BF") then return end
		if admin:GetInt() == 2 and not ply:IsSuperAdmin() or admin:GetInt() == 1 and not ply:IsAdmin() then return end
		enterfunc(ply)
	end)

	concommand.Add("gman_exit", function(ply)
		if not IsValid(ply) or not ply:GetNWBool("GMAN_BF") then return end
		if admin:GetInt() == 2 and not ply:IsSuperAdmin() or admin:GetInt() == 1 and not ply:IsAdmin() then return end
		exitfunc(ply)
	end)

	function SWEP:Reload()
	end
end