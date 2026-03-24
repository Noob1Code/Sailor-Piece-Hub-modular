-- ========================================================================
-- 📦 MÓDULO: AUTO QUEST UNITÁRIA (COM GPS POR NPC ÂNCORA)
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")
local TeleportService = Import("Modules/Teleport")

local Module = {
    NoToggle = true 
}

function Module:Init()
    self.IsRunning = false
    self.MoveLoop = nil
    self.AttackLoop = nil
    self.FarmTarget = nil
    self.OrbitAngle = 0

    self.QuestDataMap = {
        ["Starter"] = {{Name = "Quest 1: Mobs (Thief)", NPC = "QuestNPC1", Target = "Thief", Type = "Mob"}, {Name = "Quest 2: Boss (Thief Boss)", NPC = "QuestNPC2", Target = "ThiefBoss", Type = "Boss"}},
        ["Jungle"] = {{Name = "Quest 3: Mobs (Monkey)", NPC = "QuestNPC3", Target = "Monkey", Type = "Mob"}, {Name = "Quest 4: Boss (Monkey Boss)", NPC = "QuestNPC4", Target = "MonkeyBoss", Type = "Boss"}},
        ["Desert"] = {{Name = "Quest 5: Mobs (Bandits)", NPC = "QuestNPC5", Target = "DesertBandit", Type = "Mob"}, {Name = "Quest 6: Boss (Desert Boss)", NPC = "QuestNPC6", Target = "DesertBoss", Type = "Boss"}},
        ["Snow"] = {{Name = "Quest 7: Mobs (Frost Rogue)", NPC = "QuestNPC7", Target = "FrostRogue", Type = "Mob"}, {Name = "Quest 8: Boss (Snow Boss)", NPC = "QuestNPC8", Target = "SnowBoss", Type = "Boss"}},
        ["Sailor"] = {{Name = "Âncora Sailor", NPC = "JinwooMovesetNPC", Target = "Nenhum", Type = "Mob"}},
        ["Shibuya Station"] = {{Name = "Quest 9: Mobs (Sorcerer)", NPC = "QuestNPC9", Target = "Sorcerer", Type = "Mob"}, {Name = "Quest 10: Mobs (Panda Sorcerer)", NPC = "QuestNPC10", Target = "PandaMiniBoss", Type = "Boss"}},
        ["Hueco Mundo"] = {{Name = "Quest 11: Mobs (Hollow)", NPC = "QuestNPC11", Target = "Hollow", Type = "Mob"}},
        ["Shinjuku"] = {{Name = "Quest 12: Mobs", NPC = "QuestNPC12", Target = "StrongSorcerer", Type = "Mob"}, {Name = "Quest 13: Mobs", NPC = "QuestNPC13", Target = "Curse", Type = "Mob"}},
        ["Slime"] = {{Name = "Quest 14: Mobs (Slime)", NPC = "QuestNPC14", Target = "Slime", Type = "Mob"}},
        ["Academy"] = {{Name = "Quest 15: Mobs (Teacher)", NPC = "QuestNPC15", Target = "AcademyTeacher", Type = "Mob"}},
        ["Judgement"] = {{Name = "Quest 16: Mobs", NPC = "QuestNPC16", Target = "Swordsman", Type = "Mob"}},
        ["Soul Society"] = {{Name = "Quest 17: Mobs", NPC = "QuestNPC17", Target = "Quincy", Type = "Mob"}},
        ["Boss Island"] = {{Name = "Âncora de Ilha", NPC = "SummonBossNPC", Target = "Nenhum", Type = "Mob"}}
    }

    -- 📍 MAPEAMENTO INTELIGENTE: Liga cada NPC de volta à sua Ilha
    self.NpcToIsland = {
        ["QuestNPC1"] = "Starter", ["QuestNPC2"] = "Starter",
        ["QuestNPC3"] = "Jungle", ["QuestNPC4"] = "Jungle",
        ["QuestNPC5"] = "Desert", ["QuestNPC6"] = "Desert",
        ["QuestNPC7"] = "Snow", ["QuestNPC8"] = "Snow",
        ["JinwooMovesetNPC"] = "Sailor",
        ["QuestNPC9"] = "Shibuya Station", ["QuestNPC10"] = "Shibuya Station",
        ["QuestNPC11"] = "Hueco Mundo",
        ["QuestNPC12"] = "Shinjuku", ["QuestNPC13"] = "Shinjuku",
        ["QuestNPC14"] = "Slime",
        ["QuestNPC15"] = "Academy",
        ["QuestNPC16"] = "Judgement",
        ["QuestNPC17"] = "Soul Society",
        ["SummonBossNPC"] = "Boss Island"
    }

    self.IslandsInOrder = {
        "Starter", "Jungle", "Desert", "Snow", "Sailor", "Shibuya Station",
        "Hueco Mundo", "Boss Island", "Shinjuku", "Slime", "Academy", "Judgement", "Soul Society"
    }

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
    -- Se não achou nenhum NPC próximo (tá no meio do mar, etc) ou se a ilha atual for diferente da alvo, precisa teleportar!
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
end

