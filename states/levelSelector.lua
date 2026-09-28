local mod = {}
local loadStateMod = require('modules.loadState')
local bitser = require('libraries.bitser')
local w_items = require('libraries.workable_items')
local notif_man = require('modules.notification_manager')
local lume =  require('libraries.lume')
local sprites = {
    
}
local levels = {

}
local items = {
    buttons = {

    },
    buttons_difficulty = {

    }
}
local assets = {
    loaded_songs = {},
    songsLogos = {}
}
local datas = {}
local time = 0
local dtt = 0
local indexselect = 0
local difficulty_index_select = 0
local width, height, flags = love.window.getMode( )
local volume = 0
local actualSong
local fonts = {
    montserrat = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 30),size = 30},
    montserrat_15 = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 15),size = 17}
}
local show_levels = false
local difficulty = 'normal'
local function reloadFontSizes()
    local yfactor = height/600
    for i,v in pairs(fonts) do
        v.obj = love.graphics.newFont("assets/fonts/"..i..".ttf", v.size*yfactor)
    end
end
local function lerp(a,b,t) return (1-t)*a + t*b end
local function lerpPoints(a,b,t)
    return {
        x = lerp(a.x,b.x,t),
        y = lerp(a.y,b.y,t)
    }
end
local function draw_difficulties()
    if not levels[indexselect+1].difficulties then return end
    if not show_levels then return end
    local difficulties = levels[indexselect+1].difficulties
    for i,v in pairs(items.buttons_difficulty) do
        local sizefactor = height/600
        local x = v.position.x
        local y = v.position.y
        local actual = (#difficulties-difficulty_index_select)
        if v.index == actual then
            love.graphics.setColor(0.8,0.8,0.8,1)
        else
            love.graphics.setColor(0.5,0.5,0.5,1)
        end
        love.graphics.rectangle("fill",x,y*sizefactor,300*sizefactor,60*sizefactor)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(v.name,x,y*sizefactor)
    end
end
local function update_difficulties_buttons(dt)
    if not levels[indexselect+1].difficulties then return end
    if not show_levels then return end
    local difficulties = levels[indexselect+1].difficulties
    for i,v in pairs(difficulties) do
        local sizefactor = height/600
        local x = width-330*sizefactor
        local y = 80*#difficulties/(sizefactor)
        y = y-80*(i-3+difficulty_index_select)
        y = y + 60
        local actual = (#difficulties-difficulty_index_select)
        items.buttons_difficulty[v].position.x = lume.lerp(items.buttons_difficulty[v].position.x,x,dt*10)
        items.buttons_difficulty[v].position.y = lume.lerp(items.buttons_difficulty[v].position.y,y,dt*10)
    end
end
local function button_draw()
    for i,v in pairs(items.buttons) do 
        local state = 'unselected'
        local fixedindex = (i-indexselect)
        local yfactor = height/600
        if v.selected and not show_levels then state = 'selected' end
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
local function button_update(dt)
    dtt = dt
    for i,v in pairs(items.buttons) do 
        local fixedindex = (i-indexselect)
        if show_levels then
            local difficulties = levels[indexselect+1].difficulties
            fixedindex = fixedindex-(difficulty_index_select)
        end
        v.selected = false
        local sizefactor = height/600
        if i == indexselect+1 then v.selected = true end
        local y = 100 + fixedindex*(100*sizefactor)--height/2+fixedindex*300
        local difficulties = levels[indexselect+1].difficulties
        local xoffset = fixedindex*30 *sizefactor
        if i < indexselect+2 then 
            xoffset = xoffset*-1
        else
            if show_levels then
                y = y + #difficulties*80*sizefactor
            end
        end
        y = y
        v.position.y = lerp(v.position.y,y,10*dt)
        local x = width + xoffset
        --print(width)
        v.position.x = lerp(v.position.x,x,10*dt)
    end
end
local function button_add(lvl)
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
local function load_audio(lvl)
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
local lvl_info = nil
local function loadLogos(lvl)
    if not lvl  then return end
    w_items:clear()
    local path = 'data/levels'
    if lvl.official then 
        path = "data/levels/official"
    else
        path = 'data/levels'
    end
    local levelDataEnc = love.filesystem.read(path..'/'..lvl.name..'/info.txt')
    if not levelDataEnc then print('No info.txt for '..lvl.name) end
    local lvlData = lume.deserialize(levelDataEnc)
    if not lvlData then print('Couldnt load decode lvl data for '..lvl.name) lvlData = {} end
    datas[lvl.name] = lvlData
    datas[lvl.name].path = path
    local imagePath = path .. "/" .. lvl.name .. "/logo.png"
    if love.filesystem.getInfo(imagePath) then
        if assets.songsLogos[lvl.name] then
            return
        end
        assets.songsLogos[lvl.name] = love.graphics.newImage(imagePath)
    else
        assets.songsLogos[lvl.name] = love.graphics.newImage('assets/levelSelector/logoNotFound.png')
        print('Image not found', path)
    end

end
local function add_gui()
    local data_list = w_items:add_item('list')
    data_list.background_color = {1,1,1,0}
    data_list.position = {
        x = 80,
        y = height/2+25
    }
    
    data_list.params.items = {
        {name = 'name: ',value = 'name',update = function(dt,self_item)
            self_item.value = tostring(levels[indexselect+1].name)
            data_list.position.y = height/2+25
        end},
        {name = 'artist: ',value = 'name',update = function(dt,self_item)
            local name = levels[indexselect+1].name
            local data = datas[name]
            self_item.value = tostring(data.song_artist)
        end},
        {name = 'charter: ',value = 'name',update = function(dt,self_item)
            local name = levels[indexselect+1].name
            local data = datas[name]
            self_item.value = tostring(data.charter)
        end}
    }
end
local lastindex = -1
local lastSong
local function play_audio(dt)
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
local function stop_all_songs()
    for i,v in pairs(assets.loaded_songs) do love.audio.stop(v)  end
end
local function get_lvl_Info(path)
    local txt = love.filesystem.read(path..'/info.txt')
    local info = lume.deserialize(txt)
    return info
end
function mod:load()
    local externalLevelsPath = "data/levels"
    if not love.filesystem.getInfo(externalLevelsPath) then
        love.filesystem.createDirectory(externalLevelsPath)
    end
    local externalLevels = love.filesystem.getDirectoryItems(externalLevelsPath)
    local officialLevels = love.filesystem.getDirectoryItems("data/levels/official")
    for _, v in ipairs(officialLevels) do
        local info = get_lvl_Info("data/levels/official/"..v)
        table.insert(levels, {
            official = true,
            name = v,
            difficulties = info.difficulties
        })
    end

    for _, v in ipairs(externalLevels) do
        if v ~= 'official' and v ~= 'new song' then
            local info = get_lvl_Info(externalLevelsPath..'/'..v)
            table.insert(levels, {
                official = false,
                name = v,
                difficulties = info.difficulties
            })
        end
    end

    for _, v in ipairs(levels) do
        load_audio(v)
        loadLogos(v)
    end

    sprites["button_selected"] = love.graphics.newImage("assets/levelSelector/button/selected.png")
    sprites["button_unselected"] = love.graphics.newImage("assets/levelSelector/button/unselected.png")
    sprites["error_sfx"] = love.audio.newSource('assets/sfx/error.mp3','static')
    sprites.songsLogos = {}
    for _, v in ipairs(levels) do
        button_add(v)
    end
    reloadFontSizes()
    add_gui()
end
local function get_transfurmed_image_proportions(image,sizex,sizey)
    local factor = height/600
    local ogW,ogH = image:getDimensions()
    local dW,dH = sizex*factor,sizey*factor
    local sx = dW/ogW
    local sy = dH/ogH
    return sx,sy
end
local function logoDraw()
    love.graphics.setFont(fonts.montserrat_15.obj)
    local song = levels[indexselect+1]
    local img = assets.songsLogos[song.name]
    local sx,sy = get_transfurmed_image_proportions(img,200,200)
    love.graphics.setColor(1,1,1,1)
    local factor = height/600
    love.graphics.draw(img,
        80,
        height/2-180*factor,
    nil,sx,sy)


end
function mod:draw()
    button_draw()
    draw_difficulties()
    logoDraw()
    w_items:draw()
    notif_man:draw()
    if time > 0 then
        love.graphics.print('Exiting...'..'('..tostring(math.floor(time))..')')
    end
end
function mod:keypressed(key)
    if show_levels then
        if key == 'up' then difficulty_index_select = difficulty_index_select - 1 end
        if key == 'down' then difficulty_index_select =  difficulty_index_select + 1 end
    else
        if key == 'up' then indexselect = indexselect - 1 end
        if key == 'down' then indexselect = indexselect + 1 end
    end

    if indexselect < 0 then indexselect = 0 end
    if indexselect >= #levels then indexselect = #levels -1 end

    if difficulty_index_select < 0 then difficulty_index_select = 0 end
    if difficulty_index_select > #levels[indexselect+1].difficulties-1 then difficulty_index_select = #levels[indexselect+1].difficulties-1 end
    
    local lvl = levels[indexselect+1]
    local path = '/data/levels'
    if lvl.official then --this means the level  is an official level and we should load the audio from other path
        path = 'data/levels/official' --this path
    end
    if key == '7' then
        if love.filesystem.getInfo(path..'/'..lvl.name..'/'..difficulty..'.rvc') then 
            stop_all_songs()
            loadStateMod:loadState('chart_editor',{song = lvl.name,path = path,difficulty = difficulty})
        else
            local notif = notif_man:add()
            notif.text.title = 'Not found.'
            notif.text.subtitle = "couldn't find difficulty "..difficulty
            volume = 0
            love.audio.stop(sprites["error_sfx"])
            love.audio.play(sprites["error_sfx"])
        end
    end
    if key == 'escape' then
        show_levels = false
        
    end
    if key == "return" then
        if show_levels then
            
            if love.filesystem.getInfo(path..'/'..lvl.name..'/'..difficulty..'.rvc') then 
                stop_all_songs()
                loadStateMod:loadState('gameplay',{song = lvl.name,path = path,difficulty = difficulty})
            else
                local notif = notif_man:add()
                notif.text.title = 'Not found.'
                notif.text.subtitle = "couldn't find difficulty "..difficulty
                volume = 0
                love.audio.stop(sprites["error_sfx"])
                love.audio.play(sprites["error_sfx"])
            end       
        else
            show_levels = true
            local difficulties = levels[indexselect+1].difficulties
            for i,v in pairs(items.buttons_difficulty) do items.buttons_difficulty[i] = nil end
            for i,v in pairs(difficulties) do 
                items.buttons_difficulty[v] = {
                    position = {x = width-100, y = height/2},
                    index = i,
                    name = v
                }
            end
            --difficulty_index_select = #levels[indexselect+1].difficulties-1
        end

    end
end
function love.resize( w, h )
    width, height, flags = love.window.getMode( )
    reloadFontSizes()
    notif_man:resize(w,h)
end
function mod:update(dt)
    button_update(dt)
    update_difficulties_buttons(dt)
    play_audio(dt)
    w_items:update(dt)
    local difficulties = levels[indexselect+1].difficulties
    difficulty = levels[indexselect+1].difficulties[(#difficulties-difficulty_index_select)]
    if love.keyboard.isDown('backspace') then
        time = time + dt
        if time > 1 then
            time = 0
            stop_all_songs()
            loadStateMod:loadState('mainMenu')
        end
        return
    end
    notif_man:update(dt)
    if not show_levels then difficulty_index_select = 0 end
    time = 0
end

return mod