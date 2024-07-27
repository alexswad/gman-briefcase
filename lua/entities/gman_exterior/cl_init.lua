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
		if not IsValid(portal) or not portal.SetHeight then return end
		portal:SetHeight(ent.t_tall)
		portal:SetPos(ent:LocalToWorld(pos + Vector(0, 0, ent.t_tall / 2 - 50)))

		if not IsValid(ent.interior) then return end
		local portal2, pos2 = ent.interior:GetChildren()[1], ent.interior.Portal.pos
		if not IsValid(portal2) or not portal2.SetHeight then return end
		portal2:SetHeight(ent.t_tall)
		portal2:SetPos(ent.interior:LocalToWorld(pos2 + Vector(0, 0, ent.t_tall / 2 - 50)))
	end
end)

ENT.CustomDrawModel = function(self) self:DrawShadow(false) end