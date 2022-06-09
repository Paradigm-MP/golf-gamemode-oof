DetectHoleBehavior = class()

function DetectHoleBehavior:__init()
    self.current_hole = 1

    self.current_hole_marker = Marker({
        type = MarkerTypes.VerticalCylinder,
        position = vector3(0, 0, 0),
        direction = vector3(0, 0, 0),
        rotation = vector3(0, 0, 0),
        scale = vector3(1, 1, 500),
        color = Color(0, 255, 0, not shGameplayConfig.ScreenshotMode and 30 or 0)
    })
    self.current_hole_marker:SetVisible(false)

    self.hole_fx_marker_colors = 
    {
        Color(255, 0, 0, 150),
        Color(255, 121, 0, 150),
        Color(255, 255, 0, 150),
        Color(0, 255, 0, 150),
        Color(0, 255, 255, 150),
        Color(0, 0, 255, 150),
        Color(255, 0, 255, 150)
    }

    self:SubscribeToNetworkEvents()
    self:DetectHoleThread()

    Events:Subscribe("GameEnd", self, self.GameEnd)
end

function DetectHoleBehavior:GameEnd()
    self.current_hole_marker:SetVisible(false)
end

function DetectHoleBehavior:SubscribeToNetworkEvents()
    Network:Subscribe("game/sync/current_hole", function(args) self:CurrentHoleSync(args) end)
end

function DetectHoleBehavior:CurrentHoleSync(args)
    self.current_hole = args.current_hole
    
    if self.current_hole <= GameManager:GetNumHoles() then
        self.current_hole_position = GameManager:GetHolePosition(self.current_hole)
        self.current_hole_size = GameManager:GetHoleSize(self.current_hole)
    else
        self.current_hole_position = vector3(0, 0, -1000)
        self.current_hole_size = 0
    end

    self.current_hole_marker.position = self.current_hole_position

    self:CreateDetectionVolume()

    GamePlayUI:UpdateCurrentHole(self.current_hole)
    GameManager:SetCurrentHole(self.current_hole)
    self.current_hole_marker:SetVisible(true)

    -- Chat:Debug("Set Current Hole to: " .. tostring(self.current_hole))

end

function DetectHoleBehavior:CreateDetectionVolume()

    local hole_size_powerup = PowerupManager.powerup_behaviors[PowerupTypesEnum.IncreaseHoleSize]
    self.size = hole_size_powerup.activated and self.current_hole_size + hole_size_powerup.size_addition or self.current_hole_size

end

function DetectHoleBehavior:CreateHoleEffects(position)

    World:SetTimeScale(0.2)
    local fx_to_play = IsRedM and "RespawnPulse01" or "MP_Celeb_Win"
    AnimPostFX:Play(fx_to_play)

    Citizen.CreateThread(function()
        Wait(150)
        World:SetTimeScale(1.0)
        Wait(100)
        AnimPostFX:Stop(fx_to_play)
    end)

    local markers = {}

    for _, color in ipairs(self.hole_fx_marker_colors) do
        local marker = Marker({
            type = MarkerTypes.DebugSphere,
            position = position,
            direction = vector3(0, 0, 0),
            rotation = vector3(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180)),
            scale = vector3(0, 0, 0),
            color = color,
            is_rotating = true
        })
        marker:FadeOut()
        table.insert(markers, marker)
    end

    local delta = 0
    local render = Events:Subscribe("Render", function(args)
        local pos = LocalPlayer:GetPosition()
        for index, marker in ipairs(markers) do
            local scale = math.max(0, delta * 0.6 - index) / 4
            marker.scale = vector3(scale, scale, 3)
            marker.position = pos
        end
        delta = delta + 1
    end)

    Citizen.CreateThread(function()
        Wait(5000)
        for _, marker in ipairs(markers) do
            marker:Remove()
        end
        render:Unsubscribe()
    end)

end

function DetectHoleBehavior:DetectHoleThread()
    Citizen.CreateThread(function()
        while true do
            if GameManager:GetIsGameInProgress() and self.current_hole <= GameManager:GetHoleCount() and not Ufo:IsActive() then
                self:HoleDetection()
            end
            Wait(50)
        end
    end)
end

function DetectHoleBehavior:HoleDetection()
    --print("entered hole detection with current hole: ", self.current_hole)
    --print("next hole position: ", self.current_hole_position)
    if Vector3Math:Distance(LocalPlayer:GetPosition(), self.current_hole_position) < self.size then
        Network:Send("game/scored_hole" .. tostring(GameManager:GetGameId()), {
            hole = self.current_hole
        })

        -- Create fireworks because they got a hole!
        Sounds:PlaySound({name = "got_hole", volume = 0.5})
        self:CreateHoleEffects(LocalPlayer:GetPosition())
        Events:Fire("SetPlayerSafePosition", {position = self.current_hole_position + vector3(0, 0, 1)})

        -- Under par
        if PlayerLauncher.local_num_strokes <= GameManager.map_data.holes[self.current_hole].par then
            Sounds:PlaySound({name = "under_par_claps", volume = 0.3})
        end

        PlayerLauncher.local_num_strokes = 0

        -- overriden by server sync, but we want to prevent syncing this multiple times
        self.current_hole = self.current_hole + 1
        if self.current_hole <= GameManager:GetHoleCount() then
            self.current_hole_position = GameManager:GetHolePosition(self.current_hole)
            self.current_hole_size = GameManager:GetHoleSize(self.current_hole)
            self:CreateDetectionVolume()
        end
    end
    --Chat:Debug("distance to hole: " .. tostring(dist))
end