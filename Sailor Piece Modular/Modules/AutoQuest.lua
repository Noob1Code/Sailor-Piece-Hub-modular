-- ========================================================================
-- 📦 MÓDULO: AUTO QUEST (ORQUESTRADOR DE FLUXO)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local UI = Import("Ui/UI")
local TeleportService = Import("Services/Teleport")
local GameData = Import("Config/GameData")
local CombatService = Import("Services/CombatService")
local SpawnService = Import("Services/SpawnService")
local PriorityService = Import("Services/PriorityService")
local QuestService = Import("Services/QuestService")

local Module = { NoToggle = true }

function Module:Init()
    self.IsRunning = false
    self.FarmTarget = nil
    
    self.QuestDataMap = GameData.QuestDataMap
    self.NpcToIsland = GameData.NpcToIsland
    self.IslandsInOrder = GameData.IslandsInOrder

    self.SelectedIsland = self.IslandsInOrder[1]
    self.SelectedQuest = self.QuestDataMap[self.SelectedIsland][1]
    self.SelectedQuest.Island = self.SelectedIsland
end

function Module:GetCurrentIsland(hrp)
    local closestIsland, minDist = nil, math.huge
    local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
    if not serviceFolder then return nil end

    for npcName, islandName in pairs(self.NpcToIsland) do
        local npc = serviceFolder:FindFirstChild(npcName)
        if npc and npc:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude
            if dist < minDist then minDist, closestIsland = dist, islandName end
        end
    end
    return closestIsland
end

function Module:NeedsTeleport(hrp, targetIsland)
    local currentIsland = self:GetCurrentIsland(hrp)
    if not currentIsland then return true end
    return currentIsland ~= targetIsland
end

function Module:GetClosestMob(mobName, mobType)
    if mobName == "Nenhum" then return nil end
    local closest, minDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        local hum = npc:FindFirstChild("Humanoid")
        local npcBase = npc:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and npcBase and not npc:GetAttribute("IsTrainingDummy") then
            local cleanNpcName = npc.Name:gsub("%d+", ""):lower():gsub("%s+", "")
            local cleanTarget = mobName:lower():gsub("%s+", "")
            
            if cleanNpcName == cleanTarget then
                local isBoss = npc.Name:lower():find("boss") or npc:GetAttribute("Boss") or npc:GetAttribute("_IsTimedBoss")
                if mobType == "Boss" and not isBoss then continue end
                if mobType == "Mob" and isBoss then continue end

                local dist = (hrp.Position - npcBase.Position).Magnitude
                if dist < minDist then minDist, closest = dist, npc end
            end
        end
    end
    return closest
end

-- ========================================================================
-- 🖥️ UI (Mantida idêntica à versão anterior)
-- ========================================================================
local function CreateDynamicDropdown(container, defaultText, options, callback)
    -- (O código do Dropdown da UI continua o mesmo. Pode manter o seu!)
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
            
            local displayText = type(option) == "table" and option.Name or option
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
    local tabName = "Missões"
    UI:CreateSection(tabName, "Auto Quest Específico")

    local container = UI.Tabs[tabName].Container
    local questDropdown

    CreateDynamicDropdown(container, "🌍 Ilha: " .. self.SelectedIsland, self.IslandsInOrder, function(island)
        self.SelectedIsland = island
        local newQuests = self.QuestDataMap[island]
        self.SelectedQuest = newQuests[1]
        self.SelectedQuest.Island = island
        questDropdown.Refresh(newQuests, "📜 Missão: " .. self.SelectedQuest.Name)
    end)

    questDropdown = CreateDynamicDropdown(container, "📜 Missão: " .. self.SelectedQuest.Name, self.QuestDataMap[self.SelectedIsland], function(quest)
        self.SelectedQuest = quest
        self.SelectedQuest.Island = self.SelectedIsland
    end)

    UI:CreateToggle(tabName, "Auto Quest Unitária", function(state) 
        self:Toggle(state) 
    end)
    
    local WeaponService = Import("Services/WeaponService")
    WeaponService:BuildUI(tabName)
