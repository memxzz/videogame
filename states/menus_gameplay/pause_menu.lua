local mod = {
    selected = ''
}
local paused = false
local charting
local width, height, flags = love.window.getMode( )
local options = {
    'resume',
    'reset',
    'exit'
}
local sprites = {
    
}
local index = 0
local fonts = {
    montserrat = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 30),size = 15,resize = false}
}
function reloadFontSizes()
    local yfactor = height/600
    for i,v in pairs(fonts) do
        if v.resize then
            v.obj = love.graphics.newFont("assets/fonts/"..i..".ttf", v.size*yfactor)
        else
            v.obj = love.graphics.newFont("assets/fonts/"..i..".ttf", v.size)
        end
        
    end
end
function mod:load(params)
    reloadFontSizes()
    if params then
        charting = params
    end
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
    love.graphics.setFont(fonts.montserrat.obj)
    love.graphics.push('all')
    love.graphics.origin()
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle('fill',width/2-100,height/2-(#options*50)/2,200,50*#options+20)
    love.graphics.setColor(1,1,1,1)
    for i,v in pairs(options)  do
        local text = '   '..v
        if i == index+1 then text =  '> '..v end
        mod.selected = options[index+1]
        love.graphics.print(text,width/2 - 50,height/2 +50*i -120,nil)
    end
    love.graphics.pop()
end
function mod:resize( w, h )
    width, height, flags = love.window.getMode( )
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