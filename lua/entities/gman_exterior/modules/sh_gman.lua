ENT:AddHook("InteriorReady","gman",function(self,interior)
    if not IsValid(interior) then
        self:Remove() -- cannot function at all without interior
    end
    self:PhysicsInit(SOLID_NONE)
end)

ENT:AddHook("Initalize", "gman", function(self)
    self:SetOpen(false)
end)