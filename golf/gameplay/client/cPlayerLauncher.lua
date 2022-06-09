PlayerLauncher = class()

function PlayerLauncher:__init()

    self.max_power = 100
    self.power = 0

    self.angle_offset = vector3(0, 0, 0)

    self.local_num_strokes = 0 -- Local version of number of strokes for current hole
    
    KeyPress:Subscribe(Control.Jump)
    KeyPress:Subscribe(Control.Attack)
    KeyPress:Subscribe(Control.Aim)

    Events:Subscribe('KeyUp', function(args)
        self:KeyUp(args)
    end)

    Events:Subscribe('KeyPress', function(args)
        self:KeyPress(args)
    end)

end

function PlayerLauncher:KeyPress(args)
    if not GameManager:GetIsGameInProgress() then return end

    if args.key == Control.Attack then
        self:ModifyPower(1)
    elseif args.key == Control.Aim then
        self:ModifyPower(-1)
    end

end

function PlayerLauncher:ModifyPower(dir)
    if not self:CanIncreasePower() then return end
    self:SetPower(self.power + dir * 0.3)
end

function PlayerLauncher:SetPower(power)
    local overflow_active = PowerupManager.powerup_behaviors[PowerupTypesEnum.Overflow].active
    local max = overflow_active and self.max_power * 2 or self.max_power
    self.power = math.max(0, math.min(max, power))
    GamePlayUI:SetPower(self.power / self.max_power)
end

function PlayerLauncher:KeyUp(args)
    if not GameManager:GetIsGameInProgress() then return end
    
    if args.key == Control.Jump then
        self:Fire()
        Camera:Reset()
    end
end

function PlayerLauncher:CanIncreasePower()
    return Vector3Math:Length(LocalPlayer:GetPed():GetVelocity()) < 1 and
        not Ufo:IsActive() and
        not LocalPlayer:GetPed():IsInWater()
end

-- Called to launch the player with specified power
function PlayerLauncher:Fire()

    if self.power < 1 then return end -- Not enough power, probably a misclick
    if not self:CanIncreasePower() then return end

    Network:Send("game/launch" .. tostring(GameManager:GetGameId()))

    Events:Fire("SetPlayerSafePosition", {position = LocalPlayer:GetPosition()})

    LocalPlayer:GetPed():SetDamping(0, 0.002)
    LocalPlayer:GetPed():SetDamping(1, 0.002)
    LocalPlayer:GetPed():SetDamping(2, 0.002)

    self.local_num_strokes = self.local_num_strokes + 1

    local velo = Camera:GetRotation() * self.power
    LocalPlayer:GetPed():SetVelocity(velo)

    LocalPlayerBehaviors.DetectInWaterBehavior.taken_a_shot = true

    -- Overflow shot
    if self.power > self.max_power then
        CommonPowerupFX:Activate(LocalPlayer:GetPosition(), true)
        
        Citizen.CreateThread(function()
            Wait(3000)
            if Vector3Math:Length(LocalPlayer:GetPed():GetVelocity()) > 25 then
                LocalPlayer:GetPed():SetVelocity(velo)
            end
        end)

    end

    Sounds:PlaySound({
        name = "stroke",
        volume = math.min(1, self.power / self.max_power)
    })
    self:SetPower(0)
    local fx_name = "PedKill"
    AnimPostFX:Play(fx_name)

    Citizen.CreateThread(function()

        Wait(200)
        if self.power > self.max_power then
            Sounds:PlaySound({
                name = "stroke",
                volume = math.min(1, self.power / self.max_power)
            })
        end

        Wait(300)
        AnimPostFX:Stop(fx_name)
    end)

end

PlayerLauncher = PlayerLauncher()