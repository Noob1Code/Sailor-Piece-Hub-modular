-- ========================================================================
-- 🗄️ MÓDULO: GAME DATA (BANCO DE DADOS CENTRAL)
-- ========================================================================
local GameData = {}

-- 1. Lista de Ilhas na ordem que devem aparecer na UI
GameData.IslandsInOrder = {
    "Starter", "Jungle", "Desert", "Snow", "Sailor", "Shibuya Station",
    "Hollow Island", "Boss Island", "Dungeon", "Shinjuku", "Slime", "Academy", 
    "Judgement", "Soul Dominion", "Ninja", "Lawless", "Tower"
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
    ["Soul Dominion"] = "SoulDominion",
    ["Ninja"] = "Ninja",
    ["Lawless"] = "Lawless",
    ["Tower"] = "Tower"
}

-- 3. Lista de NPCs de Serviços Gerais
GameData.NpcList = {
    -- Starter / Desert / Snow
    "GroupRewardNPC", "MadokaBuyer", "ShadowQuestlineBuff", "ShadowMonarchQuestlineBuff",
    "ObservationBuyer", "DarkBladeNPC", "RagnaBuyer", "RagnaQuestlineBuff", "HakiQuestNPC",
    -- Sailor
    "BossRushShopNPC", "BossRushPortalNPC", "BossRushMerchantNPC", "AscendNPC", "TraitNPC", 
    "RerollStatNPC", "MerchantNPC", "TitlesNPC", "StorageNPC", "GemFruitDealer", "CoinFruitDealer", 
    "AlucardBuyer", "JinwooMovesetNPC",
    -- Shibuya / Hollow
    "YujiBuyerNPC", "GojoMovesetNPC", "SukunaMovesetNPC", "BlessingNPC", "EnchantNPC", 
    "GryphonBuyerNPC", "IchigoBuyer", "AizenQuestlineBuff", "HogyokuQuestNPC", "AizenMovesetNPC",
    -- Boss Island
    "SummonBossNPC", "ExchangeNPC", "MoonSlayerBuff", "GilgameshBuyerNPC", "SaberAlterBuyerNPC", 
    "BlessedMaidenMasteryNPC", "BlessedMaidenBuyerNPC", "MoonSlayerSeller", "QinShiBuyer", 
    "SaberAlterMasteryNPC", "BabylonCraftNPC", "GrailCraftNPC",
    -- Dungeon / Shinjuku / Slime
    "DungeonMerchantNPC", "DungeonPortalsNPC", "CidBuyer", "ShadowMonarchBuyerNPC",
    "StrongestofTodayBuyerNPC", "StrongestinHistoryBuyerNPC", "StrongestBossSummonerNPC",
    "SkillTreeNPC", "SlimeCraftNPC", "RimuruSummonerNPC", "RimuruMasteryNPC", "RimuruBuyer",
    -- Academy / Judgement / Soul Dominion
    "AnosQuestNPC", "AnosBossSummonerNPC", "AnosBuyerNPC", "YamatoBuyerNPC", "SpecPassivesNPC",
    "TrueAizenBuyerNPC", "TrueAizenFUnlockNPC", "TrueAizenBossSummonerNPC",
    -- Ninja / Lawless / Tower
    "StrongestShinobiBuyerNPC", "PowerNPC", "AtomicBossSummonerNPC", "AtomicQuestlineBuff", 
    "AtomicBuyer", "InfiniteTowerStatShopNPC", "InfiniteTowerPortalNPC", "InfiniteTowerMerchantNPC"
}

