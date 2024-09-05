SWEP.PrintName 		= "G-Man Suitcase"

SWEP.Author 		= "eskil"
SWEP.Instructions 	= "Left Click - Disappear / Right Click - Reappear / Reload - Change Mode"
SWEP.Purpose 		= ""
SWEP.Category		= "G-Man Briefcase"
SWEP.GMAN			= true
SWEP.GMAN_DOOR		= true

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.ViewModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"
SWEP.WorldModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"
SWEP.Slot = 4
SWEP.SlotPos = 5

SWEP.UseHands = false
SWEP.ShowViewModel = true

SWEP.ViewModelBoneMods = {
	["SuitCase_Passenger1.Case_Mesh"] = { scale = Vector(0.61, 0.61, 0.61), pos = Vector(9.444, -6.481, 0), angle = Angle(1.11, 10, 0) }
}


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

SWEP.Miss = Sound("Weapon_Crowbar.Single")
SWEP.MissSecond = Sound("npc/zombie/claw_miss2.wav")
SWEP.Hit = Sound("Weapon_Crowbar.Melee_Hit")


function SWEP:Initialize()
	self.Mode = 0
	self:SetHoldType("normal")
	self:SetNextPrimaryFire(CurTime() + 0.5)
	if CLIENT and not IsValid(self.ClientModel) then
		self.ClientModel = ClientsideModel(self.WorldModel)
		self.ClientModel:SetNoDraw(true)
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "Mode")
	self:NetworkVar("Entity", 0, "Door")
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

	function SWEP:PrimaryAttack()
	end

	function SWEP:SecondaryAttack()
	end

	function SWEP:Reload()
	end

	function SWEP:ShouldDrawViewModel()
		return true
	end

	hook.Add("HUDShouldDraw", "GMAN_HUD", function(name)
		if IsValid(LocalPlayer()) and LocalPlayer():GetNWBool("GMAN_BF") then
			if ( name == "CHudChat" ) then return true end
			return false
		end
	end)

	local cl = CreateClientConVar("cl_gman_disablevm", "0", true, false, "Disables viewmodels for briefcases")
	hook.Add("PreDrawViewModel", "GMAN_VM", function(name, ply, weapon)
		if cl:GetBool() and ply == LocalPlayer() and IsValid(weapon) and weapon.GMAN_DOOR then return true end
		if IsValid(ply) and ply:GetNWBool("GMAN_BF") then return true end
	end)

	function SWEP:Holster()
		if CLIENT and IsValid(self:GetOwner()) then
			local vm = self:GetOwner():GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
			end
		end
		return true
	end

	function SWEP:OnRemove()
		self:Holster()
		if IsValid(self.ClientModel) then
			self.ClientModel:Remove()
		end
	end

	function SWEP:ViewModelDrawn()
		local vm = self:GetOwner():GetViewModel()
		if not IsValid(vm) then return end

		self:UpdateBonePositions(vm)
	end

	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		local bone, pos, ang
		if (tab.rel and tab.rel ~= "") then

			local v = basetab[tab.rel]

			if not v then return end

			pos, ang = self:GetBoneOrientation( basetab, v, ent )

			if not pos then return end

			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)

		else

			bone = ent:LookupBone(bone_override or tab.bone)

			if not bone then return end

			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end

			if (IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() and
				ent == self:GetOwner():GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r -- Fixes mirrored models
			end
		end

		return pos, ang
	end

	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)

		if self.ViewModelBoneMods then
			if not vm:GetBoneCount() then return end
			local loopthrough = self.ViewModelBoneMods
			if not hasGarryFixedBoneScalingYet then
				allbones = {}
				for i = 0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = {
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end

				loopthrough = allbones
			end

			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if not bone then continue end
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if not hasGarryFixedBoneScalingYet then
					local cur = vm:GetBoneParent(bone)
					while (cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end

				s = s * ms

				if vm:GetManipulateBoneScale(bone) ~= s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) ~= v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) ~= p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end

	end

	function SWEP:ResetBonePositions(vm)

		if not vm:GetBoneCount() then return end
		for i = 0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end

	end
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

	function SWEP:Deploy()
		if self.Mode then
			self:GetOwner():ChatPrint("Current Mode: [" .. self.Mode .. "] " .. self.Modes[self.Mode])
		end
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
		[0] = "Ghost Self (Left Click - Disappear / Right Click - Reappear)",
		[1] = "Attack (Left Click & Right Click - Melee Attack)",
		[2] = "White Room Portal (Left Click - Open & Cloor Door / Right Click - Set Door Entrance)",
		[3] = "Linked Doors (Left Click - Set Door 1 / Right Click - Set Door 2 / Alt - Open & Close Doors)"
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
end

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
		local dir = ply:EyeAngles():Forward() * 130
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

hook.Add("PostDrawTranslucentRenderables", "GMAN_WEAPON", function()
	local wep = LocalPlayer():GetActiveWeapon()
	if IsValid(wep) and wep.GMAN_DOOR and wep:GetMode() == 2 then
		render.SetColorMaterial()
		if IsValid(wep:GetDoor()) then
			local door = wep:GetDoor()
			render.DrawWireframeSphere(door:GetPos() - door:GetForward() * 5, 2, 5, 5, door:GetOpen() and Color(8, 231, 0) or Color(255, 0, 0, 255))
			render.DrawWireframeSphere(door:GetPos() + door:GetForward() * 10, 1, 5, 5, Color( 0, 3, 197))
		end

		local tr = LocalPlayer():GetEyeTrace()
		if not tr.Hit or not tr.HitWorld or tr.StartPos:DistToSqr(tr.HitPos) > 1000 * 1000 then return end
		local pos = tr.HitPos
		render.DrawWireframeSphere( pos, 2, 5, 5, Color( 175, 0, 0, 255) )
	end
end)


local checkwep = function(ply, str)
	if not wp and (str == "swep_gmanbriefcase_b" or str == "swep_gmanbriefcase") and IsValid(ply) and not ply.GMAN_DCHAT then
		ply:ChatPrint("This addon now has Doors support!\nYou can download it at: https://steamcommunity.com/sharedfiles/filedetails/?id=499280258")
		ply.GMAN_DCHAT = true
	end

	if str == "swep_gmanbriefcase_b" and not util.IsValidModel("models/gman_briefcase.mdl") then
		if IsValid(ply) and not ply.GMAN_BCHAT then
			ply:ChatPrint("The server is missing the required addon for this weapon to work!")
			ply:ChatPrint("You can download it at: https://steamcommunity.com/workshop/filedetails/?id=1896637986")
		end
		ply.GMAN_BCHAT = true
		return false
	end

	if str == "swep_gmanbriefcase_bms" and not util.IsValidModel("models/sketchfab/quaz30/g_man_briefcase/skf_g_man_briefcase.mdl") then
		if IsValid(ply) and not ply.GMAN_BMSCHAT then
			ply:ChatPrint("The server is missing the required addon for this weapon to work!")
			ply:ChatPrint("You can download it at: https://steamcommunity.com/workshop/filedetails/?id=2870296319")
		end
		ply.GMAN_BMSCHAT = true
		return false
	end
end
hook.Add("PlayerGiveSWEP", "GMAN_CHECKSWEP", checkwep)
hook.Add("PlayerSpawnSWEP", "GMAN_CHECKSWEP", checkwep)

hook.Add("TranslateActivity", "GMAN_BRIEFCASE_SPEED_WALKANIM", function(ply, act)
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or not wep.GMAN_DOOR then return end
	if act == ACT_MP_WALK and wep:GetHoldType() == "normal" then
		return ACT_HL2MP_WALK_SUITCASE
	end
end)