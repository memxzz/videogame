local mod = {}
local loadStateMod = require('modules.loadState')
local exitTime = 0
function mod:load()
    print('[Chart_editor]: Loaded.')
end
function mod:draw()
    if exitTime > 0 then
        love.graphics.push()
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.print('Exiting...'..'('..tostring(math.floor(exitTime))..')')
        love.graphics.pop()
    end
end
function mod:update(dt)
    if love.keyboard.isDown('backspace') then
        exitTime = exitTime + dt
        if exitTime > 4 then
            exitTime = 0
            loadStateMod:loadState('mainMenu')
        end
        return
    end
    exitTime = 0
end
return mod