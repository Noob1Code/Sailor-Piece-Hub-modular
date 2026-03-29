-- ========================================================================
-- 🍀 MÓDULO: AUTO PITY (COM RENDERIZAÇÃO E POSIÇÃO FIXA)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")
local TeleportService = Import("Services/Teleport")
local GameData = Import("Config/GameData")
local CombatService = Import("Services/CombatService")
local PriorityService = Import("Services/PriorityService")
local SpawnService = Import("Services/SpawnService")
local RandomService = Import("Services/RandomService")

local Module = { NoToggle = true }

function Module:Init()
    self.IsRunning = false
    self.TargetBossModel = nil
    self.Patience = 0
    
    self.LastPity = 0
    self.MaxPity = 25
    self.PityLabelUI = nil

    self.AllBosses = {}
    
    for island, quests in pairs(GameData.QuestDataMap) do
        for _, q in ipairs(quests) do
            table.insert(self.AllBosses, { Target = q.Target, Island = island, Type = "Normal", RequiresDifficulty = false }) 
        end
    end
    if GameData.TimedBosses then
        for island, bosses in pairs(GameData.TimedBosses) do
            for _, bossName in ipairs(bosses) do 
                table.insert(self.AllBosses, { Target = bossName, Island = island, Type = "Timed", RequiresDifficulty = false }) 
            end
        end
    end
    
    if GameData.SummonBosses then
        for islandName, rules in pairs(GameData.SummonBosses) do
            for _, bossName in ipairs(rules.Bosses) do
                table.insert(self.AllBosses, { 
                    Target = bossName, 
                    Island = islandName, 
                    Type = "Summon",
                    RequiresDifficulty = rules.RequiresDifficulty,
                    Difficulties = rules.Difficulties,
                    SummonRemote = rules.SummonRemote,
                    AutoRemote = rules.AutoRemote,
                    SummonNPC = rules.SummonNPC,
                    SummonPosition = rules.SummonPosition,
                    SpawnFolders = rules.SpawnFolders
                })
            end
        end
    end

    self.SelectedPityBoss = self.AllBosses[1]
    self.SelectedDifficulty = "Padrão"
    self.LastSummonState = false
    self.RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
end

function Module:ReadPityFromScreen()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil, nil end
    local pityUI = pg:FindFirstChild("Pity", true)
    
    if pityUI and pityUI:IsA("TextLabel") then
        local text = (pityUI.ContentText ~= "" and pityUI.ContentText) or pityUI.Text
        local cur, max = text:match("(%d+)%s*/%s*(%d+)")
        if cur and max then
            return tonumber(cur), tonumber(max)
        end
    end
    return nil, nil
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
    local cleanTarget = targetName:lower():gsub("%s+", "")

    local function CheckNPC(npc)
        if npc:IsA("Model") then
            local hum = npc:FindFirstChild("Humanoid")
            local npcBase = npc:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and npcBase then
                local cleanNpcName = npc.Name:gsub("%d+", ""):lower():gsub("%s+", "")
                if cleanNpcName == cleanTarget or cleanNpcName:find(cleanTarget) then
                    local dist = (hrp.Position - npcBase.Position).Magnitude
                    if dist < minDist then minDist = dist; closest = npc end
                end
            end
        end
    end

    for _, folder in ipairs(Workspace:GetChildren()) do
        if folder.Name:find("BossSpawn_") or folder.Name:lower():find(cleanTarget) then
            CheckNPC(folder)
        end
        if folder.Name == "NPCs" or folder.Name:find("TimedBoss") then
            for _, npc in ipairs(folder:GetDescendants()) do
                CheckNPC(npc)
            end
        end
    end
    return closest
end

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
    return { Refresh = function(newOptions, resetText) defaultText = resetText; mainBtn.Text = defaultText .. " ▼"; populate(newOptions) end }
end

function Module:Start()
    local tabName = "Gacha & Itens"
    UI:CreateSection(tabName, "🍀 Sniper de Pity (Garantido)")
    local container = UI.Tabs[tabName].Container
    
    self.PityLabelUI = Instance.new("TextLabel")
    self.PityLabelUI.Size = UDim2.new(1, -10, 0, 30)
    self.PityLabelUI.BackgroundTransparency = 1
    self.PityLabelUI.TextColor3 = Color3.fromRGB(255, 215, 0)
    self.PityLabelUI.Font = Enum.Font.GothamBlack
    self.PityLabelUI.TextSize = 14
    self.PityLabelUI.Text = "Pity Atual: ?/25 (Vá bater em um boss)"
    self.PityLabelUI.Parent = container

    local filterOptions = { "Todas as Ilhas" }
    for _, island in ipairs(GameData.IslandsInOrder) do table.insert(filterOptions, island) end

    local currentFilter = "Todas as Ilhas"
    local filteredBosses = {}
    local bossDropdown
    local diffDropdown

    local function UpdateFilteredBosses()
        filteredBosses = {}
        for _, b in ipairs(self.AllBosses) do
            if currentFilter == "Todas as Ilhas" or b.Island == currentFilter then
                table.insert(filteredBosses, b)
            end
        end
        self.SelectedPityBoss = filteredBosses[1]
    end
    UpdateFilteredBosses()

    CreateDynamicDropdown(container, "🌍 Filtro: Todas as Ilhas", filterOptions, function(island)
        currentFilter = island
        UpdateFilteredBosses()
        if bossDropdown then bossDropdown.Refresh(filteredBosses, "🎯 Boss do Pity: " .. (self.SelectedPityBoss and self.SelectedPityBoss.Target or "Nenhum")) end
        
        if diffDropdown and self.SelectedPityBoss then
            local diffs = self.SelectedPityBoss.RequiresDifficulty and self.SelectedPityBoss.Difficulties or {"Padrão"}
            self.SelectedDifficulty = diffs[1]
            diffDropdown.Refresh(diffs, "🔥 Dificuldade: " .. self.SelectedDifficulty)
        end
    end)

    bossDropdown = CreateDynamicDropdown(container, "🎯 Boss do Pity: " .. (self.SelectedPityBoss and self.SelectedPityBoss.Target or "Nenhum"), filteredBosses, function(boss)
        self.SelectedPityBoss = boss
        if diffDropdown then
            local diffs = boss.RequiresDifficulty and boss.Difficulties or {"Padrão"}
            self.SelectedDifficulty = diffs[1]
            diffDropdown.Refresh(diffs, "🔥 Dificuldade: " .. self.SelectedDifficulty)
        end
    end)
    
    diffDropdown = CreateDynamicDropdown(container, "🔥 Dificuldade: " .. self.SelectedDifficulty, {"Padrão"}, function(diff)
        self.SelectedDifficulty = diff
    end)

    UI:CreateToggle(tabName, "Ligar Auto Pity (Vigia Invisível)", function(state)
        self:Toggle(state)
    end)
