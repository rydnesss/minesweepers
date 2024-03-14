local Bodypart = require 'obj/bodypart'
local Action = require 'obj/action'

local Entity = class({name = 'entity'})

function Entity:new(x, y)

    self.id = #data.entities + 1
    self.pos = vec2(x, y)
    self.lastpos = self.pos

    self.speed = 0.4
    self.step = 0

    self:generate_body()
    self:generate_info()

    self.alive = true
    self.nearby = 0
    self.actions = self:determine_actions()
    table.insert(data.entities, self)

    self.dragging = 0
    self.dragged = 0
end

function Entity:determine_actions()
    local grid = data.getgrid()

    local t = {
        Action("dig", 
        function(x, y)

            local clicked_cell = data.getcell(x, y)

            for nx = -1, 1 do 
                for ny = -1, 1 do 
                    local cell = grid
                    [math.min(data.getgrid('size'), math.max(1, self.pos.x + nx))]
                    [math.min(data.getgrid('size'), math.max(1, self.pos.y + ny))]
        
                    if cell == clicked_cell and cell.wall > 0 then 
                        cell.wall = cell.wall - 1
                        return true
                    end 

                end 
            end     

            return false
        end, 
        true,
        5 + 0 * 60, 
        lg.getHeight() - 70),

        Action("drag", 
        function(x, y)

            if self.dragging > 0 then 
                self:undrag()
                self.actions[2].name = "drag"
                return true 
            end 

            local clicked_cell = data.getcell(x, y)

            for nx = -1, 1 do 
                for ny = -1, 1 do 
                    local cell = grid
                    [math.min(data.getgrid('size'), math.max(1, self.pos.x + nx))]
                    [math.min(data.getgrid('size'), math.max(1, self.pos.y + ny))]
        
                    if cell == clicked_cell and #cell.contains > 0 and not (self.dragging > 0 or self.dragged > 0) then
                        local char = cell.contains[1] 
                        self.dragging = char.id
                        char.dragged = self.id
                        self.actions[2].name = "drop"
                        return true
                    end 

                end 
            end     

            return false
        end, 
        false,
        5 + 1 * 60, 
        lg.getHeight() - 70)
    }
    return t
end 

function Entity:undrag()
    if self.dragged > 0 then 
        data.entities[self.dragged].dragging = 0  
        self.dragged = 0
    elseif self.dragging > 0 then 
        data.entities[self.dragging].dragged = 0 
        self.dragging = 0 
    end
end 

