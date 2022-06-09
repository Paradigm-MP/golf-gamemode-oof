Test = class()

function Test:__init()
    
    if IsServer then
        RegisterCommand("s", function(source, args, rawCommand)
            KeyValueStore:Set("TestKey", {[1] = "a", [2] = true, [3] = {fun = 1}})
        end)

        RegisterCommand("g", function(source, args, rawCommand)
            KeyValueStore:Get("TestKey", function(value)
                print(value)
                print(type(value))
                output_table(value)
            end)
        end)
    end

    if IsClient then
        Events:Subscribe("LocalPlayerChat", function(args)
            if args.text == "/f" then
                Citizen.CreateThread(function()
                    local player_data = Network:Fetch("FetchPlayerData", {somedata = 34})
                    print("fetched player data: ")
                    print(player_data)
                    output_table(player_data)
                end)
            end
        end)
    end

    if IsServer then
        Network:Subscribe("FetchPlayerData", function(args)
            print("Entered Fetch subscription on server")
            return {fun = 34}
        end)
    end
end


Test = Test()