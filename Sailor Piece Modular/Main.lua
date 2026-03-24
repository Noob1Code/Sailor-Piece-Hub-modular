-- ========================================================================
-- 🌟 SAILOR PIECE PROFESSIONAL HUB - CORE (MAIN LOADER)
-- ========================================================================

local Config = {
    HubName = "Sailor Piece Hub Pro",
    Version = "1.0.0",
    BaseURL = "COLOQUE_AQUI_O_LINK_RAW_DA_PASTA_DO_GITHUB/" -- Ex: "https://raw.githubusercontent.com/SeuNome/Repo/main/"
}

local Core = {
    Modules = {},
    Services = {},
    UI = nil
}

-- 1. Baixar a UI do GitHub
print("[Loader] Baixando UI...")
local uiCode = game:HttpGet(Config.BaseURL .. "UI.lua")
Core.UI = loadstring(uiCode)()

-- 2. Sistema de Registro
function Core:RegisterModule(name, category, moduleTable)
    assert(type(moduleTable.Init) == "function", "Erro no módulo " .. name)
    moduleTable.Name = name
    moduleTable.Category = category
    self.Modules[name] = moduleTable
    print("[Core] Registrado: " .. name)
end

-- 3. Baixar e Registrar Módulos
print("[Loader] Baixando Módulos...")

local autoFarmCode = game:HttpGet(Config.BaseURL .. "AutoFarm.lua")
local AutoFarmModule = loadstring(autoFarmCode)()
Core:RegisterModule("Auto Farm (Qualquer Mob)", "Farm & Nível", AutoFarmModule)

-- (Nas próximas etapas adicionaremos o AutoBoss.lua, Piloto.lua, etc. aqui embaixo)

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