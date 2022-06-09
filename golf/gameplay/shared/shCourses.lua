Courses = class()

function Courses:__init()
    getter_setter(self, "courses")
    self.courses = {}

    self:DeclareCourses()

    for _, course in pairs(self.courses) do
        print(course)
    end
end

function Courses:DeclareCourses()

    -- self:AddCourse({
    --     course_enum = CourseEnum.TestMapEasy,
    --     map = "testmap.json",
    --     difficulty = DifficultyEnum.Easy
    -- })

    self:AddCourse({
        course_enum = CourseEnum.GolfingSocietyEasy,
        map = "golfingsociety.json",
        difficulty = DifficultyEnum.Easy
    })

    self:AddCourse({
        course_enum = CourseEnum.MorningwoodGraveyardEasy,
        map = "morningwoodgraveyard.json",
        difficulty = DifficultyEnum.Easy
    })

    self:AddCourse({
        course_enum = CourseEnum.VinewoodDamMedium,
        map = "vinewooddam.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.TheConcreteRiverMedium,
        map = "theconcreteriver.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.LagoZancudoMedium,
        map = "lagozancudo.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.DelPerroPierMedium,
        map = "delperropier.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.InternationalAirportMedium,
        map = "internationalairport.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.LandActReservoirHard,
        map = "landactreservoir.json",
        difficulty = DifficultyEnum.Hard
    })

    self:AddCourse({
        course_enum = CourseEnum.CozyCoveHard,
        map = "cozycove.json",
        difficulty = DifficultyEnum.Hard
    })

    self:AddCourse({
        course_enum = CourseEnum.MountGordoExtreme,
        map = "mountgordo.json",
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.ElysianIslandInsane,
        map = "elysianisland.json",
        difficulty = DifficultyEnum.Insane
    })

end

function Courses:AddCourse(args)
    args.order = count_table(self.courses)
    self.courses[args.course_enum] = Course(args)
end

function Courses:GetCourse(course_enum)
    return self.courses[course_enum]
end

function Courses:GetAllMapData()
    local map_data = {}
    for course_enum, course in pairs(self.courses) do
        map_data[course_enum] = course:GetMapData()
    end

    return map_data
end

Courses = Courses()