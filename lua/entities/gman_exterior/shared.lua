ENT.Base = "gmod_door_exterior"
ENT.Spawnable = false
ENT.PrintName = "Gman"
ENT.Author = "eskil based off safespace"
ENT.Interior = "gman_interior"
ENT.Model = "models/props_junk/PopCan01a.mdl"

ENT.Portal = {
    pos = Vector(0, 0, 46),
    ang = Angle(0, 0, 0),
    width = 50,
    height = 100,
}

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Open")
end

--ENT.Fallback = {pos = Vector(0, 0, 0)}

local class = string.sub(ENT.Folder, string.find(ENT.Folder, "/[^/]*$") + 1) -- only works if in a folder
local hooks = {}

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

ENT:AddHook("ShouldTeleportPortal", "gman", function(self, portal, ent)
    if not self:GetOpen() then return false end
end)