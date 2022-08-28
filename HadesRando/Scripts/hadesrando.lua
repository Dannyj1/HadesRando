--[[
Copyright 2021 Dannyj1

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local randomRooms
local roomCounter = 1
local seedText = "Seed: "
local rngId = 2

function isRoomBlacklisted(roomName)
    local patterns = { "intro", "base", "generated", "boss", "reprieve", "roomopening", "simpleroom", "a_combat25"}
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

local oLeaveRoom = LeaveRoom
function LeaveRoom(currentRun, door)
    oLeaveRoom(currentRun, door)

    if string.match(door.Room.Name, "PostBoss") then
        if HadesRando.config.randomizeKeepsakes then
            assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
            local keepsake = keepsakes[GetRngById(rngId):Random(#keepsakes)]
            assert(keepsake)

            UnequipKeepsake(CurrentRun.Hero, GameState.LastAwardTrait)
            GameState.LastAwardTrait = keepsake
            EquipKeepsake(CurrentRun.Hero, GameState.LastAwardTrait)
        end

        if HadesRando.config.randomizeCompanions then
            assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
            local companion = companions[GetRngById(rngId):Random(#companions)]
            assert(companion)

            UnequipAssist(CurrentRun.Hero, GameState.LastAssistTrait)
            GameState.LastAssistTrait = companion
            EquipAssist(CurrentRun.Hero, GameState.LastAssistTrait)
        end

        if HadesRando.config.randomizeCompanions and HadesRando.config.randomizeKeepsakes then
            door.Room.BlockKeepsakeMenu = true
        end
    end
end


OnAnyLoad{ "DeathArea DeathAreaBedroom DeathAreaBedroomHades DeathAreaOffice RoomPreRun",
        function(triggerArgs)
            RoomData = DeepCopyTable(HadesRando.data.roomDataCopy)
            EncounterData = DeepCopyTable(HadesRando.data.encounterDataCopy)
            LootData = DeepCopyTable(HadesRando.data.lootDataCopy)
            EnemyData = DeepCopyTable(HadesRando.data.enemyDataCopy)
            HadesRando.config.seed = nil
        end
}

local oStartOver = StartOver
function StartOver()
    roomCounter = 1
    EncounterData.MiniBossSpreadShot.SpawnWaves[1].Spawns[1].TotalCount = 2
    EncounterData.MiniBossSpreadShot.SpawnWaves[1].Spawns[1].SpawnOnIds = { 548132, 547901 }

    if HadesRando.config.seed == nil then
        seedText = "Seed: "
    else
        seedText = "Set Seed: "
    end

    setSeed()

    if HadesRando.config.randomizeBoons then
        randomizeLootTables()
    end

    if HadesRando.config.randomizeEnemies then
        randomizeEnemies()
    end

    if HadesRando.config.randomizeRooms then
        randomizeRooms()
    end

    -- ModUtil.Print(seedText .. HadesRando.config.seed)

    if HadesRando.config.randomizeKeepsakes then
        assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
        local keepsake = keepsakes[GetRngById(rngId):Random(#keepsakes)]
        assert(keepsake)
        -- ModUtil.Print("Keepsake: " .. keepsake)
        GameState.LastAwardTrait = keepsake
    end

    if HadesRando.config.randomizeCompanions then
        assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
        local companion = companions[GetRngById(rngId):Random(#companions)]
        assert(companion)
        -- ModUtil.Print("Companion: " .. companion)
        GameState.LastAssistTrait = companion
    end

    if HadesRando.config.randomizeWeapons then
        assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
        local weaponName = WeaponSets.HeroMeleeWeapons[GetRngById(rngId):Random(#WeaponSets.HeroMeleeWeapons)]
        assert(weaponName)
        local weaponData = WeaponData[weaponName]
        assert(weaponData)

        GameState.LastWeaponUpgradeData[weaponName] = { Index = GetRngById(rngId):Random(#WeaponUpgradeData[weaponName]) }
        EquipPlayerWeapon(weaponData)
        EquipWeaponUpgrade(CurrentRun.Hero)
        -- ModUtil.Print("Weapon: " .. weaponName)
        -- ModUtil.Print("Weapon Aspect Index: " .. GameState.LastWeaponUpgradeData[weaponName].Index)
    end

    if HadesRando.config.scaleStats and (HadesRando.config.randomizeRooms or HadesRando.config.randomizeEnemies) then
        scaleHealth()
    end

    --[[ TODO:
     MetaUpgradeData.lua - mirror stuff
     Implement random sounds and text lines
     Look into some waves immediately ending
     Check if stats of keepsakes etc can be randomized
     ]]
    oStartOver()

    WeaponData.HadesInvisibility.AIData.PreAttackSound = "/VO/Skelly_0509"
end

function scaleDifficultyRating(room)
    local minDifficultyRating = 15

    if room.startsWith("A_") then
        minDifficultyRating = 0
    elseif room.startsWith("B_") then
        minDifficultyRating = 5
    elseif room.startsWith("C_") then
        minDifficultyRating = 15
    elseif room.startsWith("D_") or string.find(room, "Secret") then
        minDifficultyRating = 20
    end

    if #HadesRando.data.originalEnemyDifficulty == 0 then
        for enemyName, enemy in ipairs(EnemyData) do
            if not tableContains(enemy, "GeneratorData") then
                HadesRando.data.originalEnemyDifficulty[enemyName] = nil
            else
                HadesRando.data.originalEnemyDifficulty[enemyName] = enemy["GeneratorData"]["DifficultyRating"]
            end
        end
    end

    for enemyName, enemy in pairs(EnemyData) do
        local baseEnemyName = enemyName

        if enemy["InheritFrom"] ~= nil and #enemy["InheritFrom"] > 0
                and not (tableContains(EnemyData[enemyName], "GeneratorData") or tableContains(EnemyData[enemyName]["GeneratorData"], "DifficultyRating")) then
            for _, inheritName in pairs(enemy["InheritFrom"]) do
                if tableContains(EnemyData[inheritName], "GeneratorData") and tableContains(EnemyData[inheritName]["GeneratorData"], "DifficultyRating") then
                    baseEnemyName = inheritName
                end
            end
        end

        local originalDifficulty = HadesRando.data.originalEnemyDifficulty[enemyName]
        local generatorData = EnemyData[baseEnemyName]["GeneratorData"]

        if generatorData ~= nil and originalDifficulty ~= nil then
            local difficultyRating = generatorData["DifficultyRating"]

            if difficultyRating ~= nil then
                EnemyData["GeneratorData"]["DifficultyRating"] = math.max(originalDifficulty, minDifficultyRating)
            end
        end
    end
end

local minibossNames = {"WretchAssassinMiniboss", "ThiefImpulseMineLayerMiniboss", "SpreadShotUnitMiniboss", "HeavyRangedForkedMiniboss", "HeavyRangedSplitterMiniboss", "ShieldRangedMiniBoss", "SatyrRangedMiniboss", "CrawlerMiniBoss", "RatThugMiniboss"}
local bossNames = {"Harpy", "Harpy2", "Harpy3", "HydraHeadImmortal", "Theseus", "Theseus2", "Minotaur", "Minotaur2", "HydraHeadImmortal", "HydraHeadImmortalLavamaker", "HydraHeadImmortalSummoner", "HydraHeadImmortalSlammer", "HydraHeadImmortalWavemaker"}

function scaleHealth()
    -- Formulas generated with https://www.dcode.fr/function-equation-finder
    -- TODO: tweak these formulas
    local cappedRoomCounter = math.min(roomCounter, 30)
    -- Power, 0 = 30, 10 = 30, 20 = 60, 30 = 100
    local minHealth = math.floor(0.203183 * (cappedRoomCounter ^ 1.7599) + 19.478)
    -- Power, 0 = 200, 10 = 500, 20 = 1100, 30 = 1600
    local maxHealth = math.floor(19.9166 * (cappedRoomCounter ^ 1.25734) + 186.245)
    -- Power, 0 = 250, 10 = 450, 20 = 800, 30 = 1000
    local minibossMinHealth = math.floor(22.052 * (cappedRoomCounter ^ 1.04805) + 241.334)
    -- Power, 0 = 800, 10 = 1200, 20 = 8000, 30 = 14000
    local minibossMaxHealth = math.floor(34.0967 * (cappedRoomCounter ^ 1.76857) + 303.315)
    -- Power, 0 = 4000, 10 = 4400, 20 = 6000, 30 = 9000
    local bossMinHealth = math.floor(2.27144 * (cappedRoomCounter ^ 2.26341) + 3993.92)
    -- Power, 0 = 4800, 10 = 6500, 20 = 10000, 30 = 14000
    local bossMaxHealth = math.floor(63.8987 * (cappedRoomCounter ^ 1.46376) + 4757.94)

    -- Armor
    -- Power, 0 = 40, 10 = 50, 20 = 60, 30 = 120
    local minArmor = math.floor(0.00028257 * (cappedRoomCounter ^ 3.6757) + 43.8972)
    -- Power, 0 = 400, 10 = 700, 20 = 2000, 30 = 3000
    local maxArmor = math.floor(17.8392 * (cappedRoomCounter ^ 1.47817) + 336.84)
    -- Power, 0 = 600, 10 = 850, 20 = 1800, 30 = 2400
    local minibossMinArmor = math.floor(19.3576 * (cappedRoomCounter ^ 1.34815) + 555.533)
    -- Power, 0 = 1250, 10 = 2000, 20 = 2500, 30 = 5500
    local minibossMaxArmor = math.floor(0.0760623 * (cappedRoomCounter ^ 3.19305) + 1521.6)

    if roomCounter >= 30 then
        -- No more max health scaling after 30 rooms
        maxHealth = 999999999
        bossMaxHealth = 99999999
        minibossMaxHealth = 999999999
        maxArmor = 999999999
        minibossMaxArmor = 99999999
    end

    if #HadesRando.data.originalEnemyHealth == 0 then
        for enemyName, enemy in pairs(EnemyData) do
            HadesRando.data.originalEnemyHealth[enemyName] = enemy["MaxHealth"]
        end
    end

    if #HadesRando.data.originalEnemyArmor == 0 then
        for enemyName, enemy in pairs(EnemyData) do
            HadesRando.data.originalEnemyArmor[enemyName] = enemy["HealthBuffer"]
        end
    end

    for enemyName, enemy in pairs(EnemyData) do
        local baseEnemyName = enemyName

        if enemy["InheritFrom"] ~= nil and #enemy["InheritFrom"] > 0 and not tableContains(EnemyData[enemyName], "MaxHealth") then
            for _, inheritName in pairs(enemy["InheritFrom"]) do
                if tableContains(EnemyData[inheritName], "MaxHealth") then
                    baseEnemyName = inheritName
                end
            end
        end

        local originalHealth = HadesRando.data.originalEnemyHealth[baseEnemyName]
        if originalHealth == nil then goto armor end

        if tableContains(bossNames, enemyName) then
            if originalHealth > 1 and originalHealth < bossMinHealth then
                EnemyData[enemyName]["MaxHealth"] = bossMinHealth
            elseif originalHealth > bossMaxHealth then
                EnemyData[enemyName]["MaxHealth"] = bossMaxHealth
            else
                EnemyData[enemyName]["MaxHealth"] = originalHealth
            end
        elseif tableContains(minibossNames, enemyName) then
            if originalHealth < minibossMinHealth then
                EnemyData[enemyName]["MaxHealth"] = minibossMinHealth
            elseif originalHealth > minibossMaxHealth then
                EnemyData[enemyName]["MaxHealth"] = minibossMaxHealth
            else
                EnemyData[enemyName]["MaxHealth"] = originalHealth
            end
        else
            if originalHealth < minHealth then
                EnemyData[enemyName]["MaxHealth"] = minHealth
            elseif originalHealth > maxHealth then
                EnemyData[enemyName]["MaxHealth"] = maxHealth
            else
                EnemyData[enemyName]["MaxHealth"] = originalHealth
            end
        end

        ::armor::

        if enemy["InheritFrom"] ~= nil and #enemy["InheritFrom"] > 0 and not tableContains(EnemyData[enemyName], "HealthBuffer") then
            for _, inheritName in pairs(enemy["InheritFrom"]) do
                if tableContains(EnemyData[inheritName], "HealthBuffer") then
                    baseEnemyName = inheritName
                end
            end
        end

        local originalArmor = HadesRando.data.originalEnemyArmor[baseEnemyName]
        if originalArmor == nil then goto continue end

        if not tableContains(bossNames, enemyName) then
            if tableContains(minibossNames, enemyName) then
                if originalArmor < minibossMinArmor then
                    EnemyData[enemyName]["HealthBuffer"] = minibossMinArmor
                elseif originalArmor > minibossMaxArmor then
                    EnemyData[enemyName]["HealthBuffer"] = minibossMaxArmor
                else
                    EnemyData[enemyName]["HealthBuffer"] = originalArmor
                end
            else
                if originalArmor < minArmor then
                    EnemyData[enemyName]["HealthBuffer"] = minArmor
                elseif originalHealth > maxHealth then
                    EnemyData[enemyName]["HealthBuffer"] = maxArmor
                else
                    EnemyData[enemyName]["HealthBuffer"] = originalArmor
                end
            end
        end

        ::continue::
    end
end

local oDoUnlockRoomExits = DoUnlockRoomExits
function DoUnlockRoomExits( run, room )
    if HadesRando.config.randomizeRooms and randomRooms ~= nil and #randomRooms > 0 then
        local currentRoomName = CurrentRun.CurrentRoom.Name

        -- TODO: fix double intro room
        if not roomCounter > #randomRooms and not currentRoomName == "C_Boss01" and (string.match(currentRoomName, "Boss") and not (string.match(currentRoomName, "MiniBoss")
                or string.match(currentRoomName, "Miniboss") or string.match(currentRoomName, "PostBoss")))
                and not string.match(currentRoomName, "Reprieve") and not string.startsWith(currentRoomName, "D_")
                and not string.startsWith(currentRoomName, "E_") then
            local nextRoom = randomRooms[roomCounter]
            roomCounter = roomCounter + 1
            assert(nextRoom)

            if HadesRando.config.scaleStats and (HadesRando.config.randomizeRooms or HadesRando.config.randomizeEnemies) then
                scaleHealth()
            end

            scaleDifficultyRating(nextRoom)

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
    local roomAmount = HadesRando.config.fixedRoomAmount

    if HadesRando.config.randomRoomAmount then
        assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
        roomAmount = GetRngById(rngId):Random(25, 50)
    end

    assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
    local roomsCopy = DeepCopyTable(HadesRando.data.rooms)
    local npcRooms = { "A_Story01", "B_Story01", "C_Story01" }
    local shopRooms = { "A_Shop01", "B_Shop01", "C_Shop01" }
    local erebusRooms = { "RoomChallenge01", "RoomChallenge02", "RoomChallenge03", "RoomChallenge04" }
    local bossPreRooms = { "A_PreBoss01", "B_PreBoss01", "C_PreBoss01"}
    local introRooms = { "B_Intro", "C_Intro" }
    local furiesIndex = GetRngById(rngId):Random(math.floor(roomAmount * 0.2), math.ceil(roomAmount * 0.4))
    local lernieIndex = GetRngById(rngId):Random(furiesIndex + 2, math.ceil(roomAmount * 0.8))
    local championsIndex = roomAmount
    local erebusChance = GetRngById(rngId):Random(100)
    local charonFightChance = GetRngById(rngId):Random(100)
    local npcRoom1 = table.remove(npcRooms, GetRngById(rngId):Random(#npcRooms))
    local shopRoom1 = table.remove(shopRooms, GetRngById(rngId):Random(#shopRooms))
    local shopRoom2 = table.remove(shopRooms, GetRngById(rngId):Random(#shopRooms))

    for i = 1, #roomsCopy do
        if roomsCopy[i] == npcRoom1 or roomsCopy[i] == shopRoom1 or roomsCopy[i] == shopRoom2 then
            table.remove(roomsCopy, i)
            break
        end
    end

    prepareRoomsets()
    insertRandomRoom(furiesIndex, bossPreRooms[1])
    insertRandomRoom(furiesIndex + 1, introRooms[1])
    insertRandomRoom(lernieIndex, bossPreRooms[2])
    insertRandomRoom(lernieIndex + 1, introRooms[2])
    insertRandomRoom(championsIndex, bossPreRooms[3])
    insertRandomRoomAtFreeIndex(npcRoom1, roomAmount)
    insertRandomRoomAtFreeIndex(shopRoom1, roomAmount)
    insertRandomRoomAtFreeIndex(shopRoom2, roomAmount)

    if erebusChance <= HadesRando.config.erebusEncounterChance then
        insertRandomRoomAtFreeIndex(erebusRooms[GetRngById(rngId):Random(#erebusRooms)], roomAmount)
    end

    if charonFightChance <= HadesRando.config.charonEncounterChance then
        insertRandomRoomAtFreeIndex("CharonFight01", roomAmount, math.ceil(roomAmount * 0.5))
    end

    for i = 1, roomAmount do
        if not randomRoomExistsAtIndex(i) then
            if #roomsCopy == 0 then
                roomsCopy = DeepCopyTable(HadesRando.data.rooms)
                assert(#roomsCopy == 0)

                -- Remove story rooms and shops as having duplicates of them seems to crash the game.
                for j = #roomsCopy, 1, -1 do
                    if string.match(roomsCopy[j], "Story") or string.match(roomsCopy[j], "Shop") then
                        table.remove(roomsCopy, j)
                    end
                end
            end

            local randomIndex = GetRngById(rngId):Random(#roomsCopy)
            local randomRoom = roomsCopy[randomIndex]
            local attempts = 0

            while i <= 5 and string.startsWith(randomRoom, "C_Combat") or string.startsWith(randomRoom, "C_MiniBoss") do
                if attempts == 10 then
                    roomsCopy = DeepCopyTable(HadesRando.data.rooms)
                    assert(#roomsCopy == 0)

                    -- Remove story rooms and shops as having duplicates of them seems to crash the game.
                    for j = #roomsCopy, 1, -1 do
                        if string.match(roomsCopy[j], "Story") or string.match(roomsCopy[j], "Shop") then
                            table.remove(roomsCopy, j)
                        end
                    end
                end

                randomIndex = GetRngById(rngId):Random(#roomsCopy)
                randomRoom = roomsCopy[randomIndex]
                attempts = attempts + 1
            end

            insertRandomRoom(i, randomRoom)
            table.remove(roomsCopy, randomIndex)
        end
    end
end

function prepareRoomsets()
    for _, set in pairs(HadesRando.data.roomSets) do
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

    assert(roomName ~= nil)
    assert(index >= 1)
    randomRooms[index] = roomName
    --ModUtil.Print("HadesRando.data.rooms: " .. index .. " >> " .. roomName)
end

function insertRandomRoomAtFreeIndex(roomName, roomAmount, minimumIndex)
    if minimumIndex == nil then
        minimumIndex = 1
    end

    assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
    local index = GetRngById(rngId):Random(minimumIndex, roomAmount)

    while randomRoomExistsAtIndex(index) do
        index = GetRngById(rngId):Random(minimumIndex, roomAmount)
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

    assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
    local weaponUpgradesCopy = DeepCopyTable(weaponUpgrades)
    for k, v in pairs(weaponUpgradeCounts) do
        if v > 0 then
            for _ = 1, v do
                if #weaponUpgradesCopy == 0 then
                    weaponUpgradesCopy = DeepCopyTable(weaponUpgrades)
                end

                local randomIndex = GetRngById(rngId):Random(#weaponUpgradesCopy)
                local randomTrait = weaponUpgradesCopy[randomIndex]

                table.remove(weaponUpgradesCopy, randomIndex)
                assert(randomTrait)
                table.insert(LootData[k].WeaponUpgrades, randomTrait)
                -- ModUtil.Print("WeaponUpgrades: " .. k .. " >> " .. randomTrait)
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

                local randomIndex = GetRngById(rngId):Random(#traitsCopy)
                local randomTrait = traitsCopy[randomIndex]

                table.remove(traitsCopy, randomIndex)
                assert(randomTrait)
                table.insert(LootData[k].Traits, randomTrait)
                -- ModUtil.Print("Traits: " .. k .. " >> " .. randomTrait)
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

                local randomIndex = GetRngById(rngId):Random(#consumablesCopy)
                local randomTrait = consumablesCopy[randomIndex]

                table.remove(consumablesCopy, randomIndex)
                assert(randomTrait)
                table.insert(LootData[k].Consumables, randomTrait)
                -- ModUtil.Print("Consumables: " .. k .. " >> " .. randomTrait)
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

                local randomIndex = GetRngById(rngId):Random(#linkedUpgradesCopy)
                local randomTrait = linkedUpgradesCopy[randomIndex]

                table.remove(linkedUpgradesCopy, randomIndex)
                assert(randomTrait)
                table.insert(LootData[k].LinkedUpgrades, randomTrait)
                -- ModUtil.Print("LinkedUpgrades: " .. k .. " >> " .. randomTrait)
            end
        end
    end
end

function randomizeEnemies()
    local enemiesCopy = DeepCopyTable(HadesRando.data.enemies)

    assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
    for biome, v in pairs(EncounterData) do
        if EncounterData[biome].EnemySet ~= nil or EncounterData[biome].ManualWaveTemplates ~= nil or EncounterData[biome].WaveTemplate ~= nil or EncounterData[biome].SpawnWaves ~= nil then
            if not isBiomeBlacklisted(biome) and not string.match(biome, "Story") and not string.match(biome, "Shop") then
                EncounterData[biome].MaxAppearancesThisRun = nil
                EncounterData[biome].MaxAppearancesThisBiome = nil
                EncounterData[biome].MinRoomsBetweenType = nil
                EncounterData[biome].MinRunsSinceThanatosSpawn = nil

                local length = GetRngById(rngId):Random(5, 15)
                local enemySet = {}

                if string.match(biome, "MiniBoss") or string.match(biome, "Miniboss") then
                    length = 1
                end

                for _ = 1, length do
                    if #HadesRando.data.enemies == 0 then
                        enemiesCopy = DeepCopyTable(HadesRando.data.enemies)
                    end

                    local randomEnemy

                    if string.match(biome, "MiniBoss") or string.match(biome, "Miniboss") then
                        local randomIndex = GetRngById(rngId):Random(#HadesRando.data.minibosses)
                        randomEnemy = HadesRando.data.minibosses[randomIndex]

                        while (randomEnemy == "CrawlerMiniBoss" or string.match(randomEnemy, "Rat")) and not string.startsWith(biome, "D_") do
                            randomIndex = GetRngById(rngId):Random(#HadesRando.data.minibosses)
                            randomEnemy = HadesRando.data.minibosses[randomIndex]
                        end

                        assert(randomEnemy)
                    elseif not (string.match(biome, "Opening") or string.match(biome, "Tartarus") or string.match(biome, "Asphodel") or biome == "Generated" or string.match(biome, "Intro")) then
                        local randomIndex = GetRngById(rngId):Random(#enemiesCopy)
                        randomEnemy = enemiesCopy[randomIndex]

                        assert(randomEnemy)
                        table.remove(enemiesCopy, randomIndex)
                    else
                        local randomIndex = GetRngById(rngId):Random(#enemiesCopy)
                        randomEnemy = enemiesCopy[randomIndex]

                        local excludeType = "SuperElite"

                        if biome == "RoomOpening" or biome == "RoomSimple01" or string.match(biome, "Intro") then
                            excludeType = "Elite"
                        end

                        local attempts = 0
                        while string.match(randomEnemy, excludeType) or string.match(randomEnemy, "Rat") or string.match(randomEnemy, "Satyr") do
                            if attempts == 10 then
                                enemiesCopy = DeepCopyTable(HadesRando.data.enemies)
                            end

                            randomIndex = GetRngById(rngId):Random(#enemiesCopy)
                            randomEnemy = enemiesCopy[randomIndex]
                            attempts = attempts + 1
                        end

                        assert(randomEnemy)
                        table.remove(enemiesCopy, randomIndex)
                    end

                    -- ModUtil.Print("EnemySet: " .. biome .. " >> " .. randomEnemy)
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

    assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")
    return rarities[GetRngById(rngId):Random(rarities)]
end

function setSeed()
    assert(rngId ~= nil)

    if HadesRando.config.seed == nil then
        RandomSetNextInitSeed({ Id = rngId, Seed = math.floor(GetTime({}) * 1000000) })
        RandomSynchronize(0, rngId)
        HadesRando.config.seed = GetRngById(rngId):Random(1, 9999999)
    end

    RandomSetNextInitSeed({ Id = rngId, Seed = HadesRando.config.seed })
    RandomSynchronize(0, rngId)
end

function tableContains(table, value)
    if table == nil then
        return false
    end

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

function shuffleInPlace(table)
    assert(HadesRando.config.seed ~= nil, "Tried to get a random number while the seed was nil")

    for i = #table, 2, -1 do
        local j = GetRngById(rngId):Random(i)
        table[i], table[j] = table[j], table[i]
    end
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
    local text = seedText .. (HadesRando.config.seed or "None")

    if ScreenAnchors["HadesRandoSeed"] ~= nil then
        ModifyTextBox({ Id = ScreenAnchors["HadesRandoSeed"], Text = text, Color = runDepthCopy.Color })
    else
        ScreenAnchors["HadesRandoSeed"] = CreateScreenObstacle({ Name = "BlankObstacle", X = 1905, Y = 124, Group = "Combat_Menu_Overlay" })
        CreateTextBox(MergeTables(runDepthCopy, { Id = ScreenAnchors["HadesRandoSeed"], Text = text }))
        ModifyTextBox({ Id = ScreenAnchors["HadesRandoSeed"] })
    end
end
