-- a class like this can be used in each gamemode for gamemode specific data
-- that we want to persist in-memory on the server
GamePlayer = class()

function GamePlayer:__init(player, args)
    getter_setter(self, "player")
    self.player = player
    self.player_id = self.player:GetId()
    getter_setter(self, "unique_id")
    self.unique_id = self.player:GetUniqueId()
    self.player_name = self.player:GetName()
    self.hole_count = args.hole_count

    -- game data
    self.hole_scores = {}
    for i = 1, args.hole_count do
        self.hole_scores[i] = 0
    end
    getter_setter(self, "hole_scores")
    getter_setter(self, "current_hole")
    self:SetCurrentHole(1)
end

function GamePlayer:SyncCurrentHole()
    Network:Send("game/sync/current_hole", self.player_id, {
        current_hole = self.current_hole
    })
end

function GamePlayer:GetCurrentHoleScore()
    return self.hole_scores[self.current_hole]
end

function GamePlayer:SetCurrentHoleScore(score)
    self.hole_scores[self.current_hole] = score
end

function GamePlayer:IsFinished()
    return self.current_hole == self.hole_count + 1
end

-- sends hole scores & current hole for every player in the game
function GamePlayer:ScoreSync(scores, current_holes)
    Network:Send("game/sync/score_sync", self.player_id, {
        scores = scores,
        current_holes = current_holes
    })
end

function GamePlayer:Remove()
    -- any event unsubscriptions if necessary
end

function GamePlayer:tostring()
    return "GamePlayer (" .. self.player_name .. ")"
end