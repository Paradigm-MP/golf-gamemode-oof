LobbyManager = class()

-- Handles the lobby/queue/map menu stuff
function LobbyManager:__init()

    self.queue = {}
    self.countdown_max = 15 -- Countdown from when someone readies up to when the game starts
    self.current_map = {}

    self:LoadMapData()
    self:SetupQueue()
    self:SyncCourseMapData()
    self:FullQueueSync()

    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            self:CountdownCheckLoop()
        end
    end)

    -- Set server info
    SetGameType("Golf")
    SetMapName("All sorts of golf courses")

    Network:Subscribe("lobby/queue/sync/join", function(args) self:PlayerJoinQueue(args) end)
    Network:Subscribe("lobby/queue/sync/leave", function(args) self:PlayerLeaveQueue(args) end)
    Network:Subscribe("lobby/queue/sync/ready", function(args) self:PlayerReadyQueue(args) end)
    Network:Subscribe("lobby/queue/sync/joinexistinggame", function(args) self:PlayerJoinExistingGame(args) end)
    Network:Subscribe("lobby/maps/sync/ready", function(args) self:PlayerUIReady(args) end)

    Events:Subscribe("PlayerJoined", function(args) self:PlayerJoin(args) end)
    Events:Subscribe("PlayerQuit", function(args) self:PlayerQuit(args) end)
    Events:Subscribe("lobby/playerstats/init", function(args) self:PlayerStatsInit(args) end)

end

function LobbyManager:CountdownCheckLoop()

    for course_enum, map_queue in pairs(self.queue) do

        if map_queue.countdown_active then
            map_queue.countdown = map_queue.countdown - 1
                    
            if map_queue.countdown == 0 then
                map_queue.countdown_active = false
                self:StartGame(map_queue)
                break
            end
            
        end
    end
    
end

function LobbyManager:PlayerStatsInit(args)
    local sync_info = self:GetPlayerBasicSyncInfo(args.player)
    sync_info.action = "update"
    Network:Send("lobby/players/sync/single", -1, sync_info)
end

function LobbyManager:PlayerJoinExistingGame(args)
    GameManager:PlayerJoinExisting(args.player)
end

function LobbyManager:PlayerUIReady(args)
    self:SyncCourseMapData(args.player)
    self:FullQueueSync(args.player)
    self:SyncPlayerData(args.player)
    self:SyncAllCountdowns(args.player)
    self:SyncBestScores(args.player)
    args.player:GetStoredValue({key = "HighestDifficultyUnlocked", callback = function(highest_difficulty_unlocked)
        if not highest_difficulty_unlocked then
            highest_difficulty_unlocked = 1
            args.player:StoreValue({key = "HighestDifficultyUnlocked", value = 1})
        end
        Network:Send("lobby/highest_difficulty/sync", args.player, {highest_difficulty_unlocked = highest_difficulty_unlocked})
    end})

    local sync_info = self:GetPlayerBasicSyncInfo(args.player)
    sync_info.action = "add"
    Network:Send("lobby/players/sync/single", -1, sync_info)

    -- Give admin tags
    if args.player:GetUniqueId() == "6a3252bb0a17edf642acc4bafc7b286e3978aaca" -- LF
    or args.player:GetUniqueId() == "bddbfdd365d3f7b3ddc450ca0230534784f77356" then -- Dev_34
        args.player:SetNetworkValue("Nametags", {
            {
                name = "Admin",
                color = "red"
            }
        })
    end

    Chat:Broadcast({
        text = args.player:GetName() .. " joined.",
        use_name = true,
        style = "italic",
        color = Colors.Gray
    })
    
    SteamAvatars:PlayerJoined({player = args.player})
    LobbyShopManager:PlayerReady(args.player)
end

function LobbyManager:AvatarLoaded(id)
    local player = sPlayers:GetByUniqueId(id)
    assert(player ~= nil, "AvatarLoaded failed, could not find a valid player")

    local sync_info = self:GetPlayerBasicSyncInfo(player)
    sync_info.action = "update"
    Network:Send("lobby/players/sync/single", -1, sync_info)
end

function LobbyManager:UpdateLevel(player)
    local sync_info = self:GetPlayerBasicSyncInfo(player)
    sync_info.action = "update"
    Network:Send("lobby/players/sync/single", -1, sync_info)
end

function LobbyManager:PlayerJoin(args)
    Chat:Broadcast({
        text = args.player:GetName() .. " joined.",
        use_name = true,
        style = "italic",
        color = Colors.Gray
    })
end

