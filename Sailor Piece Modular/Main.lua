local REPO_URL = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub-modular/main/Sailor%20Piece%20Modular/"
local moduleCache = {}

pcall(function()
    local Players = game:GetService("Players")
    local VirtualUser = game:GetService("VirtualUser")
    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

getgenv().Import = function(modulePath)
    if moduleCache[modulePath] then return moduleCache[modulePath] end
    local url = REPO_URL .. modulePath .. ".lua?t=" .. tostring(math.random(1000, 9999))

    local result
    local success, err = pcall(function() result = game:HttpGet(url) end)
    if not success or not result or result:find("404: Not Found") then
        error("❌ Erro de Download (Verifique o GitHub): " .. modulePath)
    end

    local loadedFunc, loadError = loadstring(result)
    if not loadedFunc then error("❌ Erro de Sintaxe: " .. tostring(loadError)) end

    local moduleData = loadedFunc()
    moduleCache[modulePath] = moduleData
    return moduleData
end

local Config = { HubName = "Sailor Piece Hub Pro", Version = "1.0.1" }
local Core = { Modules = {} }

Core.UI = Import("Ui/UI")
local CombatService = Import("Services/CombatService")
CombatService:Init()

function Core:RegisterModule(name, category, moduleTable)
    assert(type(moduleTable.Init) == "function", "Erro no módulo " .. name)
    moduleTable.Name = name
    moduleTable.Category = category
    self.Modules[name] = moduleTable
end

-- ==========================================
-- 📦 REGISTRO DE MÓDULOS
-- ==========================================
local AutoQuestModule = Import("Modules/AutoQuest")
Core:RegisterModule("Auto Quest (Unitária)", "Missões", AutoQuestModule)
task.wait(0.5)

local TeleportModule = Import("Services/Teleport")
Core:RegisterModule("Mundo & Teleporte", "Mundo & Teleporte", TeleportModule)
task.wait(0.5)

local AutoFarmModule = Import("Modules/AutoFarm")
Core:RegisterModule("Auto Farm (Qualquer Mob)", "Farm & Nível", AutoFarmModule)
task.wait(0.5)

local AutoBossModule = Import("Modules/AutoBoss")
Core:RegisterModule("Auto Boss", "Chefes (Boss)", AutoBossModule)
task.wait(0.5)

local AutoSummonModule = Import("Modules/AutoSummon")
Core:RegisterModule("Auto Summon Boss", "Chefes (Boss)", AutoSummonModule)
task.wait(0.5)

local AutoPityModule = Import("Modules/AutoPity")
Core:RegisterModule("Auto Pity (Garantido)", "Gacha & Itens", AutoPityModule)
task.wait(0.5)

local AutoCollectModule = Import("Modules/AutoCollect")
Core:RegisterModule("Motor de Coleta", "Coletáveis", AutoCollectModule)
task.wait(0.5)

local AutoMerchantModule = Import("Modules/AutoMerchant")
Core:RegisterModule("Mercador Remoto", "Gacha & Itens", AutoMerchantModule)
task.wait(0.5)

function Core:Init()
    self.UI:Init(Config)
    
    self.UI.OnClose = function()
        for _, module in pairs(self.Modules) do
            if module.Stop then
                pcall(function() module:Stop() end)
            end
        end
    end
    
    for _, module in pairs(self.Modules) do module:Init() end
end

function Core:Start()
    self.UI:Start()
    local WeaponService = Import("Services/WeaponService")
    WeaponService:BuildUI("Misc & Config")
    
    for name, module in pairs(self.Modules) do
        if not module.NoToggle then
            self.UI:CreateToggle(module.Category, name, function(state)
                module:Toggle(state)
            end)
        else
            if module.Start then
                pcall(function() module:Start() end)
            end
        end
    end
end

Core:Init()
Core:Start()
