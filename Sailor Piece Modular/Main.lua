-- ========================================================================
-- 🌟 SAILOR PIECE PROFESSIONAL HUB - CORE (MAIN LOADER)
-- ========================================================================

local Config = {
    HubName = "Sailor Piece Hub Pro",
    Version = "1.0.0",
    -- Link base do seu repositório (apontando para a raiz "main")
    BaseURL = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub-modular/main/"
}

local Core = {
    Modules = {},
    Services = {},
    UI = nil
}

-- 1. Baixar a UI do GitHub (Puxando da subpasta "Ui")
print("[Loader] Baixando UI...")
local uiCode = game:HttpGet(Config.BaseURL .. "Ui/UI.lua")
Core.UI = loadstring(uiCode)()

-- 2. Sistema de Registro
function Core:RegisterModule(name, category, moduleTable)
    assert(type(moduleTable.Init) == "function", "Erro no módulo " .. name)
    moduleTable.Name = name
    moduleTable.Category = category
    self.Modules[name] = moduleTable
    print("[Core] Registrado: " .. name)
end

-- 3. Baixar e Registrar Módulos (Puxando da subpasta "Modules")
print("[Loader] Baixando Módulos...")

-- Auto Farm
local autoFarmCode = game:HttpGet(Config.BaseURL .. "Modules/AutoFarm.lua")
local AutoFarmModule = loadstring(autoFarmCode)()
Core:RegisterModule("Auto Farm (Qualquer Mob)", "Farm & Nível", AutoFarmModule)

-- 4. Inicializar Tudo
function Core:Init()
    print("[Core] Inicializando sistemas...")
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
    print("🚀 Hub Carregado com Sucesso!")
end

-- GO!
Core:Init()
Core:Start()
