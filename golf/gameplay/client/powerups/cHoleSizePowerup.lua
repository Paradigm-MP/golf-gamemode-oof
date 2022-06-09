HoleSizePowerup = class()

function HoleSizePowerup:__init()
    self.type = PowerupTypesEnum.IncreaseHoleSize
    self.active = false
    self.activated = false
    self.control = Control.Cover
    self.cooldown_time = 0
    self.size_addition = 4 -- How much bigger the holes get when this is used
    self.cooldown = Timer()
    self.active_id = -1
end

function HoleSizePowerup:GetActiveId()
    return self.active_id
end

-- Activates a powerup 
function HoleSizePowerup:Activate(args)

    self.active = true
    self.charges = shGameplayConfig.PowerupData[self.type].maxCharges
    KeyPress:Subscribe(self.control)
    self.keypress = Events:Subscribe("KeyUp", function(args) self:KeyUp(args) end)
    
end

function HoleSizePowerup:CanUse()
    return self.cooldown:GetSeconds() > self.cooldown_time and self.charges > 0 and not self.activated
end

function HoleSizePowerup:KeyUp(args)
    if not self.active then return end

    if args.key == self.control and self:CanUse() then
        self.charges = self.charges - 1
        self.activated = true
        self.cooldown_time = shGameplayConfig.PowerupData[self.type].duration
        self:ModifyHoleMarkerSizes()
        LocalPlayerBehaviors.DetectHoleBehavior:CreateDetectionVolume() -- Remake hole detection areas
        CommonPowerupFX:Activate(LocalPlayer:GetPosition(), true)
        GamePlayUI:ModifyPowerup({
            type = self.type,
            duration = self.cooldown_time,
            charges = self.charges
        })
        self.cooldown:Restart()

        Citizen.CreateThread(function()
            Wait(self.cooldown_time * 1000 - 1300)
            self.activated = false
            self:ModifyHoleMarkerSizes()
            LocalPlayerBehaviors.DetectHoleBehavior:CreateDetectionVolume() -- Remake hole detection areas
        end)
    end
end

function HoleSizePowerup:ModifyHoleMarkerSizes()
    local mod = self.activated and self.size_addition or -self.size_addition
    local add = vector3(mod, mod, mod)

    for _, marker in pairs(GameManager.markers) do
        marker.scale = marker.scale + add

        marker.color.a = self.activated and 40 or 20

        if self.activated then
            CommonPowerupFX:Activate(marker.position)
        end
    end

end

-- Ends a powerup if it is an ongoing effect
function HoleSizePowerup:End(args)
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