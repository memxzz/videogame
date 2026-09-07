local mod = {}
local time = 0
local fps = 0
local loadStateMod = require('modules.loadState')

--libraries
local timerModule = require('libraries.time')
local bitser = require('libraries.bitser')
local template_handler = require('modules.template_handler')
-----------

--submenus
local pause_menu = require('states.menus_gameplay.pause_menu')
------------
local confs = {
    scrollSpeed = 80, --default 40
    input = {
        left = 'z',
        down = 'x',
        up = 'k',
        right = 'l'
    }
}
local sprites = {
    
}
local start_task
local song
local elements = {
    arrow = {
        activeIndex,
        trailIndex,
        position = {x=0,y=0}
    }
}
local debug = false
local input = {
    pointingTo = { --to what arrow each Trail is pointing.
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil

    }
}
local level = {}

local activeArrows = {
    trails = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    }
}

local accumulator = 0.0
local width, height, flags = love.window.getMode( )
local ranking = ""
local charting = false
local fixed_time = 0
local velMulty = 1 --still doesnt work
local paused = false
local songName = ''
local started = false
local rankinValues = {
    sick = 150,
    good = 100,
    bad = 50,
    miss = -150
}
local stats = {}
local stats_template = {
    points = 0,
    bestPossiblePoints = 0,
    accuracy = 0,
    rankins = {
        sick = 0,
        good = 0,
        bad = 0,
        miss = 0
    }
}
function addPoints(value)
    stats.points = stats.points + rankinValues[value]
    stats.bestPossiblePoints = stats.bestPossiblePoints + rankinValues.sick
    stats.rankins[value] = stats.rankins[value] + 1
    stats.accuracy = (stats.points/stats.bestPossiblePoints)*100
    if stats.accuracy < 0 then stats.accuracy = 0 end
    --print(stats.points,stats.accuracy)
end
local timed = 0
function beat_udpate(dt)
    if paused then return end
    local value = (60/level.bpm)
    if not started then timed = value level.beat = 0 return end
    
    timed = timed + dt
    if timed >= value then 
        level.beat = level.beat + 1
        if level.beat > level.time_sign[2] then level.beat = 1 end
        --print(level.beat)
        timed = 0
    end
end
function playsong()
    started = false
    ed = 0

end
function table_clear(table)
    for i,v in pairs(table) do table[i] = nil end
end
function reset_stats()
    ranking = ''
    stats = shallow_copy(stats_template)
end
function clear_arrows()
    for i,v in pairs(activeArrows.trails) do
        table_clear(v)
    end
end
function loadLevel(name)

    
    level = template_handler:get('level')
    

    songName = name
    fixed_time = 0
    reset_stats()
    clear_arrows()
    song = love.audio.newSource('assets/music/'..name..'.mp3','static')
    playsong()
    if charting == true then return end
    local levelDataEnc = love.filesystem.read('data/levels/'..name..'.rvc')
    local unencrypthLevel = bitser.loads(levelDataEnc)
    level = unencrypthLevel
    
    level.bpm = 180 --this is temporal
end
function playsong()
    started = false
    start_task = timerModule:addTask(function()
        print('musicStart')
        song:setPitch(velMulty)
        love.audio.play(song)
        started = true
    end,{timeDue = 2})
end

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

function distance ( pos1, pos2 )
  local dx = pos1.x - pos2.x
  local dy = pos1.y - pos2.y
  return math.sqrt ( dx * dx + dy * dy )
end

function setPointings()
    for i,v in pairs(activeArrows.trails) do 
        local bestOfZack = 99999999
        local target = nil
        for d,f in pairs(v) do 
            if f.position.y > height*4 + 600 then f = nil end
            if f ~= nil then
                local pos1 = {
                    x = 0,
                    y = height*4
                }
                local pos2 = {
                    x = 0,
                    y = f.position.y
                }
                magnitud = distance(pos1,pos2)
                if magnitud <= bestOfZack then 
                    bestOfZack = magnitud 
                    target = f 
                    target.activeIndex = d
                    target.trailIndex = i
                end 
            end
        end
        input.pointingTo[i] = target
        --print(i,target)
    end
