local mod = {}

local actualState 
function mod:loadState(state,params)
    package.loaded['states'.."."..state] = nil
    actualState = require('states'.."."..state)
    actualState:load(params)
end
function mod:draw()
    if not actualState then return end
    if actualState.draw == nil then return end
    actualState:draw()
end
function mod:update(dt) 
    if not actualState then return end
    if actualState.update == nil then return end
    actualState:update(dt)
end
function mod:keypressed(key)
    if not actualState then return end
    if actualState.keypressed == nil then return end
    actualState:keypressed(key)
end
return mod