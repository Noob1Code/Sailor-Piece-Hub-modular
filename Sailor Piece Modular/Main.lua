local REPO_URL = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub-modular/main/Sailor%20Piece%20Modular/"
local moduleCache = {}

getgenv().Import = function(modulePath)
    if moduleCache[modulePath] then return moduleCache[modulePath] end
    local url = REPO_URL .. modulePath .. ".lua?t=" .. tostring(math.random(1000, 9999))
    print("⏳ Importando: " .. modulePath)

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

print("🛠️ Inicializando Sailor Piece Hub Pro...")

local Config = { HubName = "Sailor Piece Hub Pro", Version = "1.0.1" }
local Core = { Modules = {} }

-- 1. Injeta a UI
Core.UI = Import("Ui/UI")

-- 2. Sistema de Registro
function Core:RegisterModule(name, category, moduleTable)
    assert(type(moduleTable.Init) == "function", "Erro no módulo " .. name)
    moduleTable.Name = name
    moduleTable.Category = category
    self.Modules[name] = moduleTable
end

local TeleportModule = Import("Modules/Teleport")
Core:RegisterModule("Mundo & Teleporte", "Mundo & Teleporte", TeleportModule)
local AutoFarmModule = Import("Modules/AutoFarm")
Core:RegisterModule("Auto Farm (Qualquer Mob)", "Farm & Nível", AutoFarmModule)

-- 4. Iniciar e Conectar o Botão de Fechar
function Core:Init()
    self.UI:Init(Config)
    
    -- 🛑 A MÁGICA DE DESLIGAR TUDO NO BOTÃO X 🛑
    self.UI.OnClose = function()
        print("🛑 Desligando todos os módulos ativos...")
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
    
    for name, module in pairs(self.Modules) do
        if not module.NoToggle then
            self.UI:CreateToggle(module.Category, name, function(state)
                module:Toggle(state)
            end)
        end
    end
    print("🚀 Hub Online e Operante!")
end

Core:Init()
Core:Start()
