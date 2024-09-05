GMANBF = {}
SWEP.PrintName 		= "G-Man Suitcase Rewrite"

SWEP.Author 		= "eskil"
SWEP.Instructions 	= "SHIFT + R - Cycle Modes / E + R - Open Menu"
SWEP.Purpose 		= ""
SWEP.Category		= "G-Man Briefcase"
SWEP.GMAN			= true
SWEP.GMAN_DOOR		= true

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.ViewModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"
SWEP.WorldModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"
SWEP.Slot = 5
SWEP.SlotPos = 5

SWEP.UseHands = false
SWEP.ShowViewModel = true

SWEP.ViewModelBoneMods = {
	["SuitCase_Passenger1.Case_Mesh"] = { scale = Vector(0.61, 0.61, 0.61), pos = Vector(9.444, -6.481, 0), angle = Angle(1.11, 10, 0) }
}

SWEP.Models = {{
	name = "Original",
	model = "models/props_c17/SuitCase_Passenger_Physics.mdl",
	vm = {
		["SuitCase_Passenger1.Case_Mesh"] = { scale = Vector(0.61, 0.61, 0.61), pos = Vector(9.444, -6.481, 0), angle = Angle(1.11, 10, 0) }
	},
	wm = {
		pos = Vector(5, -1, 0),
		ang = Angle(-90, 0, 0)
	}
},
{
	name = "None",
	model = "models/weapons/v_hands.mdl",
	vm = {},
},
{
	name = "GMan",
	model = "models/props_c17/SuitCase_Passenger_Physics.mdl",
	vm = {
		["root"] = { scale = Vector(1, 1, 1), pos = Vector(13.519, -8.334, -15), angle = Angle(-5.557, 0, 0) }
	},
	wm = {
		pos = Vector(20, -1, 0),
		ang = Angle(-90, 0, 0)
	}
},
{
	name = "Black Mesa",
	model = "models/props_c17/SuitCase_Passenger_Physics.mdl",
	vm = {
		["root"] = { scale = Vector(0.6, 0.6, 0.6), pos = Vector(15, -8.705, -3.889), angle = Angle(-67.778, -12.223, -67.778) }
	},
	wm = {
		pos = Vector(12, 1, 0),
		ang = Angle(180, 0, -90)
	}
}}


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
	self:NetworkVar("Entity", 0, "Dimension")
	self:NetworkVar("Entity", 1, "")
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

hook.Add("TranslateActivity", "GMAN_BRIEFCASE_SPEED_WALKANIM", function(ply, act)
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or not wep.GMAN_DOOR then return end
	if act == ACT_MP_WALK and wep:GetHoldType() == "normal" then
		return ACT_HL2MP_WALK_SUITCASE
	end
end)