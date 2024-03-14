local Action = class({name = 'action'})

function Action:new(name, onclick, keep, x, y)
    self.name = name
    self.x, self.y = x, y
    self.keep = keep
    self.available = true
    self.onclick = onclick
end 

function Action:draw()

    lg.setColor(0.1, 0.15, 0.15)
    lg.rectangle('fill', self.x, self.y, 60, 60)

    lg.setColor(0.8, 0.8, 0.8)
    lg.rectangle('line', self.x, self.y, 60, 60)

    lg.setColor(0.8, 0.8, 0.8)
    lg.setFont(data.fonts.reg)
    lg.printf(self.name, self.x + 5, self.y + 40, 50, 'center')

    if not self.available then 
        lg.setColor(0, 0, 0, 0.7)
        lg.rectangle('fill', self.x, self.y, 60, 60)
    end
end 

return Action 