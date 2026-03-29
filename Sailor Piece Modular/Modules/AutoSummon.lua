-- ========================================================================
-- 🔮 MÓDULO: AUTO SUMMON BOSS (INVOCAÇÃO NA BOSS ISLAND)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")
local TeleportService = Import("Services/Teleport")
local GameData = Import("Config/GameData")
local CombatService = Import("Services/CombatService")
local PriorityService = Import("Services/PriorityService")
local SpawnService = Import("Services/SpawnService")
local RandomService = Import("Services/RandomService")

local Module = { NoToggle = true }

function Module:Init()
    self.IsRunning = false
    self.TargetBossModel = nil
    self.Patience = 0
    self.SummonBossList = GameData.SummonBosses or {"Nenhum Boss Encontrado"}
    self.SelectedSummonBoss = self.SummonBossList[1]
    
    self.TargetIsland = "Boss Island"
    self.LastSummonState = false
    
    pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 3)
        if remotes then
            self.SummonRemote = remotes:WaitForChild("RequestSummonBoss", 3)
            self.AutoSpawnRemote = remotes:WaitForChild("RequestAutoSpawn", 3)
        end
    end)
end

function Module:GetCurrentIsland(hrp)
    local closestIsland, minDist = nil, math.huge
    local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
    if not serviceFolder then return nil end

    for npcName, islandName in pairs(GameData.NpcToIsland) do
        local npc = serviceFolder:FindFirstChild(npcName)
        if npc and npc:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude
            if dist < minDist then minDist, closestIsland = dist, islandName end
        end
    end
    return closestIsland
end

function Module:GetBossModel(targetName)
    local closest, minDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local cleanTarget = targetName:lower():gsub("%s+", "")

    for _, folder in ipairs(Workspace:GetChildren()) do
        if folder.Name == "NPCs" or folder.Name:find("BossSpawn_") or folder.Name:find("TimedBoss") then
            for _, npc in ipairs(folder:GetDescendants()) do
                if npc:IsA("Model") then
                    local hum = npc:FindFirstChild("Humanoid")
                    local npcBase = npc:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and npcBase then
                        local cleanNpcName = npc.Name:gsub("%d+", ""):lower():gsub("%s+", "")
                        if cleanNpcName == cleanTarget then
                            local dist = (hrp.Position - npcBase.Position).Magnitude
                            if dist < minDist then minDist, closest = dist, npc end
                        end
                    end
                end
            end
        end
    end
    return closest
end

function Module:Start()
    local tabName = "Chefes (Boss)"
    UI:CreateSection(tabName, "🔮 Invocação Automática (Boss Island)")

    UI:CreateDropdown(tabName, "📍 Selecionar Boss de Invocação", self.SummonBossList, function(selected)
        self.SelectedSummonBoss = selected
    end)

    UI:CreateToggle(tabName, "Auto Summon & Farm", function(state)
        self:Toggle(state)
    end)
end

function Module:StartFarm()
    if self.IsRunning then return end
    self.IsRunning = true
    self.Patience = 0
    CombatService:Start()
    PriorityService:Request("AutoSummon")

    if self.AutoSpawnRemote and not self.LastSummonState then
        pcall(function() self.AutoSpawnRemote:FireServer(self.SelectedSummonBoss) end)
        self.LastSummonState = true
    end

    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait(1) do
            
            if PriorityService:GetPermittedTask() ~= "AutoSummon" then
                task.wait(1)
                continue
            end

            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            local currentIsland = self:GetCurrentIsland(hrp)
            if currentIsland ~= self.TargetIsland then
                if self.TargetBossModel then CombatService:SetTarget(nil); self.TargetBossModel = nil end
                self.Patience = 0
                TeleportService:TeleportToIsland(self.TargetIsland)
                SpawnService.SpawnSetado = false
                RandomService:Wait(1.5, 2.5)
                continue
            end
            
            if not SpawnService.SpawnSetado then
                CombatService:SetTarget(nil, false)
                SpawnService:SetSpawn()
                task.wait(1)
                continue
            end
            
            if not self.TargetBossModel or not self.TargetBossModel:FindFirstChild("Humanoid") or self.TargetBossModel.Humanoid.Health <= 0 then
                self.TargetBossModel = self:GetBossModel(self.SelectedSummonBoss)
            end
            
            if self.TargetBossModel then
                self.Patience = 0
                CombatService:SetTarget(self.TargetBossModel, true)
            else
                CombatService:SetTarget(nil, false)
                self.TargetBossModel = nil
                
                self.Patience = self.Patience + 1
                
                if self.Patience >= 3 then
                    if self.SummonRemote then
                        pcall(function() self.SummonRemote:FireServer(self.SelectedSummonBoss) end)
                    end
                    self.Patience = 0
                    RandomService:Wait(1.0, 2.0)
                end
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    CombatService:Stop()
    PriorityService:Release("AutoSummon")
    
    if self.AutoSpawnRemote and self.LastSummonState then
        pcall(function() self.AutoSpawnRemote:FireServer(self.SelectedSummonBoss) end)
        self.LastSummonState = false
    end
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
