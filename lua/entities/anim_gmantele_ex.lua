AddCSLuaFile()

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = false
ENT.Author = "eskil"
ENT.DoNotDuplicate = true
ENT.PhysgunDisabled = true
ENT.AutomaticFrameAdvance = true
ENT.WorldModel = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.OpenSound = "doors/metal_move1.wav"
ENT.CloseSound = "doors/door_metal_rusty_move1.wav"
ENT.FullyOpen = "doors/door_metal_thin_open1.wav"


function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "EndDoorTime")
	self:NetworkVar("Bool", 0, "Close")
	self:NetworkVar("Int", 0, "BriefType")
	self:NetworkVar("Vector", 0, "PlayerColor")
end

function ENT:GetNoBrief()
	return self:GetBriefType() == 1
end

function ENT:GetGMANBrief()
	return self:GetBriefType() == 2
end

function ENT:GetBMSBrief()
	return self:GetBriefType() == 3
end

if SERVER then
	function ENT:Initialize()
		BaseClass.Initialize(self)
		self:ResetSequence("idle_all_01")
		self:SetEndDoorTime(CurTime() + 1)
	end

	function ENT:Think()
		BaseClass.Think(self)
		if not self.StartWalking and self:GetEndDoorTime() < CurTime() then
			if self:GetNoBrief() then
				self:ResetSequence("walk_all")
			else
				self:ResetSequence("walk_suitcase")
			end
			self.StartWalking = CurTime() + 1.7
			self:SetVelocity(self:GetForward() * 30)
			self:SetMoveType(MOVETYPE_NOCLIP)
			self:SetPoseParameter("move_x", 0.5)
		elseif self.StartWalking and self.StartWalking < CurTime() and not self.ClosingDoor then
			self:SetEndDoorTime(CurTime() + 1)
			self.ClosingDoor = CurTime() + 0.3
			self:SetClose(true)
		elseif self.ClosingDoor and self.ClosingDoor < CurTime() and not self.Finished then
			self.Finshed = true
			self:ResetSequence("idle_all_01")
			self:SetVelocity(vector_origin)
			self:SetMoveType(MOVETYPE_NONE)
			SafeRemoveEntityDelayed(self, 3)
		end

		self:NextThink(CurTime())
		return true
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end
end

