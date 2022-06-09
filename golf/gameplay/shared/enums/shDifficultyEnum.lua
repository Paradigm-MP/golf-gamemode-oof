DifficultyEnum = class(Enum)
--[[
    DifficultyEnum
]]

function DifficultyEnum:__init()
    self:EnumInit()

    self.Easy = 1
    self:SetDescription(self.Easy, "Easy")

    self.Medium = 2
    self:SetDescription(self.Medium, "Medium")
    
    self.Hard = 3
    self:SetDescription(self.Hard, "Hard")

    self.Extreme = 4
    self:SetDescription(self.Extreme, "Extreme")

    self.Insane = 5
    self:SetDescription(self.Insane, "Insane")
end

DifficultyEnum = DifficultyEnum()