LobbyShopManager = class()

local item_ids = 0
local function GenerateItemId()
    item_ids = item_ids + 1
    return item_ids
end

function LobbyShopManager:__init()

    self.shop_items = {["skins"] = {}, ["powerups"] = {}}
    self.DEFAULT_ITEMS = 
    {
        ["powerups"] = {},
        ["skins"] = {
            {model = "Player_0", outfit = 0}
        }
    }

    self:LoadShopItems()

    self.base_difficulty_points = 
    {
        [DifficultyEnum.Easy] = 20,
        [DifficultyEnum.Medium] = 40,
        [DifficultyEnum.Hard] = 80,
        [DifficultyEnum.Extreme] = 130,
        [DifficultyEnum.Insane] = 200
    }

    Network:Subscribe("shop/buy_item", function(args) self:BuyItem(args) end)
    Network:Subscribe("shop/equip_item", function(args) self:EquipItem(args) end)

    Events:Subscribe("gamedatabase/ready", function() self:GameDatabseReady() end)
    Events:Subscribe("PlayerFinishedGolfGame", function(args) self:PlayerFinishedGolfGame(args) end)
end

-- Gets the amount of points that a player earns after completing a game
function LobbyShopManager:GetPointsFromGame(args)

    local amount = self.base_difficulty_points[args.difficulty]
	
	local par = 0
	
	for _, data in pairs(args.holes) do
		par = par + data.par
	end
	
	local stroke = 0
	
	for hole, strokes in pairs(args.scores) do
		stroke = stroke + strokes
	end
    
    stroke = math.max(stroke, 1)
	amount = math.ceil(amount * (par / stroke) * (1 + (args.num_players - 1) / 3)) + count_table(args.holes) * 5
	
	if args.record then
		amount = amount * 3
	end

    return math.clamp(amount, 0, 50000)
    
end

function LobbyShopManager:PlayerFinishedGolfGame(args)
    local points = self:GetPointsFromGame(args)
    self:PlayerAddPoints(args.player, points)
end

function LobbyShopManager:HandlePlayerModel(player, model)
    for _, item_data in pairs(self.shop_items.skins) do
        local item_name = self:GetItemName(item_data)
        if item_name == model then
            return model
        end
    end

    -- Invalid model, reset to default
    return self.DEFAULT_ITEMS
end

function LobbyShopManager:GetItemName(item_data)
    return item_data.model .. "|" .. tostring(item_data.outfit)
end

function LobbyShopManager:EquipItem(args)
    
    if not args.id then return end -- Invalid data sent
    args.id = tonumber(args.id)

    local item_to_equip = self.shop_items[args.type][args.id]
    if not item_to_equip then return end -- Item not found

    if not self:PlayerOwnsItem(args.player, args.type, item_to_equip) then return end -- Don't own it

    if args.type == "skins" then
        
        local item_name = self:GetItemName(item_to_equip)
        if args.player:GetValue("Model") == item_name then return end  -- Already equipped
        args.player:SetNetworkValue("Model", item_name)
        
    elseif args.type == "powerups" then
        
        args.player:GetStoredValue({key = "ActivePowerups", callback = function(active_powerups)

            for powerup_enum, _ in pairs(active_powerups or {}) do
                PowerupManager:SetPowerupInactive(args.player, powerup_enum)
            end

            if not active_powerups or not active_powerups[item_to_equip.powerup_enum] then
                PowerupManager:SetPowerupActive(args.player, item_to_equip.powerup_enum)
            end
        end})
    end
    
    PlayerStatsManager:SavePlayerToDB(args.player) -- Save equipped model to DB

end

function LobbyShopManager:BuyItem(args)
    -- Called when a player tries to buy an item from the shop
    -- args: id of item and player
    if not args.id then return end -- Invalid data sent
    args.id = tonumber(args.id)

    local item_to_buy = self.shop_items[args.type][args.id]
    if not item_to_buy then return end -- Item not found

    local points = args.player:GetValue("Points")
    if points < item_to_buy.cost then return end -- Not enough points

    local bought_items = args.player:GetValue("BoughtShopItems")
    if self:PlayerOwnsItem(args.player, args.type, item_to_buy) then return end -- Already own it

    -- All good, now purchase the item!
    if args.type == "skins" then
        table.insert(bought_items.skins, {
            model = item_to_buy.model,
            outfit = item_to_buy.outfit
        })
    else
        bought_items.powerups[item_to_buy.name] = true
        PowerupManager:AddPowerup(args.player, item_to_buy.powerup_enum)
    end

    args.player:SetNetworkValue("BoughtShopItems", bought_items)
    args.player:SetNetworkValue("Points", points - item_to_buy.cost)

    self:SavePlayerToDB(args.player)
end

-- Called by GameManager when a player earns points after finishing a game
function LobbyShopManager:PlayerAddPoints(player, amount)
    local current_points = player:GetValue("Points")
    if not current_points then current_points = 0 end
    if not amount then amount = 0 end

    player:SetNetworkValue("Points", current_points + amount)
    self:SavePlayerToDB(player)
end

function LobbyShopManager:LoadShopItems()
    local data = JsonUtils:LoadJSON("lobby/server/shop/shop_items.json")
    for item_type, _ in pairs(data.items) do
        for _, item_data in pairs(data.items[item_type]) do
            if item_data.enabled == true then
                local id = GenerateItemId()
                item_data["id"] = id -- Assign each item a unique id 
                self.shop_items[item_type][id] = item_data
            end
        end
    end
end

function LobbyShopManager:PlayerReady(player)

    player:GetStoredValue({key = "Points", callback = function(points)
        player:GetStoredValue({key = "BoughtShopItems", callback = function(bought_items)

            if bought_items then
                -- Parse skin outfits
                for _, skin_data in pairs(bought_items.skins) do
                    skin_data.outfit = tonumber(skin_data.outfit)
                end
            end

            self:InitPlayerShopValues(player, {
                points = points or 0,
                bought_items = bought_items or self.DEFAULT_ITEMS
            })

            if not points then
                self:SavePlayerToDB(player)
            end
        end})
    end})

    Network:Send("shop/initial_sync", player, {data = self.shop_items})
end


function LobbyShopManager:SavePlayerToDB(player)
    player:StoreValue({key = "Points", value = player:GetValue("Points")})
    player:StoreValue({key = "BoughtShopItems", value = player:GetValue("BoughtShopItems")})
end

function LobbyShopManager:PlayerOwnsItem(player, item_type, item)
    if item_type == "powerups" then return self:PlayerOwnsPowerup(player, item.name) end

    for _, item_data in pairs(player:GetValue("BoughtShopItems").skins) do
        if tostring(item_data.model) == tostring(item.model) and tonumber(item_data.outfit) == tonumber(item.outfit) then
            return true
        end
    end

    return false
end

function LobbyShopManager:PlayerOwnsPowerup(player, powerup_name)
    return player:GetValue("BoughtShopItems").powerups[powerup_name] ~= nil
end

function LobbyShopManager:InitPlayerShopValues(player, data)
    player:SetNetworkValue("Points", data.points)
    player:SetNetworkValue("BoughtShopItems", data.bought_items)
end

function LobbyShopManager:GameDatabseReady()
    -- load things, or not :)
end

LobbyShopManager = LobbyShopManager()