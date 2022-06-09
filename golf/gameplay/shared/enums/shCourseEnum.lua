CourseEnum = class(Enum)
--[[
    CourseEnum
]]

function CourseEnum:__init()
    self:EnumInit()

    self.TestMapEasy = 1
    self:SetDescription(self.TestMapEasy, "Test Map")

    self.DelPerroPierMedium = 2
    self:SetDescription(self.DelPerroPierMedium, "Del Perro Pier")

    self.TheConcreteRiverMedium = 3
    self:SetDescription(self.TheConcreteRiverMedium, "The Concrete River")

    self.CozyCoveHard = 4
    self:SetDescription(self.CozyCoveHard, "Cozy Cove")

    self.MountGordoExtreme = 5
    self:SetDescription(self.MountGordoExtreme, "Mount Gordo")

    self.MorningwoodGraveyardEasy = 6
    self:SetDescription(self.MorningwoodGraveyardEasy, "Morningwood Graveyard")

    self.GolfingSocietyEasy = 7
    self:SetDescription(self.GolfingSocietyEasy, "Golfing Society")

    self.VinewoodDamMedium = 8
    self:SetDescription(self.VinewoodDamMedium, "Vinewood Dam")

    self.LandActReservoirHard = 9
    self:SetDescription(self.LandActReservoirHard, "Land Act Reservoir")

    self.InternationalAirportMedium = 10
    self:SetDescription(self.InternationalAirportMedium, "International Airport")

    self.ElysianIslandInsane = 11
    self:SetDescription(self.ElysianIslandInsane, "Elysian Island")

    self.LagoZancudoMedium = 12
    self:SetDescription(self.LagoZancudoMedium, "Lago Zancudo")

end

CourseEnum = CourseEnum()