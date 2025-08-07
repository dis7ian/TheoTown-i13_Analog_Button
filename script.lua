--- i13 Analog Button v1.6.2
-- Created by ian` on 2025-8-7
local drawCircle = Drawing.drawCircle
local drawImageRect = Drawing.drawImageRect
local getAlpha = Drawing.getAlpha
local getColor = Drawing.getColor
local setAlpha = Drawing.setAlpha
local setColor = Drawing.setColor
local getTime = Runtime.getTime

local SETTINGS = TheoTown.SETTINGS
local ICON_TURN_RIGHT = Icon.TURN_RIGHT

local analog
local cmdCloseTool
local config
local lastVisible

local function clamp(n, min, max)
    return n <= min and min or n >= max and max or n
end

local function clampColor(color)
    return clamp(color, 0, 255)
end

local function getButtonColor(background)
    local p = background and "bgColor" or "buttonColor"
    return config[p .. "Red"], config[p .. "Green"], config[p .. "Blue"]
end

local function drawBgButton(x, y, w, h)
    local r, g, b = getButtonColor(true)
    setColor(r - 115, g - 115, b - 115)
    drawCircle(x, y, w, h)
    setColor(r - 25, g - 25, b - 25)
    drawCircle(x + 0.5, y + 0.5, w - 1, h - 1)
    setColor(r - 115, g - 115, b - 115)
    drawCircle(x + 2, y + 2, w - 4, h - 4)
    setColor(r - 55, g - 55, b - 55)
    drawCircle(x + 4, y + 3, w - 6, h - 5)
end

local function drawButton(x, y, w, h)
    local r, g, b = getButtonColor()
    setColor(r - 115, g - 115, b - 115)
    drawCircle(x, y, w, h)
    setColor(r - 25, g - 25, b - 25)
    drawCircle(x + 0.5, y + 0.5, w - 1, h - 1)
    for i=0.5, 10, 0.5 do
        setColor(r - 6 * i, g - 6 * i, b - 6 * i)
        drawCircle(x + i, y + i, w - i - i, h - i - i)
    end
end

local function getButtonX(bw, rw)
    local postX = config.postX
    if SETTINGS.rightSidebar then
        return config.oppositePost and postX or rw - bw - postX
    end
    return config.oppositePost and rw - bw - postX or postX
end

function script:buildCityGUI()
    if not config.showButton then return end

    local root = GUI.getRoot()
    local rw = root:getClientWidth()
    local rh = root:getClientHeight()
    local size = config.buttonSize
    local alpha = 1

    local r
    local g
    local b
    local a

    cmdCloseTool = GUI.get("cmdCloseTool")
    analog = GUI.getRoot():addCanvas{
        x = getButtonX(size, rw),
        y = rh - size - config.postY,
        w = size,
        h = size,
        padding = 2,
        onDraw = function(self, x, y, w, h)
            a = getAlpha()
            r, g, b = getColor()
            setAlpha(alpha)
            drawBgButton(x, y, w, h)
        end
    }

    local getView = City.getView
    local move = City.move

    local width = City.getWidth()
    local height = City.getHeight()
    local cx, cy = getView()
    local time = getTime()
    local timeout = 0
    local tapToRotate = false

    local w = analog:getClientWidth() / 2 / 2
    local h = analog:getClientHeight() / 2 / 2
    local radius = math.sqrt(w * w + h * h)

    local dx
    local dy
    local lx
    local ly

    analog:setChildIndex(11)
    analog:addCanvas{
        onDraw = function(self, x, y, w, h)
            drawButton(x, y, w, h)
            setColor(r, g, b)
            if tapToRotate then
                drawImageRect(ICON_TURN_RIGHT, x, y, w, h)
            end
            setAlpha(a)
        end,
        onClick = function(self)
            local x, y, fx, fy = self:getTouchPoint()
            if math.abs(x - fx) > 2 or math.abs(y - fy) > 2 then return end
            if not tapToRotate then
                tapToRotate = true
                return
            end
            local rotation = (City.getRotation() + 1) % 4
            City.setRotation(rotation)
            tapToRotate = false
        end,
        onUpdate = function(self)
            if config.hideButton then
                local camX, camY = getView()
                if config.showOnMove and (cx ~= camX or cy ~= camY) then
                    alpha = 1
                    time = getTime()
                    cx = camX
                    cy = camY
                end
                if alpha ~= config.hideButtonAlpha then
                    timeout = getTime() - time
                    if timeout > config.timeout then
                        alpha = clamp(alpha - 0.05, config.hideButtonAlpha, 1)
                    end
                end
            end

            if tapToRotate then
                if getTime() - time > 500 then
                    tapToRotate = false
                end
            end

            local x, y, fx, fy = self:getTouchPoint()
            if x then
                alpha = 1
                time = getTime()
                if x == fx and y == fy and dx == nil then
                    dx = x - self:getX()
                    dy = y - self:getY()
                end
                x = clamp(x - dx, -radius, radius)
                y = clamp(y - dy, -radius, radius)
                local speed = config.speed / 100
                local moveX = -x * speed
                local moveY = -y * speed
                move(moveX, moveY)
                if lx ~= x or ly ~= y then
                    self:setPosition(x, y)
                    lx = x
                    ly = y
                end
                return
            end
            if dx then
                dx = nil
                dy = nil
                lx = nil
                ly = nil
                self:setPosition(0, 0)
            end
        end
    }
end

function script:init()
    config = Util.optStorage(TheoTown.getStorage(), draft:getId())
    config.showButton = config.showButton == nil or config.showButton
    config.showInBuildMode = config.showInBuildMode == nil or config.showInBuildMode
    config.showOnMove = config.showOnMove == nil or config.showOnMove
    config.hideButton = config.hideButton == nil or config.hideButton
    config.hideButtonAlpha = config.hideButtonAlpha or 0.2
    config.oppositePost = config.oppositePost == nil or config.oppositePost
    config.buttonSize = config.buttonSize or 45
    config.postX = config.postX or 45
    config.postY = config.postY or 50
    config.speed = config.speed or 50
    config.timeout = config.timeout or 750
    config.bgColorRed = config.bgColorRed or 192
    config.bgColorGreen = config.bgColorGreen or 192
    config.bgColorBlue = config.bgColorBlue or 192
    config.buttonColorRed = config.buttonColorRed or 160
    config.buttonColorGreen = config.buttonColorGreen or 160
    config.buttonColorBlue = config.buttonColorBlue or 160
end

function script:leaveCity()
    if analog then
        analog:delete()
        analog = nil
        cmdCloseTool = nil
        lastVisible = nil
    end
end

function script:update()
    if analog == nil then return end
    local visible = not SETTINGS.hideUI and (config.showInBuildMode or not cmdCloseTool:isVisible())
    if lastVisible == visible then return end
    lastVisible = visible
    analog:setVisible(visible)
end

local function resetConfig()
    config.showButton = true
    config.showInBuildMode = true
    config.showOnMove = true
    config.hideButton = true
    config.hideButtonAlpha = 0.2
    config.oppositePost = true
    config.buttonSize = 45
    config.postX = 45
    config.postY = 50
    config.speed = 50
    config.timeout = 750
    config.bgColorRed = 192
    config.bgColorGreen = 192
    config.bgColorBlue = 192
    config.buttonColorRed = 160
    config.buttonColorGreen = 160
    config.buttonColorBlue = 160
end

local function parseNumber(str, i)
    i = i or 2
    local ptn = "(%d+)"
    while i >= 0 do
        local ptn = ptn .. (",%s?" .. ptn):rep(i)
        local a, b, c = str:match(ptn)
        if a ~= nil then
            return tonumber(a), tonumber(b), tonumber(c)
        end
        i = i - 1
    end
end

local STRUCT_SETTINGS = {
    {
        name = "Show Button",
        onChange = function(state)
            config.showButton = state
        end
    },
    {
        name = "Auto Hide",
        onChange = function(state)
            config.hideButton = state
        end
    },
    {
        name = "Show On Moving View",
        onChange = function(state)
            config.showOnMove = state
        end
    },
    {
        name = "Opposite Position to Sidebar",
        onChange = function(state)
            config.oppositePost = state
        end
    },
    {
        name = "Show In Build Mode",
        onChange = function(state)
            config.showInBuildMode = state
        end
    },
    {
        name = "Reset",
        desc = 'Are you sure want to reset? Enter "Y" to do this action.',
        value = "",
        onChange = function(value)
            if value:find("^[yY]") then resetConfig() end
        end
    },
    {
        name = "Minimum Alpha When Hiding The Button",
        values = {0, 0.2, 0.5},
        onChange = function(value)
            config.hideButtonAlpha = value
        end
    },
    {
        name = "Button Hiding Timeout",
        desc = "Enter a number for button hiding timeout in milliseconds.",
        onChange = function(value)
            config.timeout = tonumber(value)
        end
    },
    {
        name = "Movement Speed",
        desc = "Enter a number for speed in percent.",
        onChange = function(value)
            local value = tonumber(value)
            config.speed = math.max(value, 1)
        end
    },
    {
        name = "Button Size",
        desc = "Enter a new size. (range 26 ~ 104)",
        onChange = function(value)
            value = tonumber(value)
            if value == nil then return end
            config.buttonSize = clamp(value, 26, 104)
        end
    },
    {
        name = "Button Position",
        desc = 'Enter a number in "x, y" format. The y value will be taken from x, if not provided.',
        onChange = function(value)
            local x, y = parseNumber(value, 1)
            if x == nil then return end
            config.postX = x
            config.postY = y or x
        end
    },
    {
        name = "Analog Background Color",
        desc = 'Enter a number in "r, g, b" format. The g will be taken from r and b from g, if not provided.',
        onChange = function(value)
            local r, g, b = parseNumber(value)
            if r == nil then return end
            config.bgColorRed = clampColor(r)
            config.bgColorGreen = clampColor(g or r)
            config.bgColorBlue = clampColor(b or g or r)
        end
    },
    {
        name = "Analog Button Color",
        desc = 'Enter a number in "r, g, b" format. The g will be taken from r and b from g, if not provided.',
        onChange = function(value)
            local r, g, b = parseNumber(value)
            if r == nil then return end
            config.buttonColorRed = clampColor(r)
            config.buttonColorGreen = clampColor(g or r)
            config.buttonColorBlue = clampColor(b or g or r)
        end
    }
}
local STRUCT_INACTIVE_SETTINGS = {STRUCT_SETTINGS[1]}

function script:settings()
    if City == nil then return end
    local showButton = config.showButton
    STRUCT_SETTINGS[1].value = showButton
    if not showButton then
        return STRUCT_INACTIVE_SETTINGS
    end
    STRUCT_SETTINGS[2].value = config.hideButton
    STRUCT_SETTINGS[3].value = config.showOnMove
    STRUCT_SETTINGS[4].value = config.oppositePost
    STRUCT_SETTINGS[5].value = config.showInBuildMode
    STRUCT_SETTINGS[7].value = config.hideButtonAlpha
    STRUCT_SETTINGS[8].value = config.timeout
    STRUCT_SETTINGS[9].value = config.speed
    STRUCT_SETTINGS[10].value = config.buttonSize
    STRUCT_SETTINGS[11].value = config.postX .. ", " .. config.postY
    STRUCT_SETTINGS[12].value = config.bgColorRed .. ", " .. config.bgColorGreen .. ", " .. config.bgColorBlue
    STRUCT_SETTINGS[13].value = config.buttonColorRed .. ", " .. config.buttonColorGreen .. ", " .. config.buttonColorBlue
    return STRUCT_SETTINGS
end

