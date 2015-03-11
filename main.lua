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
-- Require modules.
--------------------------------------------------------------------------------

local Ball     = require 'ball'
local dbg      = require 'dbg'
local draw     = require 'draw'
local font     = require 'font'
local hit_test = require 'hit_test'
local sounds   = require 'sounds'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- We use a coordinate system where (0, 0) is the middle of the screen, (-1, -1)
-- is the lower-left corner, and (1, 1) is the upper-right corner.

-- These will be set up in love.load.
local ball
local players  -- This will be set up in love.load.


--------------------------------------------------------------------------------
-- Supporting functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
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
  font.draw_str(score_str,       -- str
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


--------------------------------------------------------------------------------
-- Love-based functions.
--------------------------------------------------------------------------------

function love.load()
  ball    = Ball:new()
  players = {Player:new(-0.8), Player:new(0.8)}
end

function love.update(dt)
  -- Support debug slow-down.
  dbg.frame_offset = (dbg.frame_offset + 1) % dbg.cycles_per_frame
  if dbg.frame_offset ~= 0 then return end

  -- Move the ball.
  ball:update(dt)

  -- Move the players. This also handles ball collisions.
  for _, p in pairs(players) do
    p:update(dt, ball)
  end

  -- Handle any scoring that may have occurred.
  ball:handle_score_up(players)
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
