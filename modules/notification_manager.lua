--and this is the notification manager
--it's just a module that makes notifications :)
local mod = {
    items = {}
}
local time = require('libraries.time')
local lume = require('libraries.lume')
local width, height, flags = love.window.getMode( )
---@class Notification
---@field position {x:number,y:number}
---@field icon? nil
---@field text {title:string,subtitle:string}
local template = {
    index = 0,
    position = {x=0,y=0},
    icon = nil,
    size = {
        x = 300,
        y = 80
    },
    text = {
        title = 'Title',
        subtitle = 'Subtitle'
    },
    deleting = false,
    time = 1
}
local fonts = {
    montserrat = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 25),size = 25,resize = false},
    montserrat2 = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 15),size = 15,resize = false}
}
function shallow_copy(t)
  if type(t) ~= "table" then
        return t
    end

    local copy = {}

    for k, v in pairs(t) do
        copy[shallow_copy(k)] = shallow_copy(v)
    end

    return copy
end
function mod:draw()
    love.graphics.push("all")
    love.graphics.origin()
    for i,obj in pairs(mod.items) do
        local x = obj.position.x
        local y = obj.position.y
        love.graphics.setColor(0.1,0.1,0.1,1)
        love.graphics.rectangle('fill',x,y,obj.size.x,obj.size.y)
        love.graphics.setColor(0.6,0.6,0.6,1)
        love.graphics.rectangle('line',x,y,obj.size.x,obj.size.y)
        love.graphics.setColor(1,1,1,1)

        love.graphics.setFont(fonts.montserrat.obj)
        love.graphics.print(obj.text.title,x+80,y) --title

        love.graphics.setFont(fonts.montserrat2.obj)
        love.graphics.print(obj.text.subtitle,x+80,y+30) --subtitle
    end
    
    love.graphics.setColor(1,1,1,1)
    love.graphics.pop()
end
function mod:resize( w, h )
    width, height, flags = love.window.getMode( )
end
---@return Notification
function mod:add()
    local item = shallow_copy(template)
    mod.items[#mod.items+1] = item
    local added = mod.items[#mod.items]
    mod.items[#mod.items].index = #mod.items
    added.position.y = height - added.size.y - 20
    added.position.x = width+300
    added.text.title = tostring(added.index)
    time:addTask(function()
        added.deleting = true
    end,{timeDue = 8})
    return added
end
function mod:update(dt)
    time:update(dt)

    for i = #mod.items, 1, -1 do
        local obj = mod.items[i]
        local indi = i
        local vel = 3

        local x = width - obj.size.x
        local y = height - obj.size.y - 20

        if obj.deleting then
            x = width + 300

            obj.time = obj.time - dt

            if obj.time <= 0 then
                table.remove(mod.items, i)
                goto continue
            end
        end

        local yoffset = (obj.size.y + 15) * (#mod.items - indi)

        obj.position.x = lume.lerp(obj.position.x, x, dt * vel)
        obj.position.y = lume.lerp(obj.position.y, y - yoffset, dt * vel)

        ::continue::
    end
end


return mod