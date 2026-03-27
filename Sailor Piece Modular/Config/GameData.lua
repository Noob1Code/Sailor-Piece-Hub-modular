-- ========================================================================
-- 🗄️ MÓDULO: GAME DATA (BANCO DE DADOS CENTRAL)
-- ========================================================================
local GameData = {}

-- 1. Lista de Ilhas na ordem que devem aparecer na UI
GameData.IslandsInOrder = {
    "Starter", "Jungle", "Desert", "Snow", "Sailor", "Shibuya Station",
    "Hollow Island", "Boss Island", "Shinjuku", "Slime", "Academy", "Judgement", "Soul Dominion"
}

-- 2. Tradutor de Teleporte (Nome da UI -> Nome do Jogo)
GameData.TeleportMap = {
    ["Starter"] = "Starter", 
    ["Jungle"] = "Jungle", 
    ["Desert"] = "Desert",
    ["Snow"] = "Snow", 
    ["Sailor"] = "Sailor", 
    ["Shibuya Station"] = "Shibuya",
    ["Hollow Island"] = "HollowIsland", 
    ["Boss Island"] = "Boss", 
    ["Dungeon"] = "Dungeon",
    ["Shinjuku"] = "Shinjuku", 
    ["Slime"] = "Slime", 
    ["Academy"] = "Academy",
    ["Judgement"] = "Judgement", 
    ["Soul Dominion"] = "SoulDominion"
}

-- 3. Lista de NPCs de Serviços Gerais
GameData.NpcList = {
    "GroupRewardNPC", 
    "BossRushShopNPC", 
    "BossRushPortalNPC", 
    "DungeonMerchantNPC", 
    "EnchantNPC", 
    "YujiBuyerNPC", 
    "BlessingNPC", 
    "SlimeCraftNPC", 
    "RimuruMasteryNPC", 
    "SkillTreeNPC", 
    "Katana", 
    "MadokaBuyer", 
    "HakiQuestNPC", 
    "SummonBossNPC"
}

-- 4. Banco de Dados de Missões por Ilha
GameData.QuestDataMap = {
    ["Starter"] = {
        {
            Name = "Quest 1: Mobs (Thief)", 
            NPC = "QuestNPC1", 
            Target = "Thief", 
            Tracker = "Thief Hunter", 
            Type = "Mob"
        }, 
        {
            Name = "Quest 2: Boss (Thief Boss)", 
            NPC = "QuestNPC2", 
            Target = "ThiefBoss", 
            Tracker = "Thief Boss", 
            Type = "Boss"
        }
    },
    ["Jungle"] = {
        {
            Name = "Quest 3: Mobs (Monkey)", 
            NPC = "QuestNPC3", 
            Target = "Monkey", 
            Tracker = "Monkey Hunter", 
            Type = "Mob"
        }, 
        {
            Name = "Quest 4: Boss (Monkey Boss)", 
            NPC = "QuestNPC4", 
            Target = "MonkeyBoss", 
            Tracker = "Monkey Boss", 
            Type = "Boss"
        }
    },
    ["Desert"] = {
        {
            Name = "Quest 5: Mobs (Bandits)", 
            NPC = "QuestNPC5", 
            Target = "DesertBandit", 
            Tracker = "Desert Bandit Hunter", 
            Type = "Mob"
        }, 
        {
            Name = "Quest 6: Boss (Desert Boss)", 
            NPC = "QuestNPC6", 
            Target = "DesertBoss", 
            Tracker = "Desert Bandit Boss",
            Type = "Boss"
        }
    },
    ["Snow"] = {
        {
            Name = "Quest 7: Mobs (Frost Rogue)", 
            NPC = "QuestNPC7", 
            Target = "FrostRogue", 
            Tracker = "Frost Rogue Hunter", 
            Type = "Mob"
        }, 
        {
            Name = "Quest 8: Boss (Snow Boss)", 
            NPC = "QuestNPC8", 
            Target = "SnowBoss", 
            Tracker = "Winter Warden Boss",
            Type = "Boss"
        }
    },
    ["Sailor"] = {
        {
            Name = "Âncora Sailor", 
            NPC = "JinwooMovesetNPC", 
            Target = "Nenhum", 
            Type = "Mob" 
        }
    },
    ["Shibuya Station"] = {
        {
            Name = "Quest 9: Mobs (Sorcerer)", 
            NPC = "QuestNPC9", 
            Target = "Sorcerer", 
            Tracker = "Sorcerer Hunter", 
            Type = "Mob"
        }, 
        {
            Name = "Quest 10: Mobs (Panda Sorcerer)", 
            NPC = "QuestNPC10", 
            Target = "PandaMiniBoss", 
            Tracker = "Panda Sorcerer Boss",
            Type = "Boss"
        }
    },
    ["Hollow Island"] = {
        {
            Name = "Quest 11: Mobs (Hollow)", 
            NPC = "QuestNPC11", 
            Target = "Hollow", 
            Tracker = "Hollow Hunter",
            Type = "Mob"
        }
    },
    ["Shinjuku"] = {
        {
            Name = "Quest 12: Mobs", 
            NPC = "QuestNPC12", 
            Target = "StrongSorcerer", 
            Tracker = "Strong Sorcerer Hunter", 
            Type = "Mob"
        }, 
        {
            Name = "Quest 13: Mobs", 
            NPC = "QuestNPC13", 
            Target = "Curse", 
            Tracker = "Curse Hunter",
            Type = "Mob"
        }
    },
    ["Slime"] = {
        {
            Name = "Quest 14: Mobs (Slime)", 
            NPC = "QuestNPC14", 
            Target = "Slime", 
            Tracker = "Slime Warrior Hunter", 
            Type = "Mob"
        }
    },
    ["Academy"] = {
        {
            Name = "Quest 15: Mobs (Teacher)", 
            NPC = "QuestNPC15", 
            Target = "AcademyTeacher", 
            Tracker = "Academy Challenge", 
            Type = "Mob"
        }
    },
    ["Judgement"] = {
        {
            Name = "Quest 16: Mobs", 
            NPC = "QuestNPC16", 
            Target = "Swordsman", 
            Tracker = "Blade Masters", 
            Type = "Mob"
        }
    },
    ["Soul Dominion"] = {
        {
            Name = "Quest 17: Mobs", 
            NPC = "QuestNPC17", 
            Target = "Quincy", 
            Tracker = "Quincy Purge", 
            Type = "Mob"
        }
    },
    ["Boss Island"] = {
        {
            Name = "Âncora de Ilha", 
            NPC = "SummonBossNPC", 
            Target = "Nenhum", 
            Type = "Mob"
        }
    }
}

