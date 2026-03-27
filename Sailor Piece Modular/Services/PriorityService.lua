-- ========================================================================
-- 🚦 SERVIÇO: GERENCIADOR DE PRIORIDADES E ESTADOS (GAME CONTROLLER)
-- ========================================================================
local PriorityService = {
    -- 1. Definimos a hierarquia de quem é mais importante
    Priorities = {
        ["PitySystem"] = 100,   -- Prioridade Máxima
        ["AutoBoss"] = 80,      -- Muito importante
        ["AutoQuest"] = 50,     -- Importante
        ["AutoFarm"] = 10       -- Farm base (Só roda se os outros não precisarem)
    },
    
    -- 2. Controle de Estados Ativos
    ActiveRequests = {},
    
    -- 🔥 3. CACHE DE PERFORMANCE (O Pulo do Gato)
    -- Salva quem é o atual líder para não precisar recalcular a cada frame!
    CurrentPermitted = nil
}

-- ========================================================================
-- 🧠 MÁQUINA DE ESTADOS: Recalcula o Líder (Só roda quando há mudanças!)
-- ========================================================================
function PriorityService:UpdateHierarchy()
    local highestPriority = -1
    local newLeader = nil

    -- Analisa a mesa para ver quem tem a maior carta
    for taskName, isActive in pairs(self.ActiveRequests) do
        if isActive then
            local prio = self.Priorities[taskName] or 0
            if prio > highestPriority then
                highestPriority = prio
                newLeader = taskName
            end
        end
    end

    -- Se a coroa mudou de dono, avisa no console e atualiza o Cache
    if self.CurrentPermitted ~= newLeader then
        self.CurrentPermitted = newLeader
        if newLeader then
            print("👑 Novo Líder de Execução assumiu o controle: " .. newLeader)
        else
            print("💤 Todos os sistemas em repouso. Aguardando tarefas...")
        end
    end
end

-- ========================================================================
-- 📢 COMUNICAÇÃO COM OS MÓDULOS
-- ========================================================================

-- Módulo avisa que achou um alvo e quer executar
function PriorityService:Request(taskName)
    if not self.ActiveRequests[taskName] then
        print("🚦 Prioridade Solicitada por: " .. taskName)
        self.ActiveRequests[taskName] = true
        
        -- 🔥 Dispara a atualização instantaneamente
        self:UpdateHierarchy()
    end
end

-- Módulo avisa que terminou o serviço ou foi desligado
function PriorityService:Release(taskName)
    if self.ActiveRequests[taskName] then
        print("🚦 Prioridade Liberada por: " .. taskName)
        self.ActiveRequests[taskName] = nil
        
        -- 🔥 Passa a coroa para o próximo da fila
        self:UpdateHierarchy()
    end
end

-- ========================================================================
-- ⚡ RESPOSTA INSTANTÂNEA (OTIMIZADO)
-- ========================================================================
-- O Juiz: Agora responde imediatamente (O(1)) em vez de ler tabelas,
-- poupando quantidades massivas de processamento da CPU do Roblox.
function PriorityService:GetPermittedTask()
    return self.CurrentPermitted
end

return PriorityService
