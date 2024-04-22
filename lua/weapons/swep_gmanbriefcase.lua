SWEP.PrintName 		= "G-Man Suitcase"

SWEP.Author 		= "Axel"
SWEP.Instructions 	= "Left Click - Disappear / Right Click - Reappear"
SWEP.Purpose 		= ""
SWEP.Category		= "G-Man Briefcase"
SWEP.GMAN			= true

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

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.offsetVec = Vector(5, -1, 0)
SWEP.offsetAng = Angle(-90, 0, 0)

function SWEP:Initialize()
	self:SetHoldType("normal")
	self:SetNextPrimaryFire(CurTime() + 0.5)
	if CLIENT and not IsValid(self.ClientModel) then
		self.ClientModel = ClientsideModel(self.WorldModel)
		self.ClientModel:SetNoDraw(true)
	end
end

if CLIENT then
	function SWEP:DrawWorldModel(flags)
		local owner = self:GetOwner()
		if IsValid(owner) and not owner:GetNWBool("GMAN_BF") then
			local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
			if not boneid then return end

			local matrix = owner:GetBoneMatrix(boneid)
			if not matrix then return end

			local newPos, newAng = LocalToWorld(self.offsetVec, self.offsetAng, matrix:GetTranslation(), matrix:GetAngles())

			if IsValid(self.ClientModel) then
				self.ClientModel:SetPos(newPos)
				self.ClientModel:SetAngles(newAng)
				self.ClientModel:DrawModel()
			end
		else
			self:DrawModel()
		end
	end

	function SWEP:OnRemove()
		if IsValid(self.ClientModel) then
			self.ClientModel:Remove()
		end
	end

	function SWEP:PrimaryAttack()
	end

	function SWEP:SecondaryAttack()
	end

	function SWEP:Reload()
	end

	function SWEP:ShouldDrawViewModel()
		return false
	end

	hook.Add("HUDShouldDraw", "GMAN_HUD", function(name)
		if IsValid(LocalPlayer()) and LocalPlayer():GetNWBool("GMAN_BF") then
			if ( name == "CHudChat" ) then return true end
			return false
		end
	end)

	hook.Add("PreDrawViewModel", "GMAN_VM", function(name)
		if IsValid(LocalPlayer()) and LocalPlayer():GetNWBool("GMAN_BF") then
			return true
		end
	end)

elseif SERVER then
	local noclip = CreateConVar("gman_noclip", "0", {FCVAR_ARCHIVE}, "0=Collisions while Teleporting, 1=Noclipping", 0, 2)

	local DoorSounds = {
		"ambient/alarms/train_horn_distant1.wav",
		"ambient/alarms/apc_alarm_pass1.wav",
		"ambient/alarms/manhack_alert_pass1.wav",
		"ambient/alarms/scanner_alert_pass1.wav"
	}

	local function EnableNoclip(ply)
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
			ply:SetMoveType(MOVETYPE_WALK)
			ply:SetNoDraw(false)
			ply:SetCollisionGroup(COLLISION_GROUP_NONE)
			ply:SetNoTarget(false)
			ply:SetAvoidPlayers(ply.GMAN_AP or true)
		end
		ply:SetNWBool("GMAN_BF", false)
	end

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
	end

	function SWEP:PrimaryAttack()
		local owner = self:GetOwner()
		if not IsValid(owner) or owner:GetNWBool("GMAN_BF") then return end
		self:SetNextPrimaryFire(CurTime() + 3)
		self.LastGoodPos = owner:GetPos()

		enterfunc(owner, self.BriefType)

		self:SetNextSecondaryFire(CurTime() + 8)
		self:SetNextPrimaryFire(CurTime() + 8)
	end

	local exitfunc = function(owner, type)
		local tr = util.QuickTrace(owner:EyePos(), Angle(0, owner:EyeAngles().y, 0):Forward() * 60, {owner})
		if tr.Hit then return end
		tr = util.QuickTrace(owner:EyePos(), -owner:GetUp() * 128, {owner})

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

		timer.Simple(3.8, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
			end
		end)

		timer.Simple(4, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetNWEntity("GMAN_ANIM", NULL)
				DisableNoclip(owner)

				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
				SafeRemoveEntityDelayed(a, 2)
			end
		end)
	end

	function SWEP:SecondaryAttack()
		local owner = self:GetOwner()
		if not IsValid(owner) or not owner:GetNWBool("GMAN_BF") then return end
		self:SetNextSecondaryFire(CurTime() + 3)
		self.LastGoodPos = owner:GetPos()

		exitfunc(owner, self.BriefType)

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