function Entity:move()

    if self.dragged > 0 and (not self.path or #self.path < 1) then
        if data.entities[self.dragged].pos ~= data.entities[self.dragged].lastpos then  
            self.lastpos = self.pos
            self.pos = data.entities[self.dragged].lastpos
        end
    end

    if self.step > 1 then

        for step = 1, self.step do 
            if self.path and #self.path > 0 then
                self.lastpos = self.pos
                self.pos = table.shift(self.path)
                self:check_surrounding()
            end

            self.step = 0

        end
    else
        local speed = self.dragged > 0 and data.entities[self.dragged].speed or self.speed
        self.step = self.step + speed
    end 
end 

function Entity:null_path()
    self.path = {}
end

function Entity:set_path(path)
    self.path = path
end

function Entity:kill()
    self.alive = false
    self.speed = 0
    self.actions = {}
    if data.entity_index == self.id then 
        data:select_entity()
    end
    self:undrag()
end 

function Entity:go_to(x, y)
    self.path = self.alive and data.pathfind({self.pos.x, self.pos.y}, {x, y}) or nil
    if self.dragged > 0 then 
        self:undrag()
    end
end 

function Entity:check_surrounding()
    self.nearby = 0
    local grid = data.getgrid()

    for x = -1, 1 do 
        for y = -1, 1 do 
            local cell = grid
            [math.min(data.getgrid('size'), math.max(1, self.pos.x + x))]
            [math.min(data.getgrid('size'), math.max(1, self.pos.y + y))]

            if x == 0 and y == 0 then 
                self:check_floor(cell)
            else 
                if cell.mined then 
                    self.nearby = self.nearby + 1 
                end 
            end
        end 
    end 
end 

function Entity:check_floor(cell)
    if cell.mined then 
        cell:explode(1)
        self:take_damage(50)
        self:check_body_integrity()
        self:null_path()
    end 
end 

function Entity:take_damage(dmg)
    for i = 1, dmg do
        table.pick_random(self.body):hurt(1)
    end
end  

function Entity:adjust_speed()
    if self.dragged < 1 then 
        local leghealth = self:gethealth({"Left Leg", "Right Leg"})
        self.speed = leghealth / 100
    end
end

function Entity:check_body_integrity()
    for _, part in ipairs(self.body) do 
        if (part.name == "Head" or part.name == "Body") and part.health == 0 then 
            self:kill()
        end 

        if (part.name == "Left Arm" or part.name == "Right Arm") and part.health == 0 then
            for _, action in ipairs(self.actions) do 
                action.available = false
                if self.dragging > 0 then  
                    self:undrag()
                end
            end 
        end 
    end

    self:adjust_speed()
end

function Entity:draw()

    local grid = data.getgrid()
    
    if self.alive then 
        lg.setColor(1, 1, 1)
        lg.setFont(data.fonts.reg)
        lg.printf(self.nearby, (self.pos.x - 1) * grid.cellsize, (self.pos.y - 1) * grid.cellsize + grid.cellsize, grid.cellsize, 'center')
    else 
        lg.setColor(0.7, 0.7, 0.7)
    end

    lg.rectangle('fill', (self.pos.x - 1) * grid.cellsize, (self.pos.y - 1) * grid.cellsize, grid.cellsize, grid.cellsize ) 
end

function Entity:generate_body()
    self.body = 
    {
        Bodypart('Head', 30),
        Bodypart('Torso', 70),
        Bodypart('Left Arm', 25),
        Bodypart('Right Arm', 25),
        Bodypart('Left Leg', 25),
        Bodypart('Right Leg', 25)
    }
end

function Entity:gethealth(parts) -- parts is a table of strings with the names of the sought after parts.
    local health = 0 
    for _, part in ipairs(self.body) do
        if parts then --If the parts are specified... 
            for _, partname in ipairs(parts) do 
                if part.name == partname then 
                    health = health + part.health 
                end 
            end 
        else --Else just combine all parts' health
            health = health + part.health
        end 
    end 
    return health
end 

function Entity:generate_info()
    local ranks = 
    {
        "2LT.", "1LT.", "CPT.", "MAJ.", "LTC.", "COL.", 
        "PVT.", "PV2.", "PFC.", "CPL.", "SGT.", "SSG.", 
        "SFC.", "MSG.",
    }

    local f_names = 
    {
        ['male'] = 
        {
            "Axel", "Hunter", "Roderick", "Bill", "Jasper", "Kenneth", "Hank", "Roman",
            "Todd", "Vince", "Jax", "Paul", "Russel", "Rusty", "Matthew", "Rick", "Reese",
            "Edward", "Connor",
        },
        ['female'] = 
        {
            "Carol", "Dakotah", "Erika", "Molly", "Jackie", "Constance", "Bonnie", "Scarlett",
            "Alma", "Hattie", "Clara", "Georgia", "Mabel", "Lucy",
        }
    }
    local l_names = 
    {
        "Anderson", "Adams", "Armstrong", "Meyers", "Hertz", "Hart", "Baker", "Banks", "Callaway",
        "Clark", "Corbin", "Cunningham", "Duvall", "Evans", "Graves", "Harding", "Howard",
        "Owens", "Redd", "Cooper", "Grimes", "Barrett", "McConnel", "Rodgers", "Rutherford", "Ridgeway",
    }

    self.rank = table.pick_random(ranks)
    self.gender = love.math.random() < 0.5 and 'male' or 'female'
    self.name = {
        first = table.pick_random(f_names[self.gender]),
        last = table.pick_random(l_names)
    } 
end


return Entity