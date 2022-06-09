LobbyManager = class()

function LobbyManager:__init()

    Filter:Clear() -- Just in case there's a lingering filter
    self.ui = UI:Create({name = "lobby", path = "lobby/client/html/index.html"})
    self.cam_pos = 
    {
        start_pos = vector3(-1559, -1650, 233),
        end_pos = vector3(3721, 1292, 243)
    }

    Network:Subscribe("lobby/queue/sync/full", function(args) self:FullQueueSync(args) end)
    Network:Subscribe("lobby/map/sync/full", function(args) self:FullMapSync(args) end)
    Network:Subscribe("lobby/best_scores/sync", function(args) self:SyncBestScores(args) end)
    Network:Subscribe("lobby/highest_difficulty/sync", function(args) self:SyncHighestDifficulty(args) end)
    Network:Subscribe("lobby/queue/sync/single", function(args) self:SingleQueueSync(args) end)
    Network:Subscribe("lobby/players/sync/full", function(args) self:FullPlayersSync(args) end)
    Network:Subscribe("lobby/players/sync/single", function(args) self:SinglePlayerSync(args) end)
    Network:Subscribe("lobby/queue/sync/countdown", function(args) self:QueueCountdownSync(args) end)
    Network:Subscribe("lobby/queue/sync/countdown/all", function(args) self:QueueCountdownSyncAll(args) end)
    Network:Subscribe("lobby/queue/sync/game", function(args) self:QueueGameStatusSync(args) end)
    Network:Subscribe("shop/initial_sync", function(args) self:InitialShopSync(args) end)
    Network:Subscribe("gameplay/powerup/sync", function(args) self:PowerupsSync(args) end)

    Events:Subscribe("PlayerNetworkValueChanged", function(args) self:PlayerNetworkValueChanged(args) end)

    Events:Subscribe("LocalPlayerChat", function(args)
        if args.text == "/campos" then
            print(Camera:GetPosition())
        end
    end)

    self.ui:Subscribe('lobby/joinleavebutton', function(data)
        self:PressJoinLeaveButton(data)
    end)

    self.ui:Subscribe('lobby/readyupbutton', function()
        self:PressReadyButton()
    end)

    self.ui:Subscribe('lobby/joinexistinggame', function()
        self:JoinExistingGameButton()
    end)

    self.ui:Subscribe('lobby/ready', function()
        self:UIReady()
    end)

    self.ui:Subscribe('lobby/esc', function()
        self:EscPressed()
    end)

    self.ui:Subscribe('lobby/shop/equip_item', function(args)
        self:PressEquipItemButton(args)
    end)

    self.ui:Subscribe('lobby/shop/buy_item', function(args)
        self:PressBuyItemButton(args)
    end)

    self.ui:Subscribe('lobby/select_locked_map', function(data)
        self:SelectLockedMap(data)
    end)

    self.ui:Subscribe('lobby/mapselected', function()
        Sounds:PlaySound({
            name = "select_course",
            volume = 0.1
        })
    end)

    if IsRedM then
        -- TODO: fix for fivem
        KeyPress:Subscribe(Control.FrontendPause)
        KeyPress:Subscribe(Control.FrontendPauseAlternate)
    end

    Events:Subscribe("KeyUp", function(args) self:KeyUp(args) end)

end

function LobbyManager:InitialShopSync(args)

    local skins = {}
    for k,v in pairs(args.data.skins) do
        skins[tostring(k)] = v
    end

    local powerups = {}
    for k,v in pairs(args.data.powerups) do
        powerups[tostring(k)] = v
    end

    args.data.skins = skins
    args.data.powerups = powerups

    self.ui:CallEvent("lobby/shop/sync/shop_items", args.data)
    
    -- In case model is synced before UI is ready
    if LocalPlayer:GetPlayer():GetValue("Model") then
        self:PlayerNetworkValueChanged({
            name = "Model",
            player = LocalPlayer:GetPlayer(),
            val = LocalPlayer:GetPlayer():GetValue("Model")
        })
    end

end

function LobbyManager:PowerupsSync(args)
    self.ui:CallEvent("lobby/shop/sync/network_val_changed", {name = "ActivePowerups", val = args.active_powerups})
end

function LobbyManager:PlayerNetworkValueChanged(args)
    if not LocalPlayer:IsPlayer(args.player) then return end

    if args.name == "Points" or args.name == "BoughtShopItems" or args.name == "Model" 
    or args.name == "Powerups" or args.name == "ActivePowerups" then
        local data = {name = args.name, val = args.val}
        if old_val ~= nil then data.old_val = args.old_val end

        self.ui:CallEvent("lobby/shop/sync/network_val_changed", data)
    end
end

function LobbyManager:PressEquipItemButton(args)
    Sounds:PlaySound({
        name = "purchase_item",
        volume = 0.4
    })
    Network:Send("shop/equip_item", {id = args.id, type = args.type})
end

function LobbyManager:PressBuyItemButton(args)
    Sounds:PlaySound({
        name = "purchase_item",
        volume = 0.4
    })
    Network:Send("shop/buy_item", {id = args.id, type = args.type})
end

function LobbyManager:SelectLockedMap(args)
    Sounds:PlaySound({
        name = "select_locked_course",
        volume = 0.4
    })
    Tips:ShowTip("Map Locked", "Score better than par on 3 courses from the previous difficulty to unlock the courses in this difficulty")
