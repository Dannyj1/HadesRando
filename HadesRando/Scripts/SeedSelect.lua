ScreenData.SeedControl =
{
    ItemStartX = ScreenWidth / 2 + 300,
    ItemStartY = ScreenHeight / 2 - 100,
    ItemSpacing = 100,
    EntryYSpacer = 25,
    ItemsPerPage = 12,
    ScrollOffset = 0,
    Digits = { 1, 2, 3, 4, 5, 6, 7 },
}

function OpenRngSeedSelectorScreen(screen, button)
    CloseAdvancedTooltipScreen()
    UseSeedController(CurrentRun.Hero)
end

function UseSeedController( usee, args )
    PlayInteractAnimation( usee.ObjectId )
    UseableOff({ Id = usee.ObjectId })
    StopStatusAnimation( usee )
    local screen = OpenSeedControlScreen()
    UseableOn({ Id = usee.ObjectId })
end

function OpenSeedControlScreen( args )
    local screen = DeepCopyTable( ScreenData.SeedControl )
    screen.Components = {}
    local components = screen.Components
    screen.CloseAnimation = "QuestLogBackground_Out"

    OnScreenOpened({ Flag = screen.Name, PersistCombatUI = true })
    FreezePlayerUnit()
    EnableShopGamepadCursor()
    SetConfigOption({ Name = "FreeFormSelectWrapY", Value = false })
    SetConfigOption({ Name = "FreeFormSelectStepDistance", Value = 8 })
    SetConfigOption({ Name = "FreeFormSelectSuccessDistanceStep", Value = 8 })

    components.ShopBackgroundDim = CreateScreenComponent({ Name = "rectangle01", Group = "Combat_Menu" })
    components.ShopBackgroundSplatter = CreateScreenComponent({ Name = "LevelUpBackground", Group = "Combat_Menu" })
    components.ShopBackground = CreateScreenComponent({ Name = "rectangle01", Group = "Combat_Menu" })

    SetAnimation({ DestinationId = components.ShopBackground.Id, Name = "QuestLogBackground_In", OffsetY = 30 })

    SetScale({ Id = components.ShopBackgroundDim.Id, Fraction = 4 })
    SetColor({ Id = components.ShopBackgroundDim.Id, Color = {0.090, 0.055, 0.157, 0.8} })

    PlaySound({ Name = "/SFX/Menu Sounds/FatedListOpen" })

    wait(0.2)

    local itemLocationX = screen.ItemStartX
    local itemLocationY = screen.ItemStartY

    SeedControlScreenSyncDigits( screen )

    for digit, digitValue in ipairs( screen.Digits ) do
        components["DigitUp"..digit] = CreateScreenComponent({ Name = "ButtonCodexUp", X = itemLocationX, Y = itemLocationY - 100, Scale = 1.0, Sound = "/SFX/Menu Sounds/GeneralWhooshMENU", Group = "Combat_Menu" })
        components["DigitUp"..digit].OnPressedFunctionName = "SeedDigitDown"
        components["DigitUp"..digit].ControlHotkey = "MenuLeft"
        components["DigitUp"..digit].Digit = digit

        local digitKey = "DigitButton"..digit
        components[digitKey] = CreateScreenComponent({ Name = "BlankObstacle", Scale = 1, X = itemLocationX, Y = itemLocationY, Group = "Combat_Menu" })
        components[digitKey].Digit = digit
        AttachLua({ Id = components[digitKey].Id, Table = components[digitKey] })

        CreateTextBox({ Id = components[digitKey].Id,
                        Text = digitValue,
                        Color = {245, 200, 47, 255},
                        FontSize = 48,
                        OffsetX = 0, OffsetY = 0,
                        Font = "AlegreyaSansSCBold",
                        OutlineThickness = 0,
                        OutlineColor = {255, 205, 52, 255},
                        ShadowBlur = 0, ShadowColor = {0,0,0,0}, ShadowOffset={0, 2},
                        Justification = "Center",
                        DataProperties =
                        {
                            OpacityWithOwner = true,
                        },
        })

        components["DigitDown"..digit] = CreateScreenComponent({ Name = "ButtonCodexDown", X = itemLocationX, Y = itemLocationY + 100, Scale = 1.0, Sound = "/SFX/Menu Sounds/GeneralWhooshMENU", Group = "Combat_Menu" })
        components["DigitDown"..digit].OnPressedFunctionName = "SeedDigitUp"
        components["DigitDown"..digit].ControlHotkey = "MenuRight"
        components["DigitDown"..digit].Digit = digit

        itemLocationX = itemLocationX - screen.ItemSpacing
    end

    UpdateDigitDisplay( screen )

    -- Randomize button
    components.RandomizeButton = CreateScreenComponent({ Name = "ButtonDefault", Scale = 1.0, Group = "Combat_Menu", X = ScreenWidth / 2, Y = 700 })
    components.RandomizeButton.OnPressedFunctionName = "SeedControlScreenRandomize"
    CreateTextBox({ Id = components.RandomizeButton.Id,
                    Text = "Randomize Seed",
                    OffsetX = 0, OffsetY = 0,
                    FontSize = 22,
                    Color = Color.White,
                    Font = "AlegreyaSansSCRegular",
                    ShadowBlur = 0, ShadowColor = {0,0,0,1}, ShadowOffset={0, 2},
                    Justification = "Center",
                    DataProperties =
                    {
                        OpacityWithOwner = true,
                    },
    })

    -- Close button
    components.CloseButton = CreateScreenComponent({ Name = "ButtonClose", Scale = 0.7, Group = "Combat_Menu" })
    Attach({ Id = components.CloseButton.Id, DestinationId = components.ShopBackground.Id, OffsetX = -6, OffsetY = 456 })
    components.CloseButton.OnPressedFunctionName = "CloseSeedControlScreen"
    components.CloseButton.ControlHotkey = "Cancel"

    wait(0.1)
    --TeleportCursor({ OffsetX = screen.ItemStartX - 30, OffsetY = screen.ItemStartY, ForceUseCheck = true })

    screen.KeepOpen = true
    thread( HandleWASDInput, screen )
    HandleScreenInput( screen )