end
function mod:load(params)
    pause_menu:load()
    sprites["trail"] = love.graphics.newImage('assets/trail.png')
    sprites["arrow"] = love.graphics.newImage('assets/arrow.png')
    loadLevel(params.song)
    
    
end
function moveArrows(dt)
    for i,v in pairs(activeArrows.trails) do
        for d,f in pairs(v) do
            --print(i,v.position.y)
            local scroll = confs.scrollSpeed*velMulty
            f.position.y = f.position.y + (scroll * 100) * dt
            if f.position.y > height*4 + 700/(40/scroll) then 
                ranking = 'miss' 
                addPoints('miss')
                v[d] = nil
            end
        end
        
    end
end

function spawnArrow()
    if paused then return end
    for _,arrow in pairs(level.arrows) do
        local val = (fixed_time-arrow.index)-1
        
        if fixed_time >= arrow.index+1*velMulty then 
           -- print('spawn',arrow.index)
            
            for i,v in pairs(arrow) do
                --print('new')
                local scroll = confs.scrollSpeed*velMulty
                local tableD = shallow_copy(elements.arrow)
                tableD.position.y = height*4 - scroll * 100
                tableD.delay = val
                if activeArrows.trails[i] and v ~= 0 then
                    table.insert(activeArrows.trails[i],tableD)
                end
                --
            end
            level.arrows[_] = nil
        end
    end
end
function rankings(magnitud)
    local scroll = confs.scrollSpeed*velMulty
    if magnitud < 100/(40/scroll)  then ranking = 'sick' addPoints('sick') return end
    if magnitud < 600/(40/scroll)  then ranking = 'good' addPoints('good') return end
    if magnitud < 1100/(40/scroll) then ranking = 'bad' addPoints('bad') return end
end
function press(v)
    if v  == nil then return end
    local pos1 = {
        x = 0,
        y = height*4
    }
    local pos2 = {
        x = 0,
        y = v.position.y
    }
    local magnitud = distance(pos1,pos2)
    v.delay = magnitud
    if magnitud < 1400 then 
        v.position.y = 9999 
        activeArrows.trails[v.trailIndex][v.activeIndex] = nil
        rankings(magnitud) 
    end 
end
local actionList = {
    left = 4,
    down = 3,
    up = 2,
    right = 1,
}
function keyTransform(key)
    local action
    for i,v in pairs(confs.input) do
        if v == key then action = i end
    end
    if action ~= nil then action = actionList[action] end
    return action

end
function inputPress(key)
    result = keyTransform(key)
    if result == nil then return end
    for i,v in pairs(input.pointingTo) do
        if result == i then press(v) end
    end
end
function drawArrows()
---if level.arrows[time] == nil then return end
   -- print((level.arrows[time]))
   local spriteW = sprites["trail"]:getWidth()
   for i,v in pairs(activeArrows.trails) do
        for d,f in pairs(v) do
       
            f.position.x = (spriteW*2.1) - i *spriteW + width*3
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sprites["arrow"],f.position.x,f.position.y)
            if f.delay and debug then
                --print('text')
                local num = f.delay
                local result = tostring(num):sub(1, 3)
                love.graphics.push()
                love.graphics.setColor(1, 0, 0, 1)
              --  love.graphics.scale(10, 10)
                love.graphics.print(result,f.position.x+250,f.position.y+250,0,10,10)
                love.graphics.setLineWidth(20)
                love.graphics.rectangle('line',f.position.x+100,f.position.y+100,500,500)
                love.graphics.pop()
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
        
        
   end

end
function drawTrail()
    local spriteW = sprites["trail"]:getWidth()
    
    for i,v in pairs(activeArrows.trails) do
        local x = (spriteW*2.1) - i *spriteW + width*3
        love.graphics.draw(sprites["trail"],x,height*4)
    end
