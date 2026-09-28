local mod = {}

local loadState = require('modules.loadState')
local time = require('libraries.time')
local lume = require('libraries.lume')
local menus = {
    config = require('states.menus_main_menu.config')
}
local width, height, flags = love.window.getMode( )
local sprites = {}
local dt = 0.016
local list = {
    {position = {x=0,y=0}, name = 'play',time = 1},
    {position = {x=0,y=0}, name = 'chart editor',time = 1},
    {position = {x=0,y=0}, name = 'configuration',time = 0},
    {position = {x=0,y=0}, name = 'exit',time = 0.5},

}
local selection = 1
local fonts = {}
local selected = false
local states = {
    mainMenu = true,
    configMenu = false,
}
local function loadFonts()
    fonts.montserrat = love.graphics.newFont("assets/fonts/montserrat.ttf", 50)
end 
function mod:load()
    for i,v in pairs(list) do v.position.x = -500-i*200 end
    loadFonts()
    love.graphics.setFont(fonts.montserrat)
    sprites["buttonSel"] = love.graphics.newImage('assets/mainMenu/buttonSelected.png')
    sprites["buttonUnsel"] = love.graphics.newImage('assets/mainMenu/buttonUnselected.png')
    menus.config:load()

end
function mod:update(dt)
    dt = dt
    time:update(dt)
    menus.config:update(dt)
    menus.config.open = states.configMenu
end
local function changeState(state)
    for i,v in pairs(states) do
        if i ~= state then
            states[i] = false
        else
            states[i] = true
        end
    end
end
function mod:draw()
    love.graphics.setColor(1,1,1,1)
    for i,option in pairs(list) do
        local sprite = "buttonUnsel"
        if i == selection then sprite = 'buttonSel' end
        local spriteW = sprites[sprite]:getWidth()
        local spriteH = sprites[sprite]:getHeight()
        local multy =  0.2
        local target = spriteW/2*multy - 100
        if selected then target = -width-i*200 end
        local vel = 0.35
        option.position.x = lume.lerp(option.position.x,target,dt*vel)
        local x = option.position.x
        local y = height/4 + (i*100) -  spriteH/2*multy
        
        love.graphics.draw(sprites[sprite],x,y,nil,multy,multy)
        love.graphics.print(option.name,x+50,y,nil)
    end
    menus.config:draw()
end
function select(option)
    if selected then return end
    selected = true
    time:addTask(function() 
        print('here')
        if option.name == 'play' then loadState:loadState('levelSelector') end
        if option.name == 'chart editor' then loadState:loadState('chart_editor',{}) end
        if option.name == 'configuration' then changeState('configMenu') end
        if option.name == 'exit' then love.event.quit() end
    end,{timeDue = option.time})

end
function mod:keypressed(key)
    menus.config:keypressed(key)
    if key == 'escape' then 
        selected = false
        changeState('mainMenu') 
    end
    if selected then return end
    if not states.mainMenu then return end
    if key == 'up' then selection = selection - 1 end
    if key == 'down' then selection = selection + 1 end
    if key == 'return' then select(list[selection]) end
    
    if selection  < 1 then selection = 1 end
    if selection  > #list then selection = #list end

end
function mod:mousepressed( x, y, button, istouch, presses )
    
end
function love.resize( w, h )
    width, height, flags = love.window.getMode( )
    menus.config:resize()
end
return mod