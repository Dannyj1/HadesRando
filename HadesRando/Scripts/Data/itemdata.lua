--[[
Copyright 2021 Dannyj1

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

HadesRando.data.keepsakes = {
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

HadesRando.data.companions = {
    "FuryAssistTrait",
    "ThanatosAssistTrait",
    "SisyphusAssistTrait",
    "SkellyAssistTrait",
    "DusaAssistTrait",
    "AchillesPatroclusAssistTrait"
}

HadesRando.data.roomDataCopy = {}
HadesRando.data.encounterDataCopy = {}
HadesRando.data.enemyDataCopy = {}
HadesRando.data.lootDataCopy = {}

ModUtil.LoadOnce( function()
    HadesRando.data.roomDataCopy = DeepCopyTable(RoomData)
    HadesRando.data.encounterDataCopy = DeepCopyTable(EncounterData)
    HadesRando.data.enemyDataCopy = DeepCopyTable(EnemyData)
    HadesRando.data.lootDataCopy = DeepCopyTable(LootData)
end)
