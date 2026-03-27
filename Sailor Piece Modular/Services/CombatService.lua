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
    AttackLoop = nil,
    
    -- 🔥 SISTEMA DE CONTROLE DE SPAM (Anti-Crash)
    SkillQueue = {},
    LastSkillTime = 0,
    ThrottleDelay = 0.35 -- Dispara 1 habilidade a cada 0.35s (Salva a CPU e Rede)
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
    
    -- Limpa a fila ao iniciar
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

        -- O loop roda a cada 0.1s para ataques básicos
        while self.IsActive and task.wait(0.1) do
            if self.Target and self.Target:FindFirstChild("Humanoid") and self.Target.Humanoid.Health > 0 then
                
                -- 1. ATAQUE BÁSICO (Pode ser rápido, não trava o jogo)
                if self.CombatRemote then pcall(function() self.CombatRemote:FireServer() end) end
                
                -- 2. FILA DE HABILIDADES (Executa 1 por vez com Throttle)
                if tick() - self.LastSkillTime >= self.ThrottleDelay then
                    
                    if #self.SkillQueue > 0 then
                        -- Retira a primeira habilidade da fila e dispara
                        local skillToCast = table.remove(self.SkillQueue, 1)
                        
                        if skillToCast.Type == "Ability" then
                            if self.AbilityRemote then 
                                pcall(function() self.AbilityRemote:FireServer(skillToCast.Key) end) 
                            end
                        elseif skillToCast.Type == "Fruit" then
                            if self.FruitRemote then
                                pcall(function() self.FruitRemote:FireServer("UseAbility", {["KeyCode"] = skillToCast.Key, ["FruitPower"] = skillToCast.Weapon}) end)
                            end
                        end
                        
                        -- Atualiza o tempo para garantir o delay da próxima
                        self.LastSkillTime = tick()
                    else
                        -- Fila vazia? Vamos preencher com as habilidades da Arma Atual!
                        local weaponsToUse = WeaponService.SelectedWeapons
                        local wName = nil

                        if #weaponsToUse == 0 then
                            wName = self:EquipFirstWeapon()
                        else
                            -- 🔥 LIMITAÇÃO VITAL: Equipa APENAS a primeira arma da lista. 
                            -- Impede o jogo de calcular física de 5 itens no mesmo frame.
                            wName = weaponsToUse[1]
                            WeaponService:EquipWeapon(wName)
                        end

                        if wName then
                            -- Popula as skills numeradas (1, 2, 3, 4)
                            for i = 1, 4 do
                                table.insert(self.SkillQueue, {Type = "Ability", Key = i, Weapon = wName})
                            end
                            -- Popula as skills de fruta (Z, X, C, V)
                            for _, k in ipairs(fruitKeys) do
                                table.insert(self.SkillQueue, {Type = "Fruit", Key = k, Weapon = wName})
                            end
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
    
    if self.MoveLoop then task.cancel(self.MoveLoop); self.MoveLoop = nil end
    if self.AttackLoop then task.cancel(self.AttackLoop); self.AttackLoop = nil end
    
    local char = LP.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

return CombatService
