local loadStateMod = require('modules.loadState')


function love.load()
    love.keyboard.setTextInput(true)
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
function love.textinput(key)
    loadStateMod:textinput(key)
end