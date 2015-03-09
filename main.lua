--[[ pong-love/main.lua

This is the classic game pong.

# Roadmap

Anytime items

[ ] Support overlapping sound effects
[ ] Split into modules (ball, player, draw, font)

Phase I   : Human vs human gameplay (1P battle)

[x] New sound for edge hits
[ ] Spin
[ ] More points for long-lasting balls

Phase I.(half) : title and menu screen

[ ] Add a title screen
[ ] Add a play-mode menu

Phase II  : Human vs computer AI    (2P battle)

Phase III : Levels                  (Beats)

[ ] Add power-ups.

Done!
 * Draw the score in a more classic huge-pixely manner.
 * Improve collision detection so balls can't go
   through players. Note: This isn't perfect but I believe it's robust
   enough that in actual human play the ball won't pass through a player.
   (Because it will never be going fast enough to hit a bug.)

--]]


--------------------------------------------------------------------------------
-- Debug parameters.
--------------------------------------------------------------------------------

-- These are listed first for easier access.

-- Controls default new-ball behavior; set this to false for normal operation.
local in_dbg_ball_mode = false
local dbg_start_dx = 0.5
local dbg_start_dy = 0

-- If dbg_cycles_per_frame = 1, then it's full speed (normal operation), if
-- it's = 2, then we're at half speed, etc.
local dbg_cycles_per_frame = 1
local dbg_frame_offset = 0


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'
local font     = require 'font'
local hit_test = require 'hit_test'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- We use a coordinate system where (0, 0) is the middle of the screen, (-1, -1)
-- is the lower-left corner, and (1, 1) is the upper-right corner.

-- These will be set up in love.load.
local ball
local players  -- This will be set up in love.load.

-- Sounds; loaded in love.load.
local sounds = {}


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

local function draw_boxy_char(c, x, y, color)
  local w, h = get_str_size(c)
  local char_data = font[c]
  for row = 1, #char_data do
    for col = 1, #char_data[1] do
      if char_data[row][col] == 1 then
        local this_x = x + (col - 1) * font_block_size
        local this_y = y + (h - row) * font_block_size
        draw.rect(this_x, this_y, font_block_size, font_block_size, color)
      end
    end
  end
end

-- Both x_align and y_align are expected to be either
-- 0, 0.5, or 1 for near-0, centered, or near-1 alignment.
local function draw_boxy_str(s, x, y, x_align, y_align, color)
  local w, h = get_str_size(s)
  x = x - w * font_block_size * x_align
  y = y - h * font_block_size * y_align
  for i = 1, #s do
    local c = s:sub(i, i)
    draw_boxy_char(c, x, y, color)
    x = x + (get_str_size(c) + 1) * font_block_size
  end
end


--------------------------------------------------------------------------------
-- Supporting functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
end


--------------------------------------------------------------------------------
-- The Ball class.
--------------------------------------------------------------------------------

local Ball = {size = 0.04}

function Ball:new()
  local dx_sign  = math.random(2) * 2 - 3
  local dy_sign  = math.random(2) * 2 - 3
  local start_dx = 0.6
  local start_dy = 0.4

  if in_dbg_ball_mode then
    start_dx, start_dy = dbg_start_dx, dbg_start_dy
  end

  local ball = {x  = 0,
                y  = 0,
                old_x = 0,
                old_y = 0,
                dx = start_dx * dx_sign,
                dy = start_dy * dy_sign,
                w  = self.size,
                h  = self.size}
  return setmetatable(ball, {__index = self})
end

-- hit_pt is expected to be in the range [-1, 1], and determines the
-- angle that the ball bounces away at.
-- bounce_pt is the x-coord at which the ball bounces.
function Ball:bounce(hit_pt, bounce_pt, is_edge_hit)
  assert(type(hit_pt) == 'number')

  self.x = bounce_pt - (self.x - bounce_pt)

  -- Effect a slight speed-up with each player bounce.
  local speedup = 1.12
  self.dx = -speedup * self.dx
  self.dy =        2 * hit_pt

  local max_dx = 10
  if math.abs(self.dx) > max_dx then
    self.dx = sign(self.dx) * max_dx
  end

  self.did_bounce = true

  local sound = is_edge_hit and sounds.ball_edge_hit or sounds.ball_hit
  sound:play()
end

function Ball:update(dt)

  self.did_bounce = false  -- Track if we bounced this cycle already.

  self.old_x = self.x
  self.old_y = self.y

  self.x = self.x + self.dx * dt
  self.y = self.y + self.dy * dt

  local d = self.h / 2 + draw.border_size
  if self.y < (-1 + d) then self.dy =  1 * math.abs(self.dy) end
  if self.y > ( 1 - d) then self.dy = -1 * math.abs(self.dy) end
end

-- This is outside of Ball:update so that balls can interact with
-- the players (bounce) before we check for a score going up. Fast balls
-- can appear (x-wise) to go through a player when they're really bouncing.
function Ball:handle_score_up()
  if self.x >  1 then players[1]:score_up() end
  if self.x < -1 then players[2]:score_up() end
end

--------------------------------------------------------------------------------
-- The Player class.
--------------------------------------------------------------------------------

local Player = {w = 0.05, h = 0.4}

function Player:new(x)
  local p = {x = x, y = 0, score = 0, dy = 0, ddy = 0}
  return setmetatable(p, {__index = self})
end