end

function Module:FirePityRemote(remoteName)
    if not self.RemotesFolder or not self.SelectedPityBoss then return end
    local remote = self.RemotesFolder:FindFirstChild(remoteName)
    if remote then
        if self.SelectedPityBoss.RequiresDifficulty then
            pcall(function() remote:FireServer(self.SelectedPityBoss.Target, self.SelectedDifficulty) end)
        else
            pcall(function() remote:FireServer(self.SelectedPityBoss.Target) end)
        end
    end
end

function Module:StartFarm()
    if self.IsRunning then return end
    self.IsRunning = true
    self.Patience = 0
    CombatService:Start()

    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait(0.5) do
            
            local cur, max = self:ReadPityFromScreen()
            if cur and max then
                self.LastPity = cur
                self.MaxPity = max
                if self.PityLabelUI then self.PityLabelUI.Text = "Pity Atual: " .. cur .. "/" .. max end
            end

            if self.LastPity >= (self.MaxPity - 1) then
                PriorityService:Request("PitySystem")
                if PriorityService:GetPermittedTask() ~= "PitySystem" then continue end

                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                
                local targetData = self.SelectedPityBoss
                if not targetData then continue end

                local currentIsland = self:GetCurrentIsland(hrp)
                if currentIsland ~= targetData.Island then
                    if self.TargetBossModel then CombatService:SetTarget(nil); self.TargetBossModel = nil end
                    TeleportService:TeleportToIsland(targetData.Island)
                    SpawnService.SpawnSetado = false
                    RandomService:Wait(1.5, 2.5)
                    continue
                end
                
                if not SpawnService.SpawnSetado then
                    CombatService:SetTarget(nil, false)
                    SpawnService:SetSpawn()
                    task.wait(1)
                    continue
                end

                if targetData.Type == "Summon" then
                    if targetData.AutoRemote and not self.LastSummonState then
                        self:FirePityRemote(targetData.AutoRemote)
                        self.LastSummonState = true
                    end
                end

                if not self.TargetBossModel or not self.TargetBossModel:FindFirstChild("Humanoid") or self.TargetBossModel.Humanoid.Health <= 0 then
                    self.TargetBossModel = self:GetBossModel(targetData.Target)
                end
                
                if self.TargetBossModel then
                    self.Patience = 0
                    CombatService:SetTarget(self.TargetBossModel, true)
                else
                    CombatService:SetTarget(nil, false)
                    self.TargetBossModel = nil
                    self.Patience = self.Patience + 1
                    
                    if targetData.Type == "Summon" and self.Patience >= 5 then
                        if targetData.SummonPosition then
                            TeleportService:FlyTo(targetData.SummonPosition)
                            task.wait(1.5)
                        elseif targetData.SummonNPC then
                            TeleportService:FlyToNPC(targetData.SummonNPC)
                            task.wait(1.5)
                        end
                        
                        if targetData.SummonRemote then self:FirePityRemote(targetData.SummonRemote) end
                        self.Patience = 0
                        RandomService:Wait(1.0, 2.0)
                        
                        local spawnFolderName = targetData.SpawnFolders and targetData.SpawnFolders[targetData.Target]
                        if spawnFolderName then
                            local spawnZone = Workspace:FindFirstChild(spawnFolderName)
                            if spawnZone then
                                local targetPos = spawnZone:IsA("BasePart") and spawnZone.Position or (spawnZone:IsA("Model") and spawnZone.PrimaryPart and spawnZone.PrimaryPart.Position)
                                if not targetPos then
                                    local p = spawnZone:FindFirstChildWhichIsA("BasePart", true)
                                    if p then targetPos = p.Position end
                                end
                                if targetPos then TeleportService:FlyTo(targetPos + Vector3.new(0, 30, 0)) end
                            end
                        end
                    else
                        RandomService:Wait(1.0, 1.5)
                    end
                end

            else
                PriorityService:Release("PitySystem")
                
                if self.TargetBossModel then
                    CombatService:SetTarget(nil, false)
                    self.TargetBossModel = nil
                end
                
                if self.LastSummonState and self.SelectedPityBoss and self.SelectedPityBoss.AutoRemote then
                    self:FirePityRemote(self.SelectedPityBoss.AutoRemote)
                    self.LastSummonState = false
                end
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    CombatService:Stop()
    PriorityService:Release("PitySystem")
    
    if self.LastSummonState and self.SelectedPityBoss and self.SelectedPityBoss.AutoRemote then
        self:FirePityRemote(self.SelectedPityBoss.AutoRemote)
        self.LastSummonState = false
    end
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
