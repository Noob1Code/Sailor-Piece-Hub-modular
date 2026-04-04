-- ========================================================================
-- 🚦 SERVIÇO: GERENCIADOR DE PRIORIDADES E ESTADOS (GAME CONTROLLER)
-- ========================================================================
local PriorityService = {
    Priorities = {
        ["PitySystem"] = 100,
        ["AutoBoss"] = 80, 
        ["AutoSummon"] = 70,
        ["AutoCollect"] = 60,
        ["AutoQuest"] = 50,
        ["AutoFarm"] = 10
    },
    
    ActiveRequests = {},
    CurrentPermitted = nil
}

function PriorityService:UpdateHierarchy()
    local highestPriority = -1
    local newLeader = nil

    for taskName, isActive in pairs(self.ActiveRequests) do
        if isActive then
            local prio = self.Priorities[taskName] or 0
            if prio > highestPriority then
                highestPriority = prio
                newLeader = taskName
            end
        end
    end

    if self.CurrentPermitted ~= newLeader then
        self.CurrentPermitted = newLeader
    end
end

function PriorityService:Request(taskName)
    if not self.ActiveRequests[taskName] then
        self.ActiveRequests[taskName] = true
        self:UpdateHierarchy()
    end
end

function PriorityService:Release(taskName)
    if self.ActiveRequests[taskName] then
        self.ActiveRequests[taskName] = nil
        self:UpdateHierarchy()
    end
end

function PriorityService:GetPermittedTask()
    return self.CurrentPermitted
end

return PriorityService
