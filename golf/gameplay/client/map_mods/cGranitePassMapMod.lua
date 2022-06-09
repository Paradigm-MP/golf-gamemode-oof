cGranitePassMapMod = class()

function cGranitePassMapMod:__init()

    self.active = true

    Citizen.CreateThread(function()
        while self.active do
            Wait(10)
            local ped = LocalPlayer:GetPed()
            ped:SetDamping(0, 1)
            ped:SetDamping(1, 1)
            ped:SetDamping(2, 1)
            local height = GetEntityHeightAboveGround(ped:GetEntity())
            local speed = Vector3Math:Length(ped:GetVelocity())
            if ped:IsSliding() 
            or speed < 5 
            or (GetEntityHeightAboveGround(ped:GetEntity()) < 0.3 and speed < 2) then
                ped:SetVelocity(vector3(0,0,0))
            end
            -- if ped:IsInWater() then
            --     ped:SetVelocity(ped:GetVelocity() + vector3(0, 0, 10))
            -- end
        end
    end)

end

function cGranitePassMapMod:Unload()
    self.active = false
end
