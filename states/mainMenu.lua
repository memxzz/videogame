local mod = {}

local loadState = require('modules.loadState')
function mod:load()
end
function mod:update(dt)
end
function mod:draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.print('1 for level selector, 2 for chart editor')

end
function mod:keypressed(key)
    if key == '1' then loadState:loadState('levelSelector') end
    if key == '2' then loadState:loadState('chart_editor') end
end
return mod