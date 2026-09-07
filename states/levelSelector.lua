local mod = {}
local loadStateMod = require('modules.loadState')
local sprites = {
    
}
local levels = {
    'test',
    'lasuperatto',
    'cavort',
    'U53RDV [TFR],  — 22:10 pon dance or die we xdxdxd'
}
local items = {
    buttons = {

    }
}
local time = 0
local dtt = 0
local indexselect = 0
local width, height, flags = love.window.getMode( )
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
        
        love.graphics.draw(sprites['button_'..state],v.position.x,v.position.y)
        love.graphics.pop()
        local x = ((v.position.x*0.3)+300)-#v.name*11
        local y = (v.position.y*0.3)+10
        love.graphics.print(v.name,x,y,nil,2)
    end
end
function button_update(dt)
    dtt = dt
    for i,v in pairs(items.buttons) do 
        local fixedindex = (i-indexselect)
        v.selected = false
        if i == indexselect+1 then v.selected = true end
        v.position.y = lerp(v.position.y,height/2+fixedindex*300,10*dt)
        local xoffset = fixedindex*50
        if i < indexselect+2 then 
            xoffset = xoffset*-1 
        end
        v.position.x = lerp(v.position.x,width+450+xoffset,10*dt)
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

function mod:load()
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
        if love.filesystem.getInfo('data/levels/'..levels[indexselect+1]..'.rvc') then 
            loadStateMod:loadState('chart_editor',{song = levels[indexselect+1]})
        end
    end
    if key == "return" then
        if love.filesystem.getInfo('data/levels/'..levels[indexselect+1]..'.rvc') then 
            loadStateMod:loadState('gameplay',{song = levels[indexselect+1]})
        end
    end
end

function mod:update(dt)
    button_update(dt)
    if love.keyboard.isDown('backspace') then
        time = time + dt
        if time > 1 then
            time = 0
            loadStateMod:loadState('mainMenu')
        end
        return
    end
    time = 0
end

return mod