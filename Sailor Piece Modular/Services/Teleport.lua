-- ========================================================================
-- 📦 MÓDULO: NAVEGAÇÃO E TELEPORTE (FILTRO DE NPCS E GPS INTELIGENTE)
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

function Module:FlyTo(targetPos)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if hrp and hum then
        local distance = (hrp.Position - targetPos).Magnitude
        
        local speed = (GameData.Settings and GameData.Settings.SlideSpeed) or 200
        local tempo = math.max(0.1, distance / speed)

        hum.PlatformStand = true
        hrp.Velocity = Vector3.zero

        local tween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
        tween:Play()
        tween.Completed:Wait()

        hum.PlatformStand = false
    end
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

function Module:FlyToNPC(npcName)
    local targetIsland = GameData.NpcToIsland[npcName]
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if hrp and targetIsland then
        local currentIsland = self:GetCurrentIsland(hrp)
        if currentIsland ~= targetIsland then
            self:TeleportToIsland(targetIsland)
            task.wait(1.5)
        end
    end

    local serviceFolder = Workspace:WaitForChild("ServiceNPCs", 5)
    if not serviceFolder then return false end

    local npc = serviceFolder:FindFirstChild(npcName)
    
    local retries = 0
    while not npc and retries < 5 do
        task.wait(0.5)
        npc = serviceFolder:FindFirstChild(npcName)
        retries = retries + 1
    end
    
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        local pos = npc.HumanoidRootPart.Position + Vector3.new(0, 0, 5)
        self:FlyTo(pos)
        return true
    end
    
    return false
end

-- ========================================================================
-- 🖥️ HELPER: CRIADOR DE DROPDOWN DINÂMICO
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

-- ========================================================================
-- 🖥️ CONSTRUÇÃO DA UI 
-- ========================================================================
function Module:Start()
    local tabName = "Mundo & Teleporte"
    local container = UI.Tabs[tabName].Container
    
    UI:CreateSection(tabName, "Viagem Interdimensional")

    UI:CreateDropdown(tabName, "📍 Escolha a Ilha", self.IslandsDisplay, function(selected)
        self.SelectedIsland = selected
    end)

    UI:CreateButton(tabName, "🔮 Teleportar", function()
        self:TeleportToIsland(self.SelectedIsland)
    end)

    -- --- SEÇÃO DE NPCS (FILTRADO) ---
    UI:CreateSection(tabName, "Localizador de Serviços")

    local filterOptions = { "Todas as Ilhas" }
    for _, island in ipairs(GameData.IslandsInOrder) do table.insert(filterOptions, island) end

    local currentFilter = "Todas as Ilhas"
    local filteredNPCs = {}
    local npcDropdown

    local function UpdateFilteredNPCs()
        filteredNPCs = {}
        for _, npcName in ipairs(GameData.NpcList) do
            if currentFilter == "Todas as Ilhas" or GameData.NpcToIsland[npcName] == currentFilter then
                table.insert(filteredNPCs, npcName)
            end
        end
        if #filteredNPCs == 0 then table.insert(filteredNPCs, "Nenhum NPC") end
        self.SelectedNpc = filteredNPCs[1]
    end

    UpdateFilteredNPCs()

    CreateDynamicDropdown(container, "🌍 Filtro: Todas as Ilhas", filterOptions, function(island)
        currentFilter = island
        UpdateFilteredNPCs()
        if npcDropdown then
            npcDropdown.Refresh(filteredNPCs, "👤 NPC: " .. self.SelectedNpc)
        end
    end)

    npcDropdown = CreateDynamicDropdown(container, "👤 NPC: " .. self.SelectedNpc, filteredNPCs, function(npc)
        self.SelectedNpc = npc
    end)

    UI:CreateButton(tabName, "✈️ Voar até NPC", function()
        if self.SelectedNpc and self.SelectedNpc ~= "Nenhum NPC" then
            task.spawn(function()
                self:FlyToNPC(self.SelectedNpc)
            end)
        end
    end)
end

function Module:Stop() end
function Module:Toggle(state) end

return Module
