Tips = class()

function Tips:__init()
    self.ui = UI:Create({
        name = "tips", 
        path = "tips/client/html/index.html",
        css = {
            ["width"] = "450px",
            ["height"] = "250px",
            ["top"] = "25vh",
            ["position"] = "fixed",
            ["right"] = "0"
        }
    })

    self.time_between_tips = 1000 * 30 * 1 -- Every 30 seconds

    self.lobby_index = 1
    self.ingame_index = 1

    self.tips = 
    {
        Lobby = 
        {
            "Select a map, then hit \"Join\" and \"Ready\" to play a game!",
            "On this server, you \"golf\" by throwing yourself around!",
            "Feel free to join games with your friends and play together.",
            "Press T to open the chat, and Enter to send a message.",
            "You can earn points by playing games of golf!",
            "Don't like the way you look? You can buy and equip skins in the SKINS tab.",
            "Want an extra boost? Check out the POWERUPS tab to buy some sweet powerups to up your game."
        },
        Ingame = 
        {
            "Hold left & right click to adjust your power - then press space to fire! You'll fly in the direction that you are facing.",
            "Your current hole is marked with a green indicator and a tall green laser above it.",
            "When you press space, your character flies in the direction that you look.",
            "Every time you press space, you use a stroke. Try to use as few strokes as possible!",
            "Hold TAB to see the scoreboard.",
            "Don't want to play anymore? Use /quit to leave the game.",
            "On the scoreboard (TAB) you can see par values for each hole on the course.",
            "If you fall into water, a UFO will rescue you and take you to your last safe point."
        }
    }

    self:ShowBeginnerTipsThread()
end

function Tips:ShowBeginnerTipsThread()
    Citizen.CreateThread(function()
        Citizen.Wait(6000)
        while true do
            -- Check if they have played for at least an hour, if so then disable tips
            local time_online = LocalPlayer:GetPlayer():GetValue("TimeOnline")
            if time_online and time_online > 60 then
                break
            end

            self:ShowNextBeginnerTip()
            Citizen.Wait(self.time_between_tips)
        end
    end)
end

function Tips:ShowNextBeginnerTip()
    self.ui:BringToFront()
    local in_lobby = LobbyManager:GetUI():GetVisible()

    if in_lobby then
        self.ui:CallEvent('tips/add', 
            {title = "Tip", description = self.tips.Lobby[self.lobby_index]})
        self.lobby_index = self.lobby_index + 1
        if self.lobby_index > #self.tips.Lobby then self.lobby_index = 1 end
    else
        self.ui:CallEvent('tips/add', 
            {title = "Tip", description = self.tips.Ingame[self.ingame_index]})
        self.ingame_index = self.ingame_index + 1
        if self.ingame_index > #self.tips.Ingame then self.ingame_index = 1 end
    end
end

function Tips:ShowTip(title, description)
    self.ui:BringToFront()
    local in_lobby = LobbyManager:GetUI():GetVisible()

    self.ui:CallEvent('tips/add', {title = title, description = description})
end

Tips = Tips()