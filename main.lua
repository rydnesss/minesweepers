require('libs/batteries'):export()
lg = love.graphics

data = 
{
    init = 
    {
        gridsize = 20,
        mines = 15,
        squadsize = 3
    },
    fonts = 
    {
        heading = love.graphics.newFont('fonts/Emulogic.ttf', 20),
        reg = love.graphics.newFont('fonts/Emulogic.ttf', 12)
    },
    explosions = {},
    timer = {tickspeed = 0.01, i = 0}, --i is the counter, tickspeed is the rate at which the game refreshes
    mouse = {},
    entities = {},
    entity_index = 1,
    action_index = 0
}

DEBUG = 
{
    showmines = false
}

local Entity = require 'obj/entity'
local Cell = require 'obj/cell'

-------------------------------------------------------------------------------------------

function love.load()
    data.setgrid(data.init.gridsize)

    for i = 1, data.init.squadsize do 
        Entity(i, 1)
    end

    for i = 1, data.init.mines do 
        data.plantmine()
    end

    data.clear_spawn()
end 

function love.update(dt)
    data.timer.i = data.timer.i + dt 
    if data.timer.i > data.timer.tickspeed then 
        data.timer.i = 0
        data.tickgrid() --Update on a tick 
    end

    data.updategrid(dt) --Update on every frame

end 

function love.draw()
    data.drawgrid()
    data.drawgui()
end 

function love.mousepressed(x, y, button)
    local mouse = data.mouse
    local cell = data.getcell(mouse.tx, mouse.ty)

    if button == 1 then

        local keep_selection = false

        ---This code handles ability application 

        if data.action_index > 0 then 
            local action = data.entities[data.entity_index].actions[data.action_index]
            if action.onclick(mouse.tx, mouse.ty) and action.keep then 
                keep_selection = true 
            end  
        end  
        ---
        
        ---This code handles entity and ability selection

        if cell and #cell.contains > 0 and data.action_index < 1 then --If a tile with an entity is clicked and no action is chosen
            data.select_entity(cell.contains[1].id) --Select the entity
            keep_selection = true
        end 

        if data.entity_index > 0 then 
            for i, action in ipairs(data.entities[data.entity_index].actions) do 
                if x > action.x and x < action.x + 60 and y > action.y and y < action.y + 60 and action.available then 
                    keep_selection = true
                    data.action_index = i 
                end 
            end
        end 

        if not keep_selection then
            data.select_entity()
        end 

    end
    
    if button == 2 then 

        if cell and cell.wall < 1 and data.entity_index > 0 then --Else if a cell that's not a wall is clicked & an entity is selected.
            data.entities[data.entity_index]:go_to(mouse.tx, mouse.ty) --Go there
        end 
    end 
end 

function love.keypressed(key)
    if key == ',' then 
        if data.entity_index > 1 then 
            data.entity_index = data.entity_index - 1
        end 
    elseif key == '.' then 
        if data.entity_index < #data.entities then 
            data.entity_index = data.entity_index + 1 
        end 
    end 

    if key == 'space' and not DEBUG.showmines then 
        DEBUG.showmines = true 
    else
        DEBUG.showmines = false
    end
end 

-------------------------------------------------------------------------------------------

function data.setgrid(size) 
    local g = {}

    for x = 1, size do 
        g[x] = {}
        for y = 1, size do

            local wall = love.math.random() > 0.7 and 3 or 0

            g[x][y] = Cell(x, y, wall)
        end 
    end 

    data.grid = g
    data.grid.size = size
    data.grid.cellsize = (lg.getHeight() - 80) / size
end 

function data.getgrid(v)
    return data.grid[v] or data.grid
end 

function data.getcell(x, y)

    if x == 'rand' then 
        x = love.math.random(1, data.getgrid('size'))
        y = love.math.random(1, data.getgrid('size'))

        while data.getgrid()[x][y].wall > 0 or #data.getgrid()[x][y].contains > 0 do 
            x = love.math.random(1, data.getgrid('size'))
            y = love.math.random(1, data.getgrid('size'))
        end 

        return data.getgrid()[x][y]

    end 

    return data.getgrid()[x] and data.getgrid()[x][y]
end 

function data.tickgrid() --Happens on every tick
    local grid = data.getgrid()
    for x = 1, grid.size do 
        for y = 1, grid.size do 
            grid[x][y].hovered = false 
        end 
    end 

    for _, entity in ipairs(data.entities) do 
        entity:move()
    end
end

function data.updategrid(dt) --Happens on every frame
    data.mouse:update()
    local grid = data.getgrid()

    for x = 1, grid.size do 
        for y = 1, grid.size do 
            grid[x][y].contains = {}
        end 
    end 

    for i,explosion in ipairs(data.explosions) do
        if not explosion.done then 
            explosion.done = true 
            explosion.effect:emit(32)
        end   
        explosion.effect:update(dt)

        if explosion.effect:getCount() < 1 then 
            table.remove(data.explosions, i)
        end
    end

    for _, entity in ipairs(data.entities) do 
        table.insert(data.grid[entity.pos.x][entity.pos.y].contains, entity)
    end

end

