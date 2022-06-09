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

    self:AddCourse({
        course_enum = CourseEnum.ForestPathEasy,
        map = "forestpath.json",
        difficulty = DifficultyEnum.Easy
    })

    self:AddCourse({
        course_enum = CourseEnum.BolgerGladeEasy,
        map = "bolgerglade.json",
        difficulty = DifficultyEnum.Easy
    })

    self:AddCourse({
        course_enum = CourseEnum.TwoFarmsEasy,
        map = "twofarms.json",
        difficulty = DifficultyEnum.Easy
    })
    
    self:AddCourse({
        course_enum = CourseEnum.CotorraSpringsEasy,
        map = "cotorrasprings.json",
        difficulty = DifficultyEnum.Easy
    })

    self:AddCourse({
        course_enum = CourseEnum.StrawberryMedium,
        map = "strawberry.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.ThievesLandingMedium,
        map = "thieveslanding.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.OCreaghsRunMedium,
        map = "ocreaghsrun.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.RockFormationsMedium,
        map = "rockformations.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.AlpineWaterwayMedium,
        map = "alpinewaterway.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.LakeDonJulioMedium,
        map = "lakedonjulio.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.QuakersCoveMedium,
        map = "quakerscove.json",
        difficulty = DifficultyEnum.Medium
    })

    self:AddCourse({
        course_enum = CourseEnum.StDenisTrainsHard,
        map = "stdenistrains.json",
        difficulty = DifficultyEnum.Hard
    })

    self:AddCourse({
        course_enum = CourseEnum.FlatIronIslandsHard,
        map = "flatironislands.json",
        difficulty = DifficultyEnum.Hard
    })

    self:AddCourse({
        course_enum = CourseEnum.PlateausHard,
        map = "plateaus.json",
        difficulty = DifficultyEnum.Hard
    })

    self:AddCourse({
        course_enum = CourseEnum.CalumetRavineHard,
        map = "calumetravine.json",
        difficulty = DifficultyEnum.Hard
    })

    self:AddCourse({
        course_enum = CourseEnum.GranitePassHard,
        map = "granitepass.json",
        difficulty = DifficultyEnum.Hard
    })
    
    self:AddCourse({
        course_enum = CourseEnum.OwanjilaHard,
        map = "owanjila.json",
        difficulty = DifficultyEnum.Hard
    })

    self:AddCourse({
        course_enum = CourseEnum.BrandywineDropHard,
        map = "brandywinedrop.json",
        difficulty = DifficultyEnum.Hard
    })

    self:AddCourse({
        course_enum = CourseEnum.MountShannExtreme,
        map = "mountshann.json",
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.FlatIronIslandsModded,
        map = "flatironislands.json",
        modded = true,
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.DonnerFallsExtreme,
        map = "donnerfalls.json",
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.BridgeRunExtreme,
        map = "bridgerun.json",
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.FortMercerModded,
        map = "fortmercer.json",
        modded = true,
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.TwoFarmsModded,
        map = "twofarms.json",
        modded = true,
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.StDenisRooftopsExtreme,
        map = "stdenisrooftops.json",
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.GranitePassModded,
        map = "granitepass.json",
        modded = true,
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.MountHagenExtreme,
        map = "mounthagen.json",
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.OwanjilaModded,
        map = "owanjila.json",
        modded = true,
        difficulty = DifficultyEnum.Extreme
    })

    self:AddCourse({
        course_enum = CourseEnum.PlateauHopsInsane,
        map = "plateauhops.json",
        difficulty = DifficultyEnum.Insane
    })

    self:AddCourse({
        course_enum = CourseEnum.SnowTourInsane,
        map = "snowtour.json",
        difficulty = DifficultyEnum.Insane
    })

    self:AddCourse({
        course_enum = CourseEnum.MantecaFallsInsane,
        map = "mantecafalls.json",
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