function LobbyManager:GetPlayerBasicSyncInfo(p)
    return {
        id = p:GetUniqueId(),
        steamid = p:GetSteamId(),
        name = p:GetName(),
        avatar = SteamAvatars:GetBySteamId(p:GetSteamId()),
        level = p:GetValue("Level")
    }
end

function LobbyManager:SyncPlayerData(player)
    local data = {}
    local this_player_unique_id = player:GetUniqueId()
    
    for player_unique_id, p in pairs(sPlayers:GetPlayers()) do
        data[player_unique_id] = self:GetPlayerBasicSyncInfo(p)

        if player_unique_id == this_player_unique_id then
            data[player_unique_id].is_me = true
        end
    end
    Network:Send("lobby/players/sync/full", player:GetId(), data)
end

-- When a player clicks the "READY" button to ready up (or unready) for a map
function LobbyManager:PlayerReadyQueue(args)
    local mq

    -- Check to see if they're queueing for a map
    for course_enum, mapqueue in pairs(self.queue) do
        -- If this queue has the player
        if mapqueue:HasPlayer(args.player) then
            mq = mapqueue
        end
    end

    -- If we found their mapqueue, flip their READY status
    if mq then
        mq:SetPlayerReady(args.player, not mq:GetPlayerReady(args.player))
        mq:Sync()
        self:CheckCountdown(mq)
    end

end

-- Syncs the game status to a player (or everyone if not specified). 
-- Shows "GAME IN PROGRESS" screen if a game is running
function LobbyManager:QueueGameSync(player)
    Network:Send("lobby/queue/sync/game", player ~= nil and player:GetId() or -1, self.current_map)
end

-- Countdown hit 0 or everyone is ready, so start the game
function LobbyManager:StartGame(map_queue)
    map_queue.countdown_active = false
    self:SyncCountdown(nil, map_queue)

    print("Ready players:")
    output_table(map_queue:GetReadyPlayers())

    GameManager:StartGame({
        course_enum = map_queue:GetCourseEnum(),
        map = map_queue.name,
        map_data = Courses:GetCourse(map_queue:GetCourseEnum()):GetMapData(),
        difficulty = Courses:GetCourse(map_queue:GetCourseEnum()):GetDifficulty(),
        players = map_queue:GetReadyPlayers()
    })

    map_queue:Clear()
    self:FullQueueSync()
end

function LobbyManager:GetReadyPlayers()
    local players = {}
    local most = 0
    -- Check to see if they're queueing for a map
    for course_enum, mapqueue in pairs(self.queue) do
        local ready_players = mapqueue:GetReadyPlayers()
        for id, player in pairs(ready_players) do
            players[id] = player
        end
        most = math.max(count_table(ready_players), most)
    end
    return players, most
end

function LobbyManager:GetNumPlayersReady()
    return count_table(self:GetReadyPlayers())
end

-- Syncs the countdown
function LobbyManager:SyncCountdown(player, map_queue)
    Network:Send("lobby/queue/sync/countdown", player ~= nil and player:GetId() or -1, map_queue:GetCountdownSyncInfo())
end

function LobbyManager:SyncAllCountdowns(player)
    local countdowns = {}
    for course_enum, map_queue in pairs(self.queue) do
        if map_queue.countdown_active then
            countdowns[course_enum] = map_queue:GetCountdownSyncInfo()
        end
    end

    Network:Send("lobby/queue/sync/countdown/all", player ~= nil and player:GetId() or -1, countdowns)
end

-- Check if anyone is ready and if we should start or stop the countdown
function LobbyManager:CheckCountdown(map_queue)
    local ready = map_queue:GetNumPlayersReady()
    local num_queued = map_queue:GetNumPlayers()

    -- If everyone who is queued is ready, then start the game
    if ready == num_queued and ready > 0 then
        self:StartGame(map_queue)
        return
    end

    if map_queue.countdown_active then
        -- if the countdown is running and no one is ready, stop it
        if ready == 0 then
            map_queue.countdown_active = false
            self:SyncCountdown(nil, map_queue)
        end
    else
        -- If at least one player is ready, start the countdown
        if ready > 0 and not map_queue.countdown_active then
            map_queue.countdown = self.countdown_max
            map_queue.countdown_active = true
            self:SyncCountdown(nil, map_queue)
        end
    end
end

-- When someone leaves the server, remove them from the queue if they're in one
function LobbyManager:PlayerQuit(args)
    self:PlayerLeaveQueue(args)
    Network:Send("lobby/players/sync/single", -1, {
        id = args.player:GetUniqueId(),
        action = "remove"
    })
    
    Chat:Broadcast({
        text = args.player:GetName() .. " left.",
        use_name = true,
        style = "italic",
        color = Colors.Gray
    })
end

