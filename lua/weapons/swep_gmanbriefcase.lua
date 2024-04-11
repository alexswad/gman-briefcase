SWEP.PrintName 		= "Gman Briefcase"

SWEP.Author 		= "Axel"
SWEP.Instructions 	= "Left Click - Disappear / Right Click - Reappear"
SWEP.Purpose 		= "Its very heavy, almost like its filled with rocks."

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.ViewModel = "models/weapons/v_hands.mdl"
SWEP.WorldModel = "models/weapons/w_suitcase_passenger.mdl"
SWEP.Slot = 4
SWEP.SlotPos = 5

SWEP.Primary.Ammo = ""
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1

SWEP.Secondary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1

SWEP.BobScale = 2

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

function SWEP:Initialize()
	self:SetHoldType("normal")
	self:SetNextPrimaryFire(CurTime() + 0.5)
	if CLIENT and not IsValid(self.ClientModel) then
		self.ClientModel = ClientsideModel(self.WorldModel)
		self.ClientModel:SetNoDraw(true)
	end
end

local offsetVec = Vector(5, -1, 0)
local offsetAng = Angle(-90, 0, 0)
function SWEP:DrawWorldModel(flags)
	local _Owner = self:GetOwner()
	if (IsValid(_Owner) and not _Owner:GetNWBool("GMAN_BF")) then
		local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
		if not boneid then return end

		local matrix = _Owner:GetBoneMatrix(boneid)
		if not matrix then return end

		local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())

		self.ClientModel:SetPos(newPos)
		self.ClientModel:SetAngles(newAng)
		self.ClientModel:DrawModel()
	end

end

if CLIENT then
	function SWEP:OnRemove()
		self.ClientModel:Remove()
		timer.Simple(0.1, function()
			if not LocalPlayer():GetNWBool("GMAN_BF") and LocalPlayer().ColorMod then
				GetConVar("pp_colormod"):SetInt(0)
				LocalPlayer().ColorMod = nil
			end
		end)
	end

	function SWEP:PrimaryAttack()
	end

	function SWEP:SecondaryAttack()
	end

	function SWEP:Reload()
	end

	function SWEP:HUDShouldDraw( name )
		if LocalPlayer():GetNWBool("GMAN_BF") and not IsValid(LocalPlayer():GetNWEntity("GMAN_ANIM")) then
			if not LocalPlayer().ColorMod then
				GetConVar("pp_colormod"):SetInt(1)
				GetConVar("pp_colormod_addr"):SetInt(0)
				GetConVar("pp_colormod_addg"):SetInt(0)
				GetConVar("pp_colormod_addb"):SetInt(0)
				GetConVar("pp_colormod_brightness"):SetInt(0)
				GetConVar("pp_colormod_contrast"):SetInt(1)
				GetConVar("pp_colormod_color"):SetInt(0)
				GetConVar("pp_colormod_mulr"):SetInt(0)
				GetConVar("pp_colormod_mulg"):SetInt(0)
				GetConVar("pp_colormod_mulb"):SetInt(0)
				GetConVar("pp_colormod_inv"):SetInt(1)
				LocalPlayer().ColorMod = true
			end

			if ( name == "CHudChat" ) then return true end
			return false
		elseif LocalPlayer().ColorMod then
			GetConVar("pp_colormod"):SetInt(0)
			LocalPlayer().ColorMod = nil
		end
		return true
	end

	function SWEP:ShouldDrawViewModel()
		return false
	end

