local mod = {}
local loadStateMod = require('modules.loadState')
local exitTime = 0
local time = 0
local mouse = {x = 0,y = 0}
local level = {}
local fixed_delta = 1/60
local arrow = {}
local trail = 0
local debug_bpm = 180--to delete

local playing = false
local old_timestep = 0
local accumulator = 0
local song
local chart_sets = {
    offset = 0,
    size = 300,
    multy = 1,
    total_snap = false
   -- time_offset = 0,
}
local width, height, flags = love.window.getMode( )
--libraries-----------
local bitser = require('libraries.bitser')
local template_handler = require('modules.template_handler')
function new_level()
    return template_handler:get('level')
end
function load_level_fromfile(name)
    local levelDataEnc = love.filesystem.read('data/levels/'..name..'.rvc')
    local unencrypthLevel = bitser.loads(levelDataEnc)
    return unencrypthLevel 
end
function load_level(name)
    local loaded_level
    if name == nil then loaded_level = new_level() end
    if name then loaded_level = load_level_fromfile(name) end
    if name then
        song = love.audio.newSource('assets/music/'..name..'.mp3','static')
    else
        song = love.audio.newSource('assets/music/lasuperatto.mp3','static')
    end
    
    level = loaded_level
end
function draw_arrow(arrow,index)
    local bottom = 420
    local size_factor = chart_sets.size / 300
    local right = 600
    for i,v in pairs(arrow) do
       -- print('draw')
        if v == 1 then
            local d = i
            if type(d) ~= 'number' then return end
            local x =  right - d * 70
            y = bottom-index*height   +chart_sets.offset
           -- local y = bottom-index*500*size_factor + chart_sets.offset
            local amount = chart_sets.size/300
           -- print(amount)
           -- print(i)
            --print(x,y)
            love.graphics.circle('fill',x,y,30)
        end
    end
end
function draw_grid()
    local x1 = 280
    local x2 = 580

    local size_factor = chart_sets.size / 300
    local spacing = (60 / debug_bpm)*chart_sets.multy * height * size_factor

    local referenceY = 470
    --if chart_sets.offset < 0 then referenceY = referenceY + chart_sets.offset end
    love.graphics.line(x1, referenceY, x2, referenceY)

    if spacing <= 0 then return end


    local start_y = chart_sets.offset + 470


    local count = math.ceil(600 / spacing) + 2

    for i = 0, count do
        local y = start_y - spacing * i


        while y > 600 do
            y = y - spacing * count
        end

        if y >= 0 and y <= 600 then
            love.graphics.line(x1, y, x2, y)
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
    love.graphics.push()
    love.graphics.setLineWidth(1)
    love.graphics.print('time: '..tostring(time)..', offset: '..tostring(chart_sets.offset)..', size: '..tostring(chart_sets.size))
    if exitTime > 0 then
        love.graphics.push()
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.print('Exiting...'..'('..tostring(math.floor(exitTime))..')')
        love.graphics.pop()
    end
    draw_grid()
    draw_level()
    love.graphics.pop()
end
function _input(dt)
    local multy = 50
    if love.keyboard.isDown('lshift') then
        multy = 100
    end
    if love.keyboard.isDown('u') then 
        chart_sets.size = chart_sets.size + 1*multy*dt
       -- chart_sets.offset = chart_sets.offset+40*dt
    end
    if love.keyboard.isDown('i') then 
        chart_sets.size = chart_sets.size - 1*multy *dt
    end
    if love.keyboard.isDown('lshift') then
        chart_sets.total_snap = true
    else chart_sets.total_snap = false
    end
end
function get_arrow()
    local size_factor = chart_sets.size/300
    local start = 0
    arrow = nil
    for i,v  in pairs(level.arrows) do
        local vtime = time
        --local trail = 0
        for _,t in pairs(v) do
            ---print(_,t,trail)
            if t == 1 and trail == _ then
                if vtime > i-0.1*size_factor and vtime < i+0.1*size_factor then
                    arrow = v
                    
                end
            end
        end
            --print(i,vtime)
        
    end
