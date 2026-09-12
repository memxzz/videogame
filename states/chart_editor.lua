local mod = {}
local loadStateMod = require('modules.loadState')
local exitTime = 0
local time = 0
local mouse = {x = 0,y = 0}
local level = {}
local fixed_delta = 1/60
local arrow = {}
local trail = 0
local assets = {}
local playing = false
local old_timestep = 0
local accumulator = 0
local song
local last_arrow = {}
local placeable = false
local chart_sets = {
    offset = 0,
    size = 300,
    multy = 0.5,
    total_snap = false
   -- time_offset = 0,
}
local width, height, flags = love.window.getMode( )

local bitser = require('libraries.bitser')
local w_items = require('libraries.workable_items')
local template_handler = require('modules.template_handler')
local selecting =  false
local selected_area = {
    point1 = {x = 0,y = 0},
    point2 = {x = 0,y = 0}
}
local selected_notes
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
    assets['longnote_start'] = love.graphics.newImage('assets/arrow_long_start.png')
    assets['longnote_end'] = love.graphics.newImage('assets/arrow_long_end.png')
    level = loaded_level
end
function distance ( pos1, pos2 )
  local dx = pos1.x - pos2.x
  local dy = pos1.y - pos2.y
  return math.sqrt ( dx * dx + dy * dy )
end
function draw_selecting_box()
    if not selecting then return end
    
    
    local x,y = love.mouse.getPosition()
    local distance = distance(selected_area.point1,{x = x,y = y})
    if distance <= 10 then return end
    love.graphics.push("all")

    love.graphics.origin()
    love.graphics.setColor(0,0.5,1,0.7)
    love.graphics.rectangle('fill',
        x,
        y,
        selected_area.point1.x-x,
        selected_area.point1.y-y
    )
    love.graphics.setColor(0,0.3,0.8,0.8)
    love.graphics.rectangle('line',
        x,
        y,
        selected_area.point1.x-x,
        selected_area.point1.y-y
    )
    love.graphics.setColor(1,1,1,1)
    love.graphics.pop()
end
function arrow_manage_asset(v,x,y)
    if v <= 2 then
        love.graphics.circle('fill',x,y,30)
    end
    --if v == 2 then
    --    love.graphics.draw(assets['longnote_start'],x-35,y-35,nil,0.1,0.1)
    --end
    if v == 3 then
        love.graphics.draw(assets['longnote_end'],x-35,y-35,nil,0.1,0.1)
    end
end
local accumu = 0
local tails = {0,0,0,0}
local lastPrinted = 999999
function draw_tail(v,x,i,arrow,index)
    if v ~= 2 then return end
    if not arrow.tails then return end
    local bottom = 420
    local size_factor = chart_sets.size / 300
    --local y = arrow.tails[i]+chart_sets.offset
    local  y = index*height*size_factor
    for r = 0,(arrow.tails[i]*10)-2 do
        local sprite = 'longnote_start'
        local d = bottom-(r/10)*height*size_factor+chart_sets.offset-y
        d = d - 70*size_factor
        if r >= (arrow.tails[i]*10)-2 then 
        --    sprite = 'longnote_end' 
            End = true
        end
        love.graphics.draw(assets[sprite],x-35,d,nil,0.1,0.1*size_factor)
        
    end
    local ts = bottom-arrow.tails[i]*height*size_factor+chart_sets.offset-y
    local sprite = 'longnote_end'
    local sprite2 = 'longnote_start'
    love.graphics.draw(assets[sprite],x-35,ts,nil,0.1,0.1*size_factor)
    love.graphics.draw(assets[sprite2],x-35,ts+50*size_factor,nil,0.1,0.1*size_factor)
    --if ts <= 167 then return end
    --love.graphics.draw(assets[sprite2],x-35,y-ts+70,nil,0.1,0.1*size_factor)
end
function draw_arrow(arrow,index)
    local bottom = 420
    local size_factor = chart_sets.size / 300
    local right = 600
    for i,v in pairs(arrow) do
       -- print('draw')
        if v ~= 0 then
            local d = i
            if type(d) ~= 'number' then return end
            local x =  right - d * 70
            y = bottom-index*height*size_factor+chart_sets.offset
            
            --local amount = chart_sets.size/300
            draw_tail(v,x,i,arrow,index)
            arrow_manage_asset(v,x,y)
            
        end
    end
end
function draw_grid()
    local x1 = 280
    local x2 = 580

    local size_factor = chart_sets.size / 300
    local spacing = (60 / level.bpm)*chart_sets.multy * height * size_factor

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
function add_gui()
    local bpm_box = w_items:add_item('textBox')
    print("box",bpm_box)
    bpm_box.params.text_label = 'bpm'
    bpm_box.position = {
        x = width-220,
        y = 50
    }
    bpm_box.params.on_text_return = function(text)
        level.bpm = tonumber(text)
    end
