GolfClub = class()

function GolfClub:__init()

    Events:Subscribe("LocalPlayerChat", function(args)
        if args.text == "/club" then
            self:CreateObjects()
        end
    end)

end

function GolfClub:Render()

    if not self.ready then return end

    local should_show_club = GameManager:GetIsGameInProgress() and PlayerLauncher:CanIncreasePower()

    if not should_show_club then
        self:HideObjects()
        return
    end

    self.objects.club:SetPosition(LocalPlayer:GetPosition() + vector3(0, 0, 0.5) - Camera:GetRotation() * 2)

    local rot = Camera:GetRotation() * (180 / math.pi) + vector3(0, -90, 0)
    self.objects.club:SetRotation(rot)

end

function GolfClub:HideObjects()
    self.objects.club:SetPosition(vector3(0, 0, 0))
end

function GolfClub:CreateObjects()

    self.objects = {}

    local num_objects_created = 0

    self.objects.club = Object({
        model = "p_fencebeamstandard_qpa_01ax",
        position = Camera:GetPosition(),
        callback = function()
            num_objects_created = num_objects_created + 1
        end
    })

    self.objects.base = Object({
        model = "p_fencebreakpost01x",
        position = Camera:GetPosition(),
        callback = function()
            num_objects_created = num_objects_created + 1
        end
    })

    Citizen.CreateThread(function()
        while num_objects_created < 2 do
            Wait(50)
        end

        -- Objects have been created, now attach!
        self.objects.base:AttachToEntity({
            entity = self.objects.club,
            position = vector3(0, 0, 0.075),
            fixedRot = true
        })
        
        Chat:Debug("Attached!")

        self.ready = true
        Events:Subscribe("Render", function(args) self:Render(args) end)
        
    end)

end

if IsTest then
    GolfClub = GolfClub()
end