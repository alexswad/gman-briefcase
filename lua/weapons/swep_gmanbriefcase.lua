SWEP.PrintName 		= "Gman Briefcase"

SWEP.Author 		= "Axel"
SWEP.Instructions 	= "Left Click - Disappear / Right Click - Reappear"
SWEP.Purpose 		= "Its very heavy, almost like its filled with rocks."

SWEP.Spawnable = true
SWEP.AdminOnly = false
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
	local owner = self:GetOwner()
	if IsValid(owner) and not owner:GetNWBool("GMAN_BF") then
		local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
		if not boneid then return end

		local matrix = owner:GetBoneMatrix(boneid)
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
	end

	function SWEP:PrimaryAttack()
	end

	function SWEP:SecondaryAttack()
	end

	function SWEP:Reload()
	end

	function SWEP:HUDShouldDraw( name )
		if LocalPlayer():GetNWBool("GMAN_BF") then
			if ( name == "CHudChat" ) then return true end
			return false
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

	local function EnableNoclip(ply)
		ply:SetNWBool("GMAN_BF", true)
		ply:SetNoDraw(true)
		ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		ply:SetMoveType(MOVETYPE_FLY)
		ply:SetNoTarget(true)
	end

	local function DisableNoclip(ply)
		if ply:GetNWBool("GMAN_BF") then
			ply:SetNoDraw(false)
			ply:SetCollisionGroup(COLLISION_GROUP_NONE)
			ply:SetNoTarget(false)
			ply:SetMoveType(MOVETYPE_WALK)
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

		for k, v in pairs(owner:GetBodyGroups()) do
			a:SetBodygroup(v.id, owner:GetBodygroup(v.id))
		end
		a:SetSkin(owner:GetSkin())

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
		owner:Flashlight(false)
		EnableNoclip(owner)

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
		tr = util.QuickTrace(owner:EyePos(), -owner:GetUp() * 128, {owner})
		self.LastGoodPos = owner:GetPos()

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

		if self.DoorSounds[snd] then
			a:EmitSound(self.DoorSounds[snd], 65, 96, 1, CHAN_AUTO, SND_NOFLAGS, 133)
		end

		a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		a:Spawn()

		owner:SetNWEntity("GMAN_ANIM", a)

		timer.Simple(5, function()
			if IsValid(a) and IsValid(owner) and IsValid(self) then
				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
			end
		end)

		timer.Simple(5.1, function()
			if IsValid(a) and IsValid(owner) and IsValid(self) then
				owner:SetNWEntity("GMAN_ANIM", NULL)
				DisableNoclip(owner)

				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
				a:Remove()
			end
		end)

		self:SetNextSecondaryFire(CurTime() + 8)
		self:SetNextPrimaryFire(CurTime() + 8)
	end

	function SWEP:OnDrop()
		local owner = self:GetOwner()
		if IsValid(owner) and owner:Alive() and owner:GetNWBool("GMAN_BF") then
			owner:SetNWEntity("GMAN_ANIM", NULL)
			DisableNoclip(owner)
			owner:SetPos(self.LastGoodPos or owner:GetPos())
		end
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
end

hook.Add("SetupMove","GMAN_BRIEFCASE_SPEED", function( ply, mv )
	if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "swep_gmanbriefcase" then
		mv:SetMaxClientSpeed(130)
	end
end)

local speed = 700
hook.Add("Move", "GMAN_MOVE", function(ply, mv)
	if ply:GetNWBool("GMAN_BF") then
		local pos = Vector(0, 0, 0)
		local ang = mv:GetMoveAngles()

		if mv:KeyDown(IN_MOVERIGHT) then
			pos:Add(ang:Right() * speed)
		end

		if mv:KeyDown(IN_MOVELEFT) then
			pos:Add(-ang:Right() * speed)
		end

		if mv:KeyDown(IN_JUMP) then
			pos:Add(ang:Up() * speed)
		end

		if mv:KeyDown(IN_DUCK) then
			pos:Add(-ang:Up() * speed)
		end

		if mv:KeyDown(IN_FORWARD) then
			pos:Add(ang:Forward() * speed)
		end

		if mv:KeyDown(IN_BACK) then
			pos:Add(-ang:Forward() * speed)
		end

		mv:SetVelocity(pos)
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
	if ply:GetNWBool("GMAN_BF") then return true end
end)

hook.Add("PlayerSwitchWeapon", "GMAN_SWITCHWEAPON", function(ply, oldweapon)
	if ply:GetNWBool("GMAN_BF") and oldweapon:GetClass() == "swep_gmanbriefcase" then return true end
end)

hook.Add("TranslateActivity", "GMAN_BRIEFCASE_SPEED_WALKANIM", function(ply, act)
	if act == ACT_MP_WALK and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "swep_gmanbriefcase" then
		return ACT_HL2MP_WALK_SUITCASE
	end
end)

hook.Add("EntityTakeDamage", "GMAN_DAMAGE", function(ent, dmg)
	if IsValid(ent) and ent:GetNWBool("GMAN_BF") then return true end
end)

hook.Add("PrePlayerDraw", "GMAN_DRAWPLY", function(ply)
	if ply:GetNWBool("GMAN_BF") then return true end
end)

hook.Add("ShouldDrawLocalPlayer", "GMAN_DRAWPLY", function(ply)
	if ply:GetNWBool("GMAN_BF") then return false end
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

hook.Add("ShouldDisableLegs", "GMAN_LEGSUPPORT", function()
	if LocalPlayer():GetNWEntity("GMAN_ANIM") or LocalPlayer():GetNWBool("GMAN_BF") then
		return true
	end
end)

hook.Add("PlayerSwitchFlashlight", "GMAN_FLASHLIGHT", function(ply, bool)
	if ply:GetNWBool("GMAN_BF") and bool then
		return false
	end
end)