end
function timetogrid()
    local spacing = (60 / debug_bpm)*chart_sets.multy
    local y = math.floor(time/spacing) * spacing
    return y
end
function set_trail(x) --hardcoded btw
    if x > 285 and x < 350 then
        trail = 4
        return 
    end
    if x > 358 and x < 422 then
        trail = 3
        return 
    end
    if x > 430 and x < 490 then
        trail = 2
        return 
    end
    if x > 500 and x < 560 then
        trail = 1
        return 
    end
end
function fixed_update(fixed_dt)
    local size_factor = chart_sets.size/300
    if playing then
        chart_sets.offset = chart_sets.offset + fixed_dt*height*size_factor
   --- else 
        --chart_sets.offset = old_timestep
    end
    --print(chart_sets.time_offset)
end
function mod:update(dt)
    local x,y = love.mouse.getPosition()
    mouse.x = x
    mouse.y = y
    local changeValue = 1-(mouse.y/600)
    local size_factor = chart_sets.size/300
    --print(size_factor)
    time = changeValue + (chart_sets.offset/height)
    time = time / size_factor - 0.25/size_factor
    set_trail(x)
    get_arrow()
    
    
    --print(arrow)
    --print(trail)
    --time = time * size_factor
    --if time < 0 then time = 0 end
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
    

    accumulator = accumulator + dt
    while accumulator >= 1/60 do
        fixed_update(1/60)
        accumulator = accumulator - 1/60
    end
end
function play()
    playing = not playing
    if playing == true then
        old_timestep = chart_sets.offset
        if song then
            local value = chart_sets.offset/height
            if value > 0 and value <= song:getDuration() then 
                song:seek(value,'seconds')
            end
            
        end
        love.audio.play(song)
    else
        love.audio.stop(song)
        chart_sets.offset = old_timestep
    end
end
function end_chart()
    print('[Chart_editor]: Saved level.')
    local newLevel = bitser.dumps(level)
    love.filesystem.write('data/levels/newlevel.rvc',newLevel)
end
function mod:keypressed(key)
    if key == 'space' then
        play()
    end
    if key == 'return' then
        end_chart()
    end
end
function addNote(time)
    local d = {0,0,0,0,index = time}
    if level.arrows[time] then d = level.arrows[time] end
    d[trail] = 1
    
    level.arrows[time] = d
end

function deleteperproximity()
    local best = 9999
    for i,v in pairs(level.arrows) do
        local val = time - v.index
       -- print(val,v.index)
        if val < best and val > 0 then
            best = v.index
        end
    end
    print(level.arrows[best])
    return best
end
function deleteNote(timed)
    
    local d = {0,0,0,0,index = timed}
    if level.arrows[timed] then d = level.arrows[timed] end
    d[trail] = 0
    level.arrows[timed] = d
end
function love.mousepressed( x, y, button, istouch, presses )
    local val = timetogrid()
    if chart_sets.total_snap then val = time end
    if button  ==  1 then --left click
        --addNote(time)
        addNote(val)
    end
    
    --if not arrow then return end
    if button == 2 then -- delete arrow
        local val2 = timetogrid()
        if chart_sets.total_snap  then val2 = deleteperproximity() end
        deleteNote(val2)
    end
end

function love.wheelmoved( x, y )
    local d = 0.5
    if love.keyboard.isDown('lctrl') then
        if love.keyboard.isDown('lshift') then d = d/2 end
        chart_sets.multy = chart_sets.multy + d*y
        if chart_sets.multy < 0.25 then chart_sets.multy = 0.25 end
        return
    end
   
    chart_sets.offset = chart_sets.offset + 10*y
    if chart_sets.offset < 0  then chart_sets.offset = 0 end

    
   -- chart_sets.time_offset = chart_sets.time_offset + 10*y
end
return mod