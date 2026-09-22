local mod = {}
local loadStateMod = require('modules.loadState')
local sprites = {
    
}
local levels = {

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
local fonts = {
    montserrat = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 30),size = 30}
}
function reloadFontSizes()
    local yfactor = height/600
    for i,v in pairs(fonts) do
        v.obj = love.graphics.newFont("assets/fonts/"..i..".ttf", v.size*yfactor)
    end
end
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
        local yfactor = height/600
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
        local offset = 300*(yfactor-1)
        local x = v.position.x-120 - (#v.name*11) - offset--((v.position.x/0.3)+300)-#v.name*11
        local y = v.position.y+10*yfactor  --(v.position.y*0.3)+10
        love.graphics.setFont(fonts.montserrat.obj)
        love.graphics.print(v.name,x,y ,nil)
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
function button_add(lvl)
    table.insert(items.buttons,{
        selected = false,
        name = lvl.name,
        alpha = 1,
        position = {
            x = width+450,
            y = height
        }
    })
end
function load_audio(lvl)
    if not lvl then return end

    local path

    if lvl.official then
        path = "data/levels/official"
    else
        path = "data/levels"
    end

    local songPath = path .. "/" .. lvl.name .. "/song.mp3"

    if love.filesystem.getInfo(songPath) then
        if assets.loaded_songs[lvl.name] then
            return
        end

        assets.loaded_songs[lvl.name] =
            love.audio.newSource(songPath, "static")
    else
        print("Song not found:", songPath)
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
    local lvl = levels[indexselect+1]
    load_audio(lvl)
    if not assets.loaded_songs[lvl.name] then return end
    local dur = assets.loaded_songs[lvl.name]:getDuration()
    assets.loaded_songs[lvl.name]:seek(dur/2)
    actualSong = assets.loaded_songs[lvl.name] 
    love.audio.play(assets.loaded_songs[lvl.name])
    
end
function stop_all_songs()
    for i,v in pairs(assets.loaded_songs) do love.audio.stop(v)  end
end
function mod:load()
    local externalLevelsPath = "data/levels"
    if not love.filesystem.getInfo(externalLevelsPath) then
        love.filesystem.createDirectory(externalLevelsPath)
    end
    local externalLevels = love.filesystem.getDirectoryItems(externalLevelsPath)
    local officialLevels = love.filesystem.getDirectoryItems("data/levels/official")
    for _, v in ipairs(officialLevels) do
        table.insert(levels, {
            official = true,
            name = v
        })
    end

    for _, v in ipairs(externalLevels) do
        if v ~= 'official' and v ~= 'new song' then
            table.insert(levels, {
                official = false,
                name = v
            })
        end
    end

    for _, v in ipairs(levels) do
        load_audio(v)
    end

    sprites["button_selected"] = love.graphics.newImage("assets/levelSelector/button/selected.png")
    sprites["button_unselected"] = love.graphics.newImage("assets/levelSelector/button/unselected.png")

    for _, v in ipairs(levels) do
        button_add(v)
    end
    reloadFontSizes()
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
    local lvl = levels[indexselect+1]
    local path = '/data/levels'
    if lvl.official then --this means the level  is an official level and we should load the audio from other path
        path = 'data/levels/official' --this path
    end
    if key == '7' then
        stop_all_songs()
        
        if love.filesystem.getInfo(path..'/'..lvl.name..'/chart.rvc') then 
            loadStateMod:loadState('chart_editor',{song = lvl.name,path = path})
        end
    end
    if key == "return" then
        stop_all_songs()
        if love.filesystem.getInfo(path..'/'..lvl.name..'/chart.rvc') then 
            loadStateMod:loadState('gameplay',{song = lvl.name,path = path})
        end
    end
end
function love.resize( w, h )
    width, height, flags = love.window.getMode( )
    reloadFontSizes()
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