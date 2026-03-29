-- ========================================================================
-- ⚔️ SERVIÇO: COMBAT SERVICE (O MÚSCULO DO HUB) - MODO VOO SUAVE (ANTI-CRASH)
-- ========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local WeaponService = Import("Services/WeaponService") 

local CombatService = {
    IsActive = false,
    Target = nil,
    UseOrbit = false,
    OrbitAngle = 0,
    MoveLoop = nil,
    AttackLoop = nil,
    SkillQueue = {},
    LastSkillTime = 0,
    ThrottleDelay = 0.2,
    CurrentTween = nil
}

function CombatService:Init()
    self.CombatRemote = pcall(function() return ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit") end) and ReplicatedStorage.CombatSystem.Remotes.RequestHit or nil
    self.AbilityRemote = pcall(function() return ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility") end) and ReplicatedStorage.AbilitySystem.Remotes.RequestAbility or nil
    self.FruitRemote = pcall(function() return ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("FruitPowerRemote") end) and ReplicatedStorage.RemoteEvents.FruitPowerRemote or nil
end

function CombatService:EquipFirstWeapon()
    local char = LP.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local backpack = LP:FindFirstChild("Backpack")
        if backpack then 
            tool = backpack:FindFirstChildOfClass("Tool")
            if tool then tool.Parent = char end 
        end
    end
    return tool and tool.Name or nil
end

function CombatService:CancelTween()
    if self.CurrentTween then
        pcall(function() self.CurrentTween:Cancel() end)
        self.CurrentTween = nil
    end
end

function CombatService:SetTarget(targetEntity, useOrbit)
    if self.Target ~= targetEntity then
        self:CancelTween()
    end
    self.Target = targetEntity
    self.UseOrbit = useOrbit
end

function CombatService:Start()
    if self.IsActive then return end
    self.IsActive = true
    
    self.SkillQueue = {}
    self.LastSkillTime = 0

    self.MoveLoop = task.spawn(function()
        while self.IsActive and task.wait() do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if self.Target and self.Target:FindFirstChild("Humanoid") and self.Target.Humanoid.Health > 0 and hrp and hum then
                local targetHrp = self.Target:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    hum.PlatformStand = true
                    hrp.Velocity = Vector3.zero
                    
                    local pos
                    if self.UseOrbit then
                        self.OrbitAngle = self.OrbitAngle + math.rad(15)
                        pos = targetHrp.Position + Vector3.new(math.cos(self.OrbitAngle) * 8, 5, math.sin(self.OrbitAngle) * 8)
                    else
                        pos = targetHrp.Position - (targetHrp.CFrame.LookVector * 6) + Vector3.new(0, 6, 0)
                    end
                    
                    local targetCFrame = CFrame.new(pos, targetHrp.Position)
                    local dist = (hrp.Position - pos).Magnitude
                    
                    if dist > 15 then
                        if not self.CurrentTween or self.CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                            local tempo = dist / 150
                            if tempo < 0.1 then tempo = 0.1 end
                            
                            self.CurrentTween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
                            self.CurrentTween:Play()
                        end
                    else
                        self:CancelTween()
                        hrp.CFrame = targetCFrame
                    end
                end
            else
                self:CancelTween()
                if hum then hum.PlatformStand = false end
            end
        end
    end)

    self.AttackLoop = task.spawn(function()
        local skillPairs = {
            {Fruit = Enum.KeyCode.Z, Melee = 1},
            {Fruit = Enum.KeyCode.X, Melee = 2},
            {Fruit = Enum.KeyCode.C, Melee = 3},
            {Fruit = Enum.KeyCode.V, Melee = 4}
        }

        while self.IsActive and task.wait(0.1) do
            if self.Target and self.Target:FindFirstChild("Humanoid") and self.Target.Humanoid.Health > 0 then
                
                if self.CombatRemote then pcall(function() self.CombatRemote:FireServer() end) end
                
                if tick() - self.LastSkillTime >= self.ThrottleDelay then
                    if #self.SkillQueue > 0 then
                        local currentPair = table.remove(self.SkillQueue, 1)
                        local weaponsToUse = WeaponService.SelectedWeapons
                        
                        if #weaponsToUse == 0 then
                            local wName = self:EquipFirstWeapon()
                            if wName then
                                if self.FruitRemote then
                                    pcall(function() self.FruitRemote:FireServer("UseAbility", {["KeyCode"] = currentPair.Fruit, ["FruitPower"] = wName}) end)
                                end
                                if self.AbilityRemote then 
                                    pcall(function() self.AbilityRemote:FireServer(currentPair.Melee) end) 
                                end
                            end
                        else
                            for _, wName in ipairs(weaponsToUse) do
                                WeaponService:EquipWeapon(wName)
                                
                                if self.FruitRemote then
                                    pcall(function() self.FruitRemote:FireServer("UseAbility", {["KeyCode"] = currentPair.Fruit, ["FruitPower"] = wName}) end)
                                end
                                if self.AbilityRemote then 
                                    pcall(function() self.AbilityRemote:FireServer(currentPair.Melee) end) 
                                end
                            end
                        end
                        
                        self.LastSkillTime = tick()
                    else
                        for i = 1, 4 do
                            table.insert(self.SkillQueue, skillPairs[i])
                        end
                    end
                end
            end
        end
    end)
end

function CombatService:Stop()
    self.IsActive = false
    self.Target = nil
    self.SkillQueue = {}
    self:CancelTween()
    
    if self.MoveLoop then task.cancel(self.MoveLoop); self.MoveLoop = nil end
    if self.AttackLoop then task.cancel(self.AttackLoop); self.AttackLoop = nil end
    
    local char = LP.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

return CombatService
