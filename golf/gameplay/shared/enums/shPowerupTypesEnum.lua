PowerupTypesEnum = class(Enum)

function PowerupTypesEnum:__init()
    self:EnumInit()

    self.Wiggle = "1"
    self:SetDescription(self.Wiggle, "Wiggle") -- Wiggles your character slightly

    self.Freeze = "2"
    self:SetDescription(self.Freeze, "Freeze") -- Freezes your character midair

    self.Overflow = "3"
    self:SetDescription(self.Overflow, "Overflow") -- Allows you to charge up to 2x the normal max power

    self.IncreaseHoleSize = "4"
    self:SetDescription(self.IncreaseHoleSize, "Increase Hole Size") -- Next hole size becomes larger

    self.Vortex = "5"
    self:SetDescription(self.Vortex, "Vortex") -- Creates a vortex around the next hole that sucks you in

    self.AirJordans = "6"
    self:SetDescription(self.AirJordans, "Air Jordans") -- Allows you to slightly change your velocity mid air

end

PowerupTypesEnum = PowerupTypesEnum()