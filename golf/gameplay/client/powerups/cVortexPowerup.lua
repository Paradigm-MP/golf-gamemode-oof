VortexPowerup = class()

function VortexPowerup:__init()
    self.type = PowerupTypesEnum.Vortex
    self.active = false
    self.activated = false
    self.control = Control.Cover
    self.cooldown_time = 0
    self.range = 20
    self.cooldown = Timer()
    self.active_id = -1
end

function VortexPowerup:GetActiveId()
    return self.active_id
end

-- Activates a powerup 
function VortexPowerup:Activate(args)

    self.active = true
    self.activated = false
    self.charges = shGameplayConfig.PowerupData[self.type].maxCharges
    if IsRedM then
        KeyPress:Subscribe(self.control)
    end
    self.keypress = Events:Subscribe("KeyUp", function(args) self:KeyUp(args) end)
    
end

function VortexPowerup:CanUse()
    return self.cooldown:GetSeconds() > self.cooldown_time and self.charges > 0 and not self.activated
end

function VortexPowerup:KeyUp(args)
    if not self.active then return end

    if args.key == self.control and self:CanUse() then
        self:KeyPressed()
    end
end

function VortexPowerup:KeyPressed()
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
    self:CreateVortex()
    
    Citizen.CreateThread(function()
        Wait(self.cooldown_time * 1000 - 1300)
        self.activated = false
        -- Remove vortex
        for _, marker in ipairs(self.markers) do
            marker:Remove()
        end
        self.markers = {}
        self.render:Unsubscribe()
    end)
end

function VortexPowerup:CreateVortex()
    local vortex_position = LocalPlayerBehaviors.DetectHoleBehavior.current_hole_position
    local hole_num = LocalPlayerBehaviors.DetectHoleBehavior.current_hole

    self.markers = {}

    for i = 1, 5 do
        local marker = Marker({
            type = MarkerTypes.DebugSphere,
            position = vortex_position,
            direction = vector3(0, 0, 0),
            rotation = vector3(0,0,0),
            scale = vector3(0, 0, 0),
            color = Color:FromHSV(math.random() * 0.1 + 0.65, 0.7 + math.random() * 0.3, 0.5 + math.random() * 0.5, 0.2 * math.random()),
        })
        table.insert(self.markers, marker)
    end

    Citizen.CreateThread(function()
        while self.activated do

            if hole_num ~= LocalPlayerBehaviors.DetectHoleBehavior.current_hole then
                hole_num = LocalPlayerBehaviors.DetectHoleBehavior.current_hole
                vortex_position = LocalPlayerBehaviors.DetectHoleBehavior.current_hole_position

                for _, marker in pairs(self.markers) do
                    marker.position = vortex_position
                end
            end

            local diff = vortex_position - LocalPlayer:GetPosition()
            local len = Vector3Math:Length(diff)
            local dir = diff / len

            local force = ((self.range - len) / self.range) * 2

            if force > 0.2 then
                LocalPlayer:GetPed():SetVelocity(LocalPlayer:GetPed():GetVelocity() + dir * force)
            end

            Wait(50)

        end

    end)

    local delta = 0
    local num_markers = count_table(self.markers)
    self.render = Events:Subscribe("Render", function(args)
        for index, marker in ipairs(self.markers) do
            local d = (delta + index * self.range * 2) % (self.range / 0.1)
            local scale = 8 - d * 0.1
            marker.scale = vector3(scale, scale, scale)
        end
        delta = delta + 1
    end)

end

-- Ends a powerup if it is an ongoing effect
function VortexPowerup:End(args)
    if not self.active then return -1 end

    self.active = false
    self.charges = 0
    self.activated = false
    GamePlayUI:ModifyPowerup({
        type = self.type,
        charges = self.charges,
        remove = true
    })
    
    KeyPress:Unsubscribe(self.control)
    self.keypress:Unsubscribe()
end