-- 4. Banco de Dados de Missões por Ilha
GameData.QuestDataMap = {
    ["Starter"] = {
        { Name = "Quest 1: Mobs (Thief)", NPC = "QuestNPC1", Target = "Thief", Tracker = "Thief Hunter", Type = "Mob" }, 
        { Name = "Quest 2: Boss (Thief Boss)", NPC = "QuestNPC2", Target = "ThiefBoss", Tracker = "Thief Boss", Type = "Boss" }
    },
    ["Jungle"] = {
        { Name = "Quest 3: Mobs (Monkey)", NPC = "QuestNPC3", Target = "Monkey", Tracker = "Monkey Hunter", Type = "Mob" }, 
        { Name = "Quest 4: Boss (Monkey Boss)", NPC = "QuestNPC4", Target = "MonkeyBoss", Tracker = "Monkey Boss", Type = "Boss" }
    },
    ["Desert"] = {
        { Name = "Quest 5: Mobs (Bandits)", NPC = "QuestNPC5", Target = "DesertBandit", Tracker = "Desert Bandit Hunter", Type = "Mob" }, 
        { Name = "Quest 6: Boss (Desert Boss)", NPC = "QuestNPC6", Target = "DesertBoss", Tracker = "Desert Bandit Boss", Type = "Boss" }
    },
    ["Snow"] = {
        { Name = "Quest 7: Mobs (Frost Rogue)", NPC = "QuestNPC7", Target = "FrostRogue", Tracker = "Frost Rogue Hunter", Type = "Mob" }, 
        { Name = "Quest 8: Boss (Snow Boss)", NPC = "QuestNPC8", Target = "SnowBoss", Tracker = "Winter Warden Boss", Type = "Boss" }
    },
    ["Sailor"] = {
        { Name = "Âncora Sailor", NPC = "JinwooMovesetNPC", Target = "Nenhum", Type = "Mob" }
    },
    ["Shibuya Station"] = {
        { Name = "Quest 9: Mobs (Sorcerer)", NPC = "QuestNPC9", Target = "Sorcerer", Tracker = "Sorcerer Hunter", Type = "Mob" }, 
        { Name = "Quest 10: Mobs (Panda Sorcerer)", NPC = "QuestNPC10", Target = "PandaMiniBoss", Tracker = "Panda Sorcerer Boss", Type = "Boss" }
    },
    ["Hollow Island"] = {
        { Name = "Quest 11: Mobs (Hollow)", NPC = "QuestNPC11", Target = "Hollow", Tracker = "Hollow Hunter", Type = "Mob" }
    },
    ["Shinjuku"] = {
        { Name = "Quest 12: Mobs", NPC = "QuestNPC12", Target = "StrongSorcerer", Tracker = "Strong Sorcerer Hunter", Type = "Mob" }, 
        { Name = "Quest 13: Mobs", NPC = "QuestNPC13", Target = "Curse", Tracker = "Curse Hunter", Type = "Mob" }
    },
    ["Slime"] = {
        { Name = "Quest 14: Mobs (Slime)", NPC = "QuestNPC14", Target = "Slime", Tracker = "Slime Warrior Hunter", Type = "Mob" }
    },
    ["Academy"] = {
        { Name = "Quest 15: Mobs (Teacher)", NPC = "QuestNPC15", Target = "AcademyTeacher", Tracker = "Academy Challenge", Type = "Mob" }
    },
    ["Judgement"] = {
        { Name = "Quest 16: Mobs", NPC = "QuestNPC16", Target = "Swordsman", Tracker = "Blade Masters", Type = "Mob" }
    },
    ["Soul Dominion"] = {
        { Name = "Quest 17: Mobs", NPC = "QuestNPC17", Target = "Quincy", Tracker = "Quincy Purge", Type = "Mob" }
    },
    ["Boss Island"] = {
        { Name = "Âncora de Ilha", NPC = "SummonBossNPC", Target = "Nenhum", Type = "Mob" }
    },
    ["Ninja"] = {
        { Name = "Quest 18: Mobs", NPC = "QuestNPC18", Target = "Ninja", Tracker = "Ninja Slayer", Type = "Mob" }
    },
    ["Lawless"] = {
        { Name = "Quest 19: Mobs", NPC = "QuestNPC19", Target = "ArenaFighter", Tracker = "Arena Takedown", Type = "Mob" }
    }
}

