local loadStateMod = require('modules.loadState')


function love.load()
    love.window.setMode(1920,1080)
    local width, height = love.graphics.getDimensions( )

    print(width,height)
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