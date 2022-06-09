Ufo = class()

function Ufo:__init()
    Events:Subscribe("LocalPlayerChat", function(args)
        if args.text == "/ufo" and IsTest then
            Ufo:Spawn(function()
                Ufo:TakePlayerToPosition(GameManager:GetHolePosition(GameManager.current_hole))
            end)
        end
    end)

    self.active = false
end

function Ufo:Spawn(cb)
    if self.active then return end
    self.active = true
    self:SpawnObject(LocalPlayer:GetPosition() + vector3(0, 0, 25), cb)
end

function Ufo:SpawnObject(pos, cb)
    self.ufo = Object({
        model = 's_ufo01x',
        position = pos,
        isNetwork = true,
        callback = function()
            cb()
        end
    })
end

function Ufo:AttachLocalPlayer()
    LocalPlayer:GetPed():AttachToEntity({
        entity = self.ufo,
        position = vector3(0.1, 0.1, 0.55),
        useSoftPinning = true,
        collision = false,
        isPed = true,
        fixedRot = true
    })
end

function Ufo:TakePlayerToPosition(target_position)
    local ufo_offset = vector3(10, 10, 5)
    Camera:DetachFromPlayer(nil, nil, true, 1000)
    Camera:AttachToEntity(self.ufo, ufo_offset)

    local current_position = LocalPlayer:GetPosition() + vector3(0, 0, 1)

    Citizen.CreateThread(function()

        -- Bring UFO down
        local lerp_done = false
        Vector3Math:LerpOverTime(self.ufo:GetPosition(), current_position, 3000, function(position, done)
            self.ufo:SetPosition(position)
            Camera:PointAtEntity(self.ufo)
            lerp_done = done
        end)

        while not lerp_done do
            Wait(1)
        end

        Wait(250)
        Ufo:AttachLocalPlayer()
        Wait(250)

        -- Bring UFO up
        lerp_done = false
        local max_z = math.max(target_position.z, current_position.z)
        local target = vector3(current_position.x, current_position.y, max_z + 20)
        Vector3Math:LerpOverTime(self.ufo:GetPosition(), target, 2000, function(position, done)
            self.ufo:SetPosition(position)
            Camera:PointAtEntity(self.ufo)
            lerp_done = done
        end)

        while not lerp_done do
            Wait(1)
        end

        -- Bring UFO across to target position
        lerp_done = false
        local dist = Vector3Math:Distance(self.ufo:GetPosition(), target_position)
        Vector3Math:LerpOverTime(self.ufo:GetPosition(), vector3(target_position.x, target_position.y, self.ufo:GetPosition().z), math.max(1, dist * 0.01) * 1000, function(position, done)
            self.ufo:SetPosition(position)
            Camera:PointAtEntity(self.ufo)
            lerp_done = done
        end)

        while not lerp_done do
            Wait(1)
        end

        -- Bring UFO down to target position
        lerp_done = false
        Vector3Math:LerpOverTime(self.ufo:GetPosition(), target_position + vector3(0, 0, 2), 2000, function(position, done)
            self.ufo:SetPosition(position)
            Camera:PointAtEntity(self.ufo)
            lerp_done = done
        end)

        while not lerp_done do
            Wait(1)
        end

        local spawn_pos = self.ufo:GetPosition()
        local old_ufo = self.ufo
        local spawned = false
        self:SpawnObject(spawn_pos, function()
            spawned = true
        end)

        while not spawned do
            Wait(10)
        end

        old_ufo:Destroy()

        Citizen.CreateThread(function()
            while true do
                Wait(0)
                self.ufo:ToggleCollision(false)
            end
        end)

        Wait(1500)

        Citizen.CreateThread(function()
            Wait(250)
            Camera:Reset(true, 1000)
        end)

        -- Bring UFO back up into the sky
        lerp_done = false
        Vector3Math:LerpOverTime(self.ufo:GetPosition(), self.ufo:GetPosition() + vector3(0, 0, 50), 2000, function(position, done)
            self.ufo:SetPosition(position)
            lerp_done = done
        end)

        while not lerp_done do
            Wait(1)
        end

        self.ufo:Destroy()
        self.active = false
    end)
end

function Ufo:IsActive()
    return self.active
end


-- SlideObject
-- AttachEntityToEntity

Ufo = Ufo()