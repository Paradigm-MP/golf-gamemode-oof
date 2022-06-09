PauseMenuEdits = class()

function PauseMenuEdits:__init()
    PauseMenu:SetTitle(Colors.RDR2.Green .. "Golf! " .. Colors.RDR2.White .. " | " .. Colors.RDR2.Orange .. "Paradigm")

    Events:Subscribe("LocalPlayerSpawn", function() self:LocalPlayerSpawn() end)
    Events:Subscribe("LocalPlayerDied", function() self:LocalPlayerDied() end)
end

function PauseMenuEdits:LocalPlayerSpawn()
    PauseMenu:SetEnabledWhileDead(false)
end

function PauseMenuEdits:LocalPlayerDied()
    PauseMenu:SetEnabledWhileDead(true)
end

PauseMenuEdits = PauseMenuEdits()