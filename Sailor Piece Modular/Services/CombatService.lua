-- ========================================================================
-- ⚔️ SERVIÇO: COMBAT SERVICE (O MÚSCULO DO HUB)
-- ========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local WeaponService = Import("Services/WeaponService") 

local CombatService = {
    IsActive = false,
    Target = nil,
    UseOrbit = false,
    OrbitAngle = 0,
    MoveLoop = nil,
    AttackLoop = nil
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

function CombatService:SetTarget(targetEntity, useOrbit)
    self.Target = targetEntity
    self.UseOrbit = useOrbit
end

function CombatService:Start()
    if self.IsActive then return end
    self.IsActive = true

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
                    
                    if self.UseOrbit then
                        self.OrbitAngle = self.OrbitAngle + math.rad(15)
                        local pos = targetHrp.Position + Vector3.new(math.cos(self.OrbitAngle) * 8, 5, math.sin(self.OrbitAngle) * 8)
                        hrp.CFrame = CFrame.new(pos, targetHrp.Position)
                    else
                        local pos = targetHrp.Position - (targetHrp.CFrame.LookVector * 6) + Vector3.new(0, 6, 0)
                        hrp.CFrame = CFrame.new(pos, targetHrp.Position)
                    end
                end
            else
                if hum then hum.PlatformStand = false end
            end
        end
    end)

    self.AttackLoop = task.spawn(function()
        local fruitKeys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}

        while self.IsActive and task.wait(0.1) do
            if self.Target and self.Target:FindFirstChild("Humanoid") and self.Target.Humanoid.Health > 0 then
                
                local weaponsToUse = WeaponService.SelectedWeapons
                local namesToAttack = {}

                if #weaponsToUse == 0 then
                    local firstWep = self:EquipFirstWeapon()
                    if firstWep then table.insert(namesToAttack, firstWep) end
                else
                    for _, wName in ipairs(weaponsToUse) do
                        if WeaponService:EquipWeapon(wName) then
                            table.insert(namesToAttack, wName)
                        end
                    end
                end

                for _, wName in ipairs(namesToAttack) do
                    if self.CombatRemote then pcall(function() self.CombatRemote:FireServer() end) end
                    
                    if self.AbilityRemote then 
                        for i = 1, 4 do pcall(function() self.AbilityRemote:FireServer(i) end) end 
                    end

                    if self.FruitRemote then
                        for _, key in ipairs(fruitKeys) do
                            pcall(function()
                                self.FruitRemote:FireServer("UseAbility", {
                                    ["KeyCode"] = key,
                                    ["FruitPower"] = wName
                                })
                            end)
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
    if self.MoveLoop then task.cancel(self.MoveLoop); self.MoveLoop = nil end
    if self.AttackLoop then task.cancel(self.AttackLoop); self.AttackLoop = nil end
    local char = LP.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

return CombatService
