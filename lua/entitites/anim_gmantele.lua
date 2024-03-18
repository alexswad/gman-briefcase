AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = false
ENT.Author = "Axel"
ENT.DoNotDuplicate = true
ENT.PhysgunDisabled = true
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "EndDoorTime")
	self:NetworkVar("Bool", 0, "Exit")
	self:NetworkVar("Bool", 1, "Close")
end

if SERVER then
	function ENT:Initialize()
		self:SetSequence("idle")
		self:SetEndDoorTime(CurTime() + 3)
	end

	function ENT:Think()
		if not self.StartWalking and self:GetEndDoorTime() < CurTime() then
			self:SetSequence()
			self.StartWalking = true
		end

		self:NextThink(CurTime() + 0.1)
		return true
	end
end

if CLIENT then
	function ENT:Initialize()
		if not IsValid(self.ClientModel) then
			self.ClientModel = ClientsideModel(self.WorldModel)
			self.ClientModel:SetNoDraw(true)
		end
	end

	function ENT:OnRemove()
		self.ClientModel:Remove()
	end
end

