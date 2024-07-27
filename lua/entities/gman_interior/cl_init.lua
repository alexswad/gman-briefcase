include("shared.lua")

ENT:AddHook("ShouldRenderPortal", "gman", function(self)
	if self.t_tall == 0 then return false end
end)