hook.Add("Move", "GMAN_MOVE", function(ply, mv)
	if ply:GetNWBool("GMAN_BF") and ply:GetMoveType() == MOVETYPE_WALK then
		local pos = Vector(0, 0, 0)
		local ang = mv:GetMoveAngles()

		local speed = 400
		local inworld = true
		if SERVER then
			inworld = util.IsInWorld(ply:GetPos()) and util.IsInWorld(ply:EyePos())
		end
		local movepos = not inworld or (ply.GMAN_WTimer and ply.GMAN_WTimer > CurTime())
		if movepos then
			speed = 10
		elseif mv:KeyDown(IN_SPEED) then
			speed = 800
		end

		if mv:KeyDown(IN_MOVERIGHT) then
			pos:Add(ang:Right() * speed)
		end

		if mv:KeyDown(IN_MOVELEFT) then
			pos:Add(-ang:Right() * speed)
		end

		if mv:KeyDown(IN_JUMP) then
			pos:Add(vector_up * speed)
		end

		if mv:KeyDown(IN_DUCK) then
			pos:Add(-vector_up * speed)
		end

		if mv:KeyDown(IN_FORWARD) then
			pos:Add(ang:Forward() * speed)
		end

		if mv:KeyDown(IN_BACK) then
			pos:Add(-ang:Forward() * speed)
		end

		if movepos then
			if not inworld then ply.GMAN_WTimer = CurTime() + .2 end
			mv:SetOrigin(mv:GetOrigin() + pos)
			mv:SetVelocity(vector_origin)
		else
			ply.GMAN_WTimer = nil
			mv:SetVelocity(pos)
		end
	end
end)

hook.Add("StartCommand", "GMAN_BF", function(ply, ucmd)
	if IsValid(ply:GetNWEntity("GMAN_ANIM")) then
		ucmd:ClearMovement()
		ucmd:ClearButtons()
	end

	if ply:GetNWBool("GMAN_BF") and not (IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon().GMAN) then
		ucmd:RemoveKey(IN_ATTACK)
		ucmd:RemoveKey(IN_ATTACK2)
		ucmd:RemoveKey(IN_RELOAD)
	end
end)

hook.Add("PlayerNoClip", "GMAN_NOCLIP", function(ply)
	if ply:GetNWBool("GMAN_BF") then return true end
end)

hook.Add("PlayerSwitchWeapon", "GMAN_SWITCHWEAPON", function(ply, oldweapon)
	if ply:GetNWBool("GMAN_BF") and IsValid(oldweapon) and oldweapon:GetClass() == "swep_gmanbriefcase" then return true end
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

hook.Add("PostPlayerDeath", "GMAN_RAGDOLL", function(ply)
	if ply:GetNWBool("GMAN_BF") and IsValid(ply:GetRagdollEntity()) then
		ply:GetRagdollEntity():Remove()
	end
end)

hook.Add("CalcView", "GMAN_CALCVIEW", function(ply, origin, angles, fov)
	local ent = ply:GetNWEntity("GMAN_ANIM")
	if IsValid(ent) and not (IsValid(ply:GetViewEntity()) and ply:GetViewEntity() ~= ply) then
		local org = ent:GetPos() + Vector(0, 0, 60)
		local dir = ply:GetForward() * 130
		local tr = util.QuickTrace(org, dir, {ent, ply})

		local np = tr.HitPos

		return {
			origin = np,
			angles = (org - np):Angle(),
			fov = fov,
			drawviewer = false,
			drawviewmodel = false,
		}
	end
end)

hook.Add("ShouldDisableLegs", "GMAN_LEGSUPPORT", function()
	if IsValid(LocalPlayer():GetNWEntity("GMAN_ANIM")) or LocalPlayer():GetNWBool("GMAN_BF") then
		return true
	end
end)

hook.Add("PlayerSwitchFlashlight", "GMAN_FLASHLIGHT", function(ply, bool)
	if ply:GetNWBool("GMAN_BF") and bool then
		return false
	end
end)

hook.Add("PlayerFootstep", "GMAN_FOOTSTEP", function(ply)
	if ply:GetNWBool("GMAN_BF") then
		return true
	end
end)

hook.Add("OnEntityCreated", "GMAN_NEXTBOTFIX", function(ent)
	if ent.GetNearestTarget and not ent._GetNearestTarget then
		ent._GetNearestTarget = ent.GetNearestTarget
		function ent:GetNearestTarget()
			local res = self:_GetNearestTarget()
			if IsValid(res) and res:IsFlagSet(FL_NOTARGET) then
				return nil
			end
			return res
		end
	end
end)

local checkwep = function(ply, str)
	if str == "swep_gmanbriefcase_b" and not util.IsValidModel("models/gman_briefcase.mdl") then
		if IsValid(ply) and not ply.GMAN_CHAT then
			ply:ChatPrint("The server is missing the required addon for this weapon to work!")
			ply:ChatPrint("You can download it at: https://steamcommunity.com/sharedfiles/filedetails/?id=3218879194")
		end
		ply.GMAN_CHAT = true
		return false
	end
end
hook.Add("PlayerGiveSWEP", "GMAN_CHECKSWEP", checkwep)
hook.Add("PlayerSpawnSWEP", "GMAN_CHECKSWEP", checkwep)