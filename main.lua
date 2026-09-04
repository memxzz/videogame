local loadStateMod = require('modules.loadState')
function love.load()
    loadStateMod:loadState("mainMenu")
end
function love.draw()
    loadStateMod:draw()
end
function love.update(dt)
    loadStateMod:update(dt)
end
function love.keypressed(key)
    loadStateMod:keypressed(key)
end