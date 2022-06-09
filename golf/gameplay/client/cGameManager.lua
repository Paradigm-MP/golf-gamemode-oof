GameManager = class()

function GameManager:__init()
    -- boolean whether a game is currently in progress or not
    getter_setter(self, "is_game_in_progress") -- declares GameManager:GetIsGameInProgress() and GameManager:SetIsGameInProgress() for self.game_in_progress
    GameManager:SetIsGameInProgress(false)
    getter_setter(self, "game_id")
    getter_setter(self, "course_enum")
    getter_setter(self, "hole_count")
    getter_setter(self, "enable_ragdoll_reset")
    self.enable_ragdoll_reset = true

    self.points = 0
    self.round = 1
    self.current_hole = 1
    self.hole_count = -1

    self.scores = {}

    if IsRedM then
        -- Preload all player models
        RequestModel(GetHashKey("Player_Zero"))
        RequestModel(GetHashKey("mp_female"))
        RequestModel(GetHashKey("mp_male"))
        RequestModel(GetHashKey("Player_Three"))
    end

    if IsRedM then
        Imap:LoadValentine()
    end

    self.objects = {}
    self.hole_objects = {}
    self.markers = {}
    self.lights = {}

    Events:Subscribe("LocalPlayerDied", function(args) self:LocalPlayerDied(args) end)
    Events:Subscribe("LocalPlayerSpawn", function(args) self:LocalPlayerSpawn(args) end)
    Events:Subscribe("LocalPlayerChat", function(args) self:LocalPlayerChat(args) end)
    Events:Subscribe("PlayerQuit", function(args) self:PlayerQuit(args) end)
    Events:Subscribe("PlayerNetworkValueChanged", function(args) self:PlayerNetworkValueChanged(args) end)
    Events:Subscribe("Render", function(args) self:Render(args) end)

    Network:Subscribe("game/sync/start", function(args) self:StartGame(args) end)
    Network:Subscribe("game/sync/end", function() self:EndGame() end)
    Network:Subscribe("game/sync/quit", function() self:QuitGame() end)
    Network:Subscribe("game/sync/update_round", function(args) self:SyncNewRound(args) end)
    Network:Subscribe("gameplay/sync/respawn", function() self:Respawn() end)
    Network:Subscribe("game/sync/score_sync", function(args) self:ScoreSync(args) end)

    if IsTest then
        Events:Subscribe("LocalPlayerChat", function(args)
            if args.text == "/pos" then
                local pos = LocalPlayer:GetPosition()
                print(string.format("\"x\": %.4f, \"y\": %.4f, \"z\": %.4f", pos.x, pos.y, pos.z))
            end
        end)
    end

end

function GameManager:ScoreSync(args)

    self.scores = args

    local local_id = LocalPlayer:GetUniqueId()

    GamePlayUI:UpdateScores(self.scores)
end

function GameManager:PlayerNetworkValueChanged(args)
    -- Sync game money
    if LocalPlayer:IsPlayer(args.player) and args.name == "GameMoney" then
        self:SyncPoints({points = args.val})
    end
end

function GameManager:SyncPoints(args)
    self.points = args.points
    GamePlayUI:UpdatePoints()
end

function GameManager:SyncNewRound(args)
    if not self:GetIsGameInProgress() then return end

    self:RefreshNametags()

    self.round = args.round

    GamePlayUI:UpdateRound(true)

    Events:Fire("NewRound", {
        round_number = self.round,
        wave_type = self.wave_type
    })
end

-- Called when the game ends
function GameManager:EndGame()
    self:GameEnded()
end

function GameManager:GameEnded(quit_game)

    if not self:GetIsGameInProgress() then return end
    cMapModManager:OnGameEnd()

    Citizen.CreateThread(function()
        self:SetIsGameInProgress(false)
    
        if SpectateMode:GetIsSpectating() then
            SpectateMode:StopSpectating({respawn = false})
        end
    
        LocalPlayer:GetPed():RemoveAllWeapons()
    
        for _, object in pairs(self.objects) do
            object:Destroy()
        end

        for _, object in pairs(self.hole_objects) do
            object:Destroy()
        end

        for _, marker in pairs(self.markers) do
            marker:Remove()
        end

        self.markers = {}
        self.objects = {}
        self.hole_objects = {}
    
        GamePlayUI:GameEnd(quit_game) -- Let GamePlayUI handle the UI
    
        Events:Fire("GameEnd")
    end)

