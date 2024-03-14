local Bodypart = class({name = "Bodypart"})

function Bodypart:new(name, health)
    self.name = name 
    self.health = health
    self.maxhealth = health
end 

function Bodypart:hurt(dmg)

    self.health = math.max(0, self.health - dmg)
    
end 

function Bodypart:kill()
    self.health = 0
end

return Bodypart