-- ========================================================================
-- 🌟 SAILOR PIECE PROFESSIONAL HUB - CORE (MAIN LOADER)
-- ========================================================================

local REPO_URL = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub-modular/main/Sailor%20Piece%20Modular/"
local moduleCache = {}

-- ⚙️ SISTEMA DE IMPORTAÇÃO (Anti-Crash e Bypass de Cache)
getgenv().Import = function(modulePath)
    if moduleCache[modulePath] then return moduleCache[modulePath] end
    
    -- O math.random no final engana o Roblox para ele sempre baixar a versão mais nova do GitHub sem crashar o executor!
    local url = REPO_URL .. modulePath .. ".lua?t=" .. tostring(math.random(10000, 99999))
    print("⏳ Importando: " .. modulePath)

    local result
    local success, err = pcall(function()
        -- Removido o 'true' que estava causando o crash!
        result = game:HttpGet(url) 
    end)

    if not success or not result or result:find("404: Not Found") or result == "404: Not Found" then
        error("❌ Erro 404 (Arquivo não encontrado no GitHub): " .. url)
    end

    local loadedFunc, loadError = loadstring(result)
    if not loadedFunc then
        error("❌ Erro de Sintaxe no arquivo: " .. modulePath .. ".lua\nDetalhe: " .. tostring(loadError))
    end

    local moduleData = loadedFunc()
    moduleCache[modulePath] = moduleData
    return moduleData
end

print("🛠️ Inicializando Sailor Piece Hub Pro...")

-- ========================================================================
-- 📁 CONFIGURAÇÕES E CORE
-- ========================================================================
local Config = {
    HubName = "Sailor Piece Hub Pro",
    Version = "1.0.0"
}

local Core = {
    Modules = {}
}

-- 1. Baixar a UI
-- Atenção: Se a sua pasta se chama literalmente "2-Ui", troque "Ui/UI" por "2-Ui/UI"
Core.UI = Import("Ui/UI")

-- 2. Sistema de Registro
function Core:RegisterModule(name, category, moduleTable)
    assert(type(moduleTable.Init) == "function", "Erro de padronização no módulo: " .. name)
    moduleTable.Name = name
    moduleTable.Category = category
    self.Modules[name] = moduleTable
    print("✅ Módulo Registrado: " .. name)
end

-- 3. Baixar e Registrar Módulos
-- Atenção: Se a sua pasta se chama literalmente "1-Modules", troque "Modules/AutoFarm" por "1-Modules/AutoFarm"
local AutoFarmModule = Import("Modules/AutoFarm")
Core:RegisterModule("Auto Farm (Qualquer Mob)", "Farm & Nível", AutoFarmModule)

-- 4. Inicializar Tudo
function Core:Init()
    print("⚙️ Preparando sistemas...")
    self.UI:Init(Config)
    
    for _, module in pairs(self.Modules) do
        module:Init()
    end
end

function Core:Start()
    self.UI:Start()
    
    for name, module in pairs(self.Modules) do
        self.UI:CreateToggle(module.Category, name, function(state)
            module:Toggle(state)
        end)
    end
    print("🚀 Hub Online e Operante!")
end

-- ========================================================================
-- 🏁 EXECUÇÃO
-- ========================================================================
Core:Init()
Core:Start()
