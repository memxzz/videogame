local mod = {}
---libraries
local timerModule = require('libraries.time')
local w_items = require('libraries.workable_items')
local loadStateMod = require('modules.loadState')
local lume = require('libraries.lume')
local stats = {}
local songSound = love.sound --this needs to stop before leaving
local width, height, flags = love.window.getMode( )
local songName = ''
local fonts = {
    montserrat = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 30),size = 15,resize = false},
    montserrat_12 = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 60),size = 22,resize = false},
    montserrat_13 = {obj = love.graphics.newFont("assets/fonts/montserrat.ttf", 200),size = 22,resize = false}
}
local exiting = false
local black_screen_time = 1
local rank_color = {1,1,1,1}
local rank_man = require('modules.rankings_manager')
local function get_ranking()
    rank_color = {1,1,0,1}
    if stats.accuracy >= 99.8 then
        return 'T'
    end
    if stats.accuracy >= 95 then
        return 'S+'
    end
    if stats.accuracy >= 90 then
        return 'S'
    end
    rank_color = {0,1,0,1}
    if stats.accuracy >= 85 then   
        return 'A+'
    end
    if stats.accuracy >= 80 then
        
        return 'A'
    end
    rank_color = {0,0,1,1}
    if stats.accuracy >= 70 then
        return 'B'
    end
    if stats.accuracy >= 50 then
        return 'C'
    end
    rank_color = {1,0,0,1}
    return 'F'
end
local function add_gui()
    w_items:clear()
    local sizefactory = height/600
    local sizefactorx = width/600
    local list = {}
    local ranking = w_items:add_item("textLabel")
    ranking.background_color = {0,0,0,0}
    ranking.params.font = fonts.montserrat_13.obj
    ranking.position.x = 50*sizefactorx
    ranking.position.y = 100*sizefactory
    ranking.params.text = get_ranking()
    local name = w_items:add_item("textLabel")
    name.background_color = {0,0,0,0}
    name.params.font = fonts.montserrat_12.obj
    name.params.text = songName
    name.position.y = 100*sizefactory
    name.position.x = width/2-50*sizefactorx
    
    local stats_list = w_items:add_item('list')
    stats_list.params.font = fonts.montserrat.obj
    stats_list.params.item_distance = 35
    stats_list.position.x = width/2-50*sizefactorx
    stats_list.position.y = 180*sizefactory
    stats_list.background_color = {0,0,0,0}
    stats_list.params.items = {
        {name = 'points: ',value = tostring(stats.points)},
        {name = 'accuracy: ',value = tostring(stats.accuracy)..'%'},
        {name = 'sicks: ',value = tostring(stats.rankins.sick)},
        {name = 'goods: ',value = tostring(stats.rankins.good)},
        {name = 'bads: ',value = tostring(stats.rankins.bad)},
        {name = 'misses: ',value = tostring(stats.rankins.miss)},
    }

    local exit = w_items:add_item("textButton")
    exit.background_color = {1,0.4,0.4,1}
    exit.params.font = fonts.montserrat.obj
    exit.params.text = 'Exit'
    exit.position.x = width-200
    exit.position.y = height-50
    exit.params.on_click = function ()
        if not exiting then
            timerModule:addTask(function ()
                loadStateMod:loadState('levelSelector')
                songSound:stop()
            end,{timeDue = 2})
            exiting = true
        end
    end
end
function mod:load(params)
    print('Song ended successfully.')
    width, height, flags = love.window.getMode( )
    songName = params.songName
    stats = params.stats
    songSound = params.songSound
    add_gui()
    rank_man:add_ranking(params.difficulty,params,params.path..'/'..params.songName)
end
function mod:update(dt)
    local target = 0
    if exiting then 
        target = 1 
        songSound:setVolume(1-black_screen_time)
    end
    timerModule:update(dt)
    black_screen_time = lume.lerp(black_screen_time,target,dt*(target+1))
end
function mod:draw()
    w_items:draw()
    love.graphics.setColor(0,0,0,black_screen_time)
    love.graphics.rectangle("fill",0,0,width,height)
end
return mod