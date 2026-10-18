local lume = require('libraries.lume')
local mod = {}
local rankings = {

}
local function prepare_data(path,difficulty)
    local d = love.filesystem.read(path..'/info.txt')
    local data = lume.deserialize(d)
    if not love.filesystem.getInfo(path..'/rankings.txt') then
        rankings = {}
        for i,v in pairs(data.difficulties) do
            rankings[v] = {}
        end
        local new_data = lume.serialize(rankings)
        if difficulty and not rankings[difficulty] then rankings[difficulty] = {} end
        love.filesystem.write(path..'/rankings.txt',new_data)
    else
        local info = love.filesystem.read(path..'/rankings.txt')
        info = lume.deserialize(info)
        rankings = info
    end
end
local function update_data(new_version,path)
    --prepare_data(path)
    rankings = new_version
    for i,v in pairs(new_version) do
        print(i,v)
    end
    local serial = lume.serialize(new_version)
    love.filesystem.write(path..'/rankings.txt',serial)
end
function mod:add_ranking(difficulty,info,path)
    prepare_data(path,difficulty)
    if not rankings[difficulty] then rankings[difficulty] = {} end
    local per_difficulty_cantity = #rankings[difficulty]
    rankings[difficulty][per_difficulty_cantity+1] = info
    update_data(rankings,path)
    print('[rankings_manager] Added ranking.')
end
function mod:get_data(path,difficulty)
    prepare_data(path,difficulty)

    return rankings
end

return mod