-- 5. Sistema de GPS: NPC -> Ilha
GameData.NpcToIsland = {
    ["QuestNPC1"] = "Starter", ["QuestNPC2"] = "Starter",
    ["QuestNPC3"] = "Jungle", ["QuestNPC4"] = "Jungle",
    ["QuestNPC5"] = "Desert", ["QuestNPC6"] = "Desert",
    ["QuestNPC7"] = "Snow", ["QuestNPC8"] = "Snow",
    ["JinwooMovesetNPC"] = "Sailor",
    ["QuestNPC9"] = "Shibuya Station", ["QuestNPC10"] = "Shibuya Station",
    ["QuestNPC11"] = "Hollow Island",
    ["QuestNPC12"] = "Shinjuku", ["QuestNPC13"] = "Shinjuku",
    ["QuestNPC14"] = "Slime",
    ["QuestNPC15"] = "Academy",
    ["QuestNPC16"] = "Judgement",
    ["QuestNPC17"] = "Soul Dominion",
    ["SummonBossNPC"] = "Boss Island"
}

-- 6. Progressão do Piloto Automático (Usaremos no próximo módulo!)
GameData.QuestProgression = {
    { Island = "Starter", Quest = "Quest 1: Mobs (Thief)", MinLevel = 1 }, { Island = "Starter", Quest = "Quest 2: Boss (Thief Boss)", MinLevel = 100 },
    { Island = "Jungle", Quest = "Quest 3: Mobs (Monkey)", MinLevel = 250 }, { Island = "Jungle", Quest = "Quest 4: Boss (Monkey Boss)", MinLevel = 500 },
    { Island = "Desert", Quest = "Quest 5: Mobs (Bandits)", MinLevel = 750 }, { Island = "Desert", Quest = "Quest 6: Boss (Desert Boss)", MinLevel = 1000 },
    { Island = "Snow", Quest = "Quest 7: Mobs (Frost Rogue)", MinLevel = 1500 }, { Island = "Snow", Quest = "Quest 8: Boss (Snow Boss)", MinLevel = 2000 },
    { Island = "Shibuya Station", Quest = "Quest 9: Mobs (Sorcerer)", MinLevel = 3000 }, { Island = "Shibuya Station", Quest = "Quest 10: Mobs (Panda Sorcerer)", MinLevel = 4000 },
    { Island = "Hollow Island", Quest = "Quest 11: Mobs (Hollow)", MinLevel = 5000 }, { Island = "Shinjuku", Quest = "Quest 12: Mobs", MinLevel = 6250 },
    { Island = "Shinjuku", Quest = "Quest 13: Mobs", MinLevel = 7000 }, { Island = "Slime", Quest = "Quest 14: Mobs (Slime)", MinLevel = 8000 },
    { Island = "Academy", Quest = "Quest 15: Mobs (Teacher)", MinLevel = 10000 }, { Island = "Judgement", Quest = "Quest 16: Mobs", MinLevel = 10750 },
    { Island = "Soul Dominion", Quest = "Quest 17: Mobs", MinLevel = 11500 }
}

-- 7. Chefões Ocultos, Invocados e Eventos de Tempo (Sem Missão)
GameData.HiddenBosses = {
    ["Sailor"] = {"JinwooBoss", "AlucardBoss"},
    ["Shibuya Station"] = {"YujiBoss", "SukunaBoss", "GojoBoss"},
    ["Hollow Island"] = {"AizenBoss"},
    ["Judgement"] = {"YamatoBoss"},
}

-- 8. Chefões de Invocação (Precisam disparar o Remote: SummonBossRemote)
GameData.SummonBosses = {
    ["Boss Island"] = {"SaberBoss", "QinShiBoss", "IchigoBoss", "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"}
}

-- 9. Chefões de Evento / Tempo (Requerem o "Sniper de Chat" para achar)
GameData.TimedBosses = {
    ["Eventos"] = {"MadokaBoss", "Rimuru"}
}

return GameData
