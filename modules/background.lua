
local mod = {}

local t_time = 0
local gradient = require("modules.gradient")
local width, height = love.graphics.getDimensions()

local color = {1, 1, 1}
local targetColor = {1,1,1}

local backgroundColor = {0.2, 0.2, 0.2}
local backgroundTarget = {0.2, 0.2, 0.2}

local lerpSpeed = 3
function mod:setColor(r, g, b)
    targetColor = {r, g, b}

    backgroundTarget = {
        r * 0.2,
        g * 0.2,
        b * 0.2
    }
end

function mod:load(colord)
    love.graphics.setBackgroundColor(
        backgroundColor[1],
        backgroundColor[2],
        backgroundColor[3]
    )
    if colord then
        targetColor = colord
        color = colord
        backgroundColor[1],backgroundColor[2],backgroundColor[3] = colord[1]*.2,colord[2]*.2,colord[3]*.2
        backgroundTarget[1],backgroundTarget[2],backgroundTarget[3] = colord[1]*.2,colord[2]*.2,colord[3]*.2
    end
end

local function draw_grad_circle(time)
    local color1 = {0, 0, 0, 0}
    local al = 0.45 + 0.25 * math.sin(time)

    local color2 = {
        color[1] * 0.6,
        color[2] * 0.6,
        color[3] * 0.6,
        al
    }

    local x = math.sin(time * 1.2) / 2
    x = x * width / 1.5 + width / 1.5

    local y = math.sin(time)
    y = y * height / 1.5

    love.gradient.draw(
        function()
            love.graphics.rectangle(
                "fill",
                x,
                y,
                width * al,
                height * al
            )
        end,
        "radial",
        x,
        y + height / 2,
        width / 2,
        height / 2,
        color1,
        color2
    )
end

local function draw_background()
    local inter = 10
    local multi = 0.05

    for i = 0, 12 * inter, inter do
        draw_grad_circle(t_time * multi + i)
    end
end

function mod:resize()
    width, height = love.graphics.getDimensions()
end

function mod:update(dt)
    t_time = t_time + dt

    -- Factor de interpolación independiente de los FPS
    local a = 1 - math.exp(-lerpSpeed * dt)

    -- Interpolar paleta y fondo
    for i = 1, 3 do
        color[i] = color[i]
            + (targetColor[i] - color[i]) * a

        backgroundColor[i] = backgroundColor[i]
            + (backgroundTarget[i] - backgroundColor[i]) * a
    end

    love.graphics.setBackgroundColor(
        backgroundColor[1],
        backgroundColor[2],
        backgroundColor[3]
    )
end

function mod:draw()
    love.graphics.setColor(1, 1, 1, 1)

    draw_background()

    love.graphics.setColor(1, 1, 1, 1)
end

return mod
