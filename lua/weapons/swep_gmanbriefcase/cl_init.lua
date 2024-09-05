include("shared.lua")
include("vgui.lua")

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
	if IsValid(self:GetOwner()) then
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