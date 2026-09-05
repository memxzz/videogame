local mod = {}
local loadStateMod = require('modules.loadState')
local exitTime = 0
local time = 0
local mouse = {x = 0,y = 0}
local level = {}
local fixed_delta = 1/60
local chart_sets = {
    offset = 300,
    size = 120
}
local width, height, flags = love.window.getMode( )
--libraries-----------
local bitser = require('libraries.bitser')
local template_handler = require('modules.template_handler')
function new_level()
    level = template_handler:get('level')
end
function load_level_fromfile(name)
    local levelDataEnc = love.filesystem.read('data/levels/'..name..'.rvc')
    local unencrypthLevel = bitser.loads(levelDataEnc)
    return unencrypthLevel 
end
function load_level(name)
    local loaded_level
    if name == nil then loaded_level = new_level() end
    if loaded_level == nil then loaded_level = load_level_fromfile(name) end
    level = loaded_level
end
function draw_level_old()
    if level == nil then return end
    if level.arrows[time] ~= nil then
        print('time')
        for i,arrow in pairs(level.arrows[time]) do
            if arrow == 1 then
                print('yay')
                love.graphics.circle('fill',i*30 + height/2,time + 85,30)
            end
        end
            --
    end
end
function draw_arrow(arrow,index)
    local bottom = 450
    local right = 250
    for i,v in pairs(arrow) do
       -- print('draw')
        if v == 1 then
            local x = i * 70 + right
            local y = bottom-index*chart_sets.size + chart_sets.offset
           
           -- print(i)
            --print(x,y)
            love.graphics.circle('fill',x,y+40*120/chart_sets.size,30)
        end
    end
end
function draw_level()
    if level == nil then return end
    local top = 0
    local size = chart_sets.size
    local table = {}
    local d = 0
    --size = 0
    for i,v in pairs(level.arrows) do
        --size = size + 1
        d = d + 1
        v.index = i
        table[d] = v
    end
    for i,v in pairs(table) do
        --print(i)
        --size = size + 1
        draw_arrow(v,v.index)
      
    end
end
function mod:load()
    print('[Chart_editor]: Loaded.')
    load_level('lasuperatto')
    print('[Chart_editor]: Level: '..tostring(level))
end
function mod:draw()
    love.graphics.print('time: '..tostring(time)..', offset: '..tostring(chart_sets.offset)..', size: '..tostring(chart_sets.size))
    if exitTime > 0 then
        love.graphics.push()
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.print('Exiting...'..'('..tostring(math.floor(exitTime))..')')
        love.graphics.pop()
    end
    draw_level()
end
function _input(dt)
    local multy = 1
    if love.keyboard.isDown('lshift') then
        multy = 10
    end
    if love.keyboard.isDown('o') then 
        chart_sets.offset = chart_sets.offset + 1*multy*dt
    end
    if love.keyboard.isDown('p') then 
        chart_sets.offset = chart_sets.offset - 1*multy *dt
    end
    if love.keyboard.isDown('u') then 
        chart_sets.size = chart_sets.size + 1*multy*dt
       -- chart_sets.offset = chart_sets.offset+40*dt
    end
    if love.keyboard.isDown('i') then 
        chart_sets.size = chart_sets.size - 1*multy *dt
    end
end
function mod:update(dt)
    local x,y = love.mouse.getPosition()
    mouse.x = x
    mouse.y = y
    local changeValue = 1-(mouse.y/600)
    time = changeValue*chart_sets.size + chart_sets.offset * 100
    if love.keyboard.isDown('backspace') then
        exitTime = exitTime + dt
        if exitTime > 4 then
            exitTime = 0
            loadStateMod:loadState('mainMenu')
        end
        return
    end
    exitTime = 0
    _input(dt)
end
return mod