end

function SeedDigitUp( screen, button )
    local newDigitValue = screen.Digits[button.Digit]
    newDigitValue = newDigitValue - 1
    if newDigitValue < 0 then
        newDigitValue = 9
    end
    screen.Digits[button.Digit] = newDigitValue
    local newSeed = 0
    for digit, digitValue in ipairs( screen.Digits ) do
        newSeed = newSeed + (digitValue * math.pow(10, digit - 1))
    end

    HadesRando.config.seed = newSeed
    UpdateDigitDisplay( screen )
end

function SeedDigitDown( screen, button )
    local newDigitValue = screen.Digits[button.Digit]
    newDigitValue = newDigitValue + 1
    if newDigitValue > 9 then
        newDigitValue = 0
    end
    screen.Digits[button.Digit] = newDigitValue
    local newSeed = 0
    for digit, digitValue in ipairs( screen.Digits ) do
        newSeed = newSeed + (digitValue * math.pow(10, digit - 1))
    end

    HadesRando.config.seed = newSeed
    UpdateDigitDisplay( screen )
end

function SeedControlScreenSyncDigits( screen )
    local displayNumber = (HadesRando.config.seed or 0000000)
    if displayNumber ~= nil then
        for digit = 1, #screen.Digits do
            local digitValue = displayNumber % 10
            screen.Digits[digit] = digitValue
            displayNumber = math.floor( displayNumber / 10 )
        end
    end
end

function UpdateDigitDisplay( screen )
    for digit, digitValue in ipairs( screen.Digits ) do
        local digitKey = "DigitButton"..digit
        ModifyTextBox({ Id = screen.Components["DigitButton"..digit].Id, Text = digitValue })
    end
end

function SeedControlScreenRandomize( screen, button )
    math.randomseed(math.floor(GetTime({}) * 1000000))
    local newSeed = math.random(0, 9999999)

    HadesRando.config.seed = newSeed
    SeedControlScreenSyncDigits( screen )
    UpdateDigitDisplay( screen )
end

function CloseSeedControlScreen( screen, button )
    local newSeed = 0
    local place = 1
    for digit, digitValue in ipairs( screen.Digits ) do
        newSeed = newSeed + (digitValue * math.pow(10, digit - 1))
    end

    HadesRando.config.seed = newSeed
    DisableShopGamepadCursor()
    SetConfigOption({ Name = "FreeFormSelectWrapY", Value = false })
    SetConfigOption({ Name = "FreeFormSelectStepDistance", Value = 16 })
    SetConfigOption({ Name = "FreeFormSelectSuccessDistanceStep", Value = 8 })
    SetAnimation({ DestinationId = screen.Components.ShopBackground.Id, Name = screen.CloseAnimation })
    PlaySound({ Name = "/SFX/Menu Sounds/FatedListClose" })
    CloseScreen( GetAllIds( screen.Components ), 0.1 )
    UnfreezePlayerUnit()
    screen.KeepOpen = false
    OnScreenClosed({ Flag = screen.Name })
end

ModUtil.WrapBaseFunction("CreatePrimaryBacking", function ( baseFunc )
    local components = ScreenAnchors.TraitTrayScreen.Components

    if ModUtil.PathGet("CurrentDeathAreaRoom") then
        components.RngSeedButton = CreateScreenComponent({ Name = "ButtonDefault", Scale = 1.0, Group = "Combat_Menu_TraitTray", X = CombatUI.TraitUIStart + 105, Y = 930 })
        components.RngSeedButton.OnPressedFunctionName = "OpenRngSeedSelectorScreen"
        CreateTextBox({ Id = components.RngSeedButton.Id,
                        Text = "Set Randomizer Seed",
                        OffsetX = 0, OffsetY = 0,
                        FontSize = 22,
                        Color = Color.White,
                        Font = "AlegreyaSansSCRegular",
                        ShadowBlur = 0, ShadowColor = {0,0,0,1}, ShadowOffset={0, 2},
                        Justification = "Center",
                        DataProperties =
                        {
                            OpacityWithOwner = true,
                        },
        })
        Attach({ Id = components.RngSeedButton.Id, DestinationId = components.RngSeedButton, OffsetX = 500, OffsetY = 500 })
    end
    baseFunc()
end, HadesRando)