-- ========================================================================
-- 🌟 SAILOR PIECE PROFESSIONAL HUB - CORE (MAIN LOADER)
-- ========================================================================

-- A URL Base exata apontando para dentro da sua pasta principal
local REPO_URL = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub-modular/main/"
local moduleCache = {}

-- ⚙️ SISTEMA DE IMPORTAÇÃO (Evita crashes e faz cache)
getgenv().Import = function(modulePath)
    if moduleCache[modulePath] then return moduleCache[modulePath] end
    
    local url = REPO_URL .. modulePath .. ".lua"
    print("⏳ Importando: " .. modulePath)

    local result
    local success, err = pcall(function()
        result = game:HttpGet(url, true) 
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

-- 1. Baixar a UI usando o nosso novo sistema Import
Core.UI = Import("Ui/UI")

-- 2. Sistema de Registro
function Core:RegisterModule(name, category, moduleTable)
    assert(type(moduleTable.Init) == "function", "Erro de padronização no módulo: " .. name)
    moduleTable.Name = name
    moduleTable.Category = category
    self.Modules[name] = moduleTable
    print("✅ Módulo Registrado: " .. name)
end

-- 3. Baixar e Registrar Módulos da pasta Modules
-- Se der erro de nome, o F9 vai te avisar exatamente qual arquivo falhou!
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
