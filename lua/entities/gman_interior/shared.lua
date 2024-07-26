ENT.Base = "gmod_door_interior"
ENT.Author = "eskil based off safe space"
ENT.Exterior = "gman_exterior"
ENT.Model = "models/props/gman/gman_box.mdl"
local class = string.sub(ENT.Folder, string.find(ENT.Folder, "/[^/]*$") + 1) -- only works if in a folder
local hooks = {}
ENT.Portal = {
    pos = Vector(-190, -0, -35),
    ang = Angle(0, 0, 0),
    width = 50,
    height = 100,
}

if not wp then
    return
end

--ENT.Fallback = {pos = Vector(10, 0, 10)}

-- Hook system for modules
function ENT:AddHook(name, id, func)
    if not hooks[name] then
        hooks[name] = {}
    end

    hooks[name][id] = func
end

function ENT:RemoveHook(name, id)
    if hooks[name] and hooks[name][id] then
        hooks[name][id] = nil
    end
end

function ENT:CallHook(name, ...)
    local a, b, c, d, e, f
    a, b, c, d, e, f = self.BaseClass.CallHook(self, name, ...)
    if a ~= nil then return a, b, c, d, e, f end
    if not hooks[name] then return end

    for k, v in pairs(hooks[name]) do
        a, b, c, d, e, f = v(self, ...)
        if a ~= nil then return a, b, c, d, e, f end
    end
end

function ENT:LoadFolder(folder, addonly, noprefix)
    folder = "entities/" .. class .. "/" .. folder .. "/"
    local modules = file.Find(folder .. "*.lua", "LUA")

    for _, plugin in ipairs(modules) do
        if noprefix then
            if SERVER then
                AddCSLuaFile(folder .. plugin)
            end

            if not addonly then
                include(folder .. plugin)
            end
        else
            local prefix = string.Left(plugin, string.find(plugin, "_") - 1)

            if (CLIENT and (prefix == "sh" or prefix == "cl")) then
                if not addonly then
                    include(folder .. plugin)
                end
            elseif (SERVER) then
                if (prefix == "sv" or prefix == "sh") and (not addonly) then
                    include(folder .. plugin)
                end

                if (prefix == "sh" or prefix == "cl") then
                    AddCSLuaFile(folder .. plugin)
                end
            end
        end
    end
end

ENT:LoadFolder("modules/libraries")
ENT:LoadFolder("modules")

function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self.ExitBox = {Min = self:OBBMins(), Max = self:OBBMaxs()}
end

ENT:AddHook("ShouldTeleportPortal", "gman", function(self, portal, ent)
    if not self.exterior:GetOpen() then return false end
end)