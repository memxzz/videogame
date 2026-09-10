--this library was made to handle items like textBoxes and others.
--made by me atto :  )
local name = 'workable_items'
local mod = {
    items = {}
}
local itemType = {
    ['textBox'] = 1,
    ['textLabel'] = 2
}
local params_per_type = {
    ['textBox'] = {
        text_label = 'template',
        text = '',
        on_text_change = function() end,
        on_click = function() end,
        size = {
            x = 200,
            y = 50
        },
        position = {
            x = 0,
            y = 0
        }
    }
}
local item = {
    typ = itemType.textBox, --type
    params = {}
    
}

function shallow_copy(t)
  if type(t) ~= "table" then
        return t
    end

    local copy = {}

    for k, v in pairs(t) do
        copy[shallow_copy(k)] = shallow_copy(v)
    end

    return copy
end

function on_type_draw(item)
    if item.typ == itemType.textBox then
        if item.text == '' then
            love.graphics.print(item.text_label)
        else love.graphics.print(item.text)
        end
        
    end
end
function mod:draw()
    for i,item in pairs(mod.items)  do
        love.graphics.push("all")
        love.graphics.origin()
        love.graphics.rectangle('fill',item.position.x,item.position.y,item.size.x,item.size.y)
        on_type_draw(item)
        love.graphics.pop()
    end
end
function mod:update(dt)
end
function love.mousepressed( x, y, button, istouch, presses )

end
function mod:add_item(typ)
    if not itemType[typ] then print('['..workable_items.."]: Can't add item. Type is not acceptable.") return end
    local newItem = shallow_copy(item)
    newItem.typ = itemType[typ]
    newItem.params = shallow_copy(params_per_type[typ])

    mod.items[#mod.items + 1] = newTask
    return mod.items[#mod.items]
end
return mod