-- When a player presses the "LEAVE" button for a map or quits the game
function LobbyManager:PlayerLeaveQueue(args)
    local mq

    -- Check to see if they're already queueing for a map
    for course_enum, mapqueue in pairs(self.queue) do
        -- If this queue has the player, remove them
        if mapqueue:HasPlayer(args.player) then
            mapqueue:RemovePlayer(args.player)
            mq = mapqueue
        end
    end

    -- If we found someone and removed them, sync it
    if mq then
        mq:Sync()
        self:CheckCountdown(mq)
    end
end

-- When a player joins or switched to a queue
function LobbyManager:PlayerJoinQueue(args)
    -- Check validity of sent data
    if not args.course_enum then return end
    if not self.queue[args.course_enum] then return end

    -- Check to see if they're already queueing for a map
    for course_enum, mapqueue in pairs(self.queue) do
        -- If this queue has the player and it's not the one they just clicked on, remove them
        if mapqueue:HasPlayer(args.player) and course_enum ~= args.course_enum then
            mapqueue:RemovePlayer(args.player)
            mapqueue:Sync()
            self:CheckCountdown(mapqueue)
        end
    end

    local mapqueue = self.queue[args.course_enum]
    -- Now add the player
    mapqueue:AddPlayer(args.player)
    -- And sync to all players
    mapqueue:Sync()
    self:CheckCountdown(mapqueue)
end

-- Syncs all map data to a player, or all players if none specified
function LobbyManager:SyncCourseMapData(player)
    Network:Send("lobby/map/sync/full", player ~= nil and player:GetId() or -1, self.map_data)
end

-- Load all map data
function LobbyManager:LoadMapData()

    for course_enum, course in pairs(Courses:GetCourses()) do
        local data = JsonUtils:LoadJSON("lobby/server/maps/" .. course:GetMap())
        data.difficulty = course:GetDifficulty() -- override what is in .json file (if anything)
        data.order = course.order
        data.modded = course.modded
        data.course_enum = course_enum
        course:SetMapData(data)
    end

    self.map_data = Courses:GetAllMapData()
end

function LobbyManager:GetMapData(course_enum)
    return Courses:GetCourse(course_enum):GetMapData()
end

-- if not player arg then sync to all clients
-- this function was written before the synchronous option existed for KeyValueStore
function LobbyManager:SyncBestScores(player)
    local best_scores = {}

    local loaded_courses_count = 0
    local courses = Courses:GetCourses()
    local courses_count = count_table(courses)
    local function send_if_completed()
        if loaded_courses_count == courses_count then
            -- all course best score data has been fetched
            if not player then
                Network:Broadcast("lobby/best_scores/sync", best_scores)
            else
                Network:Send("lobby/best_scores/sync", player:GetId(), best_scores)
            end
        end
    end

    for course_enum, course in pairs(courses) do
        local keys = {
            "BestCourseScore" .. tostring(course_enum),
            "BestCourseScorePlayer" .. tostring(course_enum),
            "BestCourseScoreDate" .. tostring(course_enum)
        }

        KeyValueStore:Get({keys = keys, callback = function(values)
            if count_table(values) == 0 then
                loaded_courses_count = loaded_courses_count + 1
                send_if_completed()
                return
            end
            best_scores[course_enum] = values

            local query = "SELECT name FROM player_data WHERE unique_id=@uniqueid"
            local params = {["@uniqueid"] = values["BestCourseScorePlayer" .. tostring(course_enum)]}
            SQL:Fetch(query, params, function(result)
                if result and result[1] then
                    local key = "BestCourseScorePlayer" .. tostring(course_enum)
                    best_scores[course_enum][key] = result[1].name
                end

                loaded_courses_count = loaded_courses_count + 1
                send_if_completed()
            end)
        end})
    end
end

-- Sets up the queue per map per difficulty
function LobbyManager:SetupQueue()
    for course_enum, course in pairs(Courses:GetCourses()) do
        self.queue[course_enum] = MapQueue({
            course_enum = course_enum,
            map = course:GetMap(),
            difficulty = course:GetDifficulty()
        })
    end
end

-- Clears all queues (on game start)
function LobbyManager:ClearQueues()
    for course_enum, map_queue in pairs(self.queue) do
        map_queue:Clear()
    end
end

--[[
    Syncs all queues to a player, or to all players if none specified
]]
function LobbyManager:FullQueueSync(player)
    local data = {}
    for course_enum, mapqueue in pairs(self.queue) do
        data[course_enum] = mapqueue:GetSyncData()
    end

    Network:Send("lobby/queue/sync/full", player ~= nil and player:GetId() or -1, data)
end

LobbyManager = LobbyManager()