local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local Module = {}

function Module:Init()
    self.IsRunning = false
    self.MoveLoop = nil
    self.AttackLoop = nil
    self.Target = nil
    self.CombatRemote = pcall(function() return ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit") end) and ReplicatedStorage.CombatSystem.Remotes.RequestHit or nil
    self.AbilityRemote = pcall(function() return ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility") end) and ReplicatedStorage.AbilitySystem.Remotes.RequestAbility or nil
end

function Module:GetEnemy()
    local closest, minDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        local hum = npc:FindFirstChild("Humanoid")
        local npcBase = npc:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and npcBase and not npc:GetAttribute("IsTrainingDummy") then
            local dist = (hrp.Position - npcBase.Position).Magnitude
            if dist < minDist then minDist = dist; closest = npc end
        end
    end
    return closest
end

function Module:EquipWeapon()
    local char = LP.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local backpack = LP:FindFirstChild("Backpack")
        if backpack then tool = backpack:FindFirstChildOfClass("Tool"); if tool then tool.Parent = char end end
    end
end

function Module:Start()
    self.IsRunning = true
    self.MoveLoop = task.spawn(function()
        while self.IsRunning and task.wait() do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if not self.Target or not self.Target:FindFirstChild("Humanoid") or self.Target.Humanoid.Health <= 0 then
                self.Target = self:GetEnemy()
            end

            if self.Target and hrp and hum then
                local targetHrp = self.Target:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    hrp.Velocity = Vector3.zero
                    hum.PlatformStand = true
                    hrp.CFrame = CFrame.new(targetHrp.Position - (targetHrp.CFrame.LookVector * 5) + Vector3.new(0, 5, 0), targetHrp.Position)
                end
            else
                if hum then hum.PlatformStand = false end
            end
        end
    end)

    self.AttackLoop = task.spawn(function()
        while self.IsRunning and task.wait(0.1) do
            if self.Target and self.Target:FindFirstChild("Humanoid") and self.Target.Humanoid.Health > 0 then
                self:EquipWeapon()
                if self.CombatRemote then pcall(function() self.CombatRemote:FireServer() end) end
                if self.AbilityRemote then for i = 1, 4 do pcall(function() self.AbilityRemote:FireServer(i) end) end end
            end
        end
    end)
end

function Module:Stop()
    self.IsRunning = false
    if self.MoveLoop then task.cancel(self.MoveLoop); self.MoveLoop = nil end
    if self.AttackLoop then task.cancel(self.AttackLoop); self.AttackLoop = nil end
    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
    self.Target = nil
end

function Module:Toggle(state)
    if state then self:Start() else self:Stop() end
end

return Module