function Player:draw()
  local w, h = self.w, self.h
  draw.rect_w_mid_pt(self.x, self.y, w, h)

  local score_str = tostring(self.score)
  local align = sign(self.x) == 1 and 'right' or 'left'

  local sgn = sign(self.x)
  local str_x = 0.98 * sgn
  local x_align = (sgn + 1) / 2  -- Map to 0 or 1.
  draw_boxy_str(score_str,       -- str
                str_x, -0.9,     -- x, y
                x_align, 0.0,    -- x_align, y_align
                draw.gray)       -- color
end

function Player:stop_at(y)
  self.y   = y
  self.dy  = 0
  self.ddy = 0
end

function Player:handle_if_hit(ball)


  assert(ball.old_x)
  assert(ball.old_y)

  -- We only need to check for collisions with incoming balls.
  if sign(self.x) ~= sign(ball.dx) then return end

  local half_w, half_h = (self.w + ball.w) / 2, (self.h + ball.h) / 2
  local box = {mid_x = self.x, mid_y = self.y,
               half_w = half_w, half_h = half_h}
  local ball_line = {x1 = ball.old_x, y1 = ball.old_y,
                     x2 = ball.x,     y2 = ball.y}

  --print(string.format('box: mid=(%g, %g) half_size=(%g, %g)', box.mid_x, box.mid_y, box.half_w, box.half_h))
  --print(string.format('line: (%g, %g) -> (%g, %g)', ball_line.x1, ball_line.y1, ball_line.x2, ball_line.y2))

  if not hit_test.box_and_line(box, ball_line) then return end

  -- Avoid double bounces; a high-speed ball can go from one side to the other
  -- in a single dx, which may trigger both bounce code paths.
  if ball.did_bounce then return end
  
  -- hit_pt is in the range [-1, 1]
  local hit_pt = (ball.y - self.y) / ((self.h + ball.h) / 2)
  local bounce_pt = self.x - sign(self.x) * (self.w + ball.w) / 2

  -- Check for edge hits; this is when the ball hits the smaller player edge.
  local ball_x = (ball.old_x + ball.x) / 2
  local ball_y = (ball.old_y + ball.y) / 2
  local x_off = math.abs(ball_x - self.x) / half_w
  local y_off = math.abs(ball_y - self.y) / half_h

  local is_edge_hit = y_off > x_off

  if is_edge_hit then
    hit_pt = sign(hit_pt) * 1.3
    bounce_pt = ball.x
  end

  ball:bounce(hit_pt, bounce_pt, is_edge_hit)
end

function Player:update(dt, ball)
  -- Movement.
  self.y  = self.y  + self.dy  * dt + (self.ddy / 2) * dt ^ 2
  self.dy = self.dy + self.ddy * dt

  local d = self.h / 2 + draw.border_size
  local min, max = -1 + d, 1 - d

  if self.y < min then self:stop_at(min) end
  if self.y > max then self:stop_at(max) end

  self:handle_if_hit(ball)
end

function Player:score_up()
  sounds.point:play()
  self.score = self.score + 1
  ball = Ball:new()
end


-- Love-based functions.

function love.load()
  ball    = Ball:new()
  players = {Player:new(-0.8), Player:new(0.8)}

  local sound_names = {'ball_hit', 'ball_edge_hit', 'point'}

  for _, name in pairs(sound_names) do
    local filename = 'audio/' .. name .. '.wav'
    sounds[name] = love.audio.newSource(filename, 'static')
  end
end

function love.update(dt)
  -- Support debug slow-down.
  dbg_frame_offset = (dbg_frame_offset + 1) % dbg_cycles_per_frame
  if dbg_frame_offset ~= 0 then return end

  -- Move the ball.
  ball:update(dt)

  -- Move the players. This also handles ball collisions.
  for _, p in pairs(players) do
    p:update(dt, ball)
  end

  -- Handle any scoring that may have occurred.
  ball:handle_score_up()
end

function love.draw()
  draw.borders()
  
  for _, p in pairs(players) do
    p:draw()
  end

  draw.center_line()

  -- Draw the ball.
  -- TODO Move this into the Ball class.
  draw.rect_w_mid_pt(ball.x, ball.y, ball.w, ball.h, draw.cyan)
end

-- This is the player movement speed.
local player_ddy = 16
local player_dy  = 2.5

function love.keypressed(key, isrepeat)
  -- We don't care about auto-repeat key siganls.
  if isrepeat then return end

  -- The controls are: [QA for player 1] [PL for player 2].
  local actions = {
    q = {p = players[1], sign =  1},
    a = {p = players[1], sign = -1},
    p = {p = players[2], sign =  1},
    l = {p = players[2], sign = -1}
  }
  actions.s = actions.a

  local action = actions[key]
  if not action then return end

  local pl = action.p
  pl.ddy = action.sign * player_ddy
  pl.dy  = action.sign * player_dy
end

function love.keyreleased(key)
  local actions = {
    q = {p = players[1], sign =  1},
    a = {p = players[1], sign = -1},
    p = {p = players[2], sign =  1},
    l = {p = players[2], sign = -1}
  }
  actions.s = actions.a

  local action = actions[key]
  if not action then return end

  -- Ignore key releases that are not active, such as the player pressing
  -- down on Q, down on A, then releasing Q. A is still active.
  local pl = action.p
  if sign(pl.ddy) ~= action.sign then return end

  pl:stop_at(pl.y)
end