end

function GameManager:QuitGame()
    self:GameEnded(true)
end

function GameManager:GetPoints()
    return self.points
end

function GameManager:GetCurrentRound()
    return self.round
end

function GameManager:GetHolePosition(hole_number)
    local pos
    if hole_number == 0 then
        pos = self.map_data.playerSpawnPoints[1].pos
    else
        pos = self.map_data.holes[hole_number].pos
    end
    return vector3(pos.x, pos.y, pos.z)
end

function GameManager:GetHoleSize(hole_number)
    return self.map_data.holes[hole_number].size
end

function GameManager:GetNumHoles()
    return count_table(self.map_data.holes)
end

function GameManager:RefreshNametags()
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        for id, player in pairs(cPlayers:GetPlayers()) do
            if not LocalPlayer:IsPlayer(player) then
                CreateMpGamerTag(player:GetPlayerId(), player:GetName(), false, false, "")
            end
        end
    end)
end


-- Called by the server when a player joins a game (or a game just started and they were ready)
function GameManager:StartGame(args)
    self.course_enum = args.course_enum
    self.game_id = args.game_id
    self.hole_count = args.hole_count
    -- Hide ui
    UI:SetCursor(false)
    UI:SetFocus(false)

    BlackScreen:Show()
    LobbyManager:GetUI():Hide()

    if SpectateMode:GetIsSpectating() then
        SpectateMode:StopSpectating({respawn = false})
    end

    Sounds:PlaySound({
        name = "game_start",
        volume = 0.4
    })

    -- Store data
    self.map = 
    {
        name = args.mapname,
        difficulty = args.difficulty
    }
    self.map_data = LobbyManager:GetMapData()[args.course_enum]

    World:SetTime(self.map_data.time.hour, self.map_data.time.minute, 0)
    World:SetTimestepEnabled(self.map_data.timestepEnabled)
    World:SetWeather(self.map_data.weather)

    LocalPlayer:GetPed():RemoveAllWeapons()

    LocalPlayer:GetPlayer():Freeze(true)
    self:RefreshNametags()

    if shGameplayConfig.DisableGolfing then
        Citizen.InvokeNative(0x4B8F743A4A6D2FF8, true)
    end

    Filter:Clear()

    if self.map_data.filter then
        Filter:Apply({
            name = self.map_data.filter.name,
            amount = self.map_data.filter.amount
        })
    else
        if IsFiveM then
            Filter:Apply({
                name = "rply_saturation",
                amount = 0.05
            })
        end
    end

    local light = Light({
        position = LocalPlayer:GetPosition(),
        color = Colors.White,
        type = LightTypes.Point,
        shadow = false,
        range = 10,
        intensity = 5
    })

    cMapModManager:OnGameStart(args.course_enum)

    Events:Subscribe("Render", function()
        light:SetPosition(LocalPlayer:GetPosition() + vector3(0, 0, 2))
    end)

    self:SpawnHoleObjects()

    SetLocalPlayerCanUsePickupsWithThisModel(GetHashKey(LocalPlayer:GetPlayer():GetValue("Model")), false)
    PlayerLauncher:SetPower(0)
    self.current_hole = 1
    Events:Fire("SetPlayerSafePosition", {position = self:GetRandomPlayerSpawnPoint()})

    self:Respawn(function()
        Citizen.CreateThread(function()
            Citizen.Wait(1000)
            GamePlayUI:GameStart()
            LocalPlayer:GetPed():SetInvincible(true)
            LocalPlayer:GetPed():DisablePainAudio(true)
            self:StartRagdollLoop()
            self:StartRagdollMonitoring()
            Camera:Reset()
            Citizen.Wait(500)
            BlackScreen:Hide(2000)
        end)
    end)

    self:SetIsGameInProgress(true)
end

