local mod = {}

local loadState = require('modules.loadState')
local width, height, flags = love.window.getMode( )
local sprites = {}
local list = {
    'play',
    'chart editor'
}
local selection = 1
function mod:load()
    sprites["buttonSel"] = love.graphics.newImage('assets/mainMenu/buttonSelected.png')
    sprites["buttonUnsel"] = love.graphics.newImage('assets/mainMenu/buttonUnselected.png')
end
function mod:update(dt)
end
function mod:draw()
    love.graphics.setColor(1,1,1,1)
    for i,option in pairs(list) do
        local sprite = "buttonUnsel"
        if i == selection then sprite = 'buttonSel' end
        local spriteW = sprites[sprite]:getWidth()
        local spriteH = sprites[sprite]:getHeight()
        local multy =  0.3
        local x = (width/2) - spriteW/2*multy
        local y = height/4 + (i*140) -  spriteH/2*multy
        
        love.graphics.draw(sprites[sprite],x,y,nil,multy,multy)
        love.graphics.print(option,x+50,y,nil,multy*10,multy*10)
    end
    --love.graphics.print('1 for level selector, 2 for chart editor')

end
function select(option)
    if option == 'play' then loadState:loadState('levelSelector') end
    if option == 'chart editor' then loadState:loadState('chart_editor',{}) end
end
function mod:keypressed(key)
    if key == 'up' then selection = selection - 1 end
    if key == 'down' then selection = selection + 1 end
    if key == 'return' then select(list[selection]) end
    if selection  < 1 then selection = 1 end
    if selection  > #list then selection = #list end
    --if key == '1' then loadState:loadState('levelSelector') end
    --if key == '2' then loadState:loadState('chart_editor') end
end
return mod