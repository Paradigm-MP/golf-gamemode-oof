PowerupManager = class()

function PowerupManager:__init()
    self.powerups = {}
    self.active_powerups = {} -- Equipped powerups

    self.powerup_behaviors = {} -- Map of powerup enums to behavior class singletons
    self.activated_powerups = {} -- Powerups that have been activated and have ongoing effects

    self:DeclareNetworkSubscriptions()
    self:InitializePowerupBehaviors()
end

function PowerupManager:DeclareNetworkSubscriptions()
    Network:Subscribe("gameplay/powerup/sync", function(args) self:PowerupSync(args) end)
end

function PowerupManager:PowerupSync(args)
    self.powerups = args.powerups
    self.active_powerups = args.active_powerups
    output_table(args)
end

function PowerupManager:HasPowerup(powerup_enum)
    return self.powerups[powerup_enum] == true
end

function PowerupManager:IsPowerupActive(powerup_enum)
    return self.active_powerups[powerup_enum] == true
end

function PowerupManager:ActivatePowerup(args)
    if not self.active_powerups[args.type] then return end

    if self.powerup_behaviors[args.type] then
        if self.active_powerups[args.type] then
            self.powerup_behaviors[args.type]:End()
        end

        self.powerup_behaviors[args.type]:Activate(args)
    end

end

function PowerupManager:EndAllPowerups()
    for type, powerup in pairs(self.powerup_behaviors) do
        powerup:End()
    end
end

function PowerupManager:InitializePowerupBehaviors()
    self.powerup_behaviors[PowerupTypesEnum.Wiggle] = WigglePowerup()
    self.powerup_behaviors[PowerupTypesEnum.Freeze] = FreezePowerup()
    self.powerup_behaviors[PowerupTypesEnum.Overflow] = OverflowPowerup()
    self.powerup_behaviors[PowerupTypesEnum.IncreaseHoleSize] = HoleSizePowerup()
    self.powerup_behaviors[PowerupTypesEnum.Vortex] = VortexPowerup()
    self.powerup_behaviors[PowerupTypesEnum.AirJordans] = AirJordansPowerup()
end

PowerupManager = PowerupManager()