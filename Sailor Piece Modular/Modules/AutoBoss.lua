-- ========================================================================
-- 👑 MÓDULO: AUTO BOSS AVANÇADO (FILA + SNIPER DE CHAT)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local LP = Players.LocalPlayer
local UI = Import("Ui/UI")
local TeleportService = Import("Services/Teleport")
local GameData = Import("Config/GameData")
local CombatService = Import("Services/CombatService")
local PriorityService = Import("Services/PriorityService")
local SpawnService = Import("Services/SpawnService")

local Module = { NoToggle = true }

function Module:Init()
    self.IsRunning = false
    self.BossQueue = {} 
    self.AllBosses = {}
    
    self.ChatConnections = {}
    self.BossStateCache = {} -- "Alive", "Dead", ou "PendingCheck"
    self.DeadTimes = {}      -- Salva o tick() de quando o boss morreu
    
    -- 1. Extrai os Chefes Silenciosos (Que têm Missão)
    for island, quests in pairs(GameData.QuestDataMap) do
        for _, q in ipairs(quests) do
            if q.Type == "Boss" then
                table.insert(self.AllBosses, { Target = q.Target, Island = island })
            end
        end
    end

    -- 2. Extrai os Chefes de Tempo (Que avisam no Chat)
    if GameData.TimedBosses then
        for island, bosses in pairs(GameData.TimedBosses) do
            for _, bossName in ipairs(bosses) do
                table.insert(self.AllBosses, { Target = bossName, Island = island })
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
-- 📡 SNIPER DE CHAT (AGORA COM TRADUTOR)
-- ========================================================================
function Module:MonitorChat(msg)
    if not self.IsRunning then return end
    
    local text = string.lower(msg)
    local msgNoSpaces = text:gsub("%s+", "")
    
    for _, b in ipairs(self.BossQueue) do
        -- 1. Verifica se existe uma tradução no GameData
        local chatNameTranslation = GameData.BossChatNames and GameData.BossChatNames[b.Target]
        local baseName
        
        -- 2. Se tiver tradução, usa ela. Se não, usa a lógica antiga de limpar o nome.
        if chatNameTranslation then
            baseName = string.lower(chatNameTranslation):gsub("%s+", "")
        else
            baseName = string.lower(b.Target:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
        end
        
        -- 3. Procura o nome no chat
        if msgNoSpaces:find(baseName) then 
            if text:find("spawned") then
                self.BossStateCache[b.Target] = "Alive"
                self.DeadTimes[b.Target] = nil
                print("🚨 [SNIPER] O Boss " .. b.Target .. " apareceu no chat! Interceptando...")
            elseif text:find("defeated") then
                self.BossStateCache[b.Target] = "Dead"
                self.DeadTimes[b.Target] = tick()
                print("💀 [SNIPER] O Boss " .. b.Target .. " foi derrotado.")
            end
        end
    end
end

function Module:StartChatSniper()
    pcall(function()
        if TextChatService then
            table.insert(self.ChatConnections, TextChatService.MessageReceived:Connect(function(msg)
                if msg and msg.Text then self:MonitorChat(msg.Text) end
            end))
        end
    end)
    pcall(function()
        local defaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if defaultChat and defaultChat:FindFirstChild("OnMessageDoneFiltering") then
            table.insert(self.ChatConnections, defaultChat.OnMessageDoneFiltering.OnClientEvent:Connect(function(msgData)
                if msgData and msgData.Message then self:MonitorChat(msgData.Message) end
            end))
        end
    end)
end

function Module:StopChatSniper()
    for _, conn in ipairs(self.ChatConnections) do conn:Disconnect() end
    table.clear(self.ChatConnections)
end

-- ========================================================================
-- 🖥️ UI (Mantido igual ao que você já tinha gerado antes)
-- ========================================================================
local function CreateDynamicDropdown(container, defaultText, options, callback)
    -- (O código do Dropdown da UI continua 100% o mesmo da mensagem anterior)
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

    CreateDynamicDropdown(container, "🌍 Filtro: Todas as Ilhas", filterOptions, function(island)
        currentFilter = island
        UpdateFilteredBosses()
        if selectedToAdd then
            bossDropdown.Refresh(filteredBosses, "💀 Boss: " .. selectedToAdd.Target)
        end
    end)

    bossDropdown = CreateDynamicDropdown(container, "💀 Boss: " .. (selectedToAdd and selectedToAdd.Target or "Nenhum"), filteredBosses, function(boss)
        selectedToAdd = boss
    end)

    UI:CreateButton(tabName, "➕ Adicionar Boss à Fila", function()
        if selectedToAdd then
            table.insert(self.BossQueue, selectedToAdd)
            print("Boss adicionado à fila: " .. selectedToAdd.Target)
            RefreshQueueUI()
        end
    end)

    UI:CreateSection(tabName, "Gerenciar Fila")

    queueDropdown = CreateDynamicDropdown(container, "🗑️ Selecione para Remover", {{Target="Fila Vazia", Index=0}}, function(qItem)
        selectedToRemoveIndex = qItem.Index
    end)

    UI:CreateButton(tabName, "➖ Remover da Fila", function()
        if selectedToRemoveIndex and selectedToRemoveIndex > 0 then
            table.remove(self.BossQueue, selectedToRemoveIndex)
            RefreshQueueUI()
        end
    end)

    UI:CreateToggle(tabName, "Ligar Auto Boss (Fila Inteligente)", function(state) self:Toggle(state) end)
    RefreshQueueUI()
end

-- ========================================================================
-- 🔄 LÓGICA DO CÉREBRO: OTIMIZAÇÃO E EXECUÇÃO
-- ========================================================================
function Module:StartFarm()
    self.IsRunning = true
    self:StartChatSniper()
    CombatService:Start()
    PriorityService:Request("AutoBoss")
    
    -- Reseta os status quando liga
    self.BossStateCache = {}
    self.DeadTimes = {}

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait() do
            if PriorityService:GetPermittedTask() ~= "AutoBoss" then
                CombatService:SetTarget(nil, false)
                task.wait(1)
                continue
            end
            
            if #self.BossQueue == 0 then
                CombatService:SetTarget(nil, false)
                task.wait(1)
                continue
            end

            -- 🔥 1. ACORDA OS CHEFES SILENCIOSOS
            for _, b in ipairs(self.BossQueue) do
                local tName = b.Target
                if self.BossStateCache[tName] == "Dead" and self.DeadTimes[tName] then
                    local respawnTime = GameData.SilentBosses and GameData.SilentBosses[tName]
                    if respawnTime then
                        -- Se o tempo de respawn de 8s acabou, marca pra checar de novo
                        if tick() - self.DeadTimes[tName] > respawnTime then
                            self.BossStateCache[tName] = "PendingCheck"
                            self.DeadTimes[tName] = nil
                        end
                    end
                end
            end

            -- 🔥 2. DECIDE QUEM CAÇAR NA FILA
            local currentBoss = nil
            for _, b in ipairs(self.BossQueue) do
                local state = self.BossStateCache[b.Target]
                if state == nil then state = "PendingCheck" end -- A primeira vez que liga, tem que checar todos!
                
                -- Prioridade: Se o Sniper de Chat disse que tá vivo, ou se precisa ser checado
                if state == "Alive" or state == "PendingCheck" then
                    currentBoss = b
                    break
                end
            end

            -- Se todos os bosses da fila estiverem "Dead" esperando o chat ou os 8s
            if not currentBoss then
                CombatService:SetTarget(nil, false)
                task.wait(0.5)
                continue
            end

            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
-- 🌍 TELEPORTE INTELIGENTE E SPAWN
            local currentIsland = self:GetCurrentIsland(hrp)
            if currentIsland ~= currentBoss.Island then
                CombatService:SetTarget(nil, false)
                TeleportService:TeleportToIsland(currentBoss.Island)
                SpawnService.SpawnSetado = false
                task.wait(1.5)
                continue
            end
            
            -- 🛏️ SETAR SPAWN
            if not SpawnService.SpawnSetado then
                CombatService:SetTarget(nil, false)
                SpawnService:SetSpawn()
                task.wait(1)
                continue
            end
            
            -- 🎯 ATAQUE / VALIDAÇÃO
            local bossModel = self:GetBossModel(currentBoss.Target)
            
            if bossModel then
                self.BossStateCache[currentBoss.Target] = "Alive"
                CombatService:SetTarget(bossModel, true)
            else
                CombatService:SetTarget(nil, false)
                self.BossStateCache[currentBoss.Target] = "Dead"
                self.DeadTimes[currentBoss.Target] = tick()
                task.wait(0.5)
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    self:StopChatSniper()
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    CombatService:Stop()
    PriorityService:Release("AutoBoss")
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
