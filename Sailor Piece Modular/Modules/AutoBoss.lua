-- ========================================================================
-- 👑 MÓDULO: AUTO BOSS AVANÇADO (SISTEMA DE FILA)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")
local TeleportService = Import("Services/Teleport")
local GameData = Import("Config/GameData")
local CombatService = Import("Services/CombatService")
local PriorityService = Import("Services/PriorityService")

local Module = { NoToggle = true }

function Module:Init()
    self.IsRunning = false
    self.BossQueue = {}
    self.AllBosses = {}
    
    -- 1. Extrai os Bosses Padrões (Que têm Missão)
    for island, quests in pairs(GameData.QuestDataMap) do
        for _, q in ipairs(quests) do
            if q.Type == "Boss" then
                table.insert(self.AllBosses, {
                    Target = q.Target,
                    Island = island
                })
            end
        end
    end

    -- 2. Extrai os Bosses Ocultos e de Eventos (Que NÃO têm Missão)
    if GameData.HiddenBosses then
        for island, bosses in pairs(GameData.HiddenBosses) do
            for _, bossName in ipairs(bosses) do
                table.insert(self.AllBosses, {
                    Target = bossName,
                    Island = island
                })
            end
        end
    end
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

function Module:GetBossModel(targetName)
    local closest, minDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    local cleanTarget = targetName:lower():gsub("%s+", "")

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        local hum = npc:FindFirstChild("Humanoid")
        local npcBase = npc:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and npcBase then
            local cleanNpcName = npc.Name:gsub("%d+", ""):lower():gsub("%s+", "")
            if cleanNpcName == cleanTarget then
                local dist = (hrp.Position - npcBase.Position).Magnitude
                if dist < minDist then minDist, closest = dist, npc end
            end
        end
    end
    return closest
end

-- ========================================================================
-- 🖥️ UI: COMPONENTES DINÂMICOS
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
            
            local displayText = type(option) == "table" and option.Target or option
            optBtn.Text = displayText
            optBtn.Parent = optionsContainer
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)

            optBtn.MouseButton1Click:Connect(function()
                isOpen = false
                defaultText = "📍 " .. displayText
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
    local tabName = "Chefes (Boss)"
    UI:CreateSection(tabName, "Filtro e Seleção")
    local container = UI.Tabs[tabName].Container

    -- Variáveis de controle da UI
    local filterOptions = { "Todas as Ilhas" }
    for _, island in ipairs(GameData.IslandsInOrder) do table.insert(filterOptions, island) end

    local currentFilter = "Todas as Ilhas"
    local filteredBosses = {}
    local selectedToAdd = nil
    local selectedToRemoveIndex = nil

    local bossDropdown
    local queueDropdown

    local function UpdateFilteredBosses()
        filteredBosses = {}
        for _, b in ipairs(self.AllBosses) do
            if currentFilter == "Todas as Ilhas" or b.Island == currentFilter then
                table.insert(filteredBosses, b)
            end
        end
        selectedToAdd = filteredBosses[1]
    end
    UpdateFilteredBosses()

    local function RefreshQueueUI()
        local queueDisplay = {}
        for i, b in ipairs(self.BossQueue) do
            table.insert(queueDisplay, { Target = i .. ". " .. b.Target, Index = i })
        end
        if #queueDisplay == 0 then table.insert(queueDisplay, { Target = "Fila Vazia", Index = 0 }) end
        
        selectedToRemoveIndex = queueDisplay[1].Index
        if queueDropdown then queueDropdown.Refresh(queueDisplay, "🗑️ Remover: " .. queueDisplay[1].Target) end
    end

    -- 1. Filtro de Ilhas
    CreateDynamicDropdown(container, "🌍 Filtro: Todas as Ilhas", filterOptions, function(island)
        currentFilter = island
        UpdateFilteredBosses()
        if selectedToAdd then
            bossDropdown.Refresh(filteredBosses, "💀 Boss: " .. selectedToAdd.Target)
        end
    end)

    -- 2. Lista de Bosses Disponíveis (Limpa)
    bossDropdown = CreateDynamicDropdown(container, "💀 Boss: " .. (selectedToAdd and selectedToAdd.Target or "Nenhum"), filteredBosses, function(boss)
        selectedToAdd = boss
    end)

    -- 3. Adicionar à Lista
    UI:CreateButton(tabName, "➕ Adicionar Boss à Fila", function()
        if selectedToAdd then
            table.insert(self.BossQueue, selectedToAdd)
            print("Boss adicionado à fila: " .. selectedToAdd.Target)
            RefreshQueueUI()
        end
    end)

    UI:CreateSection(tabName, "Gerenciar Fila")

    -- 4. Lista da Fila Atual
    queueDropdown = CreateDynamicDropdown(container, "🗑️ Selecione para Remover", {{Target="Fila Vazia", Index=0}}, function(qItem)
        selectedToRemoveIndex = qItem.Index
    end)

    -- 5. Remover da Lista
    UI:CreateButton(tabName, "➖ Remover da Fila", function()
        if selectedToRemoveIndex and selectedToRemoveIndex > 0 then
            table.remove(self.BossQueue, selectedToRemoveIndex)
            RefreshQueueUI()
        end
    end)

    -- 6. Controle de Execução
    UI:CreateToggle(tabName, "Ligar Auto Boss (Fila)", function(state) self:Toggle(state) end)
    RefreshQueueUI()
end

-- ========================================================================
-- 🔄 LÓGICA DO CÉREBRO: OTIMIZAÇÃO E EXECUÇÃO
-- ========================================================================
function Module:StartFarm()
    self.IsRunning = true
    CombatService:Start()
    PriorityService:Request("AutoBoss")

    self.BrainLoop = task.spawn(function()
        local queueIndex = 1

        while self.IsRunning and task.wait() do
            -- Pausa se outro módulo (como AutoQuest) tiver prioridade maior
            if PriorityService:GetPermittedTask() ~= "AutoBoss" then
                CombatService:SetTarget(nil, false)
                task.wait(1)
                continue
            end
            
            -- Se a fila estiver vazia, aguarda
            if #self.BossQueue == 0 then
                CombatService:SetTarget(nil, false)
                task.wait(1)
                continue
            end

            -- Reinicia o ciclo se chegar ao fim da fila
            if queueIndex > #self.BossQueue then queueIndex = 1 end
            
            local currentBoss = self.BossQueue[queueIndex]
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            -- 🌍 TELEPORTE INTELIGENTE
            local currentIsland = self:GetCurrentIsland(hrp)
            if currentIsland ~= currentBoss.Island then
                CombatService:SetTarget(nil, false)
                TeleportService:TeleportToIsland(currentBoss.Island)
                task.wait(4) -- Tempo para renderizar a ilha
                continue
            end
            
            -- 🎯 CAÇA AO BOSS
            local bossModel = self:GetBossModel(currentBoss.Target)
            
            if bossModel then
                -- O Boss está vivo! Atacar!
                CombatService:SetTarget(bossModel, true)
            else
                -- ⚡ O Boss está morto ou não spawnou! Pula para o próximo da fila
                CombatService:SetTarget(nil, false)
                queueIndex = queueIndex + 1
                task.wait(0.5) -- Pequeno delay antes de checar o próximo da fila
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    CombatService:Stop()
    PriorityService:Release("AutoBoss")
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
