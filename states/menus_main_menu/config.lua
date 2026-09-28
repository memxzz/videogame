local lume = require('libraries.lume')
local w_items = require('libraries.workable_items')
local mod = {
    open = false,
    position = {
        x = 0,
        y = 0
    }
}
local assets = {
    background = love.graphics.newImage('assets/mainMenu/menus/config/menu_background.png')
}
local conf_manager = require('modules.configuration_manager')
local width, height, flags = love.window.getMode( )
local configuration = {}
local menu_items = {
    sections = {

    },
    data = {

    }
}
local section = ''
local function get_transfurmed_image_proportions(image,sizex,sizey)
    local factor = height/600
    local ogW,ogH = image:getDimensions()
    local dW,dH = sizex*factor,sizey*factor
    local sx = dW/ogW
    local sy = dH/ogH
    return sx,sy
end
local old = ''
local function update_showed_data(force)
    if old == section and not force then return end
    old = section
    if not configuration then return end
    if not configuration[section] then return end
    for i,v in pairs(menu_items.data) do
        v.ind:delete(v.ind)
        v.value:delete(v.value)
        menu_items.data[i] = nil
    end
    local newTable = {}
    for i,v in pairs(configuration[section]) do
        local item = w_items:add_item("textBox")
        local indItem = w_items:add_item("textLabel")
        indItem.params.text = i
        item.params.text_label = tostring(v)
        item.params.on_text_return = function (change)
            configuration[section][i] = tonumber(change)
            item.params.text_label = tostring(change)
        end
        newTable[i] = {ind = indItem,value = item}
    end
    menu_items.data = newTable

end
local function save_data()
    print('[config_menu]: Saving data.')
    conf_manager:set_data(configuration)
end
function mod:load()
    w_items:clear()
    configuration = conf_manager:get_data()
    local iw = assets.background:getWidth()
    local ih = assets.background:getHeight()
    mod.position.y = height+ih/2
    mod.position.x = width/2-iw/2
    local section_index = 0
    for sect,data in pairs(configuration) do
        local newItem = w_items:add_item("textButton")
        newItem.size = {
            x = 210,
            y = 60
        }
        newItem.params.text = sect
        newItem.params.on_click = function ()
            section = sect
        end
        menu_items.sections[sect] = newItem
        section_index = section_index + 1
    end
end
local function update_items_pos()
    local sizefactory = height/600
    local sizefactorx = width/600
    local section_index = 0
    for i,v in pairs(menu_items.sections) do
        v.position.y = mod.position.y+90 + section_index*70
        v.position.x = mod.position.x+50
        section_index = section_index + 1
    end
end
local function update_data_items_pos()
    if not menu_items.data then return end
    if not #menu_items.data then return end 
    local sizefactory = height/600
    local sizefactorx = width/600
    local section_index = 0
    for i,v in pairs(menu_items.data) do
        v.ind.position.x = mod.position.x+300
        v.value.position.x = v.ind.position.x + 300

        v.ind.position.y = mod.position.y+90+section_index*70
        v.value.position.y = v.ind.position.y
        section_index = section_index + 1
    end
end
function love.textinput(key)
    w_items:textinput(key)
end
function mod:draw()
    local new_sizex,new_sizey = get_transfurmed_image_proportions(assets.background,640,460)
    local sizefactory = height/600
    local sizefactorx = width/600
    love.graphics.draw(assets.background,
        mod.position.x,
        mod.position.y,
        0,
        new_sizex,
        new_sizey)
    w_items:draw()
end
function love.mousepressed( x, y, button, istouch, presses )
    w_items:mousepressed( x, y, button, istouch, presses )
end
function mod:keypressed(key)
    w_items:keypressed(key)
end
local old_state = false
function mod:update(dt)
    update_showed_data()
    local new_sizex,new_sizey = get_transfurmed_image_proportions(assets.background,640,460)
    local iw = assets.background:getWidth()
    local ih = assets.background:getHeight()
    if mod.open then
        mod.position.y = lume.lerp(mod.position.y,height/2-(ih*new_sizey)/2,dt *10)
        mod.position.x = lume.lerp(mod.position.x,width/2-(iw*new_sizex)/2,dt *10)
    else
        mod.position.y = lume.lerp(mod.position.y,height/2+(ih*new_sizey),dt*10)
        mod.position.x = lume.lerp(mod.position.x,width/2-(iw*new_sizex)/2,dt*10)
    end
    update_items_pos()
    update_data_items_pos()
    w_items:update(dt)
    if old_state == mod.open then return end
    old_state = mod.open
    if not mod.open then save_data() end
end
function mod:resize()
    width, height, flags = love.window.getMode( )
end
return mod