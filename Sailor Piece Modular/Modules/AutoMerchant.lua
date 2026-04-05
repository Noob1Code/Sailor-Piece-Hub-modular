-- ========================================================================
-- 🛒 MÓDULO: AUTO MERCHANT (COMPRAS REMOTAS E INSTANTÂNEAS)
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

function Module:Start()
    local tabName = "Gacha & Itens"
    UI:CreateSection(tabName, "🛒 Merchant Remoto (Sailor Island)")
    local container = UI.Tabs[tabName].Container

    local itemDropdown = CreateDynamicDropdown(container, "📦 Item: " .. self.SelectedItem, self.Items, function(item)
        self.SelectedItem = item
    end)

    UI:CreateButton(tabName, "💰 Comprar o Máximo (Insta-Buy)", function()
        task.spawn(function()
            pcall(function()
                local merchantRemotes = ReplicatedStorage:FindFirstChild("Remotes") 
                                     and ReplicatedStorage.Remotes:FindFirstChild("MerchantRemotes")
                
                local purchaseRemote = merchantRemotes and merchantRemotes:FindFirstChild("PurchaseMerchantItem")
                
                if purchaseRemote and purchaseRemote:IsA("RemoteFunction") then
                    -- Usa InvokeServer porque é uma RemoteFunction que espera resposta do servidor
                    purchaseRemote:InvokeServer(self.SelectedItem, 999)
                end
            end)
        end)
    end)
end

function Module:Stop() end
function Module:Toggle(state) end

return Module
