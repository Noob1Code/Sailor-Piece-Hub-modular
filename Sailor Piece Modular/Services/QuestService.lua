-- ========================================================================
-- 👁️ SERVIÇO: QUEST SERVICE (LEITOR DE INTERFACE)
-- ========================================================================
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local QuestService = {}

-- 🔍 1. Busca a caixa oficial de missões do jogo na tela
function QuestService:GetQuestContainer()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    
    -- O caminho exato que você descobriu no console!
    local questUI = pg:FindFirstChild("QuestUI")
    local q1 = questUI and questUI:FindFirstChild("Quest")
    local q2 = q1 and q1:FindFirstChild("Quest")
    local holder = q2 and q2:FindFirstChild("Holder")
    local content = holder and holder:FindFirstChild("Content")
    
    -- Verifica se a caixa existe e está visível
    if content and content.Visible then
        return content
    end
    return nil
end

-- ❓ 2. Responde: "Existe ALGUMA missão ativa agora?"
function QuestService:HasAnyQuest()
    local container = self:GetQuestContainer()
    if not container then return false end
    
    local questInfo = container:FindFirstChild("QuestInfo")
    local req = questInfo and questInfo:FindFirstChild("QuestRequirement")
    
    -- Se tem a caixa de requerimento com "0/5" ou "0/100", então tem missão.
    if req and req:IsA("TextLabel") and req.Text:match("%d+%s*/%s*%d+") then
        return true
    end
    return false
end

-- 🎯 3. Responde: "A missão que está na tela é a que eu quero?"
function QuestService:IsTracking(targetName)
    local container = self:GetQuestContainer()
    if not container then return false end
    
    local cleanTarget = targetName:lower():gsub("%s+", "")
    
    -- Vasculha todos os textos dentro da caixa de missão procurando o nome do alvo
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text ~= "" then
            local cleanText = obj.Text:lower():gsub("%s+", "")
            if cleanText:find(cleanTarget) then
                return true -- Achou! É a missão correta!
            end
        end
    end
    
    return false -- Não achou o nome. É outra missão (ex: Aizen 0/100).
end

-- ✅ 4. Responde: "A missão já bateu 5/5 ou 100/100?"
function QuestService:IsQuestCompleted()
    local container = self:GetQuestContainer()
    if not container then return false end
    
    local questInfo = container:FindFirstChild("QuestInfo")
    local req = questInfo and questInfo:FindFirstChild("QuestRequirement")
    
    if req and req:IsA("TextLabel") then
        local currStr, maxStr = req.Text:match("(%d+)%s*/%s*(%d+)")
        if currStr and maxStr then
            return tonumber(currStr) >= tonumber(maxStr)
        end
    end
    return false
end

return QuestService