end
function debug_draw()
    if not debug then return end
    local y = height*4
    love.graphics.setColor(1,0,0,1)
    love.graphics.line(800,y,4000,y)
    for i,v in pairs(input.pointingTo) do
        if v then
            love.graphics.line(width*3,height*6,v.position.x+800,v.position.y+500)
        end
    end
    love.graphics.setColor(1,1,1,1)
end
function mod:draw()
    love.graphics.print(ranking,width/2 - 50,height/2 -50,nil,2)
    local stringedPoints = 'points: '..tostring(stats.points)
    local stringedAccuracy = 'accuracy: '..tostring(math.floor(stats.accuracy * 100 + 0.5) / 100).."%"
    local pointsOffsetX = 20
    local accuracyOffsetX = 20

    love.graphics.print(stringedPoints,pointsOffsetX,height/2-200,nil,1.5)
    love.graphics.print(stringedAccuracy,accuracyOffsetX,height/2-170,nil,1.5)
    love.graphics.print(fps.." "..tostring(level.bpm).." "..tostring(level.beat)..'/'..tostring(level.time_sign[2])..' '..tostring(fixed_time))
    
    love.graphics.push()
    love.graphics.setColor(1,1,1,1)
    love.graphics.scale(0.15, 0.15)
    drawTrail()
    drawArrows()
    debug_draw()
    
    love.graphics.pop()
    pause_menu:draw()
end
local isDownT =  {
    left = false,
    down = false,
    up = false,
    right = false
}
function chart()
    if charting == false  then return end
    local chart = {0,0,0,0}
    local changed = false
    if love.keyboard.isDown(confs.input.left) and isDownT.left == false then
        isDownT.left = true
        chart[actionList.left] = 1
        changed = true
    end
    if love.keyboard.isDown(confs.input.right) and isDownT.right == false then
        isDownT.right = true
        chart[actionList.right] = 1
        changed = true
    end
    if love.keyboard.isDown(confs.input.up) and isDownT.up == false then
        isDownT.up = true
        chart[actionList.up] = 1
        changed = true
    end
    if love.keyboard.isDown(confs.input.down) and isDownT.down == false then
        isDownT.down = true
        chart[actionList.down] = 1
        changed = true
    end
    if changed == true then
        level.arrows[fixed_time] = chart
        print(chart) 
    end

    
end
function love.keyreleased(key)
    if key == confs.input.left then isDownT.left = false end
    if key == confs.input.right then isDownT.right = false end
    if key == confs.input.up then isDownT.up = false end
    if key == confs.input.down then isDownT.down = false end
end
local t = 0
function fixed_update(fixed_dt)
    t = t + velMulty/1
    --print(velMulty/1)
    if t < 1 then  return end
    t = 0
    if paused == false then
        fixed_time = fixed_time + fixed_dt
    end
    beat_udpate(fixed_dt)
    
    spawnArrow()
end
function mod:update(dt)
    time = time + dt*velMulty
    time = math.floor(time * 100 + 0.5) / 100
    fps = 1/dt
    if paused == false then
        moveArrows(dt)
    end
    if start_task then
        start_task.paused = paused
    end
    setPointings()
    timerModule:update(dt)
    chart()
    pause_menu:update(dt,paused)
    accumulator = accumulator + dt
    while accumulator >= 1/60 do
        fixed_update(1/60)
        accumulator = accumulator - 1/60
    end
    --inputPress(dt)
end
function pause_menu_selection(option)
    pause_menu:reset()
    if option == 'resume' then
        paused = false
        if not start_task then  return end
        if start_task.time < start_task.timeDue then return end
        love.audio.play(song)
        return
    end
    if option == 'reset' then
        paused = false
        loadLevel(songName)
    end
    if option == 'exit' then
        loadStateMod:loadState('levelSelector')
        return
    end
end
function mod:keypressed( key )
    if not paused then  inputPress(key) end
    pause_menu:key(key)
    if key == '-' then debug = not debug end
    if key ==  'escape' then 
        love.audio.pause(song)
        paused = true
    end
    if not paused then return end
    if key == 'return' then
        pause_menu_selection(pause_menu.selected)
    end
end

return mod