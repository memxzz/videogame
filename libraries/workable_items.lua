--this library was made to handle items like textBoxes, textLabels and others.
--made by me atto :  )

local name = 'workable_items'
local mod = {
    items = {},
    states = {
        texting = false,
        adding_file = false
    }
}
---@alias itemType
---|'textBox'
---|'textLabel'
---|'list'
---|'fileBox'
local itemType = {
    ['textBox'] = 1,
    ['textLabel'] = 2,
    ['list'] = 3,
    ['fileBox'] = 4
}
--textbox
---@class TextBoxParams
---@field text_label string
---@field text string
---@field on_text_change function
---@field on_text_return function
---@field on_click function
---@field texting boolean 
--filebox
---@class FileBoxParams
---@field dialog_settings {title:string}
---@field text_label string
---@field file string?
---@field on_dialog_end fun(files:table,filtername:string,errorstring:string)
---@field adding_file boolean  
--textlabel
---@class TextLabelParams
---@field text string

--listItem
---@class listItem
---@field name string
---@field value string
---@field update? fun(dt,self_item)

--list
---@class ListParams
---@field item_distance number
---@field items table

local params_per_type = {
    ---@type TextBoxParams
    ['textBox'] = {
        text_label = 'template',
        text = '',
        on_text_change = function() end,
        on_text_return = function() end,
        on_click = function() end,
        texting = false,
    },
    ---@type FileBoxParams
    ['fileBox'] = {
        dialog_settings = {
            title = 'Title'
        },
        text_label = 'template',
        file = nil,
        on_dialog_end = function(files,filtername,errorstring) end,
        adding_file = false,
    },
    ---@type TextLabelParams
    ['textLabel'] = {
        text = 'template',
    },
    ---@type ListParams
    ['list'] = {
        item_distance = 20,
        items = {
            {name = 'name',value = 'value'} --both strings
        }
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
    background_color = {0.8,0.8,0.8,1}, --rgba, same as love2d setColor()
    update = function() end,
    params = {}
    
}
---@alias ItemParams TextBoxParams|FileBoxParams|TextLabelParams|ListParams
---@alias ItemByType
---| TextBoxItem
---| TextLabelItem
---| ListItemObject
---| FileBoxItem

---@class Item
---@field typ number
---@field size { x: number, y: number }
---@field position { x: number, y: number }
---@field background_color number[]
---@field update fun(dt: number)


---@class TextBoxItem: Item
---@field typ 1
---@field params TextBoxParams

---@class FileBoxItem: Item
---@field typ 4
---@field params FileBoxParams

---@class TextLabelItem: Item
---@field typ 2
---@field params TextLabelParams

---@class ListItemObject: Item
---@field typ 3
---@field params ListParams

local function shallow_copy(t)
  if type(t) ~= "table" then
        return t
    end

    local copy = {}

    for k, v in pairs(t) do
        copy[shallow_copy(k)] = shallow_copy(v)
    end

    return copy
end

local function on_type_draw(item)
    if item.typ == itemType.textBox then
        local x = item.position.x
        local y = item.position.y
        local height = item.size.x
        local tExtra = ''
        if item.params.texting then tExtra = '|' end
        if item.params.text == '' then
            love.graphics.print(item.params.text_label,x,y)
        else love.graphics.print(item.params.text..tExtra,x,y)
        end
    end
    if item.typ == itemType.fileBox then
        local x = item.position.x
        local y = item.position.y
        local height = item.size.x
        --if not item.params.file then
            love.graphics.print(item.params.text_label,x,y)
        --else 
        --    love.graphics.print(item.params.file,x,y)
        --end
    end
    if item.typ == itemType.textLabel then
        local x = item.position.x
        local y = item.position.y
        local height = item.size.x
        love.graphics.print(item.params.text,x,y)
    end
    if item.typ == itemType.list then
        for i,element in pairs(item.params.items) do
            local x = item.position.x
            local y = item.position.y + (i-1) * item.params.item_distance
            local height = item.size.x
            item.size.y = (i) * item.params.item_distance
            love.graphics.print(element.name..'   '..element.value,x,y)
        end
    end
end
function mod:draw()
    for i,item in pairs(mod.items)  do
        local bgcolor = item.background_color
        love.graphics.push("all")
        love.graphics.origin()
        love.graphics.setColor(bgcolor[1],bgcolor[2],bgcolor[3],bgcolor[4])
        love.graphics.rectangle('fill',item.position.x,item.position.y,item.size.x,item.size.y)
        love.graphics.setColor(1,1,1,1)
        on_type_draw(item)
        love.graphics.pop()
    end
end
function mod:update(dt)
    for i,item in pairs(mod.items) do
        if item.update then
            item.update(dt)
        end
        if item.typ == itemType.list then
            for d,element in pairs(item.params.items) do
                if element.update then
                    element.update(dt,element)
                end
            end
        end
    end
end
local lastText = ''
local function on_type_pressed(item)
    if mod.states.texting  then return end
    if mod.states.adding_file then return end
    if item.typ == itemType.textBox then
        lastText = item.params.text
        item.params.text = ' '
        item.params.texting = true
        mod.states.texting = true
    end
    if item.typ == itemType.fileBox then
        item.params.adding_file = true
        mod.states.adding_file = true
        local file = love.window.showFileDialog(
            'openfile',
            function(files,filtername,errorstring) 
                item.params.adding_file = false
                mod.states.adding_file = false
                item.params.on_dialog_end(files,filtername,errorstring)
            end,
            item.params.dialog_settings
        )
    end
end
function mod:textinput(key)
    for i,item in pairs(mod.items) do
        if item.typ == itemType.textBox and item.params.texting then
            if key ~= 'return' and key ~= 'backspace' then     
                if item.params.text == ' ' then
                    item.params.text = key
                else
                    item.params.text = item.params.text..key
                end
                
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
                if key == 'escape' then
                    item.params.text = lastText
                    mod.states.texting = false
                    item.params.texting = false 
                end
                
                item.params.on_text_change()
            else 
                mod.states.texting = false
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
function mod:clear()
    for i,v in pairs(mod.items) do
        mod.items[i] = nil
    end
end
---@overload fun(typ: "textBox"): TextBoxItem
---@overload fun(typ: "fileBox"): FileBoxItem
---@overload fun(typ: "textLabel"): TextLabelItem
---@overload fun(typ: "list"): ListItemObject
---@param typ "textBox"|"fileBox"|"textLabel"|"list"
---@return ItemByType
function mod:add_item(typ)
    if not itemType[typ] then print('['..name.."]: Can't add item. Type is not acceptable.") return  end
    local newItem = shallow_copy(item)
    newItem.typ = itemType[typ]
    newItem.params = shallow_copy(params_per_type[typ])

    mod.items[#mod.items + 1] = newItem
    return mod.items[#mod.items]
end
return mod