end
function mod:load(params)
    w_items:clear()
    print('[Chart_editor]: Loaded.')
    --load_level('lasuperatto')
    load_level(params.song)

    add_gui()

    print('[Chart_editor]: Level: '..tostring(level))
end
function mod:draw()
    love.graphics.push()
    love.graphics.setLineWidth(1)
    love.graphics.print('time: '..tostring(time)..', offset: '..tostring(chart_sets.offset)..', size: '..tostring(chart_sets.size)..', bpm: '..tostring(level.bpm))
    love.graphics.setColor(1,1,1,1)

    
    if exitTime > 0 then
        love.graphics.push()
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.print('Exiting...'..'('..tostring(math.floor(exitTime))..')')
        love.graphics.pop()
    end
    draw_grid()
    draw_level()
    draw_selecting_box()
    w_items:draw()
    love.graphics.pop()
    love.graphics.rotate(0)
end
function _input(dt)
    local multy = 50
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
    local spacing = (60 / level.bpm)*chart_sets.multy
    local y = math.floor(time/spacing) * spacing
    return y
end
function set_trail(x) --hardcoded btw
    if x > 600 then placeable = false return end
    if x < 263 then placeable = false return end
    placeable = true
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
    w_items:update(dt)
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
    local size_factor = chart_sets.size / 300
    if playing == true then
        old_timestep = chart_sets.offset
        if song then
            local value = (chart_sets.offset/height) /size_factor
            if value > 0 and value <= song:getDuration() then 
                song:seek(value,'seconds')
            end
            
        end
        song:play()
        --love.audio.play(song)
    else
        song:stop()
        --love.audio.stop(song)
        chart_sets.offset = old_timestep
    end
end
function end_chart()
    print('[Chart_editor]: Saved level.')
    local newLevel = bitser.dumps(level)
    love.filesystem.write('data/levels/newlevel.rvc',newLevel)
end
function love.textinput(key)
    w_items:textinput(key)
end
function mod:keypressed(key)
    w_items:keypressed(key)
    if key == 'space' then
        play()
    end
    if key == 'return' then
        end_chart()
    end
end
function addNote(time,typ)
    if not placeable then return end
    local d = {0,0,0,0,index = time}
    if level.arrows[time] then d = level.arrows[time] end
    d[trail] = typ
    if typ ~= 3 then last_arrow = d end
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
    w_items:mousepressed(x,y,button,istouch,presses)
    selected_area.point1.x = x
    selected_area.point1.y = y
    if button == 1 then selecting = true  end
    if chart_sets.total_snap then val = time end
    if button  ==  1 then --left click
        --addNote(time)
        addNote(val,1)
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
    if love.keyboard.isDown('lshift') then
        chart_sets.size = chart_sets.size + 10*y
        chart_sets.offset = chart_sets.offset + (chart_sets.offset/chart_sets.size)*10*y --the happines and wholesomeness formula
        return
    end
    chart_sets.offset = chart_sets.offset + 25*(300/chart_sets.size)*y
    if chart_sets.offset < 0  then chart_sets.offset = 0 end

    
   -- chart_sets.time_offset = chart_sets.time_offset + 10*y
end
function make_selection()
    local p1 = selected_area.point1
    local p2 = selected_area.point2
    local res = p1.x-p2.x
    local param0 = 1
    local param1 = trail
    local d = 1
    if res < 0 then
        print('left 2 right')
        param0 = 4
        d = -1
    end
    for i = param0,param1,d do
        for i,v in pairs(level.arrows)
            print(v)
        end
    end
    print(trail)
end
function love.mousereleased( x, y, button, istouch, presses )
    if button == 1 then 
        selected_area.point2 = {x = x,y = y}
        if selecting then make_selection() end
        selecting = false  
    end
    if not last_arrow then return end
    if not last_arrow.index then return end
    local y = timetogrid()
    local distance = y-last_arrow.index
    if distance <= 0 then return end
    if not last_arrow[trail] then return end 
    if last_arrow[trail] == 0 then return end
    local tails = level.arrows[last_arrow.index].tails
    if not tails then tails = {0,0,0,0} end
    level.arrows[last_arrow.index][trail] = 2
    tails[trail] = y-last_arrow.index
    level.arrows[last_arrow.index].tails = tails
    print('added longnote at: '..tostring(y)..', longness: '..tostring(y-last_arrow.index))
end
return mod