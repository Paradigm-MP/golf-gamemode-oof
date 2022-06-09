GameDatabase = class()

--[[
    Class for dealing with persistent data in mysql
]]
function GameDatabase:__init()

    Events:Subscribe("mysql/Ready", function() self:InitDatabase() end)
end

function GameDatabase:InitDatabase()
    local await = true

    Citizen.CreateThread(function()

        for _, db in pairs(GameDBConfig.tables) do
            SQL:Execute("CREATE TABLE IF NOT EXISTS " .. db, nil, function(changed)
            end)
        end

        -- Game database is ready to be used
        Events:Fire("gamedatabase/ready")
    end)
end

GameDatabase = GameDatabase()