-- ========================================================================
-- 🔄 LOOPS DE FARM
-- ========================================================================
function Module:StartFarm()
    self.IsRunning = true

    self.MoveLoop = task.spawn(function()
        while self.IsRunning and task.wait() do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not hrp or not hum or not self.SelectedQuest then continue end

            local qTarget = self.SelectedQuest.Target
            local qNPC = self.SelectedQuest.NPC
            local qIsland = self.SelectedQuest.Island
            local qType = self.SelectedQuest.Type

            -- 🛑 O CÉREBRO DE GPS QUE VOCÊ SUGERIU 🛑
            if self:NeedsTeleport(hrp, qIsland) then
                print("🗺️ Localização divergente! Teleportando para: " .. qIsland)
                TeleportService:TeleportToIsland(qIsland)
                task.wait(4) -- Dá tempo para a tela de carregamento do teleporte sumir
                continue
            end

            local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
            local npc = serviceFolder and serviceFolder:FindFirstChild(qNPC)

            -- Âncoras (Não tem missão de combate)
            if qTarget == "Nenhum" then
                self.FarmTarget = nil
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    TeleportService:FlyToNPC(qNPC)
                end
                continue
            end

            -- Pegar a Quest de Combate
            if not self:IsQuestActive(qTarget) then
                self.FarmTarget = nil 
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    TeleportService:FlyToNPC(qNPC)
                    task.wait(0.2)
                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then 
                        fireproximityprompt(prompt)
                        task.wait(1.5) 
                    end
                end
            else
                -- Missão ativa! Procura o mob
                if not self.FarmTarget or not self.FarmTarget:FindFirstChild("Humanoid") or self.FarmTarget.Humanoid.Health <= 0 then
                    self.FarmTarget = self:GetClosestMob(qTarget, qType)
                end
                
                if self.FarmTarget then
                    local targetHrp = self.FarmTarget:FindFirstChild("HumanoidRootPart")
                    if targetHrp then
                        hum.PlatformStand = true
                        hrp.Velocity = Vector3.zero
                        
                        -- Voo Orbital em volta do alvo
                        self.OrbitAngle = self.OrbitAngle + math.rad(15)
                        local radius = 8
                        local height = 5
                        local pos = targetHrp.Position + Vector3.new(math.cos(self.OrbitAngle) * radius, height, math.sin(self.OrbitAngle) * radius)
                        
                        hrp.CFrame = CFrame.new(pos, targetHrp.Position)
                    end
                end
            end
        end
    end)

    self.AttackLoop = task.spawn(function()
        while self.IsRunning and task.wait(0.1) do
            if self.FarmTarget and self.FarmTarget:FindFirstChild("Humanoid") and self.FarmTarget.Humanoid.Health > 0 then
                self:EquipWeapon()
                if self.CombatRemote then pcall(function() self.CombatRemote:FireServer() end) end
                if self.AbilityRemote then for i = 1, 4 do pcall(function() self.AbilityRemote:FireServer(i) end) end end
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    if self.MoveLoop then task.cancel(self.MoveLoop); self.MoveLoop = nil end
    if self.AttackLoop then task.cancel(self.AttackLoop); self.AttackLoop = nil end
    
    local char = LP.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
    self.FarmTarget = nil
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
