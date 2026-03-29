
-- ========================================================================
-- 🎲 SERVIÇO: RANDOM SERVICE (SISTEMA DE HUMANIZAÇÃO ANTI-CHEAT)
-- ========================================================================
local RandomService = {}

function RandomService:GetTime(min, max)
    if not max then 
        max = min 
        min = 0 
    end
    return min + (math.random() * (max - min))
end

function RandomService:Wait(min, max)
    local waitTime = self:GetTime(min, max)
    task.wait(waitTime)
    return waitTime
end

return RandomService
