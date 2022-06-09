AirJordansPowerup = class()

function AirJordansPowerup:__init()
    self.type = PowerupTypesEnum.AirJordans
    self.active = false
    self.control = Control.Cover
    self.cooldown_time = 3
    self.cooldown = Timer()
    self.active_id = -1

    -- Inputs that trigger velocity changes
    self.current_input = 0
    
    self.move_inputs = 
    {
        [Control.MoveUpOnly] = 1,
        [Control.MoveDownOnly] = -1
    }
end

function AirJordansPowerup:GetActiveId()
    return self.active_id
end

function AirJordansPowerup:StartUsing()

    local markers = {
        {
            marker = Marker({
                type = MarkerTypes.DebugSphere,
                position = vector3(0, 0, 0),
                direction = vector3(0, 0, 0),
                rotation = vector3(0,0,0),
                scale = vector3(0.25, 0.25, 0.25),
                color = Color:FromHSV(0.65, 0.8, 0.7, 0.3),
            }),
            bone_name = IsRedM and "skel_r_foot" or "SKEL_R_Foot"
        },
        {
            marker = Marker({
                type = MarkerTypes.DebugSphere,
                position = vector3(0, 0, 0),
                direction = vector3(0, 0, 0),
                rotation = vector3(0,0,0),
                scale = vector3(0.25, 0.25, 0.25),
                color = Color:FromHSV(0.65, 0.8, 0.7, 0.3),
            }),
            bone_name = IsRedM and "skel_l_foot" or "SKEL_L_Foot"
        }
    }

    self.render = Events:Subscribe("Render", function(args)
        local ped = LocalPlayer:GetPed()
        for _, data in pairs(markers) do
            if IsRedM then
                data.marker.position = ped:GetEntityBonePosition(data.bone_name)
            else
                data.marker.position = ped:GetBonePositionByName(data.bone_name)
            end
        end
    end)

    for control, vector in pairs(self.move_inputs) do
        KeyPress:Subscribe(control)
    end

    self.control_keypress = Events:Subscribe("KeyPress", function(args)
        if self.move_inputs[args.key] then
            self.current_input = self.current_input + self.move_inputs[args.key]
        end
    end)

    Citizen.CreateThread(function()
        while self.activated do
            if Vector3Math:Length(LocalPlayer:GetPed():GetVelocity()) > 5 and self.current_input ~= 0 then
                LocalPlayer:GetPed():SetVelocity(LocalPlayer:GetPed():GetVelocity() + Camera:GetRotation() * self.current_input * 0.15)
            end
            self.current_input = 0
            Wait(50)
        end
    end)

    Citizen.CreateThread(function()
        Wait(self.cooldown_time * 1000)
        for _, marker in pairs(markers) do
            marker.marker:Remove()
        end
        self:StopUsing()
    end)
end

function AirJordansPowerup:StopUsing()
    self.activated = false
    self.render:Unsubscribe()
    self.control_keypress:Unsubscribe()

    for control, vector in pairs(self.move_inputs) do
        KeyPress:Unsubscribe(control)
    end

end

-- Activates a powerup 
function AirJordansPowerup:Activate(args)

    self.active = true
    self.activated = false
    self.charges = shGameplayConfig.PowerupData[self.type].maxCharges

    if IsRedM then
        KeyPress:Subscribe(self.control)
    end

    self.keypress = Events:Subscribe("KeyUp", function(args) self:KeyUp(args) end)
    
end

function AirJordansPowerup:CanUse()
    return not Ufo:IsActive() and 
        self.cooldown:GetSeconds() > self.cooldown_time and self.charges > 0
end

function AirJordansPowerup:KeyUp(args)
    if not self.active then return end

    if args.key == self.control and self:CanUse() then
        self:StartUsing()
    end
end

function AirJordansPowerup:KeyPressed()
    if not self.active then return end
    if not self:CanUse() then return end

    self.charges = self.charges - 1
    self.activated = true
    self.cooldown_time = shGameplayConfig.PowerupData[self.type].duration
    GamePlayUI:ModifyPowerup({
        type = self.type,
        duration = self.cooldown_time,
        charges = self.charges
    })
    self.cooldown:Restart()
    CommonPowerupFX:Activate(LocalPlayer:GetPosition(), true)

    self:StartUsing()

end

-- Ends a powerup if it is an ongoing effect
function AirJordansPowerup:End(args)
    if not self.active then return -1 end

    self.active = false
    self.activated = false
    self.charges = 0
    GamePlayUI:ModifyPowerup({
        type = self.type,
        charges = self.charges,
        remove = true
    })
    
    KeyPress:Unsubscribe(self.control)
    self.keypress:Unsubscribe()
end