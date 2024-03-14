local Cell = class({name = 'cell'})

function Cell:new(x, y, wall)
    self.pos = vec2(x, y)
    self.wall = wall
    self.hovered = false 
    self.mined = false 
    self.revealed = false
    self.exploded = false
    self.contains = {}
end

function Cell:plantmine()
    self.mined = true
end 

function Cell:demine()
    self.mined = false 
    data.init.mines = data.init.mines - 1
end

local particle = love.graphics.newImage('img/particle.png')
local explosion = love.graphics.newParticleSystem(particle, 120)
explosion:setParticleLifetime(1, 3)
explosion:setLinearAcceleration(-160, -160, 160, 160)
explosion:setSpread(6.2)
explosion:setSpeed(-160, 160)
explosion:setColors(1, 1, 1, 1, 1, 1, 1, 0)

function Cell:explode(n) --n is blast radius
    local grid = data.getgrid()
    self:demine()
    table.insert(data.explosions, {effect = explosion:clone(), pos = self.pos, done = false})

    for x = -n, n do 
        for y = -n, n do
            local cell = grid
            [math.min(data.getgrid('size'), math.max(1, self.pos.x + x))]
            [math.min(data.getgrid('size'), math.max(1, self.pos.y + y))]

            cell.wall = math.max(0, cell.wall - 1)
            
            if cell.mined then --Chain reaction
                cell:explode(n) --Any offset mines explode with an even stronger radius
            end

            cell.revealed = true
            if #cell.contains > 0 then
                cell.contains[1]:take_damage(50)
                cell.contains[1]:check_body_integrity()
                cell.contains[1]:null_path()
            end
        end 
    end  
end 


local img = 
{
    ['wall'] = 
    {
        love.graphics.newImage('img/wall/1.png'),
        love.graphics.newImage('img/wall/2.png'),
        love.graphics.newImage('img/wall/3.png')
    }
}

function Cell:draw(cx, cy, size)

    local grid = data.getgrid()
    local x = self.pos.x 
    local y = self.pos.y

    local style = 'line'

    lg.setColor(0.1, 0.15, 0.15)

    
    if grid[x][y].wall > 0 then 
        lg.draw(img['wall'][grid[x][y].wall], cx, cy, nil, grid.cellsize/32)
    end

    if grid[x][y].hovered then 
        lg.setColor(0.6, 0.6, 0.6, 0.5)
        lg.rectangle('fill', cx, cy, grid.cellsize, grid.cellsize)
    end 

    if grid[x][y].mined and (grid[x][y].revealed or DEBUG.showmines) then 
        style = 'fill'
        lg.setColor(0.8, 0.4, 0.4)
    end

    lg.rectangle(style, cx, cy, grid.cellsize, grid.cellsize)

end 

return Cell