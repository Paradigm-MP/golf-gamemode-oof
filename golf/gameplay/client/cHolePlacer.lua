HolePlacer = class()

function HolePlacer:__init()
    self.poses = {}

    -- RegisterCommand("filter", function(source, args, rawCommand)
    --     Filter:Clear()
    --     Filter:Apply({
    --         name = args[1],
    --         amount = args[2] and tonumber(args[2]) or 1
    --     })
    -- end)
    
    RegisterCommand("hole", function(source, args, rawCommand)
        table.insert(self.poses, {
            pos = LocalPlayer:GetPosition()
        })

        for k, v in pairs(self.poses) do
            local x, y, z = v.pos.x, v.pos.y, v.pos.z
            print('{"pos": {"x": ' .. tostring(x) .. ', "y": ' .. tostring(y) .. ', "z": ' .. tostring(z) .. '}')
        end
    end)

    RegisterCommand("holelist", function(source, args, rawCommand)
        for k, v in pairs(self.poses) do
            local x, y, z = v.pos.x, v.pos.y, v.pos.z
            print('{"pos": {"x": ' .. tostring(x) .. ', "y": ' .. tostring(y) .. ', "z": ' .. tostring(z) .. '}')
        end
    end)
end

HolePlacer = HolePlacer()