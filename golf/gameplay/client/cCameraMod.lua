CameraMod = class()

function CameraMod:__init()
    Events:Subscribe("Render", function()
        ClampGameplayCamPitch(tofloat(-360.0), tofloat(360.0))
    end)
end

CameraMod = CameraMod()