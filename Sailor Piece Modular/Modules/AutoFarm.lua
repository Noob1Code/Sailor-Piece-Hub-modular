-- ========================================================================
-- 📦 MÓDULO: AUTO FARM (GENÉRICO) - REFATORADO
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")
local CombatService = Import("Services/CombatService") -- O nosso Músculo!

local Module = {}

function Module:Init()
    self.IsRunning = false
    self.BrainLoop = nil
    self.Target = nil
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

function Module:Start()
    self.IsRunning = true
    
    -- Acorda o músculo
    CombatService:Start()

    -- O Cérebro: Apenas encontra o inimigo e diz ao músculo para atacar
    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait() do
            if not self.Target or not self.Target:FindFirstChild("Humanoid") or self.Target.Humanoid.Health <= 0 then
                self.Target = self:GetEnemy()
            end

            if self.Target then
                -- true = usa o voo orbital (giratório). false = usa o voo fixo nas costas.
                CombatService:SetTarget(self.Target, false) 
            else
                CombatService:SetTarget(nil, false) -- Pausa se não houver alvo
            end
        end
    end)
end

function Module:Stop()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    
    -- Manda o músculo descansar
    CombatService:Stop()
    self.Target = nil
end

function Module:Toggle(state)
    if state then self:Start() else self:Stop() end
end

return Module
