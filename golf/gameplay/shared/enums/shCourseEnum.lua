CourseEnum = class(Enum)
--[[
    CourseEnum
]]

function CourseEnum:__init()
    self:EnumInit()

    self.TwoFarmsEasy = 1
    self:SetDescription(self.TwoFarmsEasy, "Two Farms")

    self.ForestPathEasy = 2
    self:SetDescription(self.ForestPathEasy, "Forest Path")

    self.BolgerGladeEasy = 3
    self:SetDescription(self.BolgerGladeEasy, "Bolger Glade")

    self.StrawberryMedium = 4
    self:SetDescription(self.StrawberryMedium, "Strawberry")

    self.ThievesLandingMedium = 5
    self:SetDescription(self.ThievesLandingMedium, "Thieves Landing")

    self.RockFormationsMedium = 6
    self:SetDescription(self.RockFormationsMedium, "Rock Formations")

    self.QuakersCoveMedium = 7
    self:SetDescription(self.QuakersCoveMedium, "Quaker's Cove")

    self.StDenisTrainsHard = 8
    self:SetDescription(self.StDenisTrainsHard, "St. Denis Trains")

    self.FlatIronIslandsHard = 9
    self:SetDescription(self.FlatIronIslandsHard, "Flat Iron Islands")

    self.PlateausHard = 10
    self:SetDescription(self.PlateausHard, "Plateaus")

    self.CalumetRavineHard = 11
    self:SetDescription(self.CalumetRavineHard, "Calumet Ravine")

    self.OwanjilaHard = 12
    self:SetDescription(self.OwanjilaHard, "Owanjila")

    self.BrandywineDropHard = 13
    self:SetDescription(self.BrandywineDropHard, "Brandywine Drop")

    self.MountShannExtreme = 14
    self:SetDescription(self.MountShannExtreme, "Mount Shann")

    self.BridgeRunExtreme = 15
    self:SetDescription(self.BridgeRunExtreme, "Bridge Run")

    self.StDenisRooftopsExtreme = 16
    self:SetDescription(self.StDenisRooftopsExtreme, "St. Denis Rooftops")

    self.MountHagenExtreme = 17
    self:SetDescription(self.MountHagenExtreme, "Mount Hagen")

    self.PlateauHopsInsane = 18
    self:SetDescription(self.PlateauHopsInsane, "Plateau Hops")

    self.SnowTourInsane = 19
    self:SetDescription(self.SnowTourInsane, "Snow Tour")

    self.MantecaFallsInsane = 20
    self:SetDescription(self.MantecaFallsInsane, "Manteca Falls")

    self.CotorraSpringsEasy = 21
    self:SetDescription(self.CotorraSpringsEasy, "Cotorra Springs")

    self.GranitePassHard = 22
    self:SetDescription(self.GranitePassHard, "Granite Pass")

    self.DonnerFallsExtreme = 23
    self:SetDescription(self.DonnerFallsExtreme, "Donner Falls")

    self.OCreaghsRunMedium = 24
    self:SetDescription(self.OCreaghsRunMedium, "O'Creagh's Run")

    self.LakeDonJulioMedium = 25
    self:SetDescription(self.LakeDonJulioMedium, "Lake Don Julio")

    self.AlpineWaterwayMedium = 26
    self:SetDescription(self.AlpineWaterwayMedium, "Alpine Waterway")

    self.FortMercerModded = 27
    self:SetDescription(self.FortMercerModded, "Fort Mercer")

    self.TwoFarmsModded = 28
    self:SetDescription(self.TwoFarmsModded, "Two Farms")

    self.GranitePassModded = 29
    self:SetDescription(self.GranitePassModded, "Granite Pass")

    self.OwanjilaModded = 30
    self:SetDescription(self.OwanjilaModded, "Owanjila")

    self.FlatIronIslandsModded = 31
    self:SetDescription(self.FlatIronIslandsModded, "Flat Iron Islands")
end

CourseEnum = CourseEnum()