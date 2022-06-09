GamePlayUI = class()

function GamePlayUI:__init()
    self.ui = UI:Create({name = "gameplayui", path = "gameplay/client/ui/html/index.html", visible = false})
    self.scoreboard = UI:Create({name = "scoreboard", path = "gameplay/client/ui/html/scoreboard.html", visible = false})

    self.scoreboard_control = IsRedM and Control.CreatorMenuToggle or Control.FrontendLeaderboard

    if IsRedM then
        HUD:HideComponent(HudComponent.everything)
    elseif IsFiveM then
        HUD:SetVisible(false)
    end

    HUD:SetDisplayRadar(false)

    self:HandleScoreboardKeypresses()

    self.ui:Subscribe('game/ready', function(args) self:UIReady() end)
    self.scoreboard:Subscribe('game/ready', function(args) self:UIReady() end)

    Events:Subscribe("PlayerNetworkValueChanged", function(args) self:PlayerNetworkValueChanged(args) end)
    
end

function GamePlayUI:PlayerNetworkValueChanged(args)

    if LocalPlayer:IsPlayer(args.player) and args.name == "Points" and args.old_val then
        self.ui:CallEvent('golf/ui/update_points', {new_points = args.val, old_points = args.old_val})
    end

end

function GamePlayUI:HandleScoreboardKeypresses()
    
    KeyPress:Subscribe(self.scoreboard_control)
        
    Events:Subscribe("KeyDown", function(args)
        if args.key == self.scoreboard_control and GameManager:GetIsGameInProgress() then
            self.scoreboard:Show()
            self.scoreboard:BringToFront()
        end
    end)

    Events:Subscribe("KeyUp", function(args)
        if args.key == self.scoreboard_control and GameManager:GetIsGameInProgress() then
            self.scoreboard:Hide()
            self.scoreboard:SendToBack()
        end
    end)

end

function GamePlayUI:GetUI()
    return self.ui
end

function GamePlayUI:GameEnd(quit_game)
    Citizen.CreateThread(function()
        Citizen.Wait(quit_game and 500 or 5000)
        BlackScreen:Show(1000)
        IconManager:Clear()
        PowerupManager:EndAllPowerups()

        Citizen.Wait(1000)
        self.ui:Hide()
        self:ShowFinish()
        IconManager:Clear()

        Citizen.Wait(quit_game and 3000 or 10000)
        self:HideFinish()

        Citizen.Wait(1000)
        LobbyManager:Reset()
        BlackScreen:Hide(1000)

        Citizen.Wait(1000)
        LobbyManager:GetUI():BringToFront()
    end)

end

function GamePlayUI:UIReady()
    self.ui:CallEvent('golf/ui/set_my_id', {id = LocalPlayer:GetUniqueId()})
    self.scoreboard:CallEvent('golf/ui/set_my_id', {id = LocalPlayer:GetUniqueId()})
end

function GamePlayUI:ShowFinish()
    Citizen.CreateThread(function()
        Citizen.Wait(250)
        self.scoreboard:BringToFront()
        self.scoreboard:Show()
    end)
end

function GamePlayUI:HideFinish()
    self.scoreboard:SendToBack()
    self.scoreboard:Hide()
end

-- Called when the player joins a game
function GamePlayUI:GameStart()
    self:UpdatePoints()
    self:SetIngame()
    if not shGameplayConfig.ScreenshotMode then
        self.ui:Show()
    end
    self.ui:SendToBack()

    for powerup_enum, _ in pairs(PowerupManager.active_powerups) do
        PowerupManager:ActivatePowerup({type = powerup_enum})

        local data = deepcopy(shGameplayConfig.PowerupData[powerup_enum])
        data.type = powerup_enum
        data.charges = data.maxCharges
        data.duration = nil -- Remove duration here so it doesn't start counting down
        self:AddPowerup(data)
    end
    
    self.ui:CallEvent('gameplayui/game/difficulty', {difficulty = GameManager.map.difficulty})
end

function GamePlayUI:StartSpectating(args)
    self.ui:CallEvent('gameplayui/spectate/show', {
        name = is_class_instance(args.player, Player) and (args.player:GetName()) or ("Actor" .. tostring(args.player:GetUniqueId()))
    })
end

function GamePlayUI:SetPower(power_percent)
    self.ui:CallEvent('gameplayui/power/set', {power_percent = power_percent})
end

function GamePlayUI:UpdateScores(args)

    -- Populate names for the scoreboard
    args.names = {}

    for player_unique_id, current_hole in pairs(args.current_holes) do
        local player = cPlayers:GetByUniqueId(player_unique_id)
        if player then
            args.names[player_unique_id] = player:GetName()
        end
    end

    self.ui:CallEvent('golf/ui/update_scores', args)
    self.scoreboard:CallEvent('golf/ui/update_scores', args)
end

function GamePlayUI:StopSpectating()
    self.ui:CallEvent('gameplayui/spectate/hide')
end

function GamePlayUI:ActivatePowerup(name)
    self.ui:CallEvent('gameplayui/powerup/activate', {name = name})
end

function GamePlayUI:AddPowerup(args)
    self.ui:CallEvent('gameplayui/powerup/add', args)
end

function GamePlayUI:ModifyPowerup(args)
    self.ui:CallEvent('gameplayui/powerup/modify', args)
end

function GamePlayUI:SetIngame()
    local data = {
        difficulty = DifficultyEnum:GetDescription(GameManager.map_data.difficulty),
        name = GameManager.map_data.name,
        num_holes = count_table(GameManager.map_data.holes),
        map_data = GameManager.map_data
    }
    self.ui:CallEvent('golf/ui/set_ingame', data)
    self.scoreboard:CallEvent('golf/ui/set_ingame', data)
end

function GamePlayUI:UpdateCurrentHole(hole)
    self.ui:CallEvent('golf/ui/update_current_hole', {hole = hole})
end

function GamePlayUI:UpdateStrokes(strokes)
    self.ui:CallEvent('golf/ui/update_strokes', {strokes = strokes})
end

function GamePlayUI:UpdatePoints()
    self.ui:CallEvent('gameplayui/update_points', {points = GameManager:GetPoints()})
end

function GamePlayUI:UpdateRound()
    --self.ui:CallEvent('gameplayui/update_round', {round = GameManager:GetCurrentRound()})
end

GamePlayUI = GamePlayUI()