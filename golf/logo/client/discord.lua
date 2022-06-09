local LogoUIManager = class()

function LogoUIManager:__init()
    self.ui = UI:Create({name = "logo", path = "logo/client/html/index.html"})
    self.ui:SendToBack()

    Events:Subscribe("Render", function()
        --Render:SetTextEdge(1, Colors.Black)
        if not shGameplayConfig.ScreenshotMode then
            Render:DrawText(vector2(0.001,0.96), "Join us at http://discord.paradigm.mp", Colors.SaddleBrown, 0.4, true)
        end
    end)
    
end

local LogoUIManager = LogoUIManager()