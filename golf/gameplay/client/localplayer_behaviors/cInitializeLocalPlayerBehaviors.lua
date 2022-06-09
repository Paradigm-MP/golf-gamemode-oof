LocalPlayerBehaviors = class()

function LocalPlayerBehaviors:__init()
    
end

function LocalPlayerBehaviors:__postLoad()
    LocalPlayerBehaviors:InitializeBehaviors()
end

function LocalPlayerBehaviors:InitializeBehaviors()
    self.DetectHoleBehavior = DetectHoleBehavior()
    self.DetectInWaterBehavior = DetectInWaterBehavior()
end

LocalPlayerBehaviors = LocalPlayerBehaviors()