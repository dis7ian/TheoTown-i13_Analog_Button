--- i13 Analog Button v1.6.1
-- Created by ian` on 2023-09-25

local analog
local config
local frame

local function clamp(n, min, max)
   return math.min(math.max(n, min), max)
end

local function init(v)
   return v == nil and true or v
end

local function onRange(p0, p1, range)
   return math.abs(p0 - p1) <= range
end

local function checkFrame(id)
   local draft = Draft.getDraft(id)
   if not draft then
      return false, "The entered draft id is not found."
   elseif draft:getFrameCount() ~= 2 then
      return false, "The frame must have 2 frames."
   end

   local w0, h0 = Drawing.getImageSize(draft:getFrame(1))
   local w1, h1 = Drawing.getImageSize(draft:getFrame(2))
   if (w0 + h0 + w1 + h1) / 4 ~= 30 then
      return false, "The frame size must be 30x30 pixels."
   end

   return true, draft
end

local function resetFrame()
   config.frame = "$i13_analog_button_frame00"
   frame = Draft.getDraft(config.frame)
end

local function resetConfig()
   for k in pairs(config) do config[k] = nil end

   resetFrame()
   config.hideButton = true
   config.hideButtonAlpha = 0.2
   config.oppositePost = true
   config.postX = 45
   config.postY = 50
   config.showButton = true
   config.showInBuildMode = true
   config.showOnMove = true
   config.speed = 50
   config.timeout = 750

   config.bgColorRed = 192
   config.bgColorGreen = 192
   config.bgColorBlue = 192

   config.buttonColorRed = 160
   config.buttonColorGreen = 160
   config.buttonColorBlue = 160
end

local function setVisible()
   local showUI = not TheoTown.SETTINGS.hideUI
   if config.showInBuildMode then return showUI end
   return showUI and not GUI.get("cmdCloseTool"):isVisible()
end

function script:init()
   local storage = TheoTown.getStorage()
   config = Util.optStorage(storage, draft:getId())

   local oldKey = "analogViewButton_ian00"
   local oldConfig = storage[oldKey]
   if oldConfig then
      for k, v in pairs(oldConfig) do config[k] = v end
      storage[oldKey] = nil
   end

   config.frame = config.frame or "$i13_analog_button_frame00"
   config.hideButton = init(config.hideButton)
   config.hideButtonAlpha = config.hideButtonAlpha or 0.2
   config.oppositePost = init(config.oppositePost)
   config.postX = config.postX or 45
   config.postY = config.postY or 50
   config.showButton = init(config.showButton)
   config.showInBuildMode = init(config.showInBuildMode)
   config.showOnMove = init(config.showOnMove)
   config.speed = config.speed or 50
   config.timeout = config.timeout or 750

   config.bgColorRed = config.bgColorRed or 192
   config.bgColorGreen = config.bgColorGreen or 192
   config.bgColorBlue = config.bgColorBlue or 192

   config.buttonColorRed = config.buttonColorRed or 160
   config.buttonColorGreen = config.buttonColorGreen or 160
   config.buttonColorBlue = config.buttonColorBlue or 160

   local stat, res = checkFrame(config.frame)
   if stat then frame = res end
   if not frame or frame:getFrameCount() ~= 2 then resetFrame() end
end

function script:settings()
   if not City then return end

   local showButtonConfig = {
      name = "Show Button",
      value = config.showButton,
      onChange = function(state)
         config.showButton = state
      end
   }

   if not config.showButton then
      return {showButtonConfig}
   end

   return {
      showButtonConfig,
      {
         name = "Auto Hide",
         value = config.hideButton,
         onChange = function(state)
            config.hideButton = state
         end
      },
      {
         name = "Show When Moving the View",
         value = config.showOnMove,
         onChange = function(state)
            config.showOnMove = state
         end
      },
      {
         name = "Opposite Position to Sidebar",
         value = config.oppositePost,
         onChange = function(state)
            config.oppositePost = state
         end
      },
      {
         name = "Show In Build Mode",
         value = config.showInBuildMode,
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
         name = "Button Frame",
         desc = "Enter the animation id of the button frame.",
         value = config.frame,
         onChange = function(id)
            if #id == 0 then resetFrame() end

            local stat, res = checkFrame(id)
            if stat then
               config.frame = id
               frame = res
            else
               Debug.toast(res)
            end
         end
      },
      {
         name = "Minimum Alpha When Hiding The Button",
         value = config.hideButtonAlpha,
         values = {0, 0.2, 0.5},
         onChange = function(value)
            config.hideButtonAlpha = value
         end
      },
      {
         name = "Button Hiding Timeout",
         desc = "Enter a number for button hiding timeout in milliseconds.",
         value = config.timeout,
         onChange = function(value)
            config.timeout = tonumber(value)
         end
      },
      {
         name = "Movement Speed",
         desc = "Enter a number for speed in percent.",
         value = config.speed,
         onChange = function(value)
            local value = tonumber(value)
            config.speed = math.max(value, 1)
         end
      },
      {
         name = "Button X Position",
         desc = "Enter a number for x position.",
         value = config.postX,
         onChange = function(value)
            config.postX = tonumber(value)
         end
      },
      {
         name = "Button Y Position",
         desc = "Enter a number for y position.",
         value = config.postY,
         onChange = function(value)
            config.postY = tonumber(value)
         end
      },
      {
         name = "Analog Background Color Red",
         desc = "Enter a number for background color red. (Range 0 ~ 255)",
         value = config.bgColorRed,
         onChange = function(value)
            local value = tonumber(value)
            config.bgColorRed = clamp(value, 0, 255)
         end
      },
      {
         name = "Analog Background Color Green",
         desc = "Enter a number for background color green. (Range 0 ~ 255)",
         value = config.bgColorGreen,
         onChange = function(value)
            local value = tonumber(value)
            config.bgColorGreen = clamp(value, 0, 255)
         end
      },
      {
         name = "Analog Background Color Blue",
         desc = "Enter a number for background color blue. (Range 0 ~ 255)",
         value = config.bgColorBlue,
         onChange = function(value)
            local value = tonumber(value)
            config.bgColorBlue = clamp(value, 0, 255)
         end
      },
      {
         name = "Analog Button Color Red",
         desc = "Enter a number for button color red. (Range 0 ~ 255)",
         value = config.buttonColorRed,
         onChange = function(value)
            local value = tonumber(value)
            config.buttonColorRed = clamp(value, 0, 255)
         end
      },
      {
         name = "Analog Button Color Green",
         desc = "Enter a number for button color green. (Range 0 ~ 255)",
         value = config.buttonColorGreen,
         onChange = function(value)
            local value = tonumber(value)
            config.buttonColorGreen = clamp(value, 0, 255)
         end
      },
      {
         name = "Analog Button Color Blue",
         desc = "Enter a number for button color blue. (Range 0 ~ 255)",
         value = config.buttonColorBlue,
         onChange = function(value)
            local value = tonumber(value)
            config.buttonColorBlue = clamp(value, 0, 255)
         end
      }
   }
end

function script:leaveCity()
   if config.showButton then analog = nil end
end

local function getX(root)
   local postX = config.postX
   local rw = root:getClientWidth() - 45 - postX
   if TheoTown.SETTINGS.rightSidebar then
      return config.oppositePost and postX or rw
   end
   return config.oppositePost and rw or postX
end

local function getColor(i)
   local key = i == 1 and "bgColor" or "buttonColor"
   return config[key .. "Red"], config[key .. "Green"], config[key .. "Blue"]
end

local function drawButton(x, y, w, h, i, alpha)
   Drawing.setAlpha(alpha)
   Drawing.setColor(getColor(i))
   Drawing.drawImageRect(frame:getFrame(i), x, y, w, h)
   Drawing.reset()
end

local function drawRotateIcon(x, y, w, h)
   local x = x + 6
   local y = y + 6
   local w = w - 10
   local h = h - 10
   Drawing.drawImageRect(Icon.TURN_RIGHT, x, y, w, h)
end

function script:buildCityGUI()
   if not config.showButton then return end

   local alpha = 1
   local cityWidth = City.getWidth()
   local cityHeight = City.getHeight()
   local root = GUI.getRoot()
   local tapToRotate = false
   local time = Runtime.getTime()
   local timeout = 0

   analog = root:addCanvas{
      x = getX(root),
      y = root:getClientHeight() - 45 - config.postY,
      w = 45,
      h = 45,
      onInit = function(self)
         self:setChildIndex(11)
      end,
      onDraw = function(self, x, y, w, h)
         drawButton(x, y, w, h, 1, alpha)
      end
   }

   analog:addCanvas{
      w = 45,
      h = 45,
      onDraw = function(self, x, y, w, h)
         drawButton(x, y, w, h, 2, alpha)
         if tapToRotate then drawRotateIcon(x, y, w, h) end
      end,
      onUpdate = function(self)
         if config.hideButton then
            local camX, camY = City.getView()
            if not self.camX then
               self.camX = camX
               self.camY = camY
            end

            if config.showOnMove and (self.camX ~= camX or self.camY ~= camY)
            then
               alpha = 1
               time = Runtime.getTime()
               self.camX = camX
               self.camY = camY
            end

            if alpha ~= config.hideButtonAlpha then
               timeout = Runtime.getTime() - time
               if timeout > config.timeout then
                  alpha = clamp(alpha - 0.05, config.hideButtonAlpha, 1)
               end
            end
         end

         if tapToRotate then
            if timeout > 500 then
               tapToRotate = false
            end
         end

         local cx, cy, fx, fy = self:getTouchPoint()
         if cx then
            local x = self:getX()
            local y = self:getY()
            alpha = 1
            time = Runtime.getTime()

            if cx == fx and cy == fy then
               if self.diffX then return end
               self.diffX = cx - x
               self.diffY = cy - y
               return
            end

            x = clamp(math.floor(cx - self.diffX), -10, 10)
            y = clamp(math.floor(cy - self.diffY), -10, 10)
            local speed = config.speed / 100
            local moveX = -x * speed
            local moveY = -y * speed
            City.move(moveX, moveY)
            self:setPosition(x, y)
            return
         end

         if self.diffX then
            self.diffX = nil
            self.diffY = nil
            self:setPosition(0, 0)
         end
      end,
      onClick = function(self)
         local cx, cy, fx, fy = self:getTouchPoint()
         if not (onRange(cx, fx, 2) and onRange(cy, fy, 2)) then return end
         if not tapToRotate then
            tapToRotate = true
            return
         end

         local rotation = City.getRotation() + 1
         if rotation > 3 then rotation = 0 end
         City.setRotation(rotation)
         tapToRotate = nil
      end
   }
end

function script:update()
   if not City then return end
   if not config.showButton then return end
   analog:setVisible(setVisible())
end