function data.drawgrid()                            
    local grid = data.getgrid()

    for x = 1, grid.size do 
        for y = 1, grid.size do 

            local cx = (x - 1) * grid.cellsize
            local cy = (y - 1) * grid.cellsize 

           grid[x][y]:draw(cx, cy, grid.cellsize)

            for i, entity in ipairs(data.entities) do
                if i == data.entity_index then 
                    lg.setColor(1, 1, 1, 0.01)
                    lg.circle('line', (entity.pos.x - 1) * grid.cellsize + grid.cellsize / 2, (entity.pos.y - 1) * grid.cellsize + grid.cellsize / 2, grid.cellsize * 6/7)
                end
                entity:draw()
            end 
        
        end 
    end 

    for _, explosion in ipairs(data.explosions) do 
        love.graphics.draw(explosion.effect, (explosion.pos.x - 1) * grid.cellsize + grid.cellsize / 2, (explosion.pos.y - 1) * grid.cellsize  + grid.cellsize / 2)
    end
end

function data.plantmine()
    data.getcell('rand'):plantmine()

end 

function data.select_entity(i)
    data.entity_index = data.entities[i] and i or 0
    data.action_index = 0
end 


function data.pathfind(a, b) --Uses Max Cahill's A* pathfinding from 'batteries'.
    local a = data.grid[a[1]][a[2]].pos
    local b = data.grid[b[1]][b[2]].pos

    return pathfind {
        start = a, 
        is_goal = function(v) return v == b end, 
        neighbours = function(n)
            local adjacent = {}
            for x = -1, 1 do 
                for y = -1, 1 do
                    if (x ~= 0 or y ~= 0) and (x == 0 or y == 0) then --Only checks non-diagonal neighbours
                        local cell = data.getgrid()
                        [math.min(data.getgrid('size'), math.max(1, n.x + x))]
                        [math.min(data.getgrid('size'), math.max(1, n.y + y))]

                        if cell.wall < 1 and (#cell.contains < 1 or not cell.contains[1].alive or cell.contains[1].dragged > 0) then --Checks viability
                            table.insert(adjacent, cell.pos)
                        end
                    end
                end 
            end  
            return adjacent
        end
    }
end

function data.clear_spawn()
    local grid = data.getgrid()
    for x = 1, 3 do 
        for y = 1, 3 do 
            grid[x][y].wall = 0 
            if grid[x][y].mined then 
                grid[x][y]:demine()
            end
        end 
    end 
end 

function data.drawgui()
    local boundary = {}
    boundary.x = data.getgrid('size') * data.getgrid('cellsize') + 5
    boundary.y = 5 
    boundary.w = lg.getWidth() - boundary.x - 10
    boundary.h = lg.getHeight() - 10

    lg.rectangle('line', boundary.x, boundary.y, boundary.w, boundary.h)

    lg.setFont(data.fonts.heading)

    local char = data.entities[data.entity_index]
    
    if char then 
        lg.printf(char.rank .. " " .. char.name.first .. " " .. char .name.last, boundary.x + 15, boundary.y + 25, boundary.w - 30)

        for y, part in pairs(char.body) do
            
            local color 
            local crossout = false 
            local hp_percent = part.health / part.maxhealth 
            
            if hp_percent > 0.8 then  
                color = {0.2, 0.8, 0.2}
            elseif hp_percent > 0.5 then 
                color = {0.6, 0.6, 0.2}
            elseif hp_percent > 0 then 
                color = {0.9, 0.4, 0.2}
            else 
                color = {0.2, 0.2, 0.2}
                crossout = true
            end 

            love.graphics.setColor(color)
            lg.rectangle('fill', boundary.x + 15, boundary.y + 87 + (y - 1) * 35, 20, 20)

            if crossout then 
                lg.setLineWidth(3)
                lg.line(boundary.x + 50, boundary.y + 97 + (y - 1) * 35, boundary.x + 50 + lg.getFont():getWidth(part.name), boundary.y + 97 + (y - 1) * 35)
                lg.setColor(0.4, 0.4, 0.4)
                lg.setLineWidth(1)
            else 
                lg.setColor(1, 1, 1)
            end

            lg.printf('[' .. part.name .. ']' .. ' [' .. part.health .. '/' .. part.maxhealth .. ']', boundary.x + 45, boundary.y + 85 + (y - 1) * 35, boundary.w - 30)

            lg.setColor(1, 1, 1)
            lg.line(boundary.x + 10, boundary.y + 115 + (y - 1) * 35, boundary.x + boundary.w - 30, boundary.y + 115 + (y - 1) * 35)
        end 
    end

    lg.printf("Mines left: " .. data.init.mines, boundary.x + 15, boundary.h - 60, boundary.w - 30)

    --Actions

    if data.entity_index > 0 then 

        for x,action in ipairs(data.entities[data.entity_index].actions) do 
            action:draw(available)
        end 
    end

    if data.action_index > 0 then 
        local action = data.entities[data.entity_index].actions[data.action_index]
        lg.print(action.name, data.mouse.x, data.mouse.y + 25)
    end


end 

function data.mouse:update()
    self.x = love.mouse.getX()
    self.y = love.mouse.getY()
    self.tx = math.floor(love.mouse.getX() / data.getgrid('cellsize')) + 1
    self.ty = math.floor(love.mouse.getY() / data.getgrid('cellsize')) + 1

    local grid = data.getgrid()
    local cell = data.getcell(self.tx, self.ty)
    if cell then cell.hovered = true end   
end 