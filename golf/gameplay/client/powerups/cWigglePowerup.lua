WigglePowerup = class()

function WigglePowerup:__init()
    self.type = PowerupTypesEnum.Wiggle
    self.active = false
    self.control = Control.Cover
    self.cooldown_time = 3
    self.cooldown = Timer()
    self.active_id = -1
end

function WigglePowerup:GetActiveId()
    return self.active_id
end

-- Activates a powerup 
function WigglePowerup:Activate(args)

    self.active = true
    KeyPress:Subscribe(self.control)
    self.keypress = Events:Subscribe("KeyUp", function(args) self:KeyUp(args) end)
    
end

function WigglePowerup:CanUse()
    return Vector3Math:Length(LocalPlayer:GetPed():GetVelocity()) < 3 and
        not Ufo:IsActive() and 
        self.cooldown:GetSeconds() > self.cooldown_time
end

function WigglePowerup:KeyUp(args)
    if not self.active then return end

    if args.key == self.control and self:CanUse() then
        LocalPlayer:GetPed():SetVelocity(vector3(math.random(-7,7), math.random(5,10), math.random(-7,7)))
        GamePlayUI:ModifyPowerup({
            type = self.type,
            duration = self.cooldown_time
        })
        CommonPowerupFX:Activate(LocalPlayer:GetPosition(), true)
        self.cooldown:Restart()
    end
end

-- Ends a powerup if it is an ongoing effect
function WigglePowerup:End(args)
    if not self.active then return -1 end

    self.active = false
    self.charges = 0
    GamePlayUI:ModifyPowerup({
        type = self.type,
        charges = self.charges,
        remove = true
    })
    
    KeyPress:Unsubscribe(self.control)
    self.keypress:Unsubscribe()
end