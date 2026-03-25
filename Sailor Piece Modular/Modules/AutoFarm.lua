-- ========================================================================
-- 📦 MÓDULO: AUTO FARM ESPECÍFICO (FILTRO POR ILHA E MOB)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local UI = Import("Ui/UI")
local TeleportService = Import("Services/Teleport")
local GameData = Import("Config/GameData")
local CombatService = Import("Services/CombatService")
local SpawnService = Import("Services/SpawnService")
local PriorityService = Import("Services/PriorityService")

local Module = {
    NoToggle = true 
}

function Module:Init()
    self.IsRunning = false
    self.BrainLoop = nil
    self.Target = nil

    self.IslandsInOrder = GameData.IslandsInOrder
    self.SelectedIsland = self.IslandsInOrder[1]
    
    -- Extrai a lista inicial de mobs da primeira ilha
    self.CurrentMobList = self:GetMobsFromIsland(self.SelectedIsland)
    self.SelectedMob = self.CurrentMobList[1]
end

-- ========================================================================
-- 🔍 FUNÇÕES DE FILTRO E BUSCA
-- ========================================================================
-- Extrai apenas os nomes dos Mobs (Targets) do nosso Banco de Dados
function Module:GetMobsFromIsland(islandName)
    local mobs = {}
    local quests = GameData.QuestDataMap[islandName]
    
    if quests then
        for _, quest in ipairs(quests) do
            if quest.Target ~= "Nenhum" then
                table.insert(mobs, quest.Target)
            end
        end
    end
    
    if #mobs == 0 then table.insert(mobs, "Nenhum Mob") end
    return mobs
end

function Module:GetEnemy(targetName)
    if targetName == "Nenhum Mob" then return nil end
    local closest, minDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        local hum = npc:FindFirstChild("Humanoid")
        local npcBase = npc:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and npcBase and not npc:GetAttribute("IsTrainingDummy") then
            -- Match Exato do nome
            local cleanNpcName = npc.Name:gsub("%d+", ""):lower():gsub("%s+", "")
            local cleanTarget = targetName:lower():gsub("%s+", "")

            if cleanNpcName == cleanTarget then
                local dist = (hrp.Position - npcBase.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = npc
                end
            end
        end
    end
    return closest
end

-- ========================================================================
-- 📍 SISTEMA DE GPS (Para teleportar se estiver na ilha errada)
-- ========================================================================
function Module:GetCurrentIsland(hrp)
    local closestIsland = nil
    local minDist = math.huge
    local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
    if not serviceFolder then return nil end

    for npcName, islandName in pairs(GameData.NpcToIsland) do
        local npc = serviceFolder:FindFirstChild(npcName)
        if npc and npc:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closestIsland = islandName
            end
        end
    end
    return closestIsland
end

function Module:NeedsTeleport(hrp, targetIsland)
    local currentIsland = self:GetCurrentIsland(hrp)
    if not currentIsland then return true end
    return currentIsland ~= targetIsland
end

-- ========================================================================
-- 🖥️ UI COM DROPDOWNS DINÂMICOS
-- ========================================================================
local function CreateDynamicDropdown(container, defaultText, options, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, -10, 0, 35)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.ClipsDescendants = true
    dropdownFrame.Parent = container

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, 0, 0, 35)
    mainBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.TextSize = 13
    mainBtn.Text = defaultText .. " ▼"
    mainBtn.Parent = dropdownFrame
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 4)

    local optionsContainer = Instance.new("ScrollingFrame")
    optionsContainer.Size = UDim2.new(1, 0, 1, -40)
    optionsContainer.Position = UDim2.new(0, 0, 0, 40)
    optionsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    optionsContainer.ScrollBarThickness = 2
    optionsContainer.Parent = dropdownFrame
    Instance.new("UICorner", optionsContainer).CornerRadius = UDim.new(0, 4)

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = optionsContainer

    local isOpen = false

    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        mainBtn.Text = defaultText .. (isOpen and " ▲" or " ▼")
        dropdownFrame.Size = isOpen and UDim2.new(1, -10, 0, 130) or UDim2.new(1, -10, 0, 35)
    end)

    local function populate(newOptions)
        for _, child in ipairs(optionsContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, option in ipairs(newOptions) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -5, 0, 25)
            optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            optBtn.Font = Enum.Font.GothamSemibold
            optBtn.TextSize = 12
            optBtn.Text = option
            optBtn.Parent = optionsContainer
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)

            optBtn.MouseButton1Click:Connect(function()
                isOpen = false
                defaultText = "📍 " .. option
                mainBtn.Text = defaultText .. " ▼"
                dropdownFrame.Size = UDim2.new(1, -10, 0, 35)
                if callback then callback(option) end
            end)
        end
        task.wait(0.1)
        optionsContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end

    populate(options)
    
    return {
        Refresh = function(newOptions, resetText)
            defaultText = resetText
            mainBtn.Text = defaultText .. " ▼"
            populate(newOptions)
        end
    }
end

function Module:Start()
    local tabName = "Farm & Nível"
    UI:CreateSection(tabName, "Auto Farm Específico")

    local container = UI.Tabs[tabName].Container
    local mobDropdown

    -- Dropdown 1: Selecionar a Ilha
    CreateDynamicDropdown(container, "🌍 Ilha: " .. self.SelectedIsland, self.IslandsInOrder, function(island)
        self.SelectedIsland = island
        self.CurrentMobList = self:GetMobsFromIsland(island)
        self.SelectedMob = self.CurrentMobList[1]
        
        -- Atualiza as opções do Dropdown de Mobs!
        mobDropdown.Refresh(self.CurrentMobList, "🎯 Mob: " .. self.SelectedMob)
    end)

    -- Dropdown 2: Selecionar o Mob
    mobDropdown = CreateDynamicDropdown(container, "🎯 Mob: " .. self.SelectedMob, self.CurrentMobList, function(mob)
        self.SelectedMob = mob
    end)

    UI:CreateToggle(tabName, "Auto Farm Mob", function(state)
        self:Toggle(state)
    end)
    
    local WeaponService = Import("Services/WeaponService")
    WeaponService:BuildUI(tabName)
end

-- ========================================================================
-- 🧠 O CÉREBRO: LÓGICA DE FARM
-- ========================================================================
function Module:StartFarm()
    self.IsRunning = true
    CombatService:Start()

    PriorityService:Request("AutoFarm")

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait() do

            if PriorityService:GetPermittedTask() ~= "AutoFarm" then
                CombatService:SetTarget(nil, false)
                task.wait(1)
                continue
            end

            CombatService:Start()
                
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or self.SelectedMob == "Nenhum Mob" then continue end

            -- GPS de Ilha: Garante que estamos na ilha correta do mob selecionado
            if self:NeedsTeleport(hrp, self.SelectedIsland) then
                CombatService:SetTarget(nil, false) 
                print("🗺️ Localização divergente! Teleportando para: " .. self.SelectedIsland)
                TeleportService:TeleportToIsland(self.SelectedIsland)
                task.wait(4)
                continue
            end

            if not SpawnService.SpawnSetado then
                CombatService:SetTarget(nil, false)
                SpawnService:SetSpawn()
                task.wait(1)
                continue
            end

            -- Busca o alvo
            if not self.Target or not self.Target:FindFirstChild("Humanoid") or self.Target.Humanoid.Health <= 0 then
                self.Target = self:GetEnemy(self.SelectedMob)
            end

            if self.Target then
                CombatService:SetTarget(self.Target, false) 
            else
                CombatService:SetTarget(nil, false)
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    CombatService:Stop()
    self.Target = nil
    PriorityService:Release("AutoFarm")
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
