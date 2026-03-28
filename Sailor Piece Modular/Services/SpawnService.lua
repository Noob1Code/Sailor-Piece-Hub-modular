-- ========================================================================
-- 🛏️ SERVIÇO: GERENCIADOR DE SPAWN (CRISTAIS)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local TeleportService = Import("Services/Teleport")

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

        if islandFolder.Name:find("SpawnPointCrystal") then
            table.insert(potentialSpawns, islandFolder)
        elseif islandFolder:IsA("Folder") or islandFolder:IsA("Model") then
            for _, child in ipairs(islandFolder:GetChildren()) do
                if child.Name:find("SpawnPointCrystal") then
                    table.insert(potentialSpawns, child)
                end
            end
        end

        for _, obj in ipairs(potentialSpawns) do
            local objPos = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            
            if objPos then
                local dist = (hrp.Position - objPos.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = obj
                end
            end
        end
    end

    return closest
end

function SpawnService:SetSpawn()
    if self.SpawnSetado then return true end

    local spawnObj = self:GetClosestSpawn()
    if not spawnObj then
        return false 
    end

    local targetPart = spawnObj:IsA("BasePart") and spawnObj or spawnObj:FindFirstChildWhichIsA("BasePart", true)

    if targetPart then
        TeleportService:FlyTo(targetPart.Position + Vector3.new(0, 3, 0))
        task.wait(0.5)

        local prompt = spawnObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            local oldStyle = prompt.Style
            prompt.Style = Enum.ProximityPromptStyle.Custom
            task.wait(0.5) 
            
            pcall(function() fireproximityprompt(prompt) end)
            
            task.delay(1.5, function() 
                if prompt then prompt.Style = oldStyle end 
            end)
            
            task.wait(1) 
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
