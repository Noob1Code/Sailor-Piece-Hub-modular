-- ========================================================================
-- 🎮 MANAGER: GACHA & ITENS (SISTEMA DE NAVEGAÇÃO INTERNA)
-- ========================================================================
local UI = Import("Ui/UI")
local Module = { NoToggle = true }

function Module:Init()
    self.TabName = "Gacha & Itens"
    
    self.Pity = Import("Modules/AutoPity")
    self.Merchant = Import("Modules/AutoMerchant")
    self.Reroll = Import("Modules/AutoReroll")
    self.Pity:Init()
    self.Merchant:Init()
    self.Reroll:Init()
end

function Module:Clear()
    local container = UI.Tabs[self.TabName].Container
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

function Module:ShowMenu()
    self:Clear()
    UI:CreateSection(self.TabName, "Menu Principal")
    
    UI:CreateButton(self.TabName, "🎲 Auto Reroll Status", function() self:ShowReroll() end)
    UI:CreateButton(self.TabName, "🍀 Auto Pity (Garantido)", function() self:ShowPity() end)
    UI:CreateButton(self.TabName, "🛒 Auto Merchant", function() self:ShowMerchant() end)
end

function Module:CreateBackButton()
    UI:CreateButton(self.TabName, "⬅️ Voltar ao Menu", function() self:ShowMenu() end)
    UI:CreateSection(self.TabName, "Configurações")
end

function Module:ShowReroll()
    self:Clear()
    self:CreateBackButton()
    self.Reroll:BuildUI() 
end

function Module:ShowPity()
    self:Clear()
    self:CreateBackButton()
    self.Pity:BuildUI()
end

function Module:ShowMerchant()
    self:Clear()
    self:CreateBackButton()
    self.Merchant:BuildUI()
end

function Module:Start()
    self:ShowMenu()
end

return Module