end

function LobbyManager:KeyUp(args)
    if args.key == Control.FrontendPauseAlternate or args.key == Control.FrontendPause then
        self:EscPressed()
    end
end

function LobbyManager:EscPressed()
    if self.ui:GetVisible() then
        self.ui:Hide()
        UI:SetCursor(false)
        --UI:SetFocus(false)
    elseif not GameManager:GetIsGameInProgress() then
        Citizen.CreateThread(function()
            Wait(100)
            if not PauseMenu:IsActive() and not self.ui:GetVisible() then
                self.ui:Show()
                UI:SetCursor(true)
                UI:SetFocus(true)
            end
        end)
    end
end

function LobbyManager:SetCameraPosition()
    RequestCollisionAtCoord(self.cam_pos.start_pos.x, self.cam_pos.start_pos.y, self.cam_pos.start_pos.z)

    local rotation = vector3(-10,0,-50)
    Camera:InterpolateBetween(
        self.cam_pos.start_pos,
        self.cam_pos.end_pos,
        rotation,
        rotation,
        1000 * 60 * 15
    )

end

function LobbyManager:GetUI()
    return self.ui
end

function LobbyManager:QueueGameStatusSync(args)
    self.ui:CallEvent("lobby/queue/sync/game", args)
end

function LobbyManager:QueueCountdownSync(args)
    self.ui:CallEvent("lobby/queue/sync/countdown", args)
end

function LobbyManager:QueueCountdownSyncAll(args)
    self.ui:CallEvent("lobby/queue/sync/countdown/all", args)
end

-- When the player clicks on JOIN GAME for a game that's already going
function LobbyManager:JoinExistingGameButton()
    Network:Send('lobby/queue/sync/joinexistinggame')
end

function LobbyManager:UIReady()
    Network:Send("lobby/maps/sync/ready")
    self:Reset()
    self:GetUI():BringToFront()
    
    -- Bring to front again to go over chat
    Citizen.SetTimeout(1000, function()
        self:GetUI():BringToFront()
    end)
end

-- Resets the UI on load or after a game
function LobbyManager:Reset()
    if not self.ui:GetVisible() then
        self.ui:Show()
    end

    NetworkSetInSpectatorMode(0, 0)

    LocalPlayer:GetPlayer():Freeze(true)
    World:SetTime(12, 0, 0)

    Camera:Reset()
    self:SetCameraPosition()

    -- Must spawn player in order to load world around them for the camera
    LocalPlayer:Spawn({
        pos = self.cam_pos.start_pos - vector3(0, 0, 30),
        model = "Player_Zero",
        callback = function() 
            LocalPlayer:GetPlayer():Freeze(true)
        end
    })

    World:SetWeather(IsRedM and "SUNNY" or "EXTRASUNNY")

    UI:SetCursor(true)
    UI:SetFocus(true)
    -- Blur background
    Filter:Apply({
        name = "hud_def_blur",
        amount = 1
    })
end

function LobbyManager:PressReadyButton()
    Sounds:PlaySound({
        name = "ready",
        volume = 0.4
    })
    Network:Send("lobby/queue/sync/ready")
end

function LobbyManager:PressJoinLeaveButton(data)
    if data.joined then
        Sounds:PlaySound({
            name = "join_course",
            volume = 0.4
        })
    else
        Sounds:PlaySound({
            name = "cancel",
            volume = 0.4
        })
    end


    local joined = data.joined
    data.joined = nil
    data.course_enum = tonumber(data.course_enum)

    if joined then
        Network:Send("lobby/queue/sync/join", data)
    else
        Network:Send("lobby/queue/sync/leave")
    end
end

function LobbyManager:SinglePlayerSync(args)
    self.ui:CallEvent("lobby/players/sync/single", args)
end

function LobbyManager:FullPlayersSync(args)
    self.players = args
    self.ui:CallEvent("lobby/players/sync/full", args)
end

function LobbyManager:FullQueueSync(args)
    self.queue = args
    self.ui:CallEvent("lobby/queue/sync/full", args)
end

function LobbyManager:SyncBestScores(args)
    self.best_scores = args
    self.ui:CallEvent("lobby/best_scores/sync", args)
end

function LobbyManager:SyncHighestDifficulty(args)
    self.highest_difficulty_unlocked = args.highest_difficulty_unlocked
    self.ui:CallEvent("lobby/highest_difficulty/sync", {highest_difficulty_unlocked = args.highest_difficulty_unlocked})

    if args.alert_user then
        local difficulty_name = DifficultyEnum:GetDescription(args.highest_difficulty_unlocked)
        Tips:ShowTip("New Difficulty Unlocked!", "You unlocked the '" .. difficulty_name .. "' difficulty!")
        Sounds:PlaySound({
            name = "new_difficulty_unlocked",
            volume = 0.6
        })
    end
end

function LobbyManager:GetMapData()
    return self.map_data
end

function LobbyManager:FullMapSync(args)
    self.map_data = args
    self.ui:CallEvent("lobby/map/sync/full", args)
end

function LobbyManager:SingleQueueSync(args)
    self.queue[args.course_enum][args.difficulty] = args.data
    self.ui:CallEvent("lobby/queue/sync/single", args)
end

LobbyManager = LobbyManager()