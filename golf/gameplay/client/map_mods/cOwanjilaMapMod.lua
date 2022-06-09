cOwanjilaMapMod = class()

function cOwanjilaMapMod:__init()

    self.active = true

    Citizen.CreateThread(function()
        while self.active do
            Wait(10)
            local ped = LocalPlayer:GetPed()
            if ped:IsInWater() then
                ped:SetVelocity(ped:GetVelocity() * 1.5 + vector3(0, 0, 10))
            end
        end
    end)

end

function cOwanjilaMapMod:Unload()
    self.active = false
end
