cFlatIronIslandsMapMod = class()

function cFlatIronIslandsMapMod:__init()

    self.active = true

    Citizen.CreateThread(function()
        while self.active do
            Wait(10)
            local ped = LocalPlayer:GetPed()
            local velo = ped:GetVelocity()
            local velo_2d = vector3(velo.x, velo.y, 0)
            local speed = Vector3Math:Length(velo_2d)
            if ped:IsInWater() and speed > 10 then
                local velo_abs = vector3(velo.x, velo.y, math.abs(velo.z * 2))
                ped:SetVelocity(velo_abs)
            end
        end
    end)

end

function cFlatIronIslandsMapMod:Unload()
    self.active = false
end
