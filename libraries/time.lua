--library to handle tasks that need to be do after some time.
--made by: me :) atto.
local mod = {
    tasks = {}
}
local taskTemplate = {
    func,
    time = 0,
    timeDue = 0,
    paused = false,
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
function mod:addTask(func,confs)
    local newTask = shallow_copy(taskTemplate)
    newTask.func = func
    newTask.timeDue = confs.timeDue
    mod.tasks[#mod.tasks + 1] = newTask
    print('added')
    return mod.tasks[#mod.tasks]
    --table.insert(mod.tasks,newTask)
end
function mod:update(dt)
    for i,task in pairs(mod.tasks) do 
        if task.paused then return end
        task.time = task.time + dt
        if task.time > task.timeDue then
            task.func()
            mod.tasks[i] = nil
        end
    end
end

return mod