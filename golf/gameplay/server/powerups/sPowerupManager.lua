PowerupManager = class()

function PowerupManager:__init()

    self:DeclareEventSubscriptions()
    self:DeclareNetworkSubscriptions()
end

function PowerupManager:DeclareEventSubscriptions()
    if IsTest then
        Events:Subscribe("ChatCommand", function(args) self:ChatCommandDebug(args) end)
    end
end

function PowerupManager:ChatCommandDebug(args)
    local tokens = split(args.text, " ")
    
    if tokens[1]:find("/addpowerup") then
        local powerup_enum = tokens[2]

        PowerupManager:AddPowerup(args.player, powerup_enum)
    end

    if tokens[1]:find("/removepowerup") then
        local powerup_enum = tokens[2]

        PowerupManager:RemovePowerup(args.player, powerup_enum)
    end

    if tokens[1]:find("/setpowerupactive") then
        local powerup_enum = tokens[2]

        PowerupManager:SetPowerupActive(args.player, powerup_enum)
    end

    if tokens[1]:find("/setpowerupinactive") then
        local powerup_enum = tokens[2]

        PowerupManager:SetPowerupInactive(args.player, powerup_enum)
    end
end

function PowerupManager:AddPowerup(player, powerup_enum)
    PowerupManager:GetPlayerPowerups(player, function(powerups_result)
        local powerups = shallow_copy(powerups_result.powerups) -- we copy because this table reference is also in the cache, so we want to avoid modifying that
        powerups[powerup_enum] = true

        player:StoreValue({key = "Powerups", value = powerups})
        self:GetPlayerPowerups(player, self, self.SyncPowerups)
    end)
end

function PowerupManager:RemovePowerup(player, powerup_enum)
    PowerupManager:GetPlayerPowerups(player, function(powerups_result)
        local powerups = shallow_copy(powerups_result.powerups) -- we copy because this table reference is also in the cache, so we want to avoid modifying that
        powerups[powerup_enum] = nil

        player:StoreValue({key = "Powerups", value = powerups})

        self:SetPowerupInactive(player, powerup_enum) -- this function does the sync for RemovePowerup
    end)
end

function PowerupManager:SetPowerupActive(player, powerup_enum)
    PowerupManager:GetPlayerPowerups(player, function(powerups_result)
        local active_powerups = shallow_copy(powerups_result.active_powerups) -- we copy because this table reference is also in the cache, so we want to avoid modifying that
        active_powerups[powerup_enum] = true
        
        player:StoreValue({key = "ActivePowerups", value = active_powerups})
        self:GetPlayerPowerups(player, self, self.SyncPowerups) -- don't need to do this in StoreValue callback because of caching
    end)
end

function PowerupManager:SetPowerupInactive(player, powerup_enum)
    PowerupManager:GetPlayerPowerups(player, function(powerups_result)
        local active_powerups = shallow_copy(powerups_result.active_powerups) -- we copy because this table reference is also in the cache, so we want to avoid modifying that
        active_powerups[powerup_enum] = nil

        player:StoreValue({key = "ActivePowerups", value = active_powerups})
        self:GetPlayerPowerups(player, self, self.SyncPowerups) -- don't need to do this in callback because of caching
    end)
end

function PowerupManager:DeclareNetworkSubscriptions()
    Network:Subscribe("lobby/maps/sync/ready", function(args) self:PlayerUiReady(args) end)
end

function PowerupManager:PlayerUiReady(args)
    self:GetPlayerPowerups(args.player, self, self.SyncPowerups)
end

function PowerupManager:GetPlayerPowerups(player, instance, callback)
    player:GetStoredValue({key = "Powerups", callback = function(powerups_result)
        local powerups = powerups_result
        if not powerups then
            powerups = {}
        end

        player:GetStoredValue({key = "ActivePowerups", callback = function(active_powerups_result)
            local active_powerups = active_powerups_result
            if not active_powerups then
                active_powerups = {}
            end

            if type(instance) == "function" then
                -- if we use the function like (player, callback)
                instance({
                    powerups = powerups,
                    active_powerups = active_powerups
                })
            else
                -- if we use the function like (player, instance, callback)
                callback(instance, {
                    player = player,
                    powerups = powerups,
                    active_powerups = active_powerups
                })
            end
        end})
    end})
end

function PowerupManager:SyncPowerups(powerup_info)
    local powerups_data = {
        powerups = powerup_info.powerups,
        active_powerups = powerup_info.active_powerups
    }
    Network:Send("gameplay/powerup/sync", powerup_info.player, powerups_data)
end


PowerupManager = PowerupManager()