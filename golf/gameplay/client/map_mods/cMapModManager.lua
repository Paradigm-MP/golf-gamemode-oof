cMapModManager = class()

function cMapModManager:__init()

    self.map_mods_list = {}
    self.current_course = 0

    self:RegisterMapMods()
    Events:Subscribe("onResourceStop", function(resource_name) self:OnResourceStop(resource_name) end)

end

function cMapModManager:OnModuleUnload()
    if self.active_map_mod then
        self.active_map_mod:Unload()
    end
end

-- Clean up all spawned objects on resource stop
function cMapModManager:OnResourceStop(resource_name)
    if GetCurrentResourceName() == resource_name then
        self:OnModuleUnload()
    end
end

function cMapModManager:OnGameStart(course_enum)
    if self.map_mods_list[course_enum] then
        self.active_map_mod = self.map_mods_list[course_enum]()
    end
end

function cMapModManager:OnGameEnd()
    self:OnModuleUnload()
end

function cMapModManager:RegisterMapMods()
    self.map_mods_list[CourseEnum.FortMercerModded] = cFortMercerMapMod
    self.map_mods_list[CourseEnum.TwoFarmsModded] = cTwoFarmsMapMod
    self.map_mods_list[CourseEnum.GranitePassModded] = cGranitePassMapMod
    self.map_mods_list[CourseEnum.OwanjilaModded] = cOwanjilaMapMod
    self.map_mods_list[CourseEnum.FlatIronIslandsModded] = cFlatIronIslandsMapMod
end

cMapModManager = cMapModManager()