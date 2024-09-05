local gman = GMANBF


// Convars
function gman:GetCV_LinkedSlot(ply)
	return math.Clamp(math.Round(ply:GetInfoNum("gman_cl_pslot", 1)), 1, 5)
end

function gman:GetCV_DimensionSlot(ply)
	return math.Clamp(math.Round(ply:GetInfoNum("gman_cl_dslot", 1)), 1, 3)
end

function gman:GetCV_Mode(ply)
	return math.Clamp(math.Round(ply:GetInfoNum("gman_cl_mode", 1)), 1, 5)
end

function gman:GetCV_Godmode(ply)
	return tobool(ply:GetInfoNum("gman_cl_godmode", 0))
end

function gman:GetCV_WepModel(ply)
	return math.Clamp(math.Round(ply:GetInfoNum("gman_cl_wepmodel", 1)), 1, 5)
end

function gman:GetCV_Model(ply)
	return tobool(ply:GetInfoNum("gman_cl_model", 1))
end

if CLIENT then
	local showmodel = gman.CV_ShowVM
	function gman:GetCL_ShowVM()
		return showmodel and tobool(showmodel:GetInt())
	end
end

function gman:GetAnimEntity(ply)
	return ply:GetEntity("GMAN_ANIM")
end

function gman:IsPlayerNoclipped(ply)
	return ply:GetNWBool("GMAN_BF")
end
//

// Commands & Helpers
if CLIENT then return end

function gman:SetAnimEntity(ply, ent)
	ply:SetEntity("GMAN_ANIM", ent)
end

local noclip = gman.CV_Noclip
function gman:NoclipPlayer(ply, enable)
	if enable then
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

function gman:DoPlayerGhostDoor(owner, type, exit)
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
		self:NoclipPlayer(owner, true)

		timer.Simple(4, function()
			if IsValid(a) and IsValid(owner) then
				owner:SetNWEntity("GMAN_ANIM", NULL)
				owner:SetEyeAngles(a:GetAngles())
				SafeRemoveEntityDelayed(a, 4)
			end
		end)

		return true
	else

	end
end

function gman:DoPlayerFade(ply, fadein)

end

function gman:CreatePlayerDimension(ply, pos, ang)

end

function gman:CreateLinkedDoors(ply, pos, ang, door2)

end