FreezePowerup = class()

function FreezePowerup:__init()
    self.type = PowerupTypesEnum.Freeze
    self.active = false
    self.control = Control.Cover
    self.cooldown_time = 0
    self.cooldown = Timer()
    self.active_id = -1
end

function FreezePowerup:GetActiveId()
    return self.active_id
end

-- Activates a powerup 
function FreezePowerup:Activate(args)

    self.charges = shGameplayConfig.PowerupData[self.type].maxCharges

    self.active = true
    KeyPress:Subscribe(self.control)
    self.keypress = Events:Subscribe("KeyUp", function(args) self:KeyUp(args) end)
    
end

function FreezePowerup:CanUse()
    return self.cooldown:GetSeconds() > self.cooldown_time and self.charges > 0
end

function FreezePowerup:KeyUp(args)
    if not self.active then return end

    if args.key == self.control and self:CanUse() then
        LocalPlayer:GetPed():SetVelocity(vector3(0,0,0))

        self.charges = self.charges - 1
        self.cooldown_time = 30
        GamePlayUI:ModifyPowerup({
            type = self.type,
            duration = self.cooldown_time,
            charges = self.charges
        })
        CommonPowerupFX:Activate(LocalPlayer:GetPosition(), true)
        self.cooldown:Restart()
    end
end

-- Ends a powerup if it is an ongoing effect
function FreezePowerup:End(args)
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