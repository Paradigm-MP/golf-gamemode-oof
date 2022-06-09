cTwoFarmsMapMod = class()

function cTwoFarmsMapMod:__init()

    self.active = true

    Citizen.CreateThread(function()
        while self.active do
            Wait(100)
            local ped = LocalPlayer:GetPed()
            local velo = ped:GetVelocity()
            local new_velo = vector3(velo.x, velo.y, velo.z + 0.25)
            ped:SetVelocity(new_velo)
            ped:SetDamping(0, 0.0001)
            ped:SetDamping(1, 0.0001)
            ped:SetDamping(2, 0.0001)
        
        end
    end)

end

function cTwoFarmsMapMod:Unload()
    self.active = false
end
