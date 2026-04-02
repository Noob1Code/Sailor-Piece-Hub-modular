-- ========================================================================
-- 📦 MÓDULO: NAVEGAÇÃO E TELEPORTE (UI + SERVIÇO GLOBAL)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameData = Import("Config/GameData")

local LP = Players.LocalPlayer
local UI = Import("Ui/UI") 

local Module = {
    NoToggle = true 
}

function Module:Init()
    self.IslandsDisplay = GameData.IslandsInOrder
    self.TeleportMap = GameData.TeleportMap
    self.NpcList = GameData.NpcList
    self.SelectedIsland = self.IslandsDisplay[1]
    self.SelectedNpc = self.NpcList[1]
    self.TeleportRemote = ReplicatedStorage:FindFirstChild("TeleportToPortal", true)
end

function Module:FlyTo(targetPos)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if hrp and hum then
        local distance = (hrp.Position - targetPos).Magnitude
        local tempo = math.max(0.1, distance / 200)
        local tempo = math.max(0.1, distance / speed)

        hum.PlatformStand = true
        hrp.Velocity = Vector3.zero

        local tween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
        tween:Play()
        tween.Completed:Wait()

        hum.PlatformStand = false
    end
end

function Module:FlyToNPC(npcName)
    local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
    local npc = serviceFolder and serviceFolder:FindFirstChild(npcName)
    
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        local pos = npc.HumanoidRootPart.Position + Vector3.new(0, 0, 5)
        self:FlyTo(pos)
        return true
    end
    return false
end

function Module:TeleportToIsland(displayName)
    if self.TeleportRemote then
        local serverIslandName = self.TeleportMap[displayName]
        if serverIslandName then
            local char = LP.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end 
            pcall(function() self.TeleportRemote:FireServer(serverIslandName) end)
            local SpawnService = Import("Services/SpawnService")
            SpawnService:Reset()
        end
    end
end

-- ========================================================================
-- 🖥️ CONSTRUÇÃO DA UI (Agora com Dropdowns!)
-- ========================================================================
function Module:Start()
    local tabName = "Mundo & Teleporte"

    -- --- SEÇÃO DE ILHAS ---
    UI:CreateSection(tabName, "Viagem Interdimensional")

    -- Cria o Dropdown das Ilhas
    UI:CreateDropdown(tabName, "📍 Escolha a Ilha", self.IslandsDisplay, function(selected)
        self.SelectedIsland = selected
    end)

    -- Botão que executa a viagem para a ilha selecionada no dropdown
    UI:CreateButton(tabName, "🔮 Teleportar", function()
        self:TeleportToIsland(self.SelectedIsland)
    end)

    -- --- SEÇÃO DE NPCS ---
    UI:CreateSection(tabName, "Localizador de Serviços")

    -- Cria o Dropdown dos NPCs
    UI:CreateDropdown(tabName, "👤 Escolha o NPC", self.NpcList, function(selected)
        self.SelectedNpc = selected
    end)

    -- Botão que voa até o NPC selecionado no dropdown
    UI:CreateButton(tabName, "✈️ Voar até NPC", function()
        self:FlyToNPC(self.SelectedNpc)
    end)
end

function Module:Stop() end
function Module:Toggle(state) end

return Module
