-- ========================================================================
-- 🛏️ SERVIÇO: GERENCIADOR DE SPAWN (BLINDADO CONTRA CONFLITOS DE VOO)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local TeleportService = Import("Services/Teleport")
local RandomService = Import("Services/RandomService")
local CombatService = Import("Services/CombatService")

local SpawnService = {
    SpawnSetado = false
}

function SpawnService:GetClosestSpawn()
    local closest = nil
    local minDist = math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, islandFolder in ipairs(Workspace:GetChildren()) do
        local potentialSpawns = {}
        if islandFolder.Name:find("SpawnPointCrystal") then table.insert(potentialSpawns, islandFolder)
        elseif islandFolder:IsA("Folder") or islandFolder:IsA("Model") then
            for _, child in ipairs(islandFolder:GetChildren()) do
                if child.Name:find("SpawnPointCrystal") then table.insert(potentialSpawns, child) end
            end
        end
        for _, obj in ipairs(potentialSpawns) do
            local objPos = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if objPos then
                local dist = (hrp.Position - objPos.Position).Magnitude
                if dist < minDist then minDist = dist; closest = obj end
            end
        end
    end
    return closest
end

function SpawnService:SetSpawn()
    if self.SpawnSetado then return true end

    local spawnObj = self:GetClosestSpawn()
    if not spawnObj then return false end

    local targetPart = spawnObj:IsA("BasePart") and spawnObj or spawnObj:FindFirstChildWhichIsA("BasePart", true)

    if targetPart then
        CombatService:SetTarget(nil, false)
        TeleportService:FlyTo(targetPart.Position + Vector3.new(0, 3, 0))
        RandomService:Wait(0.5, 1.5)

        local prompt = spawnObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Velocity = Vector3.zero end
            
            pcall(function() fireproximityprompt(prompt) end)
            RandomService:Wait(0.5, 1.0) 
            
            self.SpawnSetado = true
            return true
        end
    end

    return false
end

function SpawnService:Reset()
    self.SpawnSetado = false
end

return SpawnService
