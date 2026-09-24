local mod = {
    items = {}
}
local time = require('libraries.time')
local lume = require('libraries.lume')
local width, height, flags = love.window.getMode( )
local template = {
    position = {x=0,y=0},
    icon,
    text = {
        title = 'Title',
        subtitle = 'Subtitle'
    }
}
local fonts = {
    montserrat = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 30),size = 12,resize = false}
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
    love.graphics.setFont(fonts.montserrat)
    love.graphics.push("all")
    love.graphics.origin()
    
    local size = {
        x = 300,
        y = 80
    }
    for i,obj in pairs(mod.items) do
        love.graphics.setColor(0.1,0.1,0.1,1)
        love.graphics.rectangle('fill',width-size.x,height-size.y-20,size.x,size.y)
        love.graphics.setColor(0.6,0.6,0.6,1)
        love.graphics.rectangle('line',width-size.x,height-size.y-20,size.x,size.y)
        love.graphics.setColor(1,1,1,1)
    end
    
    love.graphics.setColor(1,1,1,1)
    love.graphics.pop()
end
function love.resize( w, h )
    width, height, flags = love.window.getMode( )
end
function mod:add()
    local item = shallow_copy(template)
    table.insert(mod.items,item)
    local added = mod.items[#mod.items]
    time:addTask(function() 
        mod.items[#mod.items] = nil
    end,{timeDue = 12})
    return added
end
function mod:update(dt)
    time:update(dt)
end
return mod