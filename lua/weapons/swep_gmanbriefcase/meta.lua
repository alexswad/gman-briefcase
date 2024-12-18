

SWEP.CV_Noclip = CreateConVar("SWEP_noclip", "0", {FCVAR_ARCHIVE}, "0=Collisions while Teleporting, 1=Noclipping", 0, 2)
function SWEP:GetCV_LinkedSlot(ply)
	return math.Clamp(math.Round(ply:GetInfoNum("SWEP_cl_pslot", 1)), 1, 5)
end

function SWEP:GetCV_DimensionSlot(ply)
	return math.Clamp(math.Round(ply:GetInfoNum("SWEP_cl_dslot", 1)), 1, 3)
end

function SWEP:GetCV_Mode(ply)
	return math.Clamp(math.Round(ply:GetInfoNum("SWEP_cl_mode", 1)), 1, 5)
end

function SWEP:GetCV_Godmode(ply)
	return tobool(ply:GetInfoNum("SWEP_cl_godmode", 0))
end

function SWEP:GetCV_WepModel(ply)
	return math.Clamp(math.Round(ply:GetInfoNum("SWEP_cl_wepmodel", 1)), 1, 5)
end

function SWEP:GetCV_Model(ply)
	return tobool(ply:GetInfoNum("SWEP_cl_model", 1))
end

if CLIENT then
	local showmodel = SWEP.CV_ShowVM
	function SWEP:GetCL_ShowVM()
		return showmodel and tobool(showmodel:GetInt())
	end
end

function SWEP:GetAnimEntity(ply)
	return ply:GetEntity("GMAN_ANIM")
end

function SWEP.IsPlayerNoclipped(ply)
	return ply:GetNWBool("GMAN_BF")
end
//

// Commands & Helpers
if CLIENT then return end

function SWEP:SetAnimEntity(ply, ent)
	ply:SetEntity("GMAN_ANIM", ent)
end

local noclip = SWEP.CV_Noclip
function SWEP.NoclipPlayer(ply, enable)
	if enable ~= false then
		if noclip:GetBool() then
			ply:SetMoveType(MOVETYPE_NOCLIP)
		end
		ply:SetNWBool("GMAN_BF", true)
		ply:SetNoDraw(true)
		ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		ply:SetNoTarget(true)
		ply.GMAN_AP = ply:GetAvoidPlayers()
		ply:SetAvoidPlayers(false)
	else
		if ply:GetNWBool("GMAN_BF") then
			ply:SetMoveType(MOVETYPE_WALK)
			ply:SetNoDraw(false)
			ply:SetCollisionGroup(COLLISION_GROUP_NONE)
			ply:SetNoTarget(false)
			ply:SetAvoidPlayers(ply.GMAN_AP or true)
		end
		ply:SetNWBool("GMAN_BF", false)
	end
end

local DoorSounds = {
	"ambient/alarms/train_horn_distant1.wav",
	"ambient/alarms/apc_alarm_pass1.wav",
	"ambient/alarms/manhack_alert_pass1.wav",
	"ambient/alarms/scanner_alert_pass1.wav"
}

function SWEP:DoPlayerGhostDoor(owner, exit, type)
	if not exit then
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
		self.NoclipPlayer(owner, true)

		timer.Simple(type ~= 1 and 4 or 2, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetNWEntity("GMAN_ANIM", NULL)
				owner:SetEyeAngles(a:GetAngles())
				SafeRemoveEntityDelayed(a, 4)
			end
		end)

		return true
	else
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
				self.NoclipPlayer(owner, false)

				owner:SetPos(a:GetPos())
				owner:SetEyeAngles(a:GetAngles())
				SafeRemoveEntityDelayed(a, 2)
			end
		end)
		return true
	end
end

function SWEP:DoPlayerFade(ply, fadein)

end

function SWEP:CreatePlayerDimension(owner, slot, pos, ang)
	owner.GMDoors = owner.GMDoors or {linked = {}, dim = {}}
	if IsValid(owner.GMDoors.dim[slot]) then return owner.GMDoors.dim[slot] end

	local door = ents.Create("gman_exterior")
	door:SetAngles(ang)
	door:SetPos(pos)
	Doors:SetupOwner(door, owner)
	door:Spawn()
	door:Activate()
	door:SetOpen(true)
	owner.GMDoors.dim[slot] = door
	self:DeleteOnRemove(door)
	door:EmitSound("doors/metal_move1.wav")

	return door
end

function SWEP:CreateLinkedDoors(ply, pos, ang, door2)

end