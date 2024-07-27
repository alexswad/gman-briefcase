include("shared.lua")

hook.Add("PostDrawOpaqueRenderables", "gman_portals", function()
	for k, ent in pairs(ents.FindByClass("gman_exterior")) do
		ent.t_tall = ent.t_tall or 0

		if ent:GetOpen() and ent.t_tall < 100 then
			ent.t_tall = math.min(100, ent.t_tall + 30 * FrameTime())
		elseif ent.t_tall > 0 then
			ent.t_tall = math.max(0, ent.t_tall - 30 * FrameTime())
		end

		local portal, pos = ent:GetChildren()[1], ent.Portal.pos
		if not IsValid(portal) or not portal.SetHeight then continue end
		portal:SetHeight(ent.t_tall)
		portal:SetPos(ent:LocalToWorld(pos + Vector(0, 0, ent.t_tall / 2 - 50)))

		local int = ent.interior
		if not IsValid(int) then continue end
		int.t_tall = ent.t_tall
		local portal2, pos2 = int:GetChildren()[1], int.Portal.pos
		if not IsValid(portal2) or not portal2.SetHeight then continue end
		portal2:SetHeight(ent.t_tall)
		portal2:SetPos(int:LocalToWorld(pos2 + Vector(0, 0, ent.t_tall / 2 - 50)))
	end
end)

ENT:AddHook("ShouldRenderPortal", "gman", function(self)
	if self.t_tall == 0 then return false end
end)

ENT.CustomDrawModel = function(self) self:DrawShadow(false) end