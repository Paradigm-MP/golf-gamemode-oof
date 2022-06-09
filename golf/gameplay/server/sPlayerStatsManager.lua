PlayerStatsManager = class()

function PlayerStatsManager:__init()

    Events:Subscribe("gamedatabase/ready", function() self:GameDatabaseReady() end)
    Events:Subscribe("ClientModulesLoaded", function(args) self:ClientModulesLoaded(args) end)
    Events:Subscribe("MinuteTick", function() self:MinuteTick() end)
    Events:Subscribe("GameEnd", function() self:GameEnd() end)

    Events:Subscribe("PlayerFinishedGolfGame", function(args) self:PlayerFinishedGolfGame(args) end)
end

function PlayerStatsManager:PlayerFinishedGolfGame(args)
    if args.player:GetValue("DBInitialized") then
        self:UpdatePlayerStats(args)

        -- update the overall best score for this course if needed
        local key = "BestCourseScore" .. tostring(args.course_enum)
        KeyValueStore:Get({key = key, callback = function(best_course_score)
            if not best_course_score or best_course_score > args.total_score then
                print(args.player, " set a new overall best score for " .. CourseEnum:GetDescription(args.course_enum))
                KeyValueStore:Set({key = key, value = args.total_score})
                KeyValueStore:Set({key = "BestCourseScorePlayer" .. tostring(args.course_enum), value = args.player:GetUniqueId()})
                KeyValueStore:Set({key = "BestCourseScoreDate" .. tostring(args.course_enum), value = os.date("%x")})

                LobbyManager:SyncBestScores()
            end
        end})

        local gamestats = args.player:GetValue("GameStats")
        gamestats.games_played = gamestats.games_played + 1
        args.player:SetValue("GameStats", gamestats)
        args.player:SetValue("Level", args.player:GetValue("Level") + 1)
        self:SavePlayerToDB(args.player)

        LobbyManager:UpdateLevel(args.player)
    end
end

function PlayerStatsManager:UpdatePlayerStats(args)
    -- update Player's best score on this course
    local key = "BestCourseScore" .. tostring(args.course_enum)
    args.player:GetStoredValue({key = key, callback = function(player_current_course_best_score)
        if not player_current_course_best_score or player_current_course_best_score > args.total_score then
            print(args.player, " set a new personal record on " .. CourseEnum:GetDescription(args.course_enum))
            args.player:StoreValue({key = key, value = args.total_score})
        end
    end})

    local course = Courses:GetCourse(args.course_enum)
    print("total par: ", course:GetTotalPar())
    if args.total_score < course:GetTotalPar() then
        local under_par_key = "UnderParDifficulty=" .. tostring(args.difficulty)
        args.player:GetStoredValue({key = under_par_key, callback = function(player_under_par_on_difficulty)
            local new_under_par_value = player_under_par_on_difficulty
            if not new_under_par_value then
                new_under_par_value = 0
            end
            new_under_par_value = new_under_par_value + 1

            args.player:StoreValue({key = under_par_key, value = new_under_par_value})

            if new_under_par_value == 3 then
                local highest_difficulty_unlocked_key = "HighestDifficultyUnlocked"
                args.player:GetStoredValue({key = highest_difficulty_unlocked_key, callback = function(highest_difficulty_unlocked)
                    local new_highest_difficulty_unlocked = highest_difficulty_unlocked
                    if not new_highest_difficulty_unlocked then
                        new_highest_difficulty_unlocked = 1
                    end

                    new_highest_difficulty_unlocked = new_highest_difficulty_unlocked + 1

                    args.player:StoreValue({key = highest_difficulty_unlocked_key, value = new_highest_difficulty_unlocked})
                    Network:Send("lobby/highest_difficulty/sync", args.player, {
                        highest_difficulty_unlocked = new_highest_difficulty_unlocked,
                        alert_user = true
                    })
                end})
            end
        end})
    end
    
end

function PlayerStatsManager:GetDateNow()
    return os.date("%Y-%m-%d-%H-%M-%S")
end

-- Ticks every minute to update player stats
function PlayerStatsManager:MinuteTick()
    self:UpdatePlayerOnlineTimes()
end

function PlayerStatsManager:UpdatePlayerOnlineTimes()
    Citizen.CreateThread(function()
        for id, player in pairs(sPlayers:GetPlayers()) do
            if player:GetValue("DBInitialized") then
                player:SetNetworkValue("TimeOnline", player:GetValue("TimeOnline") + 1)
                self:SavePlayerToDB(player)
                Citizen.Wait(100)
            end
        end
    end)
end

function PlayerStatsManager:GameDatabaseReady()
    -- load stuff
end

-- Called when a client has joined
function PlayerStatsManager:ClientModulesLoaded(args)
    local query = "SELECT * FROM player_data WHERE unique_id=@uniqueid"
    local params = {["@uniqueid"] = args.player:GetUniqueId()}
    SQL:Fetch(query, params, function(result)
        if result and result[1] then
            self:InitPlayerStats(args.player, result[1])
        else
            self:InitPlayerStats(args.player, {
                unique_id = args.player:GetUniqueId(),
                name = args.player:GetName(),
                model = "Player_Zero|0",
                time_online = 0,
                last_login_ip = args.player:GetIP(),
                level = 1,
                games_played = 0,
                last_online = self:GetDateNow()
            })
            self:SavePlayerToDB(args.player)
        end
    end)
end

--[[
    Saves a player to DB with their current level, gamestats, and time online
]]
function PlayerStatsManager:SavePlayerToDB(player)

    local cmd = "INSERT INTO player_data (unique_id, name, model, time_online, last_login_ip, level, games_played, last_online)"..
        "VALUES(@uniqueid, @name, @model, @timeonline, @lastloginip, @level, @gamesplayed, @last_online) "..
        "ON DUPLICATE KEY UPDATE name=@name, level=@level, time_online=@timeonline, last_login_ip=@lastloginip, "..
        "games_played=@gamesplayed, last_online=@last_online, model=@model"
    local params = 
    {
        ["@uniqueid"] = player:GetUniqueId(),
        ["@name"] = player:GetName(),
        ["@model"] = player:GetValue("Model"),
        ["@timeonline"] = player:GetValue("TimeOnline"),
        ["@lastloginip"] = player:GetIP(),
        ["@level"] = player:GetValue("Level"),
        ["@gamesplayed"] = player:GetValue("GameStats").games_played,
        ["@last_online"] = self:GetDateNow(), -- Always save current date
    }

    SQL:Execute(cmd, params, function(rows)
        --
    end)
end

function PlayerStatsManager:InitPlayerStats(player, data)
    player:SetValue("RawStats", data)
    player:SetNetworkValue("Level", data.level)
    player:SetValue("GameStats", {games_played = data.games_played})
    player:SetNetworkValue("TimeOnline", data.time_online)
    player:SetValue("DBInitialized", true)
    player:SetNetworkValue("Model", data.model)
    player:SetNetworkValue("LastOnline", data.last_online)

    Events:Fire("gameplay/playerstats/init", {player = player})
end

PlayerStatsManager = PlayerStatsManager()