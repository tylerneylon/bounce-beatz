--[[ pong-love/main.lua

This is the classic game pong.

--]]


-- Internal drawing functions.
-- These accept input coordinates in our custom coord system.

local function draw_rect(x, y, w, h, color)

  -- Set the color.
  color = color or {255, 255, 255}
  love.graphics.setColor(color)

  -- Convert coordinates.
  local win_w, win_h = love.graphics.getDimensions()
  x, y = (x + 1) * win_w / 2, (y + 1) * win_h / 2
  w, h = w * win_w / 2, h * win_h / 2

  -- Draw the rectangle.
  love.graphics.rectangle('fill', x, y, w, h)
end

local function draw_center_line()
  local w = 0.03
  local num_bars = 12
  local h = 2 / num_bars / 2  -- First 2 = win height.
  local y = -1 + h
  for i = 1, num_bars do
    draw_rect(-w / 2, y, w, h)
    y = y + 2 * h
  end
end

-- Define the Player class.

local Player = {w = 0.05, h = 0.4}

function Player:new(x)
  local p = {x = x, y = 0, score = 0, dy = 0}
  return setmetatable(p, {__index = self})
end

function Player:draw()
  local w, h = self.w, self.h
  draw_rect(self.x - w / 2, self.y - h / 2, w, h)
end

function Player:update(dt)
  self.y = self.y + self.dy * dt
  local min, max = -1 + self.h / 2, 1 - self.h / 2
  if self.y < min then self.y, self.dy = min, 0 end
  if self.y > max then self.y, self.dy = max, 0 end
end


-- Internal globals.

-- We use a coordinate system where (0, 0) is the middle of the screen, (-1, -1)
-- is the lower-left corner, and (1, 1) is the upper-right corner.
local ball = {x = 0, y = 0, dx = -0.01, dy = 0.006}

local players = {Player:new(-0.8), Player:new(0.8)}

local blue = {0, 255, 255}

-- Love-based functions.

function love.load()
  -- This function runs once and first.
end

function love.update(dt)
  ball.x = ball.x + ball.dx
  ball.y = ball.y + ball.dy
  for _, p in pairs(players) do
    p:update(dt)
  end
end

function love.draw()
  for _, p in pairs(players) do
    p:draw()
  end
  draw_center_line()

  -- Draw the ball.
  local w, h = 0.02, 0.02
  local x, y = ball.x - w / 2, ball.y - h / 2
  draw_rect(x, y, w, h, blue)
end

-- This is the player movement speed.
local player_dy = 4

function love.keypressed(key, isrepeat)
  -- We don't care about auto-repeat key siganls.
  if isrepeat then return end

  -- The controls are: [QA for player 1] [PL for player 2].
  local dy = player_dy
  local actions = {
    q = {p = players[1], dy = -dy},
    a = {p = players[1], dy =  dy},
    p = {p = players[2], dy = -dy},
    l = {p = players[2], dy =  dy}
  }

  local action = actions[key]
  if not action then return end

  action.p.dy = action.dy
end

function love.keyreleased(key)
  local dy = player_dy
  local actions = {
    q = {p = players[1], dy = -dy},
    a = {p = players[1], dy =  dy},
    p = {p = players[2], dy = -dy},
    l = {p = players[2], dy =  dy}
  }

  local action = actions[key]
  if not action then return end

  -- Ignore key releases that are not active, such as the player pressing
  -- down on Q, down on A, then releasing Q. A is still active.
  if action.p.dy ~= action.dy then return end

  action.p.dy = 0
end
