-- ========================================================================
-- 🛒 MÓDULO: AUTO MERCHANT (TENTATIVA POR TEMPO / 5 MINUTOS)
-- ========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")

local Module = { NoToggle = true }

function Module:Init()
    self.Items = {
        "Dungeon Key", 
        "Boss Key", 
        "Rush Key",
        "Haki Color Reroll", 
        "Race Reroll", 
        "Trait Reroll", 
        "Clan Reroll",
        "Passive Shard"
    }
    self.SelectedItem = self.Items[1]
    
    self.SelectedToBuy = {} 
    self.IsRunning = false
    self.ActiveLabel = nil
    self.StatusLabel = nil
end

function Module:UpdateLabel()
    -- 🔥 SEGURANÇA: Só atualiza se a label existir e estiver na tela (evita erros ao usar o botão Voltar)
    if not self.ActiveLabel or not self.ActiveLabel.Parent then return end
    
    if #self.SelectedToBuy == 0 then
        self.ActiveLabel.Text = "Lista de Compras: Vazia"
    else
        self.ActiveLabel.Text = "Lista de Compras: " .. table.concat(self.SelectedToBuy, ", ")
    end
end

function Module:UpdateStatus(text)
    -- 🔥 SEGURANÇA: Só atualiza o status visual se o menu do Merchant estiver aberto
    if self.StatusLabel and self.StatusLabel.Parent then
        self.StatusLabel.Text = text
    end
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
                defaultText = "📦 " .. option
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
    UI:CreateSection(tabName, "🛒 Auto Merchant (Loja em 2º Plano)")
    local container = UI.Tabs[tabName].Container

    self.ActiveLabel = Instance.new("TextLabel")
    self.ActiveLabel.Size = UDim2.new(1, -10, 0, 30)
    self.ActiveLabel.BackgroundTransparency = 1
    self.ActiveLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    self.ActiveLabel.Font = Enum.Font.GothamSemibold
    self.ActiveLabel.TextSize = 12
    self.ActiveLabel.Parent = container
    self:UpdateLabel()

    self.StatusLabel = Instance.new("TextLabel")
    self.StatusLabel.Size = UDim2.new(1, -10, 0, 20)
    self.StatusLabel.BackgroundTransparency = 1
    self.StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    self.StatusLabel.Font = Enum.Font.Gotham
    self.StatusLabel.TextSize = 11
    self.StatusLabel.Text = self.IsRunning and "Status: Rodando em 2º Plano..." or "Status: Aguardando..."
    self.StatusLabel.Parent = container

    local itemDropdown = CreateDynamicDropdown(container, "📦 Selecione o Item: " .. self.SelectedItem, self.Items, function(item)
        self.SelectedItem = item
    end)

    UI:CreateButton(tabName, "➕ Adicionar à Lista", function()
        if self.SelectedItem then
            for _, w in ipairs(self.SelectedToBuy) do if w == self.SelectedItem then return end end
            table.insert(self.SelectedToBuy, self.SelectedItem)
            self:UpdateLabel()
        end
    end)

    UI:CreateButton(tabName, "➕ Adicionar Todos à Lista", function()
        for _, item in ipairs(self.Items) do
            local found = false
            for _, existing in ipairs(self.SelectedToBuy) do
                if existing == item then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(self.SelectedToBuy, item)
            end
        end
        self:UpdateLabel()
    end)

    UI:CreateButton(tabName, "➖ Remover da Lista", function()
        for i, w in ipairs(self.SelectedToBuy) do
            if w == self.SelectedItem then
                table.remove(self.SelectedToBuy, i)
                self:UpdateLabel()
                break
            end
        end
    end)

    UI:CreateButton(tabName, "🗑️ Limpar Toda a Lista", function()
        self.SelectedToBuy = {}
        self:UpdateLabel()
    end)

    UI:CreateToggle(tabName, "Ligar Auto Compra (Intervalo de 5 Min)", function(state)
        self:Toggle(state)
    end)
end

function Module:Start() end

function Module:StartFarm()
    if self.IsRunning then return end
    self.IsRunning = true

    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end

    self.BrainLoop = task.spawn(function()
        local merchantRemotes = ReplicatedStorage:FindFirstChild("Remotes") 
                             and ReplicatedStorage.Remotes:FindFirstChild("MerchantRemotes")
                             
        local purchaseRemote = merchantRemotes and merchantRemotes:FindFirstChild("PurchaseMerchantItem")
        
        local countdown = 0

        while self.IsRunning and task.wait(1) do 
            if #self.SelectedToBuy == 0 then
                self:UpdateStatus("Status: Lista vazia. Adicione itens.")
                countdown = 0
                continue
            end

            if countdown <= 0 then
                self:UpdateStatus("Status: Tentando comprar itens silenciosamente...")
                
                if purchaseRemote and purchaseRemote:IsA("RemoteFunction") then
                    for _, itemName in ipairs(self.SelectedToBuy) do
                        if not self.IsRunning then break end
                        
                        pcall(function()
                            purchaseRemote:InvokeServer(itemName, 999)
                        end)
                        
                        task.wait(0.5) 
                    end
                end
                
                countdown = 300
            else
                self:UpdateStatus("Status: Próxima tentativa em " .. countdown .. "s")
                countdown = countdown - 1
            end
        end
    end)
end

function Module:StopFarm()
    self.IsRunning = false
    self:UpdateStatus("Status: Desligado.")
    if self.BrainLoop then task.cancel(self.BrainLoop); self.BrainLoop = nil end
end

function Module:Toggle(state)
    if state then self:StartFarm() else self:StopFarm() end
end

return Module
