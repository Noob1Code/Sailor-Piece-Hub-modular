-- ========================================================================
-- 🔮 MÓDULO: AUTO SUMMON BOSS (COM VISÃO DE RAIOS-X PARA PASTAS DE SPAWN)
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
    
    self.SummonData = GameData.SummonBosses or {}
    self.IslandsWithSummon = {}
    for island, _ in pairs(self.SummonData) do table.insert(self.IslandsWithSummon, island) end
    
    self.SelectedIsland = self.IslandsWithSummon[1] or "Boss Island"
    self.CurrentIslandRules = self.SummonData[self.SelectedIsland] or {Bosses = {"Nenhum"}, Difficulties = {"Padrão"}}
    self.SelectedSummonBoss = self.CurrentIslandRules.Bosses[1]
    self.SelectedDifficulty = self.CurrentIslandRules.Difficulties[1]
    
    self.LastSummonState = false
    self.RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
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
    
    local cleanTarget = targetName:gsub("[%d%s_]+", ""):lower()

    local function CheckNPC(npc)
        if npc:IsA("Model") then
            local hum = npc:FindFirstChild("Humanoid")
            local npcBase = npc:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and npcBase then
                local cleanNpcName = npc.Name:gsub("[%d%s_]+", ""):lower()
                if cleanNpcName == cleanTarget or cleanNpcName:find(cleanTarget) then
                    local dist = (hrp.Position - npcBase.Position).Magnitude
                    if dist < minDist then minDist = dist; closest = npc end
                end
            end
        end
    end

    for _, folder in ipairs(Workspace:GetChildren()) do
        CheckNPC(folder)
        
        if folder.Name:find("BossSpawn_") or folder.Name:lower():find(cleanTarget) or folder.Name == "NPCs" or folder.Name:find("TimedBoss") then
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
    return { Refresh = function(newOptions, resetText) defaultText = resetText; mainBtn.Text = defaultText .. " ▼"; populate(newOptions) end }
end

function Module:Start()
    local tabName = "Chefes (Boss)"
    UI:CreateSection(tabName, "🔮 Invocação Automática")
    local container = UI.Tabs[tabName].Container

    local islandDropdown, bossDropdown, diffDropdown

    islandDropdown = CreateDynamicDropdown(container, "🌍 Ilha: " .. self.SelectedIsland, self.IslandsWithSummon, function(island)
        self.SelectedIsland = island
        self.CurrentIslandRules = self.SummonData[island]
        self.SelectedSummonBoss = self.CurrentIslandRules.Bosses[1]
        self.SelectedDifficulty = self.CurrentIslandRules.Difficulties[1]
        
        if bossDropdown then bossDropdown.Refresh(self.CurrentIslandRules.Bosses, "📍 Boss: " .. self.SelectedSummonBoss) end
        if diffDropdown then diffDropdown.Refresh(self.CurrentIslandRules.Difficulties, "🔥 Dif: " .. self.SelectedDifficulty) end
    end)

    bossDropdown = CreateDynamicDropdown(container, "📍 Boss: " .. self.SelectedSummonBoss, self.CurrentIslandRules.Bosses, function(boss)
        self.SelectedSummonBoss = boss
    end)
    
    diffDropdown = CreateDynamicDropdown(container, "🔥 Dif: " .. self.SelectedDifficulty, self.CurrentIslandRules.Difficulties, function(diff)
        self.SelectedDifficulty = diff
    end)

    UI:CreateToggle(tabName, "Auto Summon & Farm", function(state) self:Toggle(state) end)
end

function Module:FireRemote(remoteName)
    if not self.RemotesFolder then return end
    local remote = self.RemotesFolder:FindFirstChild(remoteName)
    if remote then
        if self.CurrentIslandRules.RequiresDifficulty then
            pcall(function() remote:FireServer(self.SelectedSummonBoss, self.SelectedDifficulty) end)
        else
            pcall(function() remote:FireServer(self.SelectedSummonBoss) end)
        end
    end
