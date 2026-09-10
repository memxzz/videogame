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
        position = {x=0,y=0},
        time = 0,
        typ = 1,
        arrowIndex,
        pressing = false,
        dead = false,
    }
}
local debug = false
local input = {
    pointingTo = { --to what arrow each Trail is pointing.
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil

    },
    lastPoint = { --last point before change
        [1] = nil,
        [2] = nil,
        [3] = nil,
        [4] = nil

    },
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
local longNotes = {}

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
    
    --level.bpm = 180 --this is temporal
end
function playsong()
    started = false
    song:setVolume(1)
    start_task = timerModule:addTask(function()
        print('musicStart')
        --song:setPitch(velMulty)
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
        local bestOfZack2 = 99999999
        local target = nil
        local tail = nil
        for d,f in pairs(v) do 
            if f.position.y > height*4 + 600 then 
                f = nil 
            end
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
        if target and target.typ == 2 then 
            input.lastPoint[i] = target 
        else 
            input.pointingTo[i] = target
        end
        
        --print(i,target)
    end
end
function mod:load(params)
    pause_menu:load()
    sprites["trail"] = love.graphics.newImage('assets/trail.png')
    sprites["arrow"] = love.graphics.newImage('assets/arrow.png')
    sprites["arrowtail_end"] = love.graphics.newImage('assets/arrow_long_end.png')
    sprites["arrowtail_start"] = love.graphics.newImage('assets/arrow_long_start.png')
    loadLevel(params.song) 
    
end
function debug_tail_top(distance,pointx,pointy,index)
    if not debug then return end
    local num = distance
    local result = num
    love.graphics.push()
    love.graphics.setColor(0, 0, 1, 1)
              --  love.graphics.scale(10, 10)
    love.graphics.print(result,pointx+250,pointy+250,0,10,10)
    love.graphics.print(index,pointx+250,pointy+350,0,10,10)
    love.graphics.setLineWidth(20)
    love.graphics.rectangle('line',pointx+100,pointy+100,500,500)
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end
function check_tail(f)
    --print('called')
    if not f.arrowIndex.tails then return end
    if f.typ ~= 2 then return end
    --if f.typ ~= 2 then return end
    --print(f.typ)

    local scroll = confs.scrollSpeed*velMulty
    local factor =  confs.scrollSpeed/80
    local tail = f.arrowIndex.tails[f.trailIndex]
    local ts = f.position.y - tail*scroll*factor*80
    local b = (1/factor)*100
    local g = (100*(factor))
    --print(b)
    ts = ts - b + g
    local distance = height*4-ts
    local distance2 = height*4-f.position.y

    --local ts = arrow.position.y - tail*scroll*factor*80
    -- print(distance)
    --print('d: ',distance2,f.arrowIndex.index)
   -- print('dead:',arrow_obj.dead)
    local arrw_obj  = activeArrows.trails[f.trailIndex][f.activeIndex]
    
    if distance2 > -100 then return end
    if f.dead then return end
    if distance > 200 then -- -1000
        --print('miss on release')
        ranking = 'miss' 
        addPoints('miss')
        f.dead = true
        --print('s',f.dead,'miss')
        --activeArrows.trails[f.trailIndex][f.activeIndex] = nil
    else -- this is temporal
        ranking = 'sick'
        addPoints('sick')
        f.dead = true
        --activeArrows.trails[f.trailIndex][f.activeIndex] = nil
    end
    
end
function moveArrows(dt)
    for i,v in pairs(activeArrows.trails) do
        for d,f in pairs(v) do
            --print(i,v.position.y)
            local scroll = confs.scrollSpeed*velMulty
            f.position.y = f.position.y + (scroll * 100) * dt
            if f.position.y > height*4 + 700/(40/scroll) then 
                --i hate hate hate hate thiss this hate this DIE
                if f.typ ~= 2 then
                    ranking = 'miss' 
                    addPoints('miss')
                    v[d] = nil
                elseif f.typ == 2 then
                    local scroll = confs.scrollSpeed*velMulty
                    local factor =  confs.scrollSpeed/80
                    local ts = f.position.y - f.arrowIndex.tails[f.trailIndex]*scroll*factor*80
                    local b = (1/factor)*100
                    local g = (100*(factor))
                    --print(b)
                    ts = ts - b + g
                    local topPos = f.position.y - ts
                    local distance = height*4-ts
                    --print(distance)
                    if distance < -3000/(80/scroll) and not f.pressing then
                        f.dead = true
                        if not f.dead then
                            
                            ranking = 'miss' 
                            addPoints('miss')
                        end
                        
                        v[d] = nil
                    end
                end
                
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
                tableD.delay = v
                tableD.time = arrow.index
                tableD.typ = v
                tableD.arrowIndex = arrow
                if activeArrows.trails[i] and v ~= 0 then
                    table.insert(activeArrows.trails[i],tableD)
                end
                --
            end
            level.arrows[_] = nil
            --longNotes[_] = arrow
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
    local arrw_obj  = activeArrows.trails[v.trailIndex][v.activeIndex]
    v.delay = magnitud
    if v.arrowIndex[v.trailIndex] == 2 and magnitud < 1400 then
        arrw_obj.pressing = true
        --return
    end
    if magnitud < 1400  then 
        if v.arrowIndex[v.trailIndex] == 1 then
            v.position.y = 9999 
            activeArrows.trails[v.trailIndex][v.activeIndex] = nil
        end
        
        rankings(magnitud) 
    end
    --if v.arrowIndex[v.trailIndex] == 2 and arrw_obj.pressing == true then print('yey') return end
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
    for i,v in pairs(input.lastPoint) do
        if result == i then press(v) end
    end
end
function inputRelease(key)
    result = keyTransform(key)
    if not result then return end
    --print(input.lastPoint[result])
    for i,v in pairs(input.lastPoint) do
        if result == i then check_tail(v) end
    end
end
local lastpoint
function debug_scissor(x, y, sx, sy)
    if not debug then return end

    love.graphics.push("all")

    love.graphics.origin()
    love.graphics.setColor(1, 0, 0, 1)

    love.graphics.rectangle("line", x, y, sx, sy)

    love.graphics.pop()
end
function drawTail(arrow,index)
    --print(arrow.position.x/3)
    local x,y,sx,sy = ((4-index)*110)+150,-width/4, 110, height
    debug_scissor(x,y,sx,sy)
    if arrow.pressing then 
        love.graphics.setScissor(x,y,sx,sy)
    end
    


    local scroll = confs.scrollSpeed*velMulty
    local tail = arrow.arrowIndex.tails[index]
    local factor =  confs.scrollSpeed/80
    --print(factor)
    for i = 0,(tail*10)-2,0.1 do
        local d = arrow.position.y -400*factor - (i)*scroll*factor*8
        --love.graphics.circle('line',arrow.position.x+50,d,40)
        --print(arrow.pressing)
        love.graphics.draw(sprites["arrowtail_start"],arrow.position.x,d,nil,1,1*factor)
        
    end
    local ts = arrow.position.y - tail*scroll*factor*80
    local b = (1/factor)*100
    local g = (100*(factor))
    --print(b)
    if lastpoint ~= input.lastPoint[arrow.trailIndex] then
        lastpoint = input.lastPoint[arrow.trailIndex]
    end
    ts = ts - b + g
    local distance = height*4-ts
    --if arrow.position.y > height*4 then return end
    love.graphics.draw(sprites["arrowtail_end"],arrow.position.x,ts,nil,1,1)
    debug_tail_top(distance,arrow.position.x,ts,arrow.arrowIndex.index) 
    
    if factor > 0.8 then  
        love.graphics.draw(sprites["arrowtail_start"],arrow.position.x,ts+700/factor,nil,1,1*factor)
    end
    
    
    --love.graphics.discard(sprites["arrowtail_start"],arrow.position.x,arrow.position.y-400*factor,nil,1,1*factor)
end
function drawArrows()
---if level.arrows[time] == nil then return end
   -- print((level.arrows[time]))
   local spriteW = sprites["trail"]:getWidth()
   for i,v in pairs(activeArrows.trails) do
        for d,f in pairs(v) do
       
            f.position.x = (spriteW*2.1) - i *spriteW + width*3
            --drawTail(f)
            love.graphics.setColor(1, 1, 1, 1)
            if f.typ == 2 then
                drawTail(f,i)
            end
            love.graphics.draw(sprites["arrow"],f.position.x,f.position.y)
            love.graphics.setScissor()
            --print(f.dead,f.arrowIndex.index)
            if f.pressing and f.typ == 2 then
                if not f.dead then 
                    --love.graphics.draw(sprites["arrow"],f.position.x,height*4)
                end
                
            end
            if f.delay and debug then
                --print('text')
                local num = f.delay
                local result = tostring(num):sub(1, 3)
                love.graphics.push()
                love.graphics.setColor(1, 0, 0, 1)
              --  love.graphics.scale(10, 10)
                love.graphics.print(result,f.position.x+250,f.position.y+250,0,10,10)
                love.graphics.print(f.arrowIndex.index,f.position.x+250,f.position.y+350,0,10,10)
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
    love.graphics.print(fps.." "..tostring(level.bpm).." "..tostring(level.beat)..'/'..tostring(level.time_sign[2])..' '..tostring(fixed_time)..' '..tostring(confs.scrollSpeed))
    
    
    love.graphics.push()
    love.graphics.setColor(1,1,1,1)
    love.graphics.scale(0.15, 0.15)
    drawTrail()
    drawArrows()
    debug_draw()
    ---for i,v in pairs(longNotes) do drawTail(v) end
    
    love.graphics.pop()
    pause_menu:draw()
end
local isDownT =  {
    left = false,
    down = false,
    up = false,
    right = false
}
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
    if key == '1' then confs.scrollSpeed = confs.scrollSpeed + 5 end
    if key == '2' then confs.scrollSpeed = confs.scrollSpeed - 5 end


    if not paused then return end
    if key == 'return' then
        pause_menu_selection(pause_menu.selected)
    end
end
function love.keyreleased(key)
    if not paused then  inputRelease(key) end
end

return mod