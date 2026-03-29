-- ========================================================================
-- ⚔️ SERVIÇO: COMBAT SERVICE (O MÚSCULO DO HUB) - COM FILTRO DE SKILLS
-- ========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local WeaponService = Import("Services/WeaponService") 

local CombatService = {
    IsActive = false,
    Target = nil,
    OrbitAngle = 0,
    MoveLoop = nil,
    AttackLoop = nil,
    
    AttackPosition = "Atrás",
    AttackDistance = 6,
    
    EnabledSkills = {
        Z = true,
        X = true,
        C = true,
        V = true,
        F = true
    },
    
    SkillQueue = {},
    LastSkillTime = 0,
    ThrottleDelay = 0.8,
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

function CombatService:SetTarget(targetEntity)
    if self.Target ~= targetEntity then self:CancelTween() end
    self.Target = targetEntity
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
                    
                    local distConfig = self.AttackDistance
                    local pos
                    local mode = self.AttackPosition
                    
                    if mode == "Orbital" then
                        self.OrbitAngle = self.OrbitAngle + math.rad(15)
                        pos = targetHrp.Position + Vector3.new(math.cos(self.OrbitAngle) * distConfig, 5, math.sin(self.OrbitAngle) * distConfig)
                    elseif mode == "Frente" then
                        pos = targetHrp.Position + (targetHrp.CFrame.LookVector * distConfig) + Vector3.new(0, 5, 0)
                    elseif mode == "Acima" then
                        pos = targetHrp.Position + Vector3.new(0, distConfig + 5, 0)
                    elseif mode == "Abaixo" then
                        pos = targetHrp.Position + Vector3.new(0, -distConfig - 2, 0)
                    elseif mode == "Diagonal" then
                        pos = targetHrp.Position + (targetHrp.CFrame.LookVector * -distConfig) + (targetHrp.CFrame.RightVector * distConfig) + Vector3.new(0, 5, 0)
                    else
                        pos = targetHrp.Position - (targetHrp.CFrame.LookVector * distConfig) + Vector3.new(0, 5, 0)
                    end
                    
                    local targetCFrame = CFrame.new(pos, targetHrp.Position)
                    local dist = (hrp.Position - pos).Magnitude
                    
                    if dist > 15 then
                        if not self.CurrentTween or self.CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                            self.CurrentTween = TweenService:Create(hrp, TweenInfo.new(dist/150, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
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
            {Key = "Z", Fruit = Enum.KeyCode.Z, Melee = 1},
            {Key = "X", Fruit = Enum.KeyCode.X, Melee = 2},
            {Key = "C", Fruit = Enum.KeyCode.C, Melee = 3},
            {Key = "V", Fruit = Enum.KeyCode.V, Melee = 4},
            {Key = "F", Fruit = Enum.KeyCode.F, Melee = 5}
        }

        while self.IsActive and task.wait(0.1) do
            if self.Target and self.Target:FindFirstChild("Humanoid") and self.Target.Humanoid.Health > 0 then
                
                if self.CombatRemote then pcall(function() self.CombatRemote:FireServer() end) end
                
                if tick() - self.LastSkillTime >= self.ThrottleDelay then
                    if #self.SkillQueue > 0 then
                        local currentPair = table.remove(self.SkillQueue, 1)
                        local weaponsToUse = WeaponService.SelectedWeapons
                        local listToIterate = #weaponsToUse > 0 and weaponsToUse or {self:EquipFirstWeapon()}
                        
                        for _, wName in ipairs(listToIterate) do
                            if wName then
                                WeaponService:EquipWeapon(wName)
                                if self.FruitRemote then pcall(function() self.FruitRemote:FireServer("UseAbility", {["KeyCode"] = currentPair.Fruit, ["FruitPower"] = wName}) end) end
                                if self.AbilityRemote then pcall(function() self.AbilityRemote:FireServer(currentPair.Melee) end) end
                            end
                        end
                        self.LastSkillTime = tick()
                    else
                        for _, pair in ipairs(skillPairs) do
                            if self.EnabledSkills[pair.Key] then
                                table.insert(self.SkillQueue, pair)
                            end
                        end
                    end
                end
            end
        end
    end)
end

function CombatService:Stop()
    self.IsActive = false; self.Target = nil; self.SkillQueue = {}; self:CancelTween()
    if self.MoveLoop then task.cancel(self.MoveLoop); self.MoveLoop = nil end
    if self.AttackLoop then task.cancel(self.AttackLoop); self.AttackLoop = nil end
    local char = LP.Character; local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

return CombatService
