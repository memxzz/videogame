--this entire script might be the most useless shit ever
--but im too stupid to know.
local mod = {}

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
function mod:get(name)
    local template = require('templates.'..name)
    return shallow_copy(template)
end
return mod