function GameManager:StartRagdollLoop()
    Citizen.CreateThread(function()
        if shGameplayConfig.DisableGolfing then return end
        
        local localplayer_ped
        while self:GetIsGameInProgress() do
            if self.enable_ragdoll_reset then
                localplayer_ped = LocalPlayer:GetPed()
                
                if not localplayer_ped:IsRagdoll() then
                    if IsRedM then
                        localplayer_ped:SetToRagdoll(-1, 1000, 1)
                    end
                    if IsFiveM then
                        localplayer_ped:SetToRagdoll(1000, 1000, 0)
                    end
                else
                    localplayer_ped:ResetRagdollTimer()
                end
            end
            -- Keep ped invincible
            LocalPlayer:GetPed():SetInvincible(true)
            Citizen.Wait(100)
        end
    end)
end

function GameManager:StartRagdollMonitoring()
    -- can we improve this?
    self.disable_ragdoll_timer = Timer()
    Citizen.CreateThread(function()
        while self:GetIsGameInProgress() do
            if not Ufo:IsActive() then
                if GameManager:GetEnableRagdollReset() then
                    local speed = Vector3Math:Length(LocalPlayer:GetPed():GetVelocity())
                    if speed < 0.15 then
                        local ang = LocalPlayer:GetPed():GetRotation()
                        if ang.x < -50 then
                            GameManager:SetEnableRagdollReset(false)
                            self.disable_ragdoll_timer:Restart()
                        end
                    end
                else
                    local ang = GetEntityRotation(LocalPlayer:GetPedId(), nil)
                    if self.disable_ragdoll_timer:GetSeconds() > 4 or ang.x > -50 then
                        GameManager:SetEnableRagdollReset(true)
                    end
                end
            end

            Wait(100)
        end
    end)
end

