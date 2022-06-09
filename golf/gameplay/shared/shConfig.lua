shGameplayConfig = class()

-- Must use class because it uses data from another class on init
function shGameplayConfig:__init()
    self.DisableGolfing = false
    self.ScreenshotMode = false -- Disables UI elements for taking screenshots

    self.HoleFlagpoleModal = IsRedM and "mp001_s_mp_finishline_banner01x" or "prop_golfflag"

    self.DifficultyColors = 
    {
        [DifficultyEnum.Easy] = Color(0,220,91),
        [DifficultyEnum.Medium] = Color(242,228,34),
        [DifficultyEnum.Hard] = Color(255,70,0),
        [DifficultyEnum.Extreme] = Color(0,255,255),
        [DifficultyEnum.Insane] = Color(255,0,255)
    }

    self.PowerupData = 
    {
        [PowerupTypesEnum.Wiggle] =                 {key = "Q"},
        [PowerupTypesEnum.Freeze] =                 {maxCharges = 5, key = "Q"},
        [PowerupTypesEnum.Overflow] =               {},
        [PowerupTypesEnum.IncreaseHoleSize] =       {duration = 20, maxCharges = 3, key = "Q"},
        [PowerupTypesEnum.Vortex] =                 {duration = 20, maxCharges = 3, key = "Q"},
        [PowerupTypesEnum.AirJordans] =             {duration = 30, maxCharges = 3, key = "Q"},
    }

    if IsClient then
        Events:Subscribe("LocalPlayerChat", function(args) 
            if args.text == "/ss" then
                shGameplayConfig.ScreenshotMode = not shGameplayConfig.ScreenshotMode
            end
        end)
    end

end

shGameplayConfig = shGameplayConfig()