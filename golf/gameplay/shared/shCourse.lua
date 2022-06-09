Course = class()

function Course:__init(args)
    getter_setter(self, "course_enum")
    self:SetCourseEnum(args.course_enum)

    getter_setter(self, "map")
    self:SetMap(args.map)

    getter_setter(self, "modded")
    self:SetModded(args.modded)

    getter_setter(self, "order")
    self:SetOrder(args.order)

    getter_setter(self, "map_data")

    getter_setter(self, "difficulty")
    self:SetDifficulty(args.difficulty)
end

function Course:GetName()
    return string.sub(self.map, 1, -6)
end

function Course:GetTotalPar()
    local total_par = 0
    for _, hole_data in pairs(self:GetMapData().holes) do
        total_par = total_par + tonumber(hole_data.par)
    end
    return total_par
end

function Course:tostring()
    return "Course (" .. self:GetMap() .. ") (" .. DifficultyEnum:GetDescription(self:GetDifficulty()) .. ")"
end