end

-- ========================================================================
-- 🔄 LÓGICA DO CÉREBRO (O SEU FLUXOGRAMA APLICADO)
-- ========================================================================
function Module:StartFarm()
    self.IsRunning = true
    CombatService:Start()
    PriorityService:Request("AutoQuest")

    -- 🔥 HACK: ATIVA O AUTO-REPEAT NATIVO DO JOGO SILENCIOSAMENTE 🔥
    task.spawn(function()
        pcall(function()
            local remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 3)
            if remotes and remotes:FindFirstChild("SettingsToggle") then
                -- Dispara os exatos remotes que você capturou no Spy!
                remotes.SettingsToggle:FireServer("EnableQuestRepeat", true)
                remotes.SettingsToggle:FireServer("AutoQuestRepeat", true)
                print("⚙️ Auto-Repeat Nativo do Jogo Ativado com Sucesso!")
            end
        end)
    end)

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait() do
            if PriorityService:GetPermittedTask() ~= "AutoQuest" then
                task.wait(1)
                continue
            end
            CombatService:Start()
                
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or not self.SelectedQuest then continue end

            local qTarget = self.SelectedQuest.Target
            local qTracker = self.SelectedQuest.Tracker or qTarget
            local qNPC = self.SelectedQuest.NPC
            local qIsland = self.SelectedQuest.Island
            local qType = self.SelectedQuest.Type

            -- 1. VERIFICAR LOCALIZAÇÃO
            if self:NeedsTeleport(hrp, qIsland) then
                CombatService:SetTarget(nil, false)
                TeleportService:TeleportToIsland(qIsland)
                task.wait(4)
                continue
            end

            -- 2. SETAR SPAWN
            if not SpawnService.SpawnSetado then
                CombatService:SetTarget(nil, false)
                SpawnService:SetSpawn()
                task.wait(1)
                continue
            end

            local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
            local npc = serviceFolder and serviceFolder:FindFirstChild(qNPC)

            -- Âncoras (Não tem combate)
            if qTarget == "Nenhum" then
                CombatService:SetTarget(nil, false)
                if npc and npc:FindFirstChild("HumanoidRootPart") then TeleportService:FlyToNPC(qNPC) end
                continue
            end

            -- 3. FLUXOGRAMA DE DECISÃO DA MISSÃO
            if not QuestService:HasAnyQuest() then
                CombatService:SetTarget(nil, false)
                self.FarmTarget = nil
                    
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    TeleportService:FlyToNPC(qNPC)
                    task.wait(0.2)
                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then 
                        fireproximityprompt(prompt) 
                        task.wait(2.5) 
                    end
                end

            elseif not QuestService:IsTracking(qTracker) then
                CombatService:SetTarget(nil, false)
                self.FarmTarget = nil
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    TeleportService:FlyToNPC(qNPC)
                    task.wait(0.2)
                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then 
                        fireproximityprompt(prompt) 
                        task.wait(2.5)
                    end
                end

            else
                -- A MISSÃO ESTÁ ATIVA E É A CORRETA -> HORA DE LUTAR!
                if QuestService:IsQuestCompleted() then
                    -- Se completou, espera 1 segundinho pro jogo devolver a quest nativamente!
                    CombatService:SetTarget(nil, false)
                    task.wait(1)
                else
                    if not self.FarmTarget or not self.FarmTarget:FindFirstChild("Humanoid") or self.FarmTarget.Humanoid.Health <= 0 then
                        self.FarmTarget = self:GetClosestMob(qTarget, qType)
                    end
                    
                    if self.FarmTarget then
                        CombatService:SetTarget(self.FarmTarget, true)
                    else
                        CombatService:SetTarget(nil, false)
                    end
                end
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    CombatService:Stop()
    self.FarmTarget = nil
    PriorityService:Release("AutoQuest")
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
