local mod = {}
local loadStateMod = require('modules.loadState')
local exitTime = 0
local time = 0
local mouse = {x = 0,y = 0}
local level = {}
local fixed_delta = 1/60
local wavetime = 0
local arrow = {}
local trail = 0
local assets = {}
local playing = false
local old_timestep = 0
local accumulator = 0
local velMulty = 1
local song
local songData
local soundSamples = {}
local last_arrow = {}
local placeable = false
local chart_sets = {
    offset = 0,
    size = 300,
    multy = 0.5,
    total_snap = false
   -- time_offset = 0,
}
local level_name = ''
local width, height, flags = love.window.getMode( )
local fps = 0
local bitser = require('libraries.bitser')
local w_items = require('libraries.workable_items')
local template_handler = require('modules.template_handler')
local selecting =  false
local debug = false
local selected_area = {
    start_trail = 0,
    point1 = {x = 0,y = 0,time},
    point2 = {x = 0,y = 0,time}
}
local selected_notes = {}
function new_level()
    return template_handler:get('level')
end
function load_level_fromfile(name)
    local levelDataEnc = love.filesystem.read('data/levels/'..name..'.rvc')
    local unencrypthLevel = bitser.loads(levelDataEnc)
    return unencrypthLevel 
end
function loadAudioSamples()
    local nTable = {}

    local count = songData:getSampleCount()*2
    local sampleRate = songData:getSampleRate()
    local duration = songData:getDuration()

    local paso = math.max(1, math.floor(count / 40000))

    for i = 0, count - 1, paso do
        local sample = songData:getSample(i)

        table.insert(nTable, {
            value = sample,
            time = (i / sampleRate)/2
        })
    end

    soundSamples = nTable

    print("duration:", songData:getDuration())
    print("last wave time:", soundSamples[#soundSamples].time)
    print("sample count:", songData:getSampleCount())
    print("sample rate:", songData:getSampleRate())


end


function load_level(name)
    local loaded_level
    if name == nil then loaded_level = new_level() end
    if name then loaded_level = load_level_fromfile(name) end
    if not name then name = 'lasuperatto' end
    song = love.audio.newSource('assets/music/'..name..'.mp3','static')
    songData = love.sound.newSoundData('assets/music/'..name..'.mp3')
    loadAudioSamples()
    assets['longnote_start'] = love.graphics.newImage('assets/arrow_long_start.png')
    assets['longnote_end'] = love.graphics.newImage('assets/arrow_long_end.png')
    level = loaded_level
    level_name =  name
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
    --print(distance)
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
local wave_time_scale = 1
local testTimes = {
    4.6829268292683,
    15.80487804878,
    72.585365853659
}
local function timeToY(t)
    local size_factor = chart_sets.size / 300
    local bottom = height - 200

    return bottom - t * height * size_factor
end
local function waveTimeToY(t)
    local size_factor = chart_sets.size / 300
    local bottom = height - 200

    -- Misma escala temporal que las notas,
    -- pero el desplazamiento viene de wavetime.
    return bottom - (t - wavetime) * height * size_factor
end


function draw_soundWave()
    local centerX = width/2
    local centerY = height - 200
    local amplitude = 300

    if #soundSamples == 0 then return end

    -- closest sample to wavetime
    local currentIndex = 1
    local closestDistance = math.abs(wavetime - soundSamples[1].time)

    for i = 2, #soundSamples do
        local distance = math.abs(wavetime - soundSamples[i].time)

        if distance < closestDistance then
            closestDistance = distance
            currentIndex = i
        end
    end

    local currentSample = soundSamples[currentIndex]

    -- Offset
    local currentY = timeToY(currentSample.time - wavetime)
    local centerOffset = centerY - currentY

    local first = math.max(1, currentIndex - 60)
    local last = math.min(#soundSamples, currentIndex + 300)

    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.setLineWidth(5)

    for i = first, last - 1 do
        local s1 = soundSamples[i]
        local s2 = soundSamples[i + 1]
        local y1 = timeToY(s1.time - wavetime)
        local y2 = timeToY(s2.time - wavetime)
        local x1 = centerX + s1.value * amplitude
        local x2 = centerX + s2.value * amplitude

        love.graphics.line(
            x1, y1+65,
            x2, y2+65
        )
    end

    love.graphics.setLineWidth(1)

    -- Debug
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1, 1)
    if  not debug  then  return end
    love.graphics.print(
        string.format(
            "time: %.9f\nwavetime: %.9f\nsample.time: %.9f\nindex: %d\ndistance: %.9f\ncenterY: %.3f\ncurrentY: %.3f\noffset: %.3f\nfps: %.3f",
            time,
            wavetime,
            currentSample.time,
            currentIndex,
            closestDistance,
            centerY,
            currentY,
            centerOffset,
            fps
        ),
        10,
        30
    )
end

function arrow_manage_asset(v,x,y,index,i)
    love.graphics.setColor(1,1,1,1)
    if selected_notes[index] then
        if selected_notes[index][i] ~= 0 then love.graphics.setColor(0.3,0.6,1,1) end
    end
    love.graphics.circle('fill',x,y,30)

    love.graphics.setColor(1,1,1,1)
end
local accumu = 0
local tails = {0,0,0,0}
local lastPrinted = 999999
function draw_tail(v,x,i,arrow,index)
    if v ~= 2 then return end
    if not arrow.tails then return end
    love.graphics.setColor(1,1,1,1)
    local bottom = height-200
    local size_factor = chart_sets.size / 300
    local sm = height/600
    --local y = arrow.tails[i]+chart_sets.offset
    local  y = index*height*size_factor
    for r = 0,(arrow.tails[i]*10)-1 do
        local sprite = 'longnote_start'
        local d = bottom-(r/10)*height*size_factor+chart_sets.offset-y
        d = d - 70*size_factor
        love.graphics.draw(assets[sprite],x-35,d-35,nil,0.1,0.1*size_factor*sm)
        
    end
    local ts = bottom-arrow.tails[i]*height*size_factor+chart_sets.offset-y
    local sprite = 'longnote_end'
    local sprite2 = 'longnote_start'
    love.graphics.draw(assets[sprite],x-35,ts,nil,0.1,0.1*size_factor)
    love.graphics.draw(assets[sprite2],x-35,ts+50*size_factor,nil,0.1,0.1*size_factor)
end
function debug_arrow_draw(x,y,i)
    if not debug then return end
    love.graphics.setColor(1,0,0,1)
    love.graphics.print('t: '..tostring(i),x,y)
    love.graphics.setColor(1,1,1,1)
end
function draw_arrow(arrow,index)
    local size = 335
    --local bottom = 420
    local bottom = height-200
    
    local size_factor = chart_sets.size / 300
    local right = width/2 + size/2
    for i,v in pairs(arrow) do
       -- print('draw')
        if v ~= 0 then
            local d = i
            if type(d) ~= 'number' then return end
            local x =  right - d * 70
            local y = bottom-index*height*size_factor+chart_sets.offset
            
            --local amount = chart_sets.size/300
            draw_tail(v,x,i,arrow,index)
            arrow_manage_asset(v,x,y,index)
            debug_arrow_draw(x,y,index)
            
        end
    end
end
function draw_grid()
    --local x1 = 280
    --local x2 = 580
    local size = 335
    local x1 = width/2 - size/2
    local x2 = width/2 + size/2

    local size_factor = chart_sets.size / 300
    local spacing = (60 / level.bpm)*chart_sets.multy * height * size_factor

    local referenceY = height-150
    --if chart_sets.offset < 0 then referenceY = referenceY + chart_sets.offset end
    love.graphics.line(x1, referenceY, x2, referenceY)

    if spacing <= 0 then return end


    local start_y = chart_sets.offset + referenceY


    local count = math.ceil(height / spacing) + 2
    
    for i = 0, count do
        local y = start_y - spacing * i


        while y > height do
            y = y - spacing * count
        end

        if y >= 0 and y <= height then
            love.graphics.line(x1, y, x2, y)
        end
    end
    for i = 0, count do
        local y = start_y - spacing*4 * i


        while y > height do
            y = y - spacing*4 * count
        end

        if y >= 0 and y <= height then
            love.graphics.setColor(1,0,0,1)
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
    w_items:clear()
    local bpm_box = w_items:add_item('textBox')
    bpm_box.params.text_label = 'bpm'
    bpm_box.position = {
        x = width-220,
        y = 50
    }
    bpm_box.params.on_text_return = function(text)
        level.bpm = tonumber(text)
    end
    local lvlname_box = w_items:add_item('textBox')
    lvlname_box.params.text_label = 'level name'
    lvlname_box.position = {
        x = width-220,
        y = 115
    }
    lvlname_box.params.on_text_return = function(text)
        level_name = text
    end
    local lvlname_text = w_items:add_item('textLabel')
    lvlname_text.params.text = level_name
    lvlname_text.position.y = 50
    lvlname_text.update = function() 
        lvlname_text.params.text = level_name 
    end
end
function mod:load(params)
    print('[Chart_editor]: Loaded.')
    load_level(params.song)
    add_gui()
    print('[Chart_editor]: Level: '..tostring(level))
end
function mod:draw()
    love.graphics.push()
    love.graphics.setLineWidth(1)
    love.graphics.print('time: '..tostring(time)..', offset: '..tostring(chart_sets.offset)..', VelMulty: '..tostring(velMulty)..', size: '..tostring(chart_sets.size)..', bpm: '..tostring(level.bpm)..', trail: '..tostring(trail))
    love.graphics.setColor(1,1,1,1)

    
    if exitTime > 0 then
        love.graphics.push()
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.print('Exiting...'..'('..tostring(math.floor(exitTime))..')')
        love.graphics.pop()
    end
    draw_soundWave()
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
function set_trail(x) --fixed
    local size = 335
    local right = width/2 + size/2
    placeable = true
    if x > right+5 then placeable = false end
    if x < right-4*80-5 then placeable = false end
    for i = 0,3 do
        local w = 80
        local v = right-i*w
        if x > v-w and x < v then
            trail = i +1
            return
        end
    end
end
function fixed_update(fixed_dt)
    local size_factor = chart_sets.size/300
    if playing then
        chart_sets.offset = chart_sets.offset + fixed_dt*height*size_factor*velMulty
   --- else 
        --chart_sets.offset = old_timestep
    end
    --print(chart_sets.time_offset)
end

function screenToTime(y)
    local size_factor = chart_sets.size / 300

    local normalizedY = (height - y) / height

    return (normalizedY + chart_sets.offset / height) / size_factor
end
function mod:update(dt)
    fps = 1/dt
    local x,y = love.mouse.getPosition()
    mouse.x = x
    mouse.y = y
    local changeValue = 1-(mouse.y/height)
    local size_factor = chart_sets.size/300
    time = screenToTime(y) - 0.25*(600/height)
    wavetime = (chart_sets.offset / height)/size_factor --screenToTime(height-200)- 0.25*(600/height)
    wavetime = wavetime
    --time = changeValue + (chart_sets.offset/height)
    --time = time/size_factor-0.25/size_factor
    --time = time
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
        song:setPitch(velMulty)
        song:play()
        --love.audio.play(song)
    else
        song:stop()
        --love.audio.stop(song)
        chart_sets.offset = old_timestep
    end
end
function end_chart()
    print('[Chart_editor]: Saved level as ['..level_name..'].')
    local newLevel = bitser.dumps(level)
    love.filesystem.write('data/levels/'..level_name..'.rvc',newLevel)
end
function mod:textinput(key)
    w_items:textinput(key)
end


function selecting_combos(key)
    if key == 'backspace' then
        for time,arrow in pairs(selected_notes) do
            for i,v in pairs(arrow) do
                if v ~= 0 then
                    level.arrows[time][i] = 0
                end
            end
        end
    end
end
function mod:keypressed(key)
    w_items:keypressed(key)
    if w_items.states.texting then return end
    selecting_combos(key)
    if key == 't' then
        debug = not debug
    end
    if key == 'space' then
        play()
    end
    if key == 'return' then
        end_chart()
    end
end
function addNote(time,typ)
    if love.keyboard.isDown('lctrl') then return end
    if not placeable then return end
    local d = {0,0,0,0,index = time}
    if level.arrows[time] then d = level.arrows[time] end
    d[trail] = typ
    if typ ~= 3 then last_arrow = d end
    level.arrows[time] = d
end

function deleteperproximity()
    print('prox')
    local bestDistance = math.huge
    local bestTime = nil

    for noteTime, note in pairs(level.arrows) do
        local distance = time - note.index

        if distance > 0 and distance < bestDistance then
            bestDistance = distance
            bestTime = noteTime
        end
    end

    return bestTime
end

function deleteNote(timed)
    if not level.arrows[timed] then print('[f: deleteNote]: No arrow section for {t: '..tostring(timed)..'}.') return end
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
    selected_area.point1.time = time
    selected_area.start_trail = trail
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
        if love.keyboard.isDown('q') then
            velMulty = velMulty+0.1*y
            if velMulty > 3 then velMulty =  3 end
            if velMulty < 0.1  then velMulty = 0.1 end
            return
        end
        chart_sets.size = chart_sets.size + 10*y
        chart_sets.offset = chart_sets.offset + (chart_sets.offset/chart_sets.size)*10*y --the happines and wholesomeness formula
        return
    end
    chart_sets.offset = chart_sets.offset + 25*(300/chart_sets.size)*y
    if chart_sets.offset < 0  then chart_sets.offset = 0 end

    
   -- chart_sets.time_offset = chart_sets.time_offset + 10*y
end
function love.resize( w, h )
    w_items:clear()
    width, height, flags = love.window.getMode( )
    add_gui()
end
function unselect()
    for i,v in pairs(selected_notes) do
        selected_notes[i] = nil
    end
end
function set_selected()
    unselect()
    local start_trail = selected_area.start_trail
    local end_trail = trail
    local time1 = selected_area.point1.time
    local time2  = selected_area.point2.time
    if time1 > time2 then  -- highest time always has to be time2.
        time2 = selected_area.point1.time
        time1  = selected_area.point2.time
    end
    local d = 1
    print('selecting')
    if end_trail-start_trail < 0 then d = -1 end
    for i = start_trail,end_trail,d do
        for d,arrow in pairs(level.arrows) do
            if arrow[i] ~= 0 and d < time2 and d > time1 then
                if not selected_notes[d] then selected_notes[d] = {0,0,0,0} end
                selected_notes[d][i] = arrow[i]
            end
        end
    end
end
function love.mousereleased( x, y, button, istouch, presses )
    if button == 1 then 
        selected_area.point2.time = time
        if selecting then set_selected() end
        selecting = false  
    end

    --add longnote
    if not last_arrow then return end
    if not last_arrow.index then return end
    if button ~= 1 then return end
    local y = timetogrid()
    local distance = y-last_arrow.index
    if distance <= 0 then return end
    if not last_arrow[trail] then return end 
    if last_arrow[trail] == 0 then return end
    if love.keyboard.isDown('lctrl') then return end
    local tails = level.arrows[last_arrow.index].tails
    if not tails then tails = {0,0,0,0} end
    level.arrows[last_arrow.index][trail] = 2
    tails[trail] = y-last_arrow.index
    level.arrows[last_arrow.index].tails = tails
    
    print('added longnote at: '..tostring(y)..', longness: '..tostring(y-last_arrow.index))
end
return mod