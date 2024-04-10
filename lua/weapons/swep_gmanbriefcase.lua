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
	if (IsValid(_Owner)) then
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
	end

	function SWEP:PrimaryAttack()
	end

	function SWEP:SecondaryAttack()
	end

	function SWEP:Reload()
	end

elseif SERVER then
	function SWEP:PrimaryAttack()
		local owner = self:GetOwner()
		if not IsValid(owner) then return end
		self:SetNextPrimaryFire(CurTime() + 2)

		local tr = util.QuickTrace(owner:GetPos() + Vector(0, 0, 5), Angle(0, owner:EyeAngles().y, 0):Forward() * 60, function() return false end)
		local a = ents.Create("anim_gmantele")
		a:SetPos(owner:GetPos())
		a:SetModel(owner:GetModel())
		a:SetPlayerColor(owner:GetPlayerColor())

		if tr.Hit then
			a:SetAngles(Angle(0, (-tr.HitNormal):Angle().y, 0))
		else
			a:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		end
		a:Spawn()

		self:SetNextPrimaryFire(CurTime() + 0.5)
	end

	function SWEP:SecondaryAttack()
	end

	function SWEP:Reload()
	end
end

hook.Add("SetupMove","GMAN_BRIEFCASE_SPEED", function( ply, mv )
	if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "swep_gmanbriefcase" then
		mv:SetMaxClientSpeed(130)
	end
end)

hook.Add("TranslateActivity", "GMAN_BRIEFCASE_SPEED_WALKANIM", function(ply, act)
	if act == ACT_MP_WALK and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "swep_gmanbriefcase" then
		return ACT_HL2MP_WALK_SUITCASE
	end
end)