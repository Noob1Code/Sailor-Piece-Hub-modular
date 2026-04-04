-- ========================================================================
-- 🧩 MÓDULO: AUTO COLLECT (MOTOR UNIVERSAL + POSIÇÕES FIXAS DE RESGATE)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")
local TeleportService = Import("Services/Teleport")
local GameData = Import("Config/GameData")
local CombatService = Import("Services/CombatService")
local PriorityService = Import("Services/PriorityService")
local RandomService = Import("Services/RandomService")

local Module = { NoToggle = true }

function Module:Init()
    self.IsRunning = false
    self.CurrentStep = 1
    self.CurrentItemObj = nil
    self.Patience = 0
    
    self.CollectiblesList = {}
    for itemName, _ in pairs(GameData.Collectibles) do
        table.insert(self.CollectiblesList, itemName)
    end
    
    self.SelectedItem = self.CollectiblesList[1] or "Nenhum Item"
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

function Module:GetItemModel(targetName, targetIsland)
    local closest, minDist = nil, math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local cleanIsland = targetIsland and targetIsland:gsub("%s+", "") or ""

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == targetName and (obj:IsA("Model") or obj:IsA("BasePart")) then
            
            local path = obj:GetFullName()
            if cleanIsland ~= "" and not path:find(cleanIsland) then
                continue
            end

            local itemPos = nil
            if obj:IsA("BasePart") then
                itemPos = obj.Position
            elseif obj:IsA("Model") and obj.PrimaryPart then
                itemPos = obj.PrimaryPart.Position
            else
                local p = obj:FindFirstChildWhichIsA("BasePart", true)
                if p then itemPos = p.Position end
            end
            
            if itemPos then
                local dist = (hrp.Position - itemPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = obj 
                end
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
    local tabName = "Coletáveis"
    UI:CreateSection(tabName, "🧩 Localizador de Itens")
    local container = UI.Tabs[tabName].Container

    self.ProgressLabel = Instance.new("TextLabel")
    self.ProgressLabel.Size = UDim2.new(1, -10, 0, 30)
    self.ProgressLabel.BackgroundTransparency = 1
    self.ProgressLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    self.ProgressLabel.Font = Enum.Font.GothamBlack
    self.ProgressLabel.TextSize = 13
    self.ProgressLabel.Text = "Status: Aguardando Início..."
    self.ProgressLabel.Parent = container

    CreateDynamicDropdown(container, "📍 Rota: " .. self.SelectedItem, self.CollectiblesList, function(item)
        self.SelectedItem = item
        self.CurrentStep = 1
        self.ProgressLabel.Text = "Rota alterada! Status: Aguardando..."
    end)

    UI:CreateButton(tabName, "🔄 Reiniciar Rota do Zero", function()
        self.CurrentStep = 1
        self.ProgressLabel.Text = "Rota Resetada para a Etapa 1!"
    end)

    UI:CreateToggle(tabName, "Ligar Auto Coleta (Ordem Estrita)", function(state)
        self:Toggle(state)
    end)
end

function Module:StartFarm()
    if self.IsRunning then return end
    self.IsRunning = true
    self.CurrentItemObj = nil
    CombatService:SetTarget(nil, false)
    PriorityService:Request("AutoCollect")

    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait(1) do
            
            if PriorityService:GetPermittedTask() ~= "AutoCollect" then continue end
            
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            local config = GameData.Collectibles[self.SelectedItem]
            if not config then continue end
            
            if self.CurrentStep > #config.IslandOrder then
                self.ProgressLabel.Text = "🎉 ROTA CONCLUÍDA! Desligue o Auto Collect."
                task.wait(2)
                continue
            end
            
            local targetIsland = config.IslandOrder[self.CurrentStep]
            self.ProgressLabel.Text = "Progresso: " .. self.CurrentStep .. "/" .. #config.IslandOrder .. " (Ilha: " .. targetIsland .. ")"
            
            local currentIsland = self:GetCurrentIsland(hrp)
            if currentIsland ~= targetIsland then
                TeleportService:TeleportToIsland(targetIsland)
                self.CurrentItemObj = nil
                RandomService:Wait(3.0, 4.0)
                continue
            end
            
            if not self.CurrentItemObj or not self.CurrentItemObj.Parent then
                self.CurrentItemObj = self:GetItemModel(config.TargetName, targetIsland)
            end
            
            if self.CurrentItemObj then
                self.Patience = 0
                local itemPos = self.CurrentItemObj:IsA("BasePart") and self.CurrentItemObj.Position or (self.CurrentItemObj:IsA("Model") and self.CurrentItemObj.PrimaryPart and self.CurrentItemObj.PrimaryPart.Position)
                
                if not itemPos then
                    local p = self.CurrentItemObj:FindFirstChildWhichIsA("BasePart", true)
                    if p then itemPos = p.Position end
                end
                
                if itemPos then
                    local dist = (hrp.Position - itemPos).Magnitude
                    
                    if dist > 15 then
                        TeleportService:FlyTo(itemPos + Vector3.new(0, 3, 0))
                        task.wait(0.5)
                    else
                        local prompt = self.CurrentItemObj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and fireproximityprompt then
                            hrp.Velocity = Vector3.zero
                            pcall(function() fireproximityprompt(prompt) end)
                            RandomService:Wait(1.5, 2.0)
                            
                            self.CurrentStep = self.CurrentStep + 1
                            self.CurrentItemObj = nil
                        else
                            RandomService:Wait(1.0, 1.5)
                        end
                    end
                end
            else
                local fixedPos = config.Positions and config.Positions[targetIsland]
                
                if fixedPos then
                    if (hrp.Position - fixedPos).Magnitude > 50 then
                        self.ProgressLabel.Text = "Forçando Renderização (Ilha: " .. targetIsland .. ")..."
                        TeleportService:FlyTo(fixedPos + Vector3.new(0, 30, 0))
                        task.wait(1)
                    else
                        self.Patience = self.Patience + 1
                        if self.Patience > 10 then self.Patience = 0 end
                        RandomService:Wait(1.0, 1.5)
                    end
                else
                    self.Patience = self.Patience + 1
                    if self.Patience > 10 then self.Patience = 0 end
                    RandomService:Wait(1.0, 1.5)
                end
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
    PriorityService:Release("AutoCollect")
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
