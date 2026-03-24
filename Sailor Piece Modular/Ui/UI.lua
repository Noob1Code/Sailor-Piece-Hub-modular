local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService") -- Necessário para o Draggable
local LP = Players.LocalPlayer

local UI = { Tabs = {}, ActiveTab = nil, OnClose = nil }

function UI:Init(HubConfig)
    local uiName = "SailorPieceHubPro_UI"
    local uiParent = pcall(function() return CoreGui.Name end) and CoreGui or LP:WaitForChild("PlayerGui")
    if uiParent:FindFirstChild(uiName) then uiParent[uiName]:Destroy() end

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = uiName
    self.ScreenGui.Parent = uiParent

    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 550, 0, 380)
    self.MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.ClipsDescendants = true -- Importante para o Minimizar funcionar bonito
    self.MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", self.MainFrame).CornerRadius = UDim.new(0, 8)

    -- TOPBAR (Área arrastável)
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    topBar.Parent = self.MainFrame
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = HubConfig.HubName .. " v" .. HubConfig.Version
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    -- BOTÃO MINIMIZAR (-)
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -70, 0, 5)
    minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Text = "-"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 18
    minBtn.Parent = topBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

    -- BOTÃO FECHAR (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = topBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

    -- LÓGICA DE MINIMIZAR
    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            self.MainFrame.Size = UDim2.new(0, 550, 0, 40) -- Encolhe pro tamanho do TopBar
        else
            self.MainFrame.Size = UDim2.new(0, 550, 0, 380) -- Volta ao tamanho normal
        end
    end)

    -- LÓGICA DE FECHAR
    closeBtn.MouseButton1Click:Connect(function()
        if self.OnClose then
            self.OnClose() -- Chama a função que desliga os scripts
        end
        self.ScreenGui:Destroy()
    end)

    -- LÓGICA DE DRAG (ARRASTAR)
    local dragging, dragInput, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- CONTEÚDO (Sidebar e Content)
    self.Sidebar = Instance.new("ScrollingFrame")
    self.Sidebar.Size = UDim2.new(0, 130, 1, -50)
    self.Sidebar.Position = UDim2.new(0, 10, 0, 45)
    self.Sidebar.BackgroundTransparency = 1
    self.Sidebar.ScrollBarThickness = 2
    self.Sidebar.Parent = self.MainFrame
    
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 5)
    sidebarLayout.Parent = self.Sidebar

    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Size = UDim2.new(1, -155, 1, -50)
    self.ContentArea.Position = UDim2.new(0, 145, 0, 45)
    self.ContentArea.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    self.ContentArea.Parent = self.MainFrame
    Instance.new("UICorner", self.ContentArea).CornerRadius = UDim.new(0, 8)
end

function UI:CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, -5, 0, 32)
    tabBtn.Text = name
    tabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 13
    tabBtn.Parent = self.Sidebar
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 4)

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(1, -10, 1, -10)
    tabContainer.Position = UDim2.new(0, 5, 0, 5)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 3
    tabContainer.Visible = false
    tabContainer.Parent = self.ContentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = tabContainer

    self.Tabs[name] = { Button = tabBtn, Container = tabContainer }

    tabBtn.MouseButton1Click:Connect(function() self:SelectTab(name) end)
    if not self.ActiveTab then self:SelectTab(name) end

    return tabContainer
end

function UI:SelectTab(tabName)
    self.ActiveTab = tabName
    for name, data in pairs(self.Tabs) do
        if name == tabName then
            data.Button.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
            data.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            data.Container.Visible = true
        else
            data.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            data.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
            data.Container.Visible = false
        end
    end
end

function UI:CreateToggle(tabName, text, callback)
    local container = self.Tabs[tabName].Container
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -10, 0, 35)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13
    toggleBtn.Text = text .. ": OFF"
    toggleBtn.Parent = container
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)

    local state = false
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.Text = text .. ": " .. (state and "ON" or "OFF")
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(50, 150, 80) or Color3.fromRGB(40, 40, 50)
        if callback then callback(state) end
    end)
end

function UI:CreateButton(tabName, text, callback)
    local container = self.Tabs[tabName].Container
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        local oldColor = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(100, 130, 230)
        task.delay(0.1, function() btn.BackgroundColor3 = oldColor end)
        if callback then callback() end
    end)
end

function UI:CreateSection(tabName, text)
    local container = self.Tabs[tabName].Container
    
    local sectionLbl = Instance.new("TextLabel")
    sectionLbl.Size = UDim2.new(1, -10, 0, 25)
    sectionLbl.BackgroundTransparency = 1
    sectionLbl.TextColor3 = Color3.fromRGB(150, 150, 255)
    sectionLbl.Font = Enum.Font.GothamBlack
    sectionLbl.TextSize = 14
    sectionLbl.Text = "--- " .. string.upper(text) .. " ---"
    sectionLbl.Parent = container
end

function UI:Start()
    self:CreateTab("Farm & Nível")
    self:CreateTab("Missões")
    self:CreateTab("Chefes (Boss)")
    self:CreateTab("Mundo & Teleporte")
    self:CreateTab("Gacha & Itens")
    self:CreateTab("Misc & Config")
end

return UI
