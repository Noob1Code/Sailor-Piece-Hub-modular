-- ========================================================================
-- 📦 MÓDULO: AUTO BOSS - REFATORADO
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")
local CombatService = Import("Services/CombatService")

local Module = {
    NoToggle = true
}

function Module:Init()
    self.IsRunning = false
    self.TargetBossName = ""
    self.BossTarget = nil
    self.BrainLoop = nil
end

function Module:GetBoss()
    local closest, minDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local function checkFolder(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 then
                local objHrp = obj:FindFirstChild("HumanoidRootPart")
                local isBoss = obj.Name:lower():find("boss") or obj:GetAttribute("Boss") or obj:GetAttribute("_IsTimedBoss")
                
                if objHrp and isBoss and not obj:GetAttribute("IsTrainingDummy") then
                    if self.TargetBossName == "" or obj.Name:lower():find(self.TargetBossName:lower()) then
                        local dist = (hrp.Position - objHrp.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            closest = obj
                        end
                    end
                end
            end
            if obj.Name:find("BossSpawn") or obj.Name:find("TimedBoss") then checkFolder(obj) end
        end
    end

    checkFolder(Workspace:FindFirstChild("NPCs"))
    checkFolder(Workspace)
    return closest
end

function Module:Start()
    local tabName = "Chefes (Boss)"
    local container = UI.Tabs[tabName].Container

    UI:CreateSection(tabName, "Configuração do Alvo")

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -10, 0, 35)
    textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = "Nome do Boss (Deixe vazio para Todos)"
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 13
    textBox.Text = ""
    textBox.Parent = container
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)

    textBox.FocusLost:Connect(function()
        self.TargetBossName = textBox.Text
    end)

    UI:CreateToggle(tabName, "Auto Farm Boss", function(state)
        self:Toggle(state)
    end)
end

function Module:StartFarm()
    self.IsRunning = true
    
    -- Acorda o músculo
    CombatService:Start()

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait() do
            if not self.BossTarget or not self.BossTarget:FindFirstChild("Humanoid") or self.BossTarget.Humanoid.Health <= 0 then
                self.BossTarget = self:GetBoss()
            end

            if self.BossTarget then
                -- Para Bosses, usar voo orbital (true) costuma ser melhor para esquivar
                CombatService:SetTarget(self.BossTarget, true) 
            else
                CombatService:SetTarget(nil, false)
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    
    -- Manda o músculo descansar
    CombatService:Stop()
    self.BossTarget = nil
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