-- 5. Sistema de GPS: NPC -> Ilha
GameData.NpcToIsland = {
    -- Quests Antigas
    ["QuestNPC1"] = "Starter", ["QuestNPC2"] = "Starter",
    ["QuestNPC3"] = "Jungle", ["QuestNPC4"] = "Jungle",
    ["QuestNPC5"] = "Desert", ["QuestNPC6"] = "Desert",
    ["QuestNPC7"] = "Snow", ["QuestNPC8"] = "Snow",
    ["QuestNPC9"] = "Shibuya Station", ["QuestNPC10"] = "Shibuya Station",
    ["QuestNPC11"] = "Hollow Island",
    ["QuestNPC12"] = "Shinjuku", ["QuestNPC13"] = "Shinjuku",
    ["QuestNPC14"] = "Slime",
    ["QuestNPC15"] = "Academy",
    ["QuestNPC16"] = "Judgement",
    ["QuestNPC17"] = "Soul Dominion",
    ["QuestNPC18"] = "Ninja",
    ["QuestNPC19"] = "Lawless",
    
    -- Starter
    ["GroupRewardNPC"] = "Starter", ["MadokaBuyer"] = "Starter", 
    ["ShadowQuestlineBuff"] = "Starter", ["ShadowMonarchQuestlineBuff"] = "Starter",
    -- Desert & Snow
    ["ObservationBuyer"] = "Desert", ["DarkBladeNPC"] = "Snow", ["RagnaBuyer"] = "Snow",
    ["RagnaQuestlineBuff"] = "Snow", ["HakiQuestNPC"] = "Snow",
    -- Sailor
    ["BossRushShopNPC"] = "Sailor", ["BossRushPortalNPC"] = "Sailor", ["BossRushMerchantNPC"] = "Sailor",
    ["AscendNPC"] = "Sailor", ["TraitNPC"] = "Sailor", ["RerollStatNPC"] = "Sailor", ["MerchantNPC"] = "Sailor",
    ["TitlesNPC"] = "Sailor", ["StorageNPC"] = "Sailor", ["GemFruitDealer"] = "Sailor", ["CoinFruitDealer"] = "Sailor",
    ["AlucardBuyer"] = "Sailor", ["JinwooMovesetNPC"] = "Sailor",
    -- Shibuya & Hollow
    ["YujiBuyerNPC"] = "Shibuya Station", ["GojoMovesetNPC"] = "Shibuya Station", ["SukunaMovesetNPC"] = "Shibuya Station",
    ["BlessingNPC"] = "Shibuya Station", ["EnchantNPC"] = "Shibuya Station", ["GryphonBuyerNPC"] = "Shibuya Station",
    ["IchigoBuyer"] = "Hollow Island", ["AizenQuestlineBuff"] = "Hollow Island", ["HogyokuQuestNPC"] = "Hollow Island", 
    ["AizenMovesetNPC"] = "Hollow Island",
    -- Boss Island
    ["ExchangeNPC"] = "Boss Island", ["MoonSlayerBuff"] = "Boss Island", ["GilgameshBuyerNPC"] = "Boss Island",
    ["SaberAlterBuyerNPC"] = "Boss Island", ["BlessedMaidenMasteryNPC"] = "Boss Island", ["BlessedMaidenBuyerNPC"] = "Boss Island",
    ["MoonSlayerSeller"] = "Boss Island", ["QinShiBuyer"] = "Boss Island", ["SaberAlterMasteryNPC"] = "Boss Island",
    ["BabylonCraftNPC"] = "Boss Island", ["GrailCraftNPC"] = "Boss Island", ["SummonBossNPC"] = "Boss Island",
    -- Dungeon & Shinjuku
    ["DungeonMerchantNPC"] = "Dungeon", ["DungeonPortalsNPC"] = "Dungeon", ["CidBuyer"] = "Dungeon", ["ShadowMonarchBuyerNPC"] = "Dungeon",
    ["StrongestofTodayBuyerNPC"] = "Shinjuku", ["StrongestinHistoryBuyerNPC"] = "Shinjuku", ["StrongestBossSummonerNPC"] = "Shinjuku",
    -- Slime, Academy & Judgement
    ["SkillTreeNPC"] = "Slime", ["SlimeCraftNPC"] = "Slime", ["RimuruSummonerNPC"] = "Slime", ["RimuruMasteryNPC"] = "Slime", ["RimuruBuyer"] = "Slime",
    ["AnosQuestNPC"] = "Academy", ["AnosBossSummonerNPC"] = "Academy", ["AnosBuyerNPC"] = "Academy",
    ["YamatoBuyerNPC"] = "Judgement", ["SpecPassivesNPC"] = "Judgement",
    -- Soul Dominion, Ninja, Lawless, Tower
    ["TrueAizenBuyerNPC"] = "Soul Dominion", ["TrueAizenFUnlockNPC"] = "Soul Dominion", ["TrueAizenBossSummonerNPC"] = "Soul Dominion",
    ["StrongestShinobiBuyerNPC"] = "Ninja",
    ["PowerNPC"] = "Lawless", ["AtomicBossSummonerNPC"] = "Lawless", ["AtomicQuestlineBuff"] = "Lawless", ["AtomicBuyer"] = "Lawless",
    ["InfiniteTowerStatShopNPC"] = "Tower", ["InfiniteTowerPortalNPC"] = "Tower", ["InfiniteTowerMerchantNPC"] = "Tower"
}

