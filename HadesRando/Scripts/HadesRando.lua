--[[
Copyright 2021 Dannyj1

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ModUtil.RegisterMod("HadesRando")

local config = {
    seed = nil,
    randomizeEnemies = true,
    randomizeBoons = true,
    randomizeKeepsakes = true,
    randomizeCompanions = true,
    randomizeWeapons = true,
    randomizeRooms = true,
    randomRoomAmount = false,
    fixedRoomAmount = 40
}

local keepsakes = {
    "MaxHealthKeepsakeTrait", -- cerberus
    "DirectionalArmorTrait", -- achilles
    "BackstabAlphaStrikeTrait", -- nyx
    "PerfectClearDamageBonusTrait", -- thanatos
    "ShopDurationTrait", -- charon
    "BonusMoneyTrait", -- hypnos
    "LowHealthDamageTrait", -- megaera
    "DistanceDamageTrait", -- orpheus
    "LifeOnUrnTrait", -- dusa
    "ReincarnationTrait", -- skelly
    "ForceZeusBoonTrait", -- zeus
    "ForcePoseidonBoonTrait", -- poseidon
    "ForceAthenaBoonTrait", -- athena
    "ForceAphroditeBoonTrait", -- aphrodite
    "ForceAresBoonTrait", -- ares
    "ForceArtemisBoonTrait", -- artemis
    "ForceDionysusBoonTrait", -- dionysus
    "FastClearDodgeBonusTrait", -- hermes
    "ForceDemeterBoonTrait", -- demeter
    "ChaosBoonTrait", -- primordial chaos
    "VanillaTrait", -- sisyphus
    "ShieldBossTrait", -- eurydice
    "ShieldAfterHitTrait", -- patroclus
    "ChamberStackTrait", -- persephone
    "HadesShoutKeepsake" -- hades
}

local companions = {
    "FuryAssistTrait",
    "ThanatosAssistTrait",
    "SisyphusAssistTrait",
    "SkellyAssistTrait",
    "DusaAssistTrait",
    "AchillesPatroclusAssistTrait"
}

local enemies = {}
local minibosses = {}
local rooms = {}
local randomRooms
local roomSets = { RoomSetData.Tartarus, RoomSetData.Asphodel, RoomSetData.Elysium, RoomSetData.Secrets }
local roomCounter = 1
HadesRando.config = config
local seedText = "Seed: "

ModUtil.LoadOnce( function()
    for biome, enemySet in pairs(EnemySets) do
        if not isBiomeBlacklisted(biome) then
            for i, enemy in ipairs(enemySet) do
                if string.match(string.lower(biome), "miniboss") then
                    table.insert(minibosses, enemy)
                else
                    table.insert(enemies, enemy)
                end
            end
        end
    end

    assert(#enemies > 10)
    assert(#minibosses > 5)

    for _, roomSet in ipairs(roomSets) do
        for k, _ in pairs(roomSet) do
            if not isRoomBlacklisted(k) then
                table.insert(rooms, k)
            end
        end
    end

    assert(#rooms > 15)
end)

function isRoomBlacklisted(roomName)
    local patterns = { "intro", "base", "generated", "boss", "reprieve", "roomopening", "simpleroom"}
    roomName = string.lower(roomName)

    if roomName == "RoomSimple01" and roomName == "RoomOpening" then
        return true
    end

    if string.match(roomName, "miniboss") then
        return false
    end

    for i, v in ipairs(patterns) do
        if string.match(roomName, string.lower(v)) then
            return true
        end
    end

    return false
end

function isBiomeBlacklisted(biome)
    local patterns = { "trap", "hydra", "attribute", "boss" }
    biome = string.lower(biome)

    if string.match(biome, "miniboss") then
        return false
    end

    for i, v in ipairs(patterns) do
        if string.match(biome, string.lower(v)) then
            return true
        end
    end

    return false
end

--[[local doDebugStuff = true
local oAttemptUseDoor = AttemptUseDoor
function AttemptUseDoor( door )
    if doDebugStuff == true then
        ForceNextRoom = "B_Boss01"

        -- Stomp any rooms already assigned to doors
        for doorId, door in pairs( OfferedExitDoors ) do
            local room = door.Room
            if room ~= nil then
                local forcedRoomData = RoomData[ForceNextRoom]
                local forcedRoom = CreateRoom( forcedRoomData )
                AssignRoomToExitDoor( door, forcedRoom )
            end
        end

        doDebugStuff = false
    end

    oAttemptUseDoor(door)
end]]

local oLeaveRoom = LeaveRoom
function LeaveRoom(currentRun, door)
    oLeaveRoom(currentRun, door)

    if string.match(door.Room.Name, "PostBoss") then
        if config.randomizeKeepsakes then
            local keepsake = keepsakes[math.random(#keepsakes)]
            assert(keepsake)

            UnequipKeepsake(CurrentRun.Hero, GameState.LastAwardTrait)
            GameState.LastAwardTrait = keepsake
            EquipKeepsake(CurrentRun.Hero, GameState.LastAwardTrait)
        end

        if config.randomizeCompanions then
            local companion = companions[math.random(#companions)]
            assert(companion)

            UnequipAssist(CurrentRun.Hero, GameState.LastAssistTrait)
            GameState.LastAssistTrait = companion
            EquipAssist(CurrentRun.Hero, GameState.LastAssistTrait)
        end

        if config.randomizeCompanions and config.randomizeKeepsakes then
            door.Room.BlockKeepsakeMenu = true
        end
    end
end

local roomDataCopy = DeepCopyTable(RoomData)
local encounterDataCopy = DeepCopyTable(EncounterData)
local lootData = DeepCopyTable(LootData)
OnAnyLoad{ "DeathArea",
        function(triggerArgs)
            RoomData = DeepCopyTable(roomDataCopy)
            EncounterData = DeepCopyTable(encounterDataCopy)
            LootData = DeepCopyTable(lootData)
            config.seed = nil
        end
}

local oStartOver = StartOver
function StartOver()
    EncounterData.MiniBossSpreadShot.SpawnWaves[1].Spawns[1].TotalCount = 2
    EncounterData.MiniBossSpreadShot.SpawnWaves[1].Spawns[1].SpawnOnIds = { 548132, 547901 }

    if config.seed == nil then
        seedText = "Seed: "
    else
        seedText = "Set Seed: "
    end

    if config.randomizeBoons then
        setSeed()
        randomizeLootTables()
    end

    if config.randomizeEnemies then
        setSeed()
        randomizeEnemies()
    end

    if config.randomizeRooms then
        setSeed()
        randomizeRooms()
    end

    ModUtil.Print(seedText .. config.seed)

    setSeed()
    if config.randomizeKeepsakes then
        local keepsake = keepsakes[math.random(#keepsakes)]
        assert(keepsake)
        ModUtil.Print("Keepsake: " .. keepsake)
        GameState.LastAwardTrait = keepsake
    end

    if config.randomizeCompanions then
        local companion = companions[math.random(#companions)]
        assert(companion)
        ModUtil.Print("Companion: " .. companion)
        GameState.LastAssistTrait = companion
    end
    
    if config.randomizeWeapons then
        local weaponName = WeaponSets.HeroMeleeWeapons[math.random(#WeaponSets.HeroMeleeWeapons)]
        assert(weaponName)
        local weaponData = WeaponData[weaponName]
        assert(weaponData)

        GameState.LastWeaponUpgradeData[weaponName] = { Index = math.random(#WeaponUpgradeData[weaponName]) }
        EquipPlayerWeapon(weaponData)
        EquipWeaponUpgrade(CurrentRun.Hero)
        ModUtil.Print("Weapon: " .. weaponName)
        ModUtil.Print("Weapon Aspect Index: " .. GameState.LastWeaponUpgradeData[weaponName].Index)
    end

    -- MetaUpgradeData.lua - mirror stuff
    -- Implement random sounds and text lines
    -- Look into some waves immediately ending
    oStartOver()

    WeaponData.HadesInvisibility.AIData.PreAttackSound = "/VO/Skelly_0509"
end

local oDoUnlockRoomExits = DoUnlockRoomExits
function DoUnlockRoomExits( run, room )
    if config.randomizeRooms and randomRooms ~= nil and #randomRooms > 0 then
        local currentRoomName = CurrentRun.CurrentRoom.Name

        if not (string.match(currentRoomName, "Boss") and not (string.match(currentRoomName, "MiniBoss")
                or string.match(currentRoomName, "Miniboss") or currentRoomName == "C_Boss01"))
                and not string.match(currentRoomName, "Reprieve") and not string.startsWith(currentRoomName, "D_")
                and not string.startsWith(currentRoomName, "E_") then
            local nextRoom = randomRooms[roomCounter]
            roomCounter = roomCounter + 1
            assert(nextRoom)

            if nextRoom == "CharonFight01" then
                teleportToCharonFight()
            else
                for doorId, door in pairs(OfferedExitDoors) do
                    if door.Name ~= "SecretDoor" then
                        local forcedRoomData = RoomData[nextRoom]
                        assert(forcedRoomData)
                        local forcedRoom

                        if not string.match(nextRoom, "Story") then
                            forcedRoom = CreateRoom(forcedRoomData)
                        else
                            forcedRoom = CreateRoom(forcedRoomData, { SkipChooseEncounter = true })
                        end

                        assert(forcedRoom)

                        AssignRoomToExitDoor(door, forcedRoom)
                    end
                end
            end
        end
    end

    oDoUnlockRoomExits(run, room)
end

function erebusTeleport()

end

function teleportToCharonFight()
    local args = {}
    AddTimerBlock(CurrentRun, "StealPresentation")
    AddInputBlock({ Name = "LeaveRoomPresentation" })
    ToggleControl({ Names = { "AdvancedTooltip", }, Enabled = false })

    HideCombatUI()
    StopSecretMusic()
    EndAmbience( 0.1 )
    StopAmbientSound({ All = true })

    wait(0.2)
    PlaySound({ Name = "/SFX/Menu Sounds/RecordScratch" })
    LockCamera({ Ids = { CurrentRun.Hero.ObjectId }, Duration = 0.22 })
    FocusCamera({ Fraction = 0.975, Duration = 0.3, ZoomType = "Overshoot" })
    wait(1.5)

    local soundId = PlaySound({ Name = "/Leftovers/Object Ambiences/ThunderLoop" })

    thread(PlayVoiceLine, { Cue = "/VO/Charon_0041" })
    ShakeScreen({ Speed = 500, Distance = 4, FalloffSpeed = 3000, Duration = 5.0 })
    StopSound({ Id = soundId, Duration = 5 })
    soundId = nil

    AdjustFullscreenBloom({ Name = "LightningStrike", Duration = 0.1 })
    AdjustRadialBlurStrength({ Fraction = 1.5, Duration = 0.1 })
    AdjustRadialBlurDistance({ Fraction = 0.125, Duration = 0.1 })
    LockCamera({ Ids = { CurrentRun.Hero.ObjectId }, Duration = 7 })
    wait(2.0)
    AdjustRadialBlurStrength({ Fraction = 0, Duration = 0.03 })
    AdjustRadialBlurDistance({ Fraction = 0, Duration = 0.03 })

    SetAnimation({ Name = "ZagreusSecretDoorDive", DestinationId = CurrentRun.Hero.ObjectId })
    PlaySound({ Name = "/Leftovers/Menu Sounds/AscensionConfirm" })
    thread( DoRumble, { { ScreenPreWait = 0.02, Fraction = 0.15, Duration = 0.7 }, } )
    Flash({ Id = CurrentRun.Hero.ObjectId, Speed = 0.5, MinFraction = 0, MaxFraction = 1.0, Color = Color.White, Duration = 1.0, ExpireAfterCycle = false })
    AdjustColorGrading({ Name = "Chaos", Duration = 0.7 })
    wait(0.7)

    CreateAnimation({ Name = "ZagreusSecretDoorDiveFadeFx", DestinationId = CurrentRun.Hero.ObjectId })
    SetAlpha({ Id = CurrentRun.Hero.ObjectId, Fraction = 0, Duration = 0.13 })

    wait(0.4)
    FullScreenFadeOutAnimation()
    wait(0.2)

    RemoveInputBlock({ Name = "LeaveRoomPresentation" })
    ToggleControl({ Names = { "AdvancedTooltip", }, Enabled = true })

    RemoveTimerBlock(CurrentRun, "StealPresentation")
    args.NextMap = "CharonFight01"
    CurrentRun.CurrentRoom.ExitFunctionName = "ExitToCharonFightPresentation"
    LeaveRoomWithNoDoor( nil, args )
end

function randomizeRooms()
    randomRooms = {}
    local roomAmount = config.fixedRoomAmount

    if config.randomRoomAmount then
        roomAmount = math.random(30, 60)
    end

    local roomsCopy = DeepCopyTable(rooms)
    local npcRooms = { "A_Story01", "B_Story01", "C_Story01" }
    local shopRooms = { "A_Shop01", "B_Shop01", "C_Shop01" }
    local erebusRooms = { "RoomChallenge01", "RoomChallenge02", "RoomChallenge03", "RoomChallenge04" }
    local furiesIndex = math.random(7, math.ceil(roomAmount * 0.4))
    local lernieIndex = math.random(furiesIndex + 1, math.ceil(roomAmount * 0.7))
    local championsIndex = math.random(lernieIndex + 1, roomAmount - 1)
    local styxIndex = roomAmount
    local erebusChance = math.random(100)
    local charonFightChance = math.random(100)

    prepareRoomsets()
    insertRandomRoom(furiesIndex, "A_PreBoss01")
    insertRandomRoom(lernieIndex, "B_PreBoss01")
    insertRandomRoom(championsIndex, "C_PreBoss01")
    insertRandomRoom(styxIndex, "C_PostBoss01")
    insertRandomRoomAtFreeIndex(npcRooms[math.random(#npcRooms)], roomAmount)
    insertRandomRoomAtFreeIndex(shopRooms[math.random(#shopRooms)], roomAmount)
    insertRandomRoomAtFreeIndex(shopRooms[math.random(#shopRooms)], roomAmount)

    if erebusChance <= 20 then
        insertRandomRoomAtFreeIndex(erebusRooms[math.random(#erebusRooms)], roomAmount)
    end

    if charonFightChance <= 3 then
        insertRandomRoomAtFreeIndex("CharonFight01", roomAmount, math.ceil(roomAmount * 0.5))
    end

    for i = 1, roomAmount do
        if not randomRoomExistsAtIndex(i) then
            if #roomsCopy == 0 then
                roomsCopy = DeepCopyTable(rooms)
                assert(#roomsCopy == 0)
            end

            local randomIndex = math.random(#roomsCopy)
            local randomRoom = roomsCopy[randomIndex]
            local attempts = 0

            while i <= 5 and string.startsWith(randomRoom, "C_Combat") or string.startsWith(randomRoom, "C_MiniBoss") do
                if attempts == 10 then
                    roomsCopy = DeepCopyTable(rooms)
                end

                randomIndex = math.random(#roomsCopy)
                randomRoom = roomsCopy[randomIndex]
                attempts = attempts + 1
            end

            insertRandomRoom(i, randomRoom)
            table.remove(roomsCopy, randomIndex)
        end
    end
end

function prepareRoomsets()
    for _, set in pairs(roomSets) do
        for roomName, room in pairs(set) do
            if room.ForceAtBiomeDepthMin ~= nil then
                room.ForceAtBiomeDepthMin = nil
            end

            if room.ForceAtBiomeDepthMax ~= nil then
                room.ForceAtBiomeDepthMax = nil
            end

            if room.MaxCreationsThisRun ~= nil then
                room.MaxCreationsThisRun = nil
            end

            if room.GameStateRequirements ~= nil and room.RequiredMaxBiomeDepth ~= nil then
                room.GameStateRequirements.RequiredMaxBiomeDepth = nil
            end
        end
    end
end

function insertRandomRoom(index, roomName, allowOverwrite)
    if allowOverwrite == nil then
        allowOverwrite = false
    end

    if not allowOverwrite then
        assert(not randomRoomExistsAtIndex(index))
    end

    assert(roomName)
    assert(index >= 1)
    randomRooms[index] = roomName
    ModUtil.Print("Rooms: " .. index .. " >> " .. roomName)
end

function insertRandomRoomAtFreeIndex(roomName, roomAmount, minimumIndex)
    if minimumIndex == nil then
        minimumIndex = 1
    end

    local index = math.random(minimumIndex, roomAmount)

    while randomRoomExistsAtIndex(index) do
        index = math.random(minimumIndex, roomAmount)
    end

    insertRandomRoom(index, roomName, false)
end

function randomRoomExistsAtIndex(index)
    return randomRooms[index] ~= nil and randomRooms[index] ~= ""
end

function randomizeLootTables()
    local weaponUpgrades = {}
    local weaponUpgradeCounts = {}
    local traits = {}
    local traitCounts = {}
    local consumables = {}
    local consumableCounts = {}
    local linkedUpgrades = {}
    local linkedUpgradeCounts = {}

    for roomName, roomData in pairs(RoomData) do
        if roomData.ForcedRewards ~= nil then
            roomData.ForcedRewards = {}
        end
    end

    for k, _ in pairs(LootData) do
        if k ~= "TrialUpgrade" then
            traitCounts[k] = 0
            weaponUpgradeCounts[k] = 0
            consumableCounts[k] = 0
            linkedUpgradeCounts[k] = 0

            if LootData[k].WeaponUpgrades ~= nil then
                for i, v2 in ipairs(LootData[k].WeaponUpgrades) do
                    weaponUpgradeCounts[k] = weaponUpgradeCounts[k] + 1
                    table.insert(weaponUpgrades, v2)
                end
            end

            if LootData[k].Traits ~= nil then
                for i, v2 in ipairs(LootData[k].Traits) do
                    traitCounts[k] = traitCounts[k] + 1
                    table.insert(traits, v2)
                end
            end

            if LootData[k].Consumables ~= nil then
                for i, v2 in ipairs(LootData[k].Consumables) do
                    consumableCounts[k] = consumableCounts[k] + 1
                    table.insert(consumables, v2)
                end
            end

            if LootData[k].LinkedUpgrades ~= nil then
                for i, v2 in ipairs(LootData[k].LinkedUpgrades) do
                    linkedUpgradeCounts[k] = linkedUpgradeCounts[k] + 1
                    table.insert(linkedUpgrades, v2)
                end
            end

            LootData[k].PriorityUpgrades = {}
            LootData[k].WeaponUpgrades = {}
            LootData[k].Traits = {}
            LootData[k].Consumables = {}
            LootData[k].LinkedUpgrades = {}

            traitCounts[k] = traitCounts[k] + math.ceil(traitCounts[k] * 0.5)
            weaponUpgradeCounts[k] = weaponUpgradeCounts[k] + math.ceil(weaponUpgradeCounts[k] * 0.5)
            consumableCounts[k] = consumableCounts[k] + math.ceil(consumableCounts[k] * 0.5)
            linkedUpgradeCounts[k] = linkedUpgradeCounts[k] + math.ceil(linkedUpgradeCounts[k] * 0.5)
        end
    end

    local weaponUpgradesCopy = DeepCopyTable(weaponUpgrades)
    for k, v in pairs(weaponUpgradeCounts) do
        if v > 0 then
            for _ = 1, v do
                if #weaponUpgradesCopy == 0 then
                    weaponUpgradesCopy = DeepCopyTable(weaponUpgrades)
                end

                local randomIndex = math.random(#weaponUpgradesCopy)
                local randomTrait = weaponUpgradesCopy[randomIndex]

                table.remove(weaponUpgradesCopy, randomIndex)
                assert(randomTrait)
                table.insert(LootData[k].WeaponUpgrades, randomTrait)
                ModUtil.Print("WeaponUpgrades: " .. k .. " >> " .. randomTrait)
            end
        end
    end

    local traitsCopy = DeepCopyTable(traits)
    for k, v in pairs(traitCounts) do
        if v > 0 then
            for _ = 1, v do
                if #traitsCopy == 0 then
                    traitsCopy = DeepCopyTable(traits)
                end

                local randomIndex = math.random(#traitsCopy)
                local randomTrait = traitsCopy[randomIndex]

                table.remove(traitsCopy, randomIndex)
                assert(randomTrait)
                table.insert(LootData[k].Traits, randomTrait)
                ModUtil.Print("Traits: " .. k .. " >> " .. randomTrait)
            end
        end
    end

    local consumablesCopy = DeepCopyTable(consumables)
    for k, v in pairs(consumableCounts) do
        if v > 0 then
            for _ = 1, v do
                if #consumablesCopy == 0 then
                    consumablesCopy = DeepCopyTable(consumables)
                end

                local randomIndex = math.random(#consumablesCopy)
                local randomTrait = consumablesCopy[randomIndex]

                table.remove(consumablesCopy, randomIndex)
                assert(randomTrait)
                table.insert(LootData[k].Consumables, randomTrait)
                ModUtil.Print("Consumables: " .. k .. " >> " .. randomTrait)
            end
        end
    end

    local linkedUpgradesCopy = DeepCopyTable(linkedUpgrades)
    for k, v in pairs(linkedUpgrades) do
        if v > 0 then
            for _ = 1, v do
                if #linkedUpgradesCopy == 0 then
                    linkedUpgradesCopy = DeepCopyTable(linkedUpgrades)
                end

                local randomIndex = math.random(#linkedUpgradesCopy)
                local randomTrait = linkedUpgradesCopy[randomIndex]

                table.remove(linkedUpgradesCopy, randomIndex)
                assert(randomTrait)
                table.insert(LootData[k].LinkedUpgrades, randomTrait)
                ModUtil.Print("LinkedUpgrades: " .. k .. " >> " .. randomTrait)
            end
        end
    end
end

function randomizeEnemies()
    local enemiesCopy = DeepCopyTable(enemies)

    for biome, v in pairs(EncounterData) do
        if EncounterData[biome].EnemySet ~= nil or EncounterData[biome].ManualWaveTemplates ~= nil or EncounterData[biome].WaveTemplate ~= nil or EncounterData[biome].SpawnWaves ~= nil then
            if not isBiomeBlacklisted(biome) and not string.match(biome, "Story") and not string.match(biome, "Shop") then
                EncounterData[biome].MaxAppearancesThisRun = nil
                EncounterData[biome].MaxAppearancesThisBiome = nil
                EncounterData[biome].MinRoomsBetweenType = nil
                EncounterData[biome].MinRunsSinceThanatosSpawn = nil

                local length = math.random(5, 15)
                local enemySet = {}

                if string.match(biome, "MiniBoss") or string.match(biome, "Miniboss") then
                    length = 1
                end

                for _ = 1, length do
                    if #enemies == 0 then
                        enemiesCopy = DeepCopyTable(enemies)
                    end

                    local randomEnemy

                    if string.match(biome, "MiniBoss") or string.match(biome, "Miniboss") then
                        local randomIndex = math.random(#minibosses)
                        randomEnemy = minibosses[randomIndex]

                        while (randomEnemy == "CrawlerMiniBoss" or string.match(randomEnemy, "Rat")) and not string.startsWith(biome, "D_") do
                            randomIndex = math.random(#minibosses)
                            randomEnemy = minibosses[randomIndex]
                        end

                        assert(randomEnemy)
                    elseif not (string.match(biome, "Opening") or string.match(biome, "Tartarus") or string.match(biome, "Asphodel") or biome == "Generated" or string.match(biome, "Intro")) then
                        local randomIndex = math.random(#enemiesCopy)
                        randomEnemy = enemiesCopy[randomIndex]

                        assert(randomEnemy)
                        table.remove(enemiesCopy, randomIndex)
                    else
                        local randomIndex = math.random(#enemiesCopy)
                        randomEnemy = enemiesCopy[randomIndex]

                        local excludeType = "SuperElite"

                        if biome == "RoomOpening" or biome == "RoomSimple01" or string.match(biome, "Intro") then
                            excludeType = "Elite"
                        end

                        local attempts = 0
                        while string.match(randomEnemy, excludeType) or string.match(randomEnemy, "Rat") or string.match(randomEnemy, "Satyr") do
                            if attempts == 10 then
                                enemiesCopy = DeepCopyTable(enemies)
                            end

                            randomIndex = math.random(#enemiesCopy)
                            randomEnemy = enemiesCopy[randomIndex]
                            attempts = attempts + 1
                        end

                        assert(randomEnemy)
                        table.remove(enemiesCopy, randomIndex)
                    end

                    ModUtil.Print("EnemySet: " .. biome .. " >> " .. randomEnemy)
                    table.insert(enemySet, randomEnemy)
                end

                if EncounterData[biome].EnemySet ~= nil and #(EncounterData[biome].EnemySet) > 0 then
                    EncounterData[biome].EnemySet = enemySet
                    assert(EncounterData[biome].EnemySet)
                end

                if EncounterData[biome].ManualWaveTemplates ~= nil and #(EncounterData[biome].ManualWaveTemplates) > 0 then
                    for _, wave in pairs(EncounterData[biome].ManualWaveTemplates) do
                        if wave.Spawns ~= nil and #(wave.Spawns) > 0 then
                            for i, spawn in ipairs(wave.Spawns) do
                                spawn.Name = enemySet[(i % #enemySet) + 1]
                                assert(spawn.Name)
                            end
                        end
                    end
                end

                if EncounterData[biome].SpawnWaves ~= nil and #(EncounterData[biome].SpawnWaves) > 0 then
                    for _, wave in pairs(EncounterData[biome].SpawnWaves) do
                        if wave.Spawns ~= nil and #(wave.Spawns) > 0 then
                            for i, spawn in ipairs(wave.Spawns) do
                                spawn.Name = enemySet[(i % #enemySet) + 1]
                                assert(spawn.Name)
                            end
                        end
                    end
                end

                if EncounterData[biome].WaveTemplate ~= nil then
                    if EncounterData[biome].WaveTemplate.Spawns ~= nil and #(EncounterData[biome].WaveTemplate.Spawns) > 0 then
                        for i, spawn in ipairs(EncounterData[biome].WaveTemplate.Spawns) do
                            spawn.Name = enemySet[(i % #enemySet) + 1]
                            assert(spawn.Name)
                        end
                    end
                end
            end
        end
    end
end

function getRandomRarity()
    local rarities = { "Common", "Rare", "Epic", "Legendary", "Heroic" }

    return rarities[math.random(rarities)]
end

function setSeed()
    if config.seed == nil then
        math.randomseed(math.floor(GetTime({}) * 1000000))
        config.seed = math.random(1, 9999999)
    end

    math.randomseed(config.seed)
end

function tableContains(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

function mergeTables(table1, table2)
    local finalTable = {}

    for _, v in ipairs(table1) do
        table.insert(finalTable, v)
    end

    for _, v in ipairs(table2) do
        table.insert(finalTable, v)
    end

    return finalTable
end

function string.startsWith(String,Start)
    return String ~= nil and Start ~= nil and string.sub(String,1,string.len(Start))==Start
end

OnAnyLoad {
    function()
        createSeedText()
    end
}

function createSeedText()
    local runDepthCopy = DeepCopyTable(UIData.CurrentRunDepth.TextFormat)
    runDepthCopy.Color = Color.White
    local text = seedText .. (config.seed or "None")

    if ScreenAnchors["HadesRandoSeed"] ~= nil then
        ModifyTextBox({ Id = ScreenAnchors["HadesRandoSeed"], Text = text, Color = runDepthCopy.Color })
    else
        ScreenAnchors["HadesRandoSeed"] = CreateScreenObstacle({ Name = "BlankObstacle", X = 1905, Y = 124, Group = "Combat_Menu_Overlay" })
        CreateTextBox(MergeTables(runDepthCopy, { Id = ScreenAnchors["HadesRandoSeed"], Text = text }))
        ModifyTextBox({ Id = ScreenAnchors["HadesRandoSeed"] })
    end
end
