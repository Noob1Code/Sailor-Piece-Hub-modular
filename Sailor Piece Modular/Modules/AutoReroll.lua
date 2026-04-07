-- ========================================================================
-- 🎲 MÓDULO: AUTO REROLL STATS (INTERAÇÃO COM MENU NATIVO E SUB-MENU)
-- ========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = Import("Ui/UI")

local Module = { NoToggle = true }

function Module:Init()
    self.StatsList = {
        "Damage",
        "Defense",
        "CooldownReduction",
        "CritChance",
        "CritDamage",
        "DamageReduction",
        "Luck"
    }
    self.SelectedStat = self.StatsList[1]
    
    self.SkipConfig = {
        ["A"] = false,
        ["S"] = false,
        ["SS"] = false,
        ["SSS"] = false
    }
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
                defaultText = "🎯 " .. option
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

function Module:BuildUI()
    local tabName = "Gacha & Itens"
    local container = UI.Tabs[tabName].Container

    UI:CreateSection(tabName, "🎲 Auto Reroll de Status")

    UI:CreateButton(tabName, "🖥️ Abrir Menu de Reroll (Nativo)", function()
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("GetStatRerollData")
            if remote and remote:IsA("RemoteFunction") then
                remote:InvokeServer()
            end
        end)
    end)

    CreateDynamicDropdown(container, "🎯 Status: " .. self.SelectedStat, self.StatsList, function(stat)
        self.SelectedStat = stat
    end)

    UI:CreateSection(tabName, "Filtro de Ranks (Auto-Skip)")

    UI:CreateToggle(tabName, "Pular Rank [A]", function(state) self.SkipConfig["A"] = state end)
    UI:CreateToggle(tabName, "Pular Rank [S]", function(state) self.SkipConfig["S"] = state end)
    UI:CreateToggle(tabName, "Pular Rank [SS]", function(state) self.SkipConfig["SS"] = state end)
    UI:CreateToggle(tabName, "Pular Rank [SSS]", function(state) self.SkipConfig["SSS"] = state end)

    UI:CreateToggle(tabName, "Ligar Auto Reroll", function(state) self:Toggle(state) end)
end

function Module:Start()
end

function Module:Toggle(state)
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then return end

    local skipRemote = remoteEvents:FindFirstChild("StatRerollUpdateAutoSkip")
    local rollRemote = remoteEvents:FindFirstChild("StatRerollAutoRoll")

    if state then
        if skipRemote then
            pcall(function() skipRemote:FireServer(self.SkipConfig) end)
        end
        if rollRemote then
            pcall(function() rollRemote:FireServer(true, "selected", {self.SelectedStat}) end)
        end
    else
        if rollRemote then
            pcall(function() rollRemote:FireServer(false, "selected", {self.SelectedStat}) end)
        end
    end
end

return Module
