SWEP.PrintName 		= "Gman Briefcase"

SWEP.Author 		= "Axel"
SWEP.Instructions 	= "Left Click - Disappear / Right Click - Reappear"
SWEP.Purpose 		= "Its very heavy, almost like its filled with rocks."

SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.ViewModel = "models/weapons/v_hands.mdl"
SWEP.WorldModel = "models/weapons/w_suitcase_passenger.mdl"

function SWEP:Initialize()
	self:SetHoldType("normal")
	if CLIENT and not IsValid(self.ClientModel) then
		self.ClientModel = ClientsideModel(self.WorldModel)
		self.ClientModel:SetNoDraw(true)
	end
end

function SWEP:DrawWorldModel(flags)
	local offsetVec = Vector(5, -1, -3.4)
	local offsetAng = Angle(-90, 0, 0)

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
end

hook.Add("SetupMove","GMAN_BRIEFCASE_SPEED", function( ply, mv )
	if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "swep_gmanbriefcase" then
		mv:SetMaxClientSpeed(130)
	end
end)