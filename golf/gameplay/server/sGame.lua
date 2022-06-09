Game = class()

function Game:__init(game_id, hole_count, args)
    getter_setter(self, "game_id")
    self:SetGameId(game_id)
    getter_setter(self, "active")
    self:SetActive(true)
    getter_setter(self, "course_enum")
    self:SetCourseEnum(args.course_enum)
    self.map = args.map -- name of the map
    self.difficulty = args.difficulty
    self.map_data = args.map_data
    self.hole_count = hole_count
    self.players = args.players
    self.game_players = {}
    for id, player in pairs(args.players) do
        self.game_players[id] = GamePlayer(player, {
            hole_count = hole_count
        })
    end

    self:SubscribeToNetworkEvents()
    self:SubscribeToEvents()
end

function Game:SubscribeToNetworkEvents()
    self.network_events = {
        Network:Subscribe("game/scored_hole" .. tostring(self.game_id), function(args) self:ScoredHole(args) end),
        Network:Subscribe("game/launch" .. tostring(self.game_id), function(args) self:PlayerLaunched(args) end),
        Network:Subscribe("game/player_quit_request" .. tostring(self.game_id), function(args) self:PlayerQuitRequest(args) end)
    }
end

function Game:SubscribeToEvents()
    self.events = {
        Events:Subscribe("PlayerQuit", function(args) self:PlayerQuit(args) end)
    }
end

function Game:Start()
    self:SyncAllScores()
    for id, game_player in pairs(self.game_players) do
        game_player:SyncCurrentHole()
    end
end

function Game:ScoredHole(args)
    local game_player = self.game_players[args.player:GetUniqueId()]

    print(args.player, " scored hole in " .. game_player:GetCurrentHoleScore() .. " shots!")

    local current_hole = game_player:GetCurrentHole() + 1
    game_player:SetCurrentHole(current_hole)
    game_player:SyncCurrentHole()
    self:SyncAllScores()
    self:CheckIfShouldEnd()

    -- Player finished game, 
    if current_hole == self.hole_count + 1 then
        local total_score = 0
        for hole_number, score in ipairs(game_player:GetHoleScores()) do
            total_score = total_score + score
        end

        Events:Fire("PlayerFinishedGolfGame", {
            course_enum = self.course_enum,
            player = args.player,
            total_score = total_score,
            scores = game_player:GetHoleScores(),
            difficulty = self.difficulty,
            holes = self.map_data.holes,
            num_players = count_table(self.game_players),
            record = false -- If this score was a new record TODO: add this
        })
    end
    
end

function Game:PlayerLaunched(args)
    local game_player = self.game_players[args.player:GetUniqueId()]

    if game_player:GetCurrentHole() <= self.hole_count then
        game_player:SetCurrentHoleScore(game_player:GetCurrentHoleScore() + 1)
        self:SyncAllScores()
    end
end

-- when a player types '/quit' during a game
function Game:PlayerQuitRequest(args)
    self:RemovePlayer(args.player)

    Network:Send("game/sync/quit", args.player:GetId())
    self:SyncAllScores() -- wont do anything if there are no players left
    self:CheckIfShouldEnd()
end

-- from "PlayerQuit" event
function Game:PlayerQuit(args)
    if not self.game_players[args.player:GetUniqueId()] then return end

    self:RemovePlayer(args.player)
    self:SyncAllScores() -- wont do anything if there are no players left
    self:CheckIfShouldEnd()
end

function Game:RemovePlayer(player)
    local game_player = self.game_players[player:GetUniqueId()]
    self.game_players[player:GetUniqueId()] = nil
    game_player:Remove()
end

function Game:CheckIfShouldEnd()
    -- end if no players
    if count_table(self.game_players) == 0 then
        self:End()
        return
    end

    -- end if all players have finished
    local all_finished = true
    for id, game_player in pairs(self.game_players) do
        if not game_player:IsFinished() then
            all_finished = false
            break
        end
    end
    if all_finished then
        self:End()
        return
    end
end

function Game:End()
    if not self:GetActive() then
        error("Entered Game:End() but Game is already inactive")
    end

    for _, network_event in ipairs(self.network_events) do
        network_event:Unsubscribe()
    end
    for _, event in ipairs(self.events) do
        event:Unsubscribe()
    end
    for id, game_player in pairs(self.game_players) do
        Network:Send("game/sync/end", game_player:GetPlayer():GetId())
        game_player:Remove()
    end
    GameManager:RemoveGame(self)
    self:SetActive(false)
end

function Game:GetScoreTable()
    local scores = {}
    for id, game_player in pairs(self.game_players) do
        scores[game_player:GetUniqueId()] = game_player:GetHoleScores()
    end
    return scores
end

function Game:GetCurrentHolesTable()
    local current_holes = {}
    for id, game_player in pairs(self.game_players) do
        current_holes[game_player:GetUniqueId()] = game_player:GetCurrentHole()
    end
    return current_holes
end

-- sends everyone's hole scores and current hole to everyone in the game
function Game:SyncAllScores()
    local scores = self:GetScoreTable()
    local current_holes = self:GetCurrentHolesTable()

    for id, game_player in pairs(self.game_players) do
        game_player:ScoreSync(scores, current_holes)
    end
end

function Game:tostring()
    return "Game (#" .. tostring(self.game_id) .. ")"
end