function GameManager:GetRandomPlayerSpawnPoint()
    local pos = self.map_data.playerSpawnPoints[math.random(#self.map_data.playerSpawnPoints)].pos
    return {x = pos.x + math.random(), y = pos.y + math.random(), z = pos.z + math.random() * 2}
end

function GameManager:Respawn(cb)
    local model_data_split = split(LocalPlayer:GetPlayer():GetValue("Model") or "", "|")
    local model = model_data_split[1]
    local outfit = tonumber(model_data_split[2])
    if outfit == nil then outfit = tonumber(split(model_data_split[2], ",")[1]) end
    LocalPlayer:Spawn({
        pos = self:GetRandomPlayerSpawnPoint(),
        model = model,
        callback = function()

            if cb then cb() end
            -- override health
            LocalPlayer:SetHealth(LocalPlayer.base_health)
            if IsRedM then
                LocalPlayer:GetPed():SetOutfitPreset(outfit)

                -- Continuously set outfit in case they have not loaded the model
                Citizen.CreateThread(function()
                    local timer = Timer()
                    while timer:GetSeconds() < 20 do
                        LocalPlayer:GetPed():SetOutfitPreset(outfit)
                        Citizen.Wait(1000)
                    end
                end)
            end


        end
    })

end

function GameManager:SpawnMapObjects()
    -- spawn all objects from self.map_data
    for _, object_data in pairs(self.map_data.objectSpawnPoints) do
        table.insert(self.objects, Object({
            model = object_data.model,
            rotation = vector3(object_data.rot.x, object_data.rot.y, object_data.rot.z),
            position = vector3(object_data.pos.x, object_data.pos.y, object_data.pos.z),
            kinematic = true,
            isNetwork = false,
            callback = function(object)
                self.objects[object:GetEntity()] = object
                if self.map_data.invisibleObjects[object_data.model] then
                    object:SetAlpha(0)
                end
            end
        }))
    end
end

function GameManager:SpawnHoleObjects()
    local color = shGameplayConfig.DifficultyColors[self.map.difficulty]
    local marker_color = Color(color.r, color.g, color.b, 20)

    for _, hole in pairs(self.map_data.holes) do
        local pos = vector3(hole.pos.x, hole.pos.y, hole.pos.z - 1)
        local size = hole.size

        table.insert(self.hole_objects,  Object({
            model = shGameplayConfig.HoleFlagpoleModal,
            rotation = vector3(0, 0, 0),
            position = pos,
            kinematic = true,
            isNetwork = false,
            callback = function(object)
                self.objects[object:GetEntity()] = object
            end
        }))

        table.insert(self.markers, Marker({
            type = MarkerTypes.VerticalCylinder,
            position = pos,
            direction = vector3(0, 0, 0),
            rotation = vector3(0, 0, 0),
            scale = vector3(size * 2, size * 2, 1),
            color = marker_color
        }))

        table.insert(self.lights, Light({
            position = pos + vector3(0, 0, 1),
            color = Colors.White,
            type = LightTypes.Point,
            shadow = false,
            range = 10,
            intensity = 8
        })
    )
    end
end

function GameManager:Render()
    for _, marker in pairs(self.markers) do
        marker:Draw()
    end

    if shGameplayConfig.ScreenshotMode then return end

    -- Disable collision of hole flags
    for _, object in pairs(self.hole_objects) do
        object:ToggleCollision(false)
    end

    if self:GetIsGameInProgress() and self.current_hole <= self.hole_count then
        local sprite_size = IsRedM and 0.03 or 0.02
        local ui_size = UI:GetSize()
        local ui_aspect_ratio = ui_size.x / ui_size.y
        local size = {x = sprite_size, y = sprite_size * ui_aspect_ratio}
        local hole_pos = self:GetHolePosition(self.current_hole)
        local pos_2d = Render:WorldToHud(hole_pos)

        local texture_dict = IsRedM and "generic_textures" or "golfputting"
        local texture_name = IsRedM and "medal_bronze" or "puttingmarker"
        
        -- Render next hole indicator
        if self.current_hole + 1 <= self.hole_count then
            local hole_pos_next = self:GetHolePosition(self.current_hole + 1)
            local pos_2d_next = Render:WorldToScreen(hole_pos_next)
            local alpha = 100

            Render:DrawSprite(
                pos_2d_next,
                {x = size.x * 0.9, y = size.y * 0.9},
                0,
                Color(255, 255, 255, alpha),
                texture_dict,
                texture_name
            )

            Render:DrawSprite(
                pos_2d_next,
                {x = size.x * 0.8, y = size.y * 0.8},
                0,
                Color(0, 155, 250, alpha),
                texture_dict,
                texture_name
            )
            
            -- if looking at it, draw "Next Hole"
            local diff = vector2(0.5, 0.5) - pos_2d_next
            local dist = math.sqrt(diff.x * diff.x + diff.y * diff.y)
            if dist < 0.09 then
                if IsRedM then
                    Render:DrawText(
                        pos_2d_next + vector2(0.02, -0.02),
                        "Next Hole",
                        Colors.White,
                        0.5,
                        true
                    )
                elseif IsFiveM then
                    Render:SetTextEdge(0.1, Colors.Black)
                    Render:DrawText(
                        pos_2d_next + vector2(0.02, -0.02),
                        "Next Hole",
                        Colors.White,
                        0.5,
                        0
                    )
                end
            end
        end

        Render:DrawSprite(
            pos_2d,
            {x = size.x * 1.1, y = size.y * 1.1},
            0,
            Color(255, 255, 255, 255),
            texture_dict,
            texture_name
        )

        Render:DrawSprite(
            pos_2d,
            size,
            0,
            Color(0, 200, 0, 255),
            texture_dict,
            texture_name
        )

        if IsRedM then
            Render:DrawText(
                pos_2d + vector2(0.02, -0.02),
                string.format("%.0fm", Vector3Math:Distance(LocalPlayer:GetPosition(), hole_pos)),
                Colors.White,
                0.5,
                true
            )
        elseif IsFiveM then
            Render:SetTextEdge(0.1, Colors.Black)
            Render:DrawText(
                pos_2d + vector2(0.02, -0.02),
                string.format("%.0fm", Vector3Math:Distance(LocalPlayer:GetPosition(), hole_pos)),
                Colors.White,
                0.5,
                0
            )
        end
    end
end

function GameManager:SetCurrentHole(hole)
    self.current_hole = hole
end

function GameManager:LocalPlayerDied(args)

end

function GameManager:LocalPlayerSpawn(args)
end

function GameManager:LocalPlayerChat(args)
    if args.text == "/quit" and GameManager:GetIsGameInProgress() then
        Network:Send("game/player_quit_request" .. tostring(self.game_id))
    end
end

function GameManager:GetAlivePlayers()
    local t = {}

    for id, player in pairs(cPlayers:GetPlayers()) do
        if player:GetValue("Alive") and not player:GetValue("Spectate") and not player:GetValue("Downed") then
            t[id] = player
        end
    end

    return t
end

function GameManager:PlayerQuit(args)

end

GameManager = GameManager()