end

function Module:StartFarm()
    if self.IsRunning then return end
    self.IsRunning = true
    self.Patience = 0
    CombatService:Start()
    PriorityService:Request("AutoSummon")

    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait(1) do
            
            if PriorityService:GetPermittedTask() ~= "AutoSummon" then
                if self.LastSummonState then
                    self:FireRemote(self.CurrentIslandRules.AutoRemote)
                    self.LastSummonState = false
                end
                task.wait(1)
                continue
            end

            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            local currentIsland = self:GetCurrentIsland(hrp)
            if currentIsland ~= self.SelectedIsland then
                if self.TargetBossModel then CombatService:SetTarget(nil); self.TargetBossModel = nil end
                self.Patience = 0
                TeleportService:TeleportToIsland(self.SelectedIsland)
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
            
            if not self.TargetBossModel or not self.TargetBossModel:FindFirstChild("Humanoid") or self.TargetBossModel.Humanoid.Health <= 0 then
                self.TargetBossModel = self:GetBossModel(self.SelectedSummonBoss)
            end
            
            if self.TargetBossModel then
                self.Patience = 0
                CombatService:SetTarget(self.TargetBossModel, true)
            else
                CombatService:SetTarget(nil, false)
                self.TargetBossModel = nil

                local npcPos = self.CurrentIslandRules.SummonPosition
                if not npcPos and self.CurrentIslandRules.SummonNPC then
                    local svcFolder = Workspace:FindFirstChild("ServiceNPCs")
                    local npcModel = svcFolder and svcFolder:FindFirstChild(self.CurrentIslandRules.SummonNPC)
                    if npcModel and npcModel:FindFirstChild("HumanoidRootPart") then
                        npcPos = npcModel.HumanoidRootPart.Position
                    end
                end

                local needsToSummon = false
                if self.CurrentIslandRules.AutoRemote and not self.LastSummonState then
                    needsToSummon = true
                elseif not self.CurrentIslandRules.AutoRemote then
                    self.Patience = self.Patience + 1
                    if self.Patience >= 4 then
                        needsToSummon = true
                        self.Patience = 0
                    end
                end

                if needsToSummon then
                    if npcPos and (hrp.Position - npcPos).Magnitude > 50 then
                        TeleportService:FlyTo(npcPos)
                        task.wait(0.5)
                        continue
                    else
                        if self.CurrentIslandRules.AutoRemote and not self.LastSummonState then
                            self:FireRemote(self.CurrentIslandRules.AutoRemote)
                            self.LastSummonState = true
                        else
                            self:FireRemote(self.CurrentIslandRules.SummonRemote)
                        end
                        RandomService:Wait(1.0, 2.0)
                    end
                end

                local spawnFolderName = self.CurrentIslandRules.SpawnFolders and self.CurrentIslandRules.SpawnFolders[self.SelectedSummonBoss]
                local targetPos = nil
                if spawnFolderName then
                    local spawnZone = Workspace:FindFirstChild(spawnFolderName)
                    if spawnZone then
                        targetPos = spawnZone:IsA("BasePart") and spawnZone.Position or (spawnZone:IsA("Model") and spawnZone.PrimaryPart and spawnZone.PrimaryPart.Position)
                        if not targetPos then
                            local p = spawnZone:FindFirstChildWhichIsA("BasePart", true)
                            if p then targetPos = p.Position end
                        end
                    end
                end

                targetPos = targetPos or npcPos

                if targetPos and (hrp.Position - targetPos).Magnitude > 50 then
                    TeleportService:FlyTo(targetPos + Vector3.new(0, 30, 0))
                    task.wait(0.5)
                end
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    CombatService:Stop()
    PriorityService:Release("AutoSummon")
    
    if self.LastSummonState then
        self:FireRemote(self.CurrentIslandRules.AutoRemote)
        self.LastSummonState = false
    end
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
