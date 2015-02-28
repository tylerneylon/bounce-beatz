--[[ pong-love/main.lua

This is the classic game pong.

TODO:
 * Set up ball as a class.
 * Try out acceleration in player movements.
 * Support overlapping sound effects.
 * Add power-ups.
 * Add levels.

Done!
 * Draw the score in a more classic huge-pixely manner.

--]]


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local font = require 'font'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- We use a coordinate system where (0, 0) is the middle of the screen, (-1, -1)
-- is the lower-left corner, and (1, 1) is the upper-right corner.

-- These will be set up in love.load.
local ball
local players  -- This will be set up in love.load.

local cyan = {0, 255, 255}

-- Sounds; loaded in love.load.
local sounds = {}

local border_size = 0.025

-- Internal drawing functions.
-- These accept input coordinates in our custom coord system.

-- x, y is the lower-left corner of the rectangle.
local function draw_rect(x, y, w, h, color)

  -- Set the color.
  color = color or {255, 255, 255}
  love.graphics.setColor(color)

  -- Convert coordinates.
  local win_w, win_h = love.graphics.getDimensions()
  -- We invert y here since love.graphics treats the top as y=0,
  -- and we treat the bottom as y=0.
  x, y = (x + 1) * win_w / 2, (1 - y) * win_h / 2
  w, h = w * win_w / 2, h * win_h / 2

  -- Shift y since love.graphics draws from the upper-left corner.
  y = y - h

  -- Draw the rectangle.
  love.graphics.rectangle('fill', x, y, w, h)
end

local function draw_rect_w_mid_pt(mid_x, mid_y, w, h, color)
  -- Set (x, y) to the lower-left corner of the rectangle.
  local x = mid_x - w / 2
  local y = mid_y - h / 2
  draw_rect(x, y, w, h, color)
end


--------------------------------------------------------------------------------
-- Font-drawing functions.
--------------------------------------------------------------------------------

-- TODO Consider moving the font-drawing functions out,
--      or perhaps moving all drawing functions together.

local font_block_size = 0.02

local function get_str_size(s)
  local w = 0
  local h = 0
  for i = 1, #s do
    local c = s:sub(i, i)
    local char_data = font[c]
    if char_data == nil then
      print('Warning: no font data for character ' .. c)
    else
      local c_height = #char_data
      if c_height > h then h = c_height end
      local c_width = #char_data[1]
      w = w + c_width
      if i > 1 then w = w + 1 end  -- For the inter-char space.
    end
  end
  return w, h
end

local function draw_boxy_char(c, x, y)
  local w, h = get_str_size(c)
  local char_data = font[c]
  for row = 1, #char_data do
    for col = 1, #char_data[1] do
      if char_data[row][col] == 1 then
        local this_x = x + (col - 1) * font_block_size
        local this_y = y + (h - row) * font_block_size
        draw_rect(this_x, this_y, font_block_size, font_block_size)
      end
    end
  end
end

-- Both x_align and y_align are expected to be either
-- 0, 0.5, or 1 for near-0, centered, or near-1 alignment.
local function draw_boxy_str(s, x, y, x_align, y_align)
  local w, h = get_str_size(s)
  x = x - w * font_block_size * x_align
  y = y - h * font_block_size * y_align
  for i = 1, #s do
    local c = s:sub(i, i)
    draw_boxy_char(c, x, y)
    x = x + (get_str_size(c) + 1) * font_block_size
  end
end


--------------------------------------------------------------------------------
-- Drawing functions.
--------------------------------------------------------------------------------

local function draw_str(s, x, y, limit, align)
  local win_w, win_h = love.graphics.getDimensions()
  x, y = (x + 1) * win_w / 2, (y + 1) * win_h / 2
  limit = limit * win_w / 2

  if align == 'right' then x = x - limit end

  love.graphics.printf(s, x, y, limit, align)
end

local function draw_borders()
  -- Draw the top and bottom boundaries.
  -- Without these, in some cases, the player may have trouble
  -- understanding where the window limits are.
  for y = -1, 1, 2 do
    draw_rect_w_mid_pt(0, y, 2, 2 * border_size)
  end
end

local function draw_center_line()
  local w = 0.02
  local num_bars = 12
  local h = 2 / (2 * num_bars + 1)
  local y = -1 + 1.5 * h
  for i = 1, num_bars do
    draw_rect_w_mid_pt(0, y, w, h)
    y = y + 2 * h
  end
end


