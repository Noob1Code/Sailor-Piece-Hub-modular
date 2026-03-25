-- ========================================================================
-- 📦 MÓDULO: AUTO QUEST UNITÁRIA (COM GPS POR NPC ÂNCORA)
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

local Module = {
    NoToggle = true 
}

function Module:Init()
    self.IsRunning = false
    self.MoveLoop = nil
    self.AttackLoop = nil
    self.FarmTarget = nil
    self.OrbitAngle = 0

    self.QuestDataMap = GameData.QuestDataMap
    self.NpcToIsland = GameData.NpcToIsland
    self.IslandsInOrder = GameData.IslandsInOrder

    self.SelectedIsland = self.IslandsInOrder[1]
    self.SelectedQuest = self.QuestDataMap[self.SelectedIsland][1]
    self.SelectedQuest.Island = self.SelectedIsland

    self.CombatRemote = pcall(function() return ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit") end) and ReplicatedStorage.CombatSystem.Remotes.RequestHit or nil
    self.AbilityRemote = pcall(function() return ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility") end) and ReplicatedStorage.AbilitySystem.Remotes.RequestAbility or nil
end

-- ========================================================================
-- 📍 SISTEMA DE GPS BASEADO EM NPCS ÂNCORA
-- ========================================================================
function Module:GetCurrentIsland(hrp)
    local closestIsland = nil
    local minDist = math.huge
    local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
    
    if not serviceFolder then return nil end

    -- Procura o NPC de missão mais próximo para deduzir a ilha atual
    for npcName, islandName in pairs(self.NpcToIsland) do
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
-- ⚙️ LÓGICA DE COMBATE E QUEST
-- ========================================================================
function Module:IsQuestActive(targetName)
    if targetName == "Nenhum" then return false end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    local targetBase = targetName:lower():gsub("%s+", "")
    
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local currStr, maxStr = obj.Text:lower():match("(%d+)%s*/%s*(%d+)")
            if currStr and maxStr then
                local isVis, temp = true, obj
                while temp and temp:IsA("GuiObject") do
                    if not temp.Visible then isVis = false; break end
                    temp = temp.Parent
                end
                if isVis then
                    local screenGui = obj:FindFirstAncestorOfClass("ScreenGui")
                    if screenGui then
                        for _, relativeObj in ipairs(screenGui:GetDescendants()) do
                            if relativeObj:IsA("TextLabel") and relativeObj.Text:lower():gsub("%s+", ""):find(targetBase) then
                                return (tonumber(currStr) < tonumber(maxStr))
                            end
                        end
                    end
                end
            end
        end
    end
    return false
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
                if dist < minDist then 
                    minDist = dist
                    closest = npc 
                end
            end
        end
    end
    return closest
end

function Module:EquipWeapon()
    local char = LP.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local backpack = LP:FindFirstChild("Backpack")
        if backpack then tool = backpack:FindFirstChildOfClass("Tool"); if tool then tool.Parent = char end end
    end
end

-- ========================================================================
-- 🖥️ UI E DROPDOWNS
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
-- 🔄 LOOPS DE FARM
-- ========================================================================
function Module:StartFarm()
    self.IsRunning = true
    CombatService:Start()
    PriorityService:Request("AutoQuest")

    self.BrainLoop = task.spawn(function()
        while self.IsRunning and task.wait() do
            if PriorityService:GetPermittedTask() ~= "AutoQuest" then
                CombatService:SetTarget(nil, false)
                task.wait(1)
                continue
            end
                
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or not self.SelectedQuest then continue end

            local qTarget = self.SelectedQuest.Target
            local qNPC = self.SelectedQuest.NPC
            local qIsland = self.SelectedQuest.Island
            local qType = self.SelectedQuest.Type

            -- GPS de Ilha
            if self:NeedsTeleport(hrp, qIsland) then
                CombatService:SetTarget(nil, false)
                print("🗺️ Localização divergente! Teleportando para: " .. qIsland)
                TeleportService:TeleportToIsland(qIsland)
                task.wait(4)
                continue
            end

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

            -- Lógica de pegar a Missão
            if not self:IsQuestActive(qTarget) then
                CombatService:SetTarget(nil, false) -- Pausa os ataques
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    TeleportService:FlyToNPC(qNPC)
                    task.wait(0.2)
                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then fireproximityprompt(prompt); task.wait(1.5) end
                end
            else
                -- Lógica de Combate: Missão ativa! Procura o mob
                if not self.FarmTarget or not self.FarmTarget:FindFirstChild("Humanoid") or self.FarmTarget.Humanoid.Health <= 0 then
                    self.FarmTarget = self:GetClosestMob(qTarget, qType)
                end
                
                -- Se achou o alvo, MANDA O MÚSCULO TRABALHAR! (true = usar Voo Orbital)
                if self.FarmTarget then
                    CombatService:SetTarget(self.FarmTarget, true)
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
