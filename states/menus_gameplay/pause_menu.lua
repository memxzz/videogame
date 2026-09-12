local mod = {
    selected = ''
}
local paused = false
local width, height, flags = love.window.getMode( )
local options = {
    'resume',
    'reset',
    'exit'
}
local sprites = {
    
}
local index = 0

function mod:load()
    sprites['back'] = love.graphics.newImage('assets/gameplay/pause_menu/back.png')
end
function mod:update(dt,pausedd)
    paused = pausedd
end
function mod:reset()
    index = 0
end
function mod:draw()
    if not paused then return end
    love.graphics.push()
    love.graphics.scale(0.7,0.7)
    local w = width/2
    w = w/0.7
    print(w)
    love.graphics.setColor(1,0,0,1)
    love.graphics.draw(sprites['back'],w-200,height/2 - 200)
    love.graphics.setColor(1,1,1,1)
    love.graphics.pop()
    for i,v in pairs(options)  do
        local text = '   '..v
        if i == index+1 then text =  '> '..v end
        mod.selected = options[index+1]
        love.graphics.print(text,w - 200,height/2 +50*i -120,nil,2)
    end
    
end
function mod:key(key)
    local action = 0
    if not paused then return end
    if key == 'up' then  action = -1 end
    if key == 'down' then  action = 1 end
    index = index + action
    if  index < 0 then index = 0 end
    if index >= #options then index = #options end
        

end
return mod