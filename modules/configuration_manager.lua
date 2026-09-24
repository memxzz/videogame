local mod = {}
--libraries (changed reference)
local lume = require('libraries.lume')
------------------------------
local data_template = {
        display = {},
        input = {
            ['4k'] = {
                left = 'z',
                down = 'x',
                up = 'k',
                right = 'l'
            }
        },
        gameplay = {
            scrollSpeed = 40,
        },

    }
function update_data() --update configurations in case there are new configs from newer updates.
    local d = love.filesystem.read('data/config.txt')
    local saved_data = lume.deserialize(d)
    for section,data in pairs(data_template) do
        for i,value in pairs(data) do 
            if not saved_data[section][i] then 
                print('added data',section,i,value)
                saved_data[section][i] = value
            end
        end
    end
    local new_data = lume.serialize(saved_data)
    love.filesystem.write('data/config.txt',new_data)
end
function prepare_data()
    if not love.filesystem.getInfo('data/config.txt') then
        local s = lume.serialize(data_template)
        love.filesystem.write('data/config.txt',s)
    else update_data()
    end
end
function mod:get_data()
    local d = love.filesystem.read('data/config.txt')
    local s = lume.deserialize(d)
    return s
end
function mod:load()
    print('[configuration_manager]: Load state.')
    prepare_data()
end
return mod 