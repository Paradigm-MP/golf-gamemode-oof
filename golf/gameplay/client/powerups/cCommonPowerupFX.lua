CommonPowerupFX = class()

function CommonPowerupFX:__init()

    Network:Subscribe("gameplay/powerups/powerup_activated", function(args)
        self:Activate(args.position)
    end)
end

function CommonPowerupFX:Activate(position, is_local)
    if is_local then
        local fx_to_play = IsFiveM and "RaceTurbo" or "PlayerHealthCrackpot"
        AnimPostFX:Play(fx_to_play)
    
        Citizen.CreateThread(function()
            Wait(500)
            AnimPostFX:Stop(fx_to_play)
        end)
    end

    local markers = {}
    local num_markers = 5

    for i = 1, num_markers do
        local marker = Marker({
            type = MarkerTypes.DebugSphere,
            position = position,
            direction = vector3(0, 0, 0),
            rotation = vector3(0,0,0),
            scale = vector3(0, 0, 0),
            color = Color:FromHSV(math.random() * 0.1 + 0.65, 0.7 + math.random() * 0.3, 0.5 + math.random() * 0.5, 0.4 * math.random()),
        })
        marker:FadeOut()
        table.insert(markers, marker)
    end

    local delta = 0
    local render = Events:Subscribe("Render", function(args)
        -- local pos = LocalPlayer:GetPosition()
        for index, marker in ipairs(markers) do
            local scale = math.max(0, delta * 0.6 - index) * 0.3
            marker.scale = vector3(scale, scale, scale)
            -- marker.position = pos
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

CommonPowerupFX = CommonPowerupFX()