-- 6. Progressão do Piloto Automático
GameData.QuestProgression = {
    { Island = "Starter", Quest = "Quest 1: Mobs (Thief)", MinLevel = 1 }, 
    { Island = "Starter", Quest = "Quest 2: Boss (Thief Boss)", MinLevel = 100 },
    { Island = "Jungle", Quest = "Quest 3: Mobs (Monkey)", MinLevel = 250 }, 
    { Island = "Jungle", Quest = "Quest 4: Boss (Monkey Boss)", MinLevel = 500 },
    { Island = "Desert", Quest = "Quest 5: Mobs (Bandits)", MinLevel = 750 }, 
    { Island = "Desert", Quest = "Quest 6: Boss (Desert Boss)", MinLevel = 1000 },
    { Island = "Snow", Quest = "Quest 7: Mobs (Frost Rogue)", MinLevel = 1500 }, 
    { Island = "Snow", Quest = "Quest 8: Boss (Snow Boss)", MinLevel = 2000 },
    { Island = "Shibuya Station", Quest = "Quest 9: Mobs (Sorcerer)", MinLevel = 3000 }, 
    { Island = "Shibuya Station", Quest = "Quest 10: Mobs (Panda Sorcerer)", MinLevel = 4000 },
    { Island = "Hollow Island", Quest = "Quest 11: Mobs (Hollow)", MinLevel = 5000 }, 
    { Island = "Shinjuku", Quest = "Quest 12: Mobs", MinLevel = 6250 },
    { Island = "Shinjuku", Quest = "Quest 13: Mobs", MinLevel = 7000 }, 
    { Island = "Slime", Quest = "Quest 14: Mobs (Slime)", MinLevel = 8000 },
    { Island = "Academy", Quest = "Quest 15: Mobs (Teacher)", MinLevel = 10000 }, 
    { Island = "Judgement", Quest = "Quest 16: Mobs", MinLevel = 10750 },
    { Island = "Soul Dominion", Quest = "Quest 17: Mobs", MinLevel = 11500 },
    { Island = "Ninja", Quest = "Quest 18: Mobs", MinLevel = 12000 }, 
    { Island = "Lawless", Quest = "Quest 19: Mobs", MinLevel = 13000 }
}

GameData.TimedBosses = {
    ["Sailor"] = {"JinwooBoss", "AlucardBoss"},
    ["Shibuya Station"] = {"YujiBoss", "SukunaBoss", "GojoBoss"},
    ["Hollow Island"] = {"AizenBoss"},
    ["Judgement"] = {"YamatoBoss"}
}

-- 8. Cronômetro dos Chefes Silenciosos (Respawn em segundos)
GameData.SilentBosses = {
    ["ThiefBoss"] = 8,
    ["MonkeyBoss"] = 8,
    ["DesertBoss"] = 8,
    ["SnowBoss"] = 8,
    ["PandaMiniBoss"] = 8
}

-- ========================================================================
-- 🗣️ TRADUTOR DO SNIPER DE CHAT (Target -> Nome no Chat)
-- ========================================================================
GameData.BossChatNames = {
    ["JinwooBoss"] = "Solo Hunter",
    ["AlucardBoss"] = "Vampire King",
    ["YujiBoss"] = "Cursed Vessel",
    ["SukunaBoss"] = "Cursed King",
    ["GojoBoss"] = "Limitless Sorcerer",
    ["AizenBoss"] = "Manipulator",
    ["YamatoBoss"] = "Yamato"
}