if CLIENT then
	local function DrawWall(pos, angle, width, height, color)
		if width < 0 or height < 0 then return end
		render.SetColorMaterial()
		render.DrawQuad(
			LocalToWorld(Vector( 0, -height, 0 ), angle_zero, pos, angle),
			LocalToWorld(Vector( 0, 0, 0 ), angle_zero, pos, angle),
			LocalToWorld(Vector( width, 0, 0 ), angle_zero, pos, angle),
			LocalToWorld(Vector( width, -height, 0 ), angle_zero, pos, angle),
			color or COLOR_WHITE
		)
	end

	function ENT:Initialize()
		self:SetIK(false)
		self:DrawShadow(false)
		if not IsValid(self.ClientModel) then
			self.ClientModel = ClientsideModel(self.WorldModel)
			self.ClientModel:SetNoDraw(true)
		end
	end

	function ENT:Think()
		BaseClass.Think(self)

		self:SetNextClientThink(CurTime())
		self:SetRenderBounds(Vector(-16, -16, 0), Vector(16, 16, 64), Vector(150, 150, 150))
		return true
	end

	function ENT:OnRemove()
		if IsValid(self.ClientModel) then
			self.ClientModel:Remove()
		end
	end

	function ENT:DrawTranslucent()
		self:DrawShadow(false)
		if self:GetEndDoorTime() == 0 and not self.DPos or not self.StartTime then
			self.DPos = self:GetPos() + self:GetForward() * 32
			self.StartTime = CurTime()
			self:EmitSound(self.OpenSound)
			return
		end

		local pos, ang = self.DPos, self:GetForward():Angle()
		local dang = self:GetForward():Angle()
		dang:RotateAroundAxis(dang:Right(), - 90)
		dang:RotateAroundAxis(dang:Up(), 90)

		if self:GetEndDoorTime() < CurTime() and not self.CloseLatch then
			self.CloseLatch = true
			self:EmitSound(self.FullyOpen)
		elseif self.CloseLatch and self:GetEndDoorTime() > CurTime() and not self.Close then
			self.Close = true
			self.HideModel = CurTime() + 0.3
			self.StartTime = CurTime()
			self:EmitSound(self.CloseSound)
		end

		local dur, elapsed = self:GetEndDoorTime() - self.StartTime, CurTime() - self.StartTime
		local per = math.Clamp(elapsed / dur, 0, 1)


		render.SetStencilEnable(true)
		render.ClearStencil()
		render.SetStencilTestMask(255)
		render.SetStencilWriteMask(255)

		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetStencilReferenceValue(1)

		per = (not (self:GetClose() or self.Close) and per or (1 - per))
		DrawWall(pos + ang:Right() * 25 + ang:Up() * 100 * per - Vector(0, 0, 1), dang, 50, 100 * per)

		local oldclip = render.EnableClipping(true)
		render.PushCustomClipPlane(self:GetForward(), self:GetForward():Dot(self.DPos))

		render.SetStencilReferenceValue(0)
		if not self.HideModel or self.HideModel > CurTime() then
			self:DrawModel()
			self:DrawBriefcase()
		end

		render.PopCustomClipPlane()

		render.SetStencilReferenceValue(1)
		render.SetStencilPassOperation(STENCILOPERATION_KEEP)
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)

		render.SuppressEngineLighting(true)
		render.ResetModelLighting(0, 0, 0)
		render.SetLocalModelLights(
			{
				{
					type = MATERIAL_LIGHT_SPOT,
					color = Vector(0.6, 0.6, 0.6),
					pos = self:GetPos() + self:GetForward() * 120 + self:GetUp() * 64,
					dir = -self:GetForward(),
					outerAngle = 90,
					linearFalloff = true,
				}
			}
		)

		render.PushCustomClipPlane(-self:GetForward(), -self:GetForward():Dot(self.DPos))
		render.DepthRange( 0, 0.1 )
		self:DrawModel()
		self:DrawBriefcase()
		render.DepthRange( 0, 1 )

		render.PopCustomClipPlane()
		render.SuppressEngineLighting(false)
		render.EnableClipping(oldclip)
		render.SetStencilEnable(false)

		dang:RotateAroundAxis(self:GetUp(), 180)
		DrawWall(pos - ang:Right() * 25 + ang:Up() * 100 * per - Vector(0, 0, 1), dang, 50, 100 * per)

	end

	function ENT:Draw()
		self:DrawTranslucent()
	end

	ENT.offsetVec = Vector(5, -1, 0)
	ENT.offsetAng = Angle(-90, 0, 0)
	function ENT:DrawBriefcase()
		if self:GetNoBrief() or not IsValid(self.ClientModel) then return end
		if not self.ModelRep and self:GetGMANBrief() then
			self.ModelRep = true
			self.ClientModel:SetModel("models/gman_briefcase.mdl")
			self.offsetVec = Vector(20, -1, 0)
		end

		if not self.ModelRep and self:GetBMSBrief() then
			self.ModelRep = true
			self.ClientModel:SetModel("models/sketchfab/quaz30/g_man_briefcase/skf_g_man_briefcase.mdl")
			self.offsetVec = Vector(12, 1, 0)
			self.offsetAng = Angle(180, 0, -90)
		end

		local boneid = self:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
		if not boneid or not IsValid(self.ClientModel) then return end

		local matrix = self:GetBoneMatrix(boneid)
		if not matrix then return end

		local newPos, newAng = LocalToWorld(self.offsetVec, self.offsetAng, matrix:GetTranslation(), matrix:GetAngles())

		self.ClientModel.IsBrief = true
		self.ClientModel:SetPos(newPos)
		self.ClientModel:SetAngles(newAng)
		self.ClientModel:DrawModel()
	end
end