-- ========================================================================
-- 🚦 SERVIÇO: GERENCIADOR DE PRIORIDADES (O CÉREBRO CENTRAL)
-- ========================================================================
local PriorityService = {
    -- 1. Definimos a hierarquia de quem é mais importante (Maior número = Maior prioridade)
    Priorities = {
        ["PitySystem"] = 100,   -- Prioridade Máxima
        ["AutoBoss"] = 90,      -- Muito importante
        ["AutoQuest"] = 75,     -- Importante
        ["AutoFarm"] = 10       -- Farm base (Só roda se os outros não precisarem)
    },
    
    -- 2. Lista de quem está "pedindo passagem" neste exato momento
    ActiveRequests = {}
}

-- Módulo avisa que achou um alvo e quer executar
function PriorityService:Request(taskName)
    if not self.ActiveRequests[taskName] then
        print("🚦 Prioridade Solicitada por: " .. taskName)
        self.ActiveRequests[taskName] = true
    end
end

-- Módulo avisa que terminou o serviço ou foi desligado
function PriorityService:Release(taskName)
    if self.ActiveRequests[taskName] then
        print("🚦 Prioridade Liberada por: " .. taskName)
        self.ActiveRequests[taskName] = nil
    end
end

-- O Juiz: Calcula quem tem a maior prioridade na fila atual
function PriorityService:GetPermittedTask()
    local highestPriority = -1
    local permittedTask = nil

    for taskName, isActive in pairs(self.ActiveRequests) do
        if isActive then
            local prio = self.Priorities[taskName] or 0
            if prio > highestPriority then
                highestPriority = prio
                permittedTask = taskName
            end
        end
    end

    return permittedTask
end

return PriorityService