-- ========================================================================
-- 🔮 BOSSES DE INVOCAÇÃO (AUTO SUMMON UNIVERSAL + DIFICULDADES)
-- ========================================================================
GameData.SummonBosses = {
    ["Boss Island"] = {
        SummonRemote = "RequestSummonBoss",
        AutoRemote = "RequestAutoSpawn",
        RequiresDifficulty = {"GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"},
        Difficulties = {"Normal", "Medium", "Hard", "Extreme"},
        SummonNPC = "SummonBossNPC",
        SpawnFolders = {},
        Bosses = {
            "SaberBoss", "QinShiBoss", "IchigoBoss", 
            "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"
        }
    },
    ["Shinjuku"] = {
        SummonRemote = "RequestSpawnStrongestBoss",
        AutoRemote = "RequestAutoSpawnStrongest",
        RequiresDifficulty = true, 
        Difficulties = {"Normal", "Medium", "Hard", "Extreme"},
        SummonNPC = "StrongestBossSummonerNPC",
        SummonPosition = Vector3.new(392, -3, -2178),
        SpawnFolders = {
            ["StrongestToday"] = "BossSpawn_StrongestToday",
            ["StrongestHistory"] = "BossSpawn_StrongestHistory"
        },
        Bosses = { "StrongestToday", "StrongestHistory" }
    },
    ["Slime"] = {
        SummonRemote = "RequestSummonBoss",
        AutoRemote = "RequestAutoSpawn",
        RequiresDifficulty = false,
        Difficulties = {"Normal", "Medium", "Hard", "Extreme"},
        SummonNPC = "RimuruSummonerNPC",
        SummonPosition = Vector3.new(-1236, 16, 279),
        SpawnFolders = {},
        Bosses = {"RimuruBoss"}
    },
    ["Academy"] = {
        SummonRemote = "RequestSpawnAnosBoss",
        AutoRemote = "RequestAutoSpawnAnos",
        RequiresDifficulty = true,
        Difficulties = {"Normal", "Medium", "Hard", "Extreme"},
        SummonNPC = "AnosBossSummonerNPC",
        SummonPosition = Vector3.new(901, 1, 1293),
        SpawnFolders = {},
        Bosses = {"Anos"}
    },
    ["Soul Dominion"] = {
        SummonRemote = "RequestSpawnTrueAizen",
        AutoRemote = "RequestAutoSpawnTrueAizen",
        RemoteFolder = "RemoteEvents",
        RequiresDifficulty = true,
        DifficultyOnly = true,
        Difficulties = {"Normal", "Medium", "Hard", "Extreme"},
        SummonNPC = "TrueAizenBossSummonerNPC",
        SummonPosition = Vector3.new(-1284, 1603, 1751),
        SpawnFolders = {},
        Bosses = {"TrueAizenBoss"} 
    },
    ["Lawless"] = {
        SummonRemote = "RequestSummonBoss",
        AutoRemote = "RequestAutoSpawn",
        RequiresDifficulty = false,
        Difficulties = {"Normal", "Medium", "Hard", "Extreme"},
        SummonNPC = "AtomicBossSummonerNPC",
        SummonPosition = Vector3.new(127, 2, 1879),
        SpawnFolders = {},
        Bosses = {"AtomicBoss"} 
    }
}

-- ========================================================================
-- 🧩 COLETÁVEIS E ITENS DO MAPA (MOTOR DE ROTAS ESCALÁVEL)
-- ========================================================================
GameData.Collectibles = {
    ["Peça de Slime (Puzzle)"] = {
        TargetName = "SlimePuzzlePiece",
        IslandOrder = {
            "Desert",
            "Snow",
            "Starter",
            "Jungle",
            "Shibuya Station",
            "Hollow Island",
            "Shinjuku"
        },
        Positions = {
            ["Starter"] = Vector3.new(61, 32, -145),
            ["Desert"] = Vector3.new(-584, 54, 317),
            ["Starter"] = Vector3.new(61, 32, -145),
            ["Snow"] = Vector3.new(61, 32, -145),
            ["Shibuya Station"] = Vector3.new(1744, 6, 494),
            ["Hollow Island"] = Vector3.new(-436, 23, 1399),
            ["Shinjuku"] = Vector3.new(787, 64, -2310)
        }
    },
        ["Peça da Dungle (Puzzle)"] = {
        TargetName = "DungeonPuzzlePiece",
        IslandOrder = {
            "Starter",
            "Jungle",
            "Desert",
            "Snow",
            "Shibuya Station",
            "Hollow Island"
        },
        Positions = {}
    }
}

GameData.Settings = {
    SlideSpeed = 150,
    ActionDelay = 1.0
}

return GameData
