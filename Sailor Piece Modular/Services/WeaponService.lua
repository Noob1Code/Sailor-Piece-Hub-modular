-- ========================================================================
-- 🗡️ SERVIÇO: GERENCIADOR DE ARMAS, SKILLS E POSICIONAMENTO
-- ========================================================================
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local UI = Import("Ui/UI")

local WeaponService = {
    SelectedWeapons = {},
    ActiveLabel = nil
}

function WeaponService:GetAvailableWeapons()
    local weapons = {}
    local char = LP.Character

    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then table.insert(weapons, tool.Name) end
        end
    end

    local backpack = LP:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then table.insert(weapons, tool.Name) end
        end
    end

    if #weapons == 0 then table.insert(weapons, "Nenhuma Arma Encontrada") end
    return weapons
end

function WeaponService:UpdateLabel()
    if not self.ActiveLabel then return end
    if #self.SelectedWeapons == 0 then
        self.ActiveLabel.Text = "Armas Ativas: Nenhuma (Usará a primeira que achar)"
    else
        self.ActiveLabel.Text = "Armas Ativas: " .. table.concat(self.SelectedWeapons, ", ")
    end
end

function WeaponService:EquipWeapon(weaponName)
    local char = LP.Character
    if not char then return false end
    if char:FindFirstChild(weaponName) then return true end
    local backpack = LP:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(weaponName)
        if tool then
            tool.Parent = char
            return true
        end
    end
    return false
end

-- ========================================================================
-- 🖥️ CONSTRUTOR DE INTERFACE (Injeta a UI na aba Misc & Config)
-- ========================================================================
function WeaponService:BuildUI(tabName)
    local container = UI.Tabs[tabName].Container
    local CombatService = Import("Services/CombatService")

    -- ==========================================
    -- 🛡️ SEÇÃO DE POSICIONAMENTO TÁTICO
    -- ==========================================
    UI:CreateSection(tabName, "🛡️ Posicionamento Tático (Combate)")

    UI:CreateDropdown(tabName, "Posição de Ataque", {"Atrás", "Frente", "Acima", "Abaixo", "Orbital", "Diagonal"}, function(val)
        CombatService.AttackPosition = val
    end)

    UI:CreateTextBox(tabName, "Distância do Alvo (Studs)", function(val)
        local num = tonumber(val)
        if num then 
            CombatService.AttackDistance = num 
        end
    end)


    -- ==========================================
    -- 🗡️ SEÇÃO DE ARMAS
    -- ==========================================
    UI:CreateSection(tabName, "🗡️ Gerenciador de Armas")
    
    self.ActiveLabel = Instance.new("TextLabel")
    self.ActiveLabel.Size = UDim2.new(1, -10, 0, 30)
    self.ActiveLabel.BackgroundTransparency = 1
    self.ActiveLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    self.ActiveLabel.Font = Enum.Font.GothamSemibold
    self.ActiveLabel.TextSize = 12
    self.ActiveLabel.TextWrapped = true
    self.ActiveLabel.Parent = container
    self:UpdateLabel()

    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, -10, 0, 35)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.ClipsDescendants = true
    dropdownFrame.Parent = container

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, -35, 0, 35)
    mainBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.TextSize = 13
    mainBtn.Text = "🗡️ Escolha a Arma ▼"
    mainBtn.Parent = dropdownFrame
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 4)

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 30, 0, 35)
    refreshBtn.Position = UDim2.new(1, -30, 0, 0)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 150)
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 16
    refreshBtn.Text = "🔄"
    refreshBtn.Parent = dropdownFrame
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)

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
    local selectedToolToManage = ""

    local function populate()
        for _, child in ipairs(optionsContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local weapons = self:GetAvailableWeapons()
        for _, wName in ipairs(weapons) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -5, 0, 25)
            optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            optBtn.Font = Enum.Font.GothamSemibold
            optBtn.TextSize = 12
            optBtn.Text = wName
            optBtn.Parent = optionsContainer
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)

            optBtn.MouseButton1Click:Connect(function()
                isOpen = false
                selectedToolToManage = wName
                mainBtn.Text = "🗡️ " .. wName .. " ▼"
                dropdownFrame.Size = UDim2.new(1, -10, 0, 35)
            end)
        end
        task.wait(0.1)
        optionsContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end

    mainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        dropdownFrame.Size = isOpen and UDim2.new(1, -10, 0, 130) or UDim2.new(1, -10, 0, 35)
    end)

    refreshBtn.MouseButton1Click:Connect(function()
        populate()
        mainBtn.Text = "🗡️ Armas Atualizadas! ▼"
    end)

    populate()

    UI:CreateButton(tabName, "➕ Adicionar Arma à Lista", function()
        if selectedToolToManage ~= "" and selectedToolToManage ~= "Nenhuma Arma Encontrada" then
            for _, w in ipairs(self.SelectedWeapons) do if w == selectedToolToManage then return end end
            table.insert(self.SelectedWeapons, selectedToolToManage)
            self:UpdateLabel()
        end
    end)

    UI:CreateButton(tabName, "➖ Remover Arma da Lista", function()
        for i, w in ipairs(self.SelectedWeapons) do
            if w == selectedToolToManage then
                table.remove(self.SelectedWeapons, i)
                self:UpdateLabel()
                break
            end
        end
    end)

    UI:CreateButton(tabName, "🗑️ Limpar Todas as Armas", function()
        self.SelectedWeapons = {}
        self:UpdateLabel()
    end)
end

return WeaponService
