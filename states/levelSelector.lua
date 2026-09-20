local mod = {}
local loadStateMod = require('modules.loadState')
local sprites = {
    
}
local levels = {
    'Chiptune Madness',
    'lasuperatto',
    'test',
    'test2',
    'test3',
    'cavort',
    'U53RDV [TFR],  — 22:10 pon dance or die we xdxdxd'
}
local items = {
    buttons = {

    }
}
local assets = {
    loaded_songs = {}
}
local time = 0
local dtt = 0
local indexselect = 0
local width, height, flags = love.window.getMode( )
local volume = 0
local actualSong
function lerp(a,b,t) return (1-t)*a + t*b end
function lerpPoints(a,b,t)
    return {
        x = lerp(a.x,b.x,t),
        y = lerp(a.y,b.y,t)
    }
end
function button_draw()
    for i,v in pairs(items.buttons) do 
        local state = 'unselected'
        local fixedindex = (i-indexselect)
        if v.selected then state = 'selected' end
        love.graphics.push()
        love.graphics.scale(0.3, 0.3)
        local touse = 1/fixedindex
        if fixedindex == 0 then touse = 0 end
        v.alpha = lerp(v.alpha,touse,15*dtt)
        --print(v.alpha,fixedindex)
        love.graphics.setColor(1,1,1,v.alpha)
        local sizefactor = height/600
        love.graphics.draw(sprites['button_'..state],v.position.x/0.3 - sprites['button_'..state]:getWidth()*sizefactor,v.position.y/0.3,0,sizefactor,sizefactor)
        love.graphics.pop()
        local x = v.position.x-100 - #v.name*11--((v.position.x/0.3)+300)-#v.name*11
        local y = v.position.y+10  --(v.position.y*0.3)+10
        love.graphics.print(v.name,x,y,nil,1.5*sizefactor,1.5*sizefactor)
    end
end
function button_update(dt)
    dtt = dt
    for i,v in pairs(items.buttons) do 
        local fixedindex = (i-indexselect)
        v.selected = false
        local sizefactor = height/600
        if i == indexselect+1 then v.selected = true end
        local y = 100 + fixedindex*(100*sizefactor)--height/2+fixedindex*300
        v.position.y = lerp(v.position.y,y,10*dt)
        local xoffset = fixedindex*30 *sizefactor
        if i < indexselect+2 then 
            xoffset = xoffset*-1 
        end
        local x = width + xoffset
        --print(width)
        v.position.x = lerp(v.position.x,x,10*dt)
    end
end
function button_add(name)
    table.insert(items.buttons,{
        selected = false,
        name = name,
        alpha = 1,
        position = {
            x = width+450,
            y = height
        }
    })
end
function load_audio(name)
    if not name then return end
    if love.filesystem.getInfo('assets/music/'..name..'.mp3') then
        if assets.loaded_songs[name] then return end
        assets.loaded_songs[name] = love.audio.newSource('assets/music/'..name..'.mp3','static')
    end
end
local lastindex = -1
local lastSong
function play_audio(dt)
    local finalVolume = 0.45
    volume = lerp(volume,finalVolume,2*dt)
    if actualSong then actualSong:setVolume(volume) end
    if lastindex == indexselect then return end
    if actualSong then love.audio.stop(actualSong) end
    volume = 0
    lastindex = indexselect
    load_audio(levels[indexselect+1])
    if not assets.loaded_songs[levels[indexselect+1]] then return end
    local dur = assets.loaded_songs[levels[indexselect+1]]:getDuration()
    assets.loaded_songs[levels[indexselect+1]]:seek(dur/2)
    actualSong = assets.loaded_songs[levels[indexselect+1]] 
    love.audio.play(assets.loaded_songs[levels[indexselect+1]])
    
end
function stop_all_songs()
    for i,v in pairs(assets.loaded_songs) do love.audio.stop(v)  end
end
function mod:load()
    for i,v in pairs(levels) do load_audio(v) end
    sprites["button_selected"] = love.graphics.newImage('assets/levelSelector/button/selected.png')
    sprites["button_unselected"] = love.graphics.newImage('assets/levelSelector/button/unselected.png')

    for i,v in pairs(levels) do
        button_add(v)
    end
end

function mod:draw()
    button_draw()
    if time > 0 then
        love.graphics.print('Exiting...'..'('..tostring(math.floor(time))..')')
    end
end
function mod:keypressed(key)
    if key == 'up' then indexselect = indexselect - 1 end
    if key == 'down' then indexselect = indexselect + 1 end
    if indexselect < 0 then indexselect = 0 end
    if indexselect >= #levels then indexselect = #levels -1 end

    if key == '7' then
        stop_all_songs()
        if love.filesystem.getInfo('data/levels/'..levels[indexselect+1]..'.rvc') then 
            loadStateMod:loadState('chart_editor',{song = levels[indexselect+1]})
        end
    end
    if key == "return" then
        stop_all_songs()
        if love.filesystem.getInfo('data/levels/'..levels[indexselect+1]..'.rvc') then 
            loadStateMod:loadState('gameplay',{song = levels[indexselect+1]})
        end
    end
end

function mod:update(dt)
    button_update(dt)
    play_audio(dt)
    if love.keyboard.isDown('backspace') then
        time = time + dt
        if time > 1 then
            time = 0
            stop_all_songs()
            loadStateMod:loadState('mainMenu')
        end
        return
    end
    time = 0
end

return mod