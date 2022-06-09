GameManager = class()

function GameManager:__init()
    -- boolean whether a game is currently in progress or not
    getter_setter(self, "is_game_in_progress") -- declares GameManager:GetIsGameInProgress() and GameManager:SetIsGameInProgress() for self.game_in_progress
    GameManager:SetIsGameInProgress(false)

    self.games = {}
    self.games_id_pool = IdPool()

    Events:Subscribe("ChatCommand", function(args)
        if args.text == "/money" then
            args.player:SetNetworkValue("GameMoney", args.player:GetValue("GameMoney") + 1000)
        end
    end)

    Events:Subscribe("PlayerQuit", function(args) self:PlayerQuit(args) end)

end

-- Resets game info like round, time elapsed, etc
function GameManager:ResetGameInfo(args)
    self.game_info = 
    {
        round = 1,
        timer = Timer(),
        map = args.map,
        players = args.players,
        map_data = args.map_data
    }
end

function GameManager:GetGameInfo()
    return self.game_info
end

-- Syncs the new round to all players
function GameManager:SyncNewRound()
    Network:Broadcast("game/sync/update_round", {
        round = self.game_info.round
    })
end

function GameManager:PlayerQuit(args)
    if self:GetIsGameInProgress() then
        self.game_info.players[args.player:GetId()] = nil
        self:CheckIfGameShouldEnd()
    end
end

-- Checks if alive players == 0, and if so, game ends
function GameManager:CheckIfGameShouldEnd()
    if count_table(self:GetAlivePlayers()) == 0 then
        self:EndGame()
    end
end

-- Ends a game because everyone either died or left
function GameManager:EndGame()
    Network:Broadcast("game/sync/end")
    GameManager:SetIsGameInProgress(false)
    LobbyManager:GameEnd()

    Events:Fire("GameEnd", {})
    print("GameManager:EndGame")
end

-- Called by LobbyManager when a game starts
function GameManager:StartGame(args)
    local hole_count = count_table(args.map_data.holes)
    local game_id = self.games_id_pool:GetNextId()
    local game = Game(game_id, hole_count, args)
    self.games[game_id] = game

    local players_starting_game = {}
    for id, player in pairs(args.players) do
        table.insert(players_starting_game, player:GetId())
    end

    local game_info = {
        course_enum = args.course_enum,
        mapname = args.map,
        difficulty = args.map_data.difficulty,
        game_id = game:GetGameId(),
        hole_count = count_table(args.map_data.holes)
    }

    Network:Send("game/sync/start", players_starting_game, game_info)

    game:Start()

    local game_started_event_info = {
        players = args.players,
        game = game
    }
    Events:Fire("GameStarted", game_started_event_info)
end

function GameManager:RemoveGame(game)
    self.games[game:GetGameId()] = nil
    print("Ended ", game)
end

function GameManager:NewRound(is_first_round)
    if not is_first_round then -- not necessary on first round
        self.game_info.round = self.game_info.round + 1
    end
    
    -- generates the next wave

    World:SetTime(LobbyManager:GetMapData(self.game_info.map.mapname).time.hour, 0, 0)

    -- Wait a little bit before setting weather, after setting the game time
    Citizen.CreateThreadNow(function()
        local saved_round_number = GameManager:GetRoundNumber()
        Wait(2000)
        World:SetWeather(LobbyManager:GetMapData(self.game_info.map.mapname).weather)
    end)

    for _, player in pairs(self.game_info.players) do
        if not is_first_round and not player:GetValue("Alive") then
            -- respawn player
            Network:Send("gameplay/sync/respawn", player)
        end
        player:SetNetworkValue("Downed", false)
        player:SetNetworkValue("Alive", true)
        player:SetNetworkValue("Spectate", false)

        if not is_first_round then
            -- Round bonus money
            self:AddMoneyToPlayer(player, shGameplayConfig.Points.RoundBonus)
        end
    end

    if not is_first_round then -- not necessary on first round
        self:SyncNewRound()
    end
end

function GameManager:GetRoundNumber()
    return self.game_info.round
end

function GameManager:GetMoneyModifier()
    local double_pts = PowerupManager:GetBehavior(PowerupTypesEnum.DoubleMoney):IsActive()
    return double_pts and 2 or 1
end

function GameManager:AddMoneyToPlayer(player, amount)
    local old_money = player:GetValue("GameMoney") or 0
    local money_to_add = amount * self:GetMoneyModifier()
    local updated_money = old_money + money_to_add
    player:SetNetworkValue("GameMoney", updated_money)
    LobbyShopManager:PlayerAddIngameMoney(player, money_to_add)
end

function GameManager:GetGameSyncInfo()
    return {
        mapname = self.game_info.map.mapname,
        difficulty = self.game_info.map.difficulty,
        spectate = self:GetSpectatingPlayers()
    }
end

function GameManager:GetSpectatingPlayers()
    local t = {}

    for id, player in pairs(self:GetPlayers()) do
        if player:GetValue("Spectate") then
            t[player:GetUniqueId()] = true
        end
    end
    
    return t
end

function GameManager:PlayerJoinExisting(player)
    if self.game_info.players[player:GetId()] then return end

    self.game_info.players[player:GetId()] = player
    local should_spectate = self.game_info.timer:GetSeconds() > 15
    GameManager:SetPlayerStartGameValues(player, not should_spectate, should_spectate)
    Network:Send("game/sync/start", player:GetId(), self:GetGameSyncInfo())
end

function GameManager:SetPlayerStartGameValues(player, alive, spectate)
    player:SetNetworkValue("Alive", alive) -- boolean
    player:SetNetworkValue("Downed", false)
    player:SetNetworkValue("Spawned", true)
    player:SetNetworkValue("GameMoney", 0)
    player:SetNetworkValue("Spectate", spectate)
    player:SetNetworkValue("Armor", 0)

    player:SetNetworkValue("InGame", true)
end

-- Gets a table of player ids who are in the game
function GameManager:GetPlayerIds()
    local ids = {}
    for id, player in pairs(self:GetPlayers()) do
        table.insert(ids, player:GetId())
    end
    return ids
end

-- Gets all players in the game (whether alive or dead or not spawned yet)
function GameManager:GetPlayers()
    return self.game_info.players
end

-- Gets all the players who are alive in the game
function GameManager:GetAlivePlayers()
    local players = {}
    for id, player in pairs(self:GetPlayers()) do
        if player:GetValue("Alive") and player:GetValue("Spawned") and not player:GetValue("Downed") then
            players[id] = player
        end
    end
    return players
end

GameManager = GameManager()