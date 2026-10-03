local lume = require('libraries.lume')
local mod = {}
local rankings_template = {
    
}
local rankings = {

}
local function prepare_data(path,difficulty)
    local d = love.filesystem.read(path..'/info.txt')
    local data = lume.deserialize(d)
    if not love.filesystem.getInfo(path..'/rankings.txt') then
        for i,v in pairs(data.difficulties) do
            rankings = {}
        end
        local new_data = lume.serialize(rankings)
        if not rankings[difficulty] then rankings[difficulty] = {} end
        love.filesystem.write(path..'/rankings.txt',new_data)
    else
        local info = love.filesystem.read(path..'/rankings.txt')
        info = lume.deserialize(info)
        rankings = info
    end
end
function mod:update_data(new_version)

end
function mod:add_ranking(difficulty,info,path)
    prepare_data(path,difficulty)
    if not rankings[difficulty] then rankings[difficulty] = {} end
    local per_difficulty_cantity = #rankings[difficulty]
    rankings[difficulty][per_difficulty_cantity+1] = info
    print('[rankings_manager] Added ranking.')
end
function mod:get_data(path,difficulty)
    prepare_data(path,difficulty)

    return rankings[difficulty]
end

return mod