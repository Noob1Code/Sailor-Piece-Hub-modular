-- ========================================================================
-- 🛏️ SERVIÇO: GERENCIADOR DE SPAWN
-- ========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local TeleportService = Import("Services/Teleport")

local SpawnService = {
    SpawnSetado = false
}

-- Identifica o Spawn mais próximo do jogador
function SpawnService:GetClosestSpawn()
    local closest = nil
    local minDist = math.huge
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return nil end

    -- NOTA: Precisamos confirmar como o jogo guarda os Spawns. 
    -- Geralmente ficam numa pasta "Spawns", "ServiceNPCs" ou espalhados pelo Workspace.
    -- Aqui estou assumindo que são NPCs ou Partes que tenham "Spawn" no nome.
    local function searchFolder(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetChildren()) do
            -- Procura por algo que indique ser um Spawn Point
            if obj.Name:lower():find("spawn") or obj:GetAttribute("IsSpawn") then
                local objPos = obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") 
                               or obj:IsA("BasePart") and obj
                
                if objPos then
                    local dist = (hrp.Position - objPos.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = obj
                    end
                end
            end
        end
    end

    -- Busca em locais comuns
    searchFolder(Workspace:FindFirstChild("ServiceNPCs"))
    searchFolder(Workspace:FindFirstChild("NPCs"))
    searchFolder(Workspace) -- Busca global como fallback

    return closest
end

-- Vai até o Spawn e interage com ele
function SpawnService:SetSpawn()
    -- Regra: Se já estiver setado, não precisa repetir
    if self.SpawnSetado then return true end

    local spawnObj = self:GetClosestSpawn()
    if not spawnObj then
        print("🛏️ Nenhum Spawn encontrado por perto!")
        return false
    end

    print("🛏️ Indo setar o Spawn em: " .. spawnObj.Name)

    local targetPos = spawnObj:IsA("Model") and spawnObj:FindFirstChild("HumanoidRootPart") 
                      or spawnObj:IsA("BasePart") and spawnObj

    if targetPos then
        -- 1. Ir até ele
        TeleportService:FlyTo(targetPos.Position + Vector3.new(0, 0, 5))
        task.wait(0.5)

        -- 2. Setar o spawn (Interagir com o ProximityPrompt)
        local prompt = spawnObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(1) -- Tempo para a ação confirmar no servidor
            
            -- 3. Confirmar se foi setado e atualizar o estado
            self.SpawnSetado = true
            print("✅ Spawn setado com sucesso!")
            return true
        end
    end

    return false
end

-- Regra: Reseta para false quando houver teleporte entre ilhas
function SpawnService:Reset()
    self.SpawnSetado = false
    print("🔄 Estado do Spawn resetado (Mudança de Ilha detectada).")
end

return SpawnService
