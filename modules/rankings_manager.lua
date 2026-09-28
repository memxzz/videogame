local lume = require('libraries.lume')
local mod = {}
local rankings = {

}
local function prepare_data(path)
    if not love.filesystem.getInfo('data/rankings.txt') then
        
    end
end

function mod:load()
    prepare_data()
end

return mod