-- Supporting functions.

local function new_ball()
  local size = 0.04
  local dx_sign = math.random(2) * 2 - 3
  local dy_sign = math.random(2) * 2 - 3
  local dx = 0.01
  --[[ Use this to help debug the score counters.
  dx = 1
  --]]
  ball = {x = 0, y = 0,
          dx = dx  * dx_sign,
          dy = 0.006 * dy_sign,
          w = size, h = size}
end

local function sign(x)
  if x > 0 then return 1 end
  return -1
end

-- Define the Player class.

local Player = {w = 0.05, h = 0.4}

function Player:new(x)
  local p = {x = x, y = 0, score = 0, dy = 0}
  return setmetatable(p, {__index = self})
end

function Player:draw()
  local w, h = self.w, self.h
  draw_rect_w_mid_pt(self.x, self.y, w, h)

  local score_str = tostring(self.score)
  local align = sign(self.x) == 1 and 'right' or 'left'

  local sgn = sign(self.x)
  local str_x = 0.98 * sgn
  local x_align = (sgn + 1) / 2  -- Map to 0 or 1.
  draw_boxy_str(score_str,       -- str
                str_x, -0.9,     -- x, y
                x_align, 0.0)    -- x_align, y_align
end

function Player:update(dt)
  self.y = self.y + self.dy * dt
  local d = self.h / 2 + border_size
  local min, max = -1 + d, 1 - d
  if self.y < min then self.y, self.dy = min, 0 end
  if self.y > max then self.y, self.dy = max, 0 end

  -- Check for a ball collision.
  -- The sign check is to enforce one collision event at a time.
  if math.abs(self.x - ball.x) < (self.w + ball.w) / 2 and
     math.abs(self.y - ball.y) < (self.h + ball.h) / 2 and
     sign(ball.dx) == sign(self.x) then

    -- Effect a slight speed-up with each player bounce.
    ball.dx = -1.12 * ball.dx

    sounds.ball_hit:play()

    -- hit_pt is in the range [-1, 1]
    local hit_pt = (ball.y - self.y) / ((self.h + ball.h) / 2)
    ball.dy = 0.03 * hit_pt
  end
end

function Player:score_up()
  sounds.point:play()
  self.score = self.score + 1
  new_ball()
end


-- Love-based functions.

function love.load()
  new_ball()
  players = {Player:new(-0.8), Player:new(0.8)}

  sounds.ball_hit = love.audio.newSource('audio/ball_hit.wav', 'static')
  sounds.point    = love.audio.newSource('audio/point.wav',    'static')
end

function love.update(dt)
  ball.x = ball.x + ball.dx
  ball.y = ball.y + ball.dy

  local d = ball.h / 2 + border_size
  if ball.y < (-1 + d) then ball.dy =  1 * math.abs(ball.dy) end
  if ball.y > ( 1 - d) then ball.dy = -1 * math.abs(ball.dy) end

  if ball.x >  1 then players[1]:score_up() end
  if ball.x < -1 then players[2]:score_up() end

  -- Move the players. This also handles ball collisions.
  for _, p in pairs(players) do
    p:update(dt)
  end
end

function love.draw()
  draw_borders()
  
  for _, p in pairs(players) do
    p:draw()
  end

  draw_center_line()

  -- Draw the ball.
  draw_rect_w_mid_pt(ball.x, ball.y, ball.w, ball.h, cyan)
end

-- This is the player movement speed.
local player_dy = 4

function love.keypressed(key, isrepeat)
  -- We don't care about auto-repeat key siganls.
  if isrepeat then return end

  -- The controls are: [QA for player 1] [PL for player 2].
  local dy = player_dy
  local actions = {
    q = {p = players[1], dy =  dy},
    a = {p = players[1], dy = -dy},
    p = {p = players[2], dy =  dy},
    l = {p = players[2], dy = -dy}
  }

  local action = actions[key]
  if not action then return end

  action.p.dy = action.dy
end

function love.keyreleased(key)
  local dy = player_dy
  local actions = {
    q = {p = players[1], dy =  dy},
    a = {p = players[1], dy = -dy},
    p = {p = players[2], dy =  dy},
    l = {p = players[2], dy = -dy}
  }

  local action = actions[key]
  if not action then return end

  -- Ignore key releases that are not active, such as the player pressing
  -- down on Q, down on A, then releasing Q. A is still active.
  if action.p.dy ~= action.dy then return end

  action.p.dy = 0
end