elseif SERVER then
	SWEP.DoorSounds = {
		"ambient/alarms/train_horn_distant1.wav",
		"ambient/alarms/apc_alarm_pass1.wav",
		"ambient/alarms/manhack_alert_pass1.wav",
		"ambient/alarms/scanner_alert_pass1.wav"
	}

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

		math.randomseed(SysTime() + a:GetCreationID())
		local snd = math.random(1, 20)

		if self.DoorSounds[snd] then
			a:EmitSound(self.DoorSounds[snd], 65, 96, 1, CHAN_AUTO, SND_NOFLAGS, 133)
		end

		if tr.Hit then
			a:SetAngles(Angle(0, (-tr.HitNormal):Angle().y, 0))
		else
			a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		end
		a:Spawn()

		owner:SetNWEntity("GMAN_ANIM", a)
		owner:SetNWBool("GMAN_BF", true)
		owner:SetNoDraw(true)
		owner:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		owner:SetMoveType(MOVETYPE_NOCLIP)

		timer.Simple(5.1, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetPos(a:GetPos())
				a:Remove()
				owner:SetNWEntity("GMAN_ANIM", NULL)
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
		tr = util.QuickTrace(owner:EyePos(), -owner:GetUp() * 80, {owner})
		self.LastGoodPos = owner:GetPos()

		local a = ents.Create("anim_gmantele_ex")
		a:SetPos(tr.Hit and tr.HitPos + Vector(0, 0, 0.5) or owner:GetPos())
		a:SetModel(owner:GetModel())
		a:SetPlayerColor(owner:GetPlayerColor())

		math.randomseed(CurTime() + a:GetCreationID())
		local snd = math.random(1, 20)

		if self.DoorSounds[snd] then
			a:EmitSound(self.DoorSounds[snd], 65, 96, 1, CHAN_AUTO, SND_NOFLAGS, 133)
		end

		a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		a:Spawn()

		owner:SetNWEntity("GMAN_ANIM", a)

		timer.Simple(5, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
			end
		end)

		timer.Simple(5.1, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetNWEntity("GMAN_ANIM", NULL)
				owner:SetNWBool("GMAN_BF", false)
				owner:SetNoDraw(false)
				owner:SetCollisionGroup(COLLISION_GROUP_NONE)
				owner:SetMoveType(MOVETYPE_WALK)

				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
				a:Remove()
				owner:SetNWEntity("GMAN_ANIM", NULL)
			end
		end)

		self:SetNextSecondaryFire(CurTime() + 8)
		self:SetNextPrimaryFire(CurTime() + 8)
	end

	function SWEP:OnDrop()
		local owner = self:GetOwner()
		if IsValid(owner) and owner:GetNWBool("GMAN_BF") then
			owner:SetNWEntity("GMAN_ANIM", NULL)
			owner:SetNWBool("GMAN_BF", false)
			owner:SetNoDraw(false)
			owner:SetCollisionGroup(COLLISION_GROUP_NONE)
			owner:SetMoveType(MOVETYPE_WALK)
			owner:SetPos(self.LastGoodPos or owner:GetPos())
		end
	end

	function SWEP:OnRemove()
		local owner = self:GetOwner()
		if IsValid(owner) and owner:GetNWBool("GMAN_BF") then
			owner:SetNWEntity("GMAN_ANIM", NULL)
			owner:SetNWBool("GMAN_BF", false)
			owner:SetNoDraw(false)
			owner:SetCollisionGroup(COLLISION_GROUP_NONE)
			owner:SetMoveType(MOVETYPE_WALK)
			owner:SetPos(self.LastGoodPos or owner:GetPos())
		end
	end
end

hook.Add("SetupMove","GMAN_BRIEFCASE_SPEED", function( ply, mv )
	if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "swep_gmanbriefcase" then
		mv:SetMaxClientSpeed(130)
	end
end)

hook.Add("StartCommand", "GMAN_BF", function(ply, ucmd)
	if IsValid(ply:GetNWEntity("GMAN_ANIM")) then
		ucmd:ClearMovement()
		ucmd:ClearButtons()
		return true
	end
end)

hook.Add("PlayerNoClip", "GMAN_NOCLIP", function(ply)
	if ply:GetNWBool("GMAN_BF") then return false end
end)

hook.Add("PlayerSwitchWeapon", "GMAN_SWITCHWEAPON", function(ply, oldweapon)
	if ply:GetNWBool("GMAN_BF") and oldweapon:GetClass() == "swep_gmanbriefcase" then return true end
end)

hook.Add("TranslateActivity", "GMAN_BRIEFCASE_SPEED_WALKANIM", function(ply, act)
	if act == ACT_MP_WALK and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "swep_gmanbriefcase" then
		return ACT_HL2MP_WALK_SUITCASE
	end
end)

hook.Add("CalcView", "GMAN_CALCVIEW", function(ply, origin, angles, fov)
	local ent = ply:GetNWEntity("GMAN_ANIM")
	if IsValid(ent) then
		local no = ent:GetPos()  + ply:GetForward() * 130
		return {
			origin = no + Vector(0, 0, 60),
			angles = (ent:GetPos() - no):Angle(),
			fov = fov,
			drawviewer = false,
			drawviewmodel = false,
		}
	end
end)