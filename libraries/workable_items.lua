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
        on_text_return = function() end,
        on_click = function() end,
        texting = false,
    }
}
local item = {
    typ = itemType.textBox, --type
    size = {
            x = 200,
            y = 50
        },
        position = {
            x = 0,
            y = 0
        },
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
        local x = item.position.x
        local y = item.position.y
        local height = item.size.x
        if item.params.text == '' then
            love.graphics.print(item.params.text_label,x,y)
        else love.graphics.print(item.params.text,x,y)
        end
        
    end
end
function mod:draw()
    for i,item in pairs(mod.items)  do
        love.graphics.push("all")
        love.graphics.origin()
        love.graphics.setColor(0.8,0.8,0.8,1)
        love.graphics.rectangle('fill',item.position.x,item.position.y,item.size.x,item.size.y)
        love.graphics.setColor(1,1,1,1)
        on_type_draw(item)
        love.graphics.pop()
    end
end
function mod:update(dt)
    
end
function on_type_pressed(item)
    if item.typ == itemType.textBox then
        item.params.text = ' '
        item.params.texting = true
    end
end
function mod:textinput(key)
    for i,item in pairs(mod.items) do
        if item.typ == itemType.textBox and item.params.texting then
            if key ~= 'return' and key ~= 'backspace' then
                item.params.text = item.params.text..key
            end
        end 
    end
end
function mod:keypressed(key)
    for i,item in pairs(mod.items) do
        if item.typ == itemType.textBox and item.params.texting then
            if key ~= 'return' then 
                if key == 'backspace' then
                    item.params.text = string.sub(item.params.text, 1, -2)
                end
                
                item.params.on_text_change()
            else 
                item.params.texting = false 
                item.params.on_text_return(item.params.text)
                item.params.text = ''
            end
        end
    end
end
function mod:mousepressed( x, y, button, istouch, presses )
    
    for i,item in pairs(mod.items) do
        
        if x > item.position.x and x < item.position.x + item.size.x then  
            if y > item.position.y and y < item.position.y+item.size.y then
                on_type_pressed(item)
            end
        end
    end
end
function mod:add_item(typ)
    if not itemType[typ] then print('['..workable_items.."]: Can't add item. Type is not acceptable.") return end
    local newItem = shallow_copy(item)
    newItem.typ = itemType[typ]
    newItem.params = shallow_copy(params_per_type[typ])

    mod.items[#mod.items + 1] = newItem
    return mod.items[#mod.items]
end
return mod