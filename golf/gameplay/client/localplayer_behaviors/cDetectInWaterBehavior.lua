DetectInWaterBehavior = class()

function DetectInWaterBehavior:__init()

    self.check_interval = 2 -- Check every X seconds
    self.in_water = false
    self.delta = 0
    self.last_safe_pos = vector3(0, 0, 0)

    Events:Subscribe("SecondTick", function() self:SecondTick() end)
    Events:Subscribe("SetPlayerSafePosition", function(args)
        self.last_safe_pos = args.position
    end)

end

function DetectInWaterBehavior:SecondTick()

    if not GameManager:GetIsGameInProgress() then return end

    self.delta = self.delta + 1

    if self.delta % 5 == 0 then
        self:RecordSafePosition()
    end

    if not LocalPlayer:GetPed():IsInWater() then
        self.in_water = false
        return
    end
    
    if self.delta % self.check_interval == 0 then

        if LocalPlayer:GetPed():IsInWater() then
            if self.in_water then
                self:ResetBackToLastSafePos()
                return
            end

            self.in_water = true
        end

    end

end

function DetectInWaterBehavior:RecordSafePosition()
    local local_ped = LocalPlayer:GetPed()
    if local_ped:IsInWater() then return end
    if Ufo:IsActive() then return end
    if Vector3Math:Length(local_ped:GetVelocity()) > 0.05 then return end

    self.last_safe_pos = LocalPlayer:GetPosition() + vector3(0, 0, 1)

end

function DetectInWaterBehavior:ResetBackToLastSafePos()
    if Ufo:IsActive() then return end
    self.in_water = false
    Ufo:Spawn(function()
        if not self.taken_a_shot then
            self.last_safe_pos = GameManager:GetHolePosition(GameManager.current_hole - 1) + vector3(0, 0, 1)
        end

        Ufo:TakePlayerToPosition(self.last_safe_pos)
        self.taken_a_shot = false

    end)
end