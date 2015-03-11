--[[ pong-love/ball.lua

A class to encapsulate ball behavior.

Import this as capital Ball, since it's a type:

local Ball = require 'ball'

--]]


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local dbg    = require 'dbg'
local draw   = require 'draw'
local sounds = require 'sounds'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local colors = {draw.cyan, draw.green, draw.yellow}

-- These are the number of bounces (aka hits) where a ball's value goes up.
local pt_thresholds = {7, 14}


--------------------------------------------------------------------------------
-- The Ball class.
--------------------------------------------------------------------------------

local Ball = {size = 0.04}

function Ball:new(ball)
  assert(self ~= ball)

  local dx_sign  = math.random(2) * 2 - 3
  local dy_sign  = math.random(2) * 2 - 3
  local start_dx = 0.6
  local start_dy = 0.4

  if dbg.is_ball_weird then
    start_dx, start_dy = dbg.start_dx, dbg.start_dy
  end

  ball = ball or {}

  ball.x,     ball.y     = 0, 0
  ball.old_x, ball.old_y = 0, 0
  ball.dx,    ball.dy    = start_dx * dx_sign, start_dy * dy_sign
  ball.w,     ball.h     = self.size, self.size
  ball.num_hits          = 0

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
  self.num_hits   = self.num_hits + 1

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

function Ball:value()
  local value = 1
  for _, threshold in ipairs(pt_thresholds) do
    if self.num_hits >= threshold then value = value + 1 end
  end
  return value
end

function Ball:draw()
  local color = colors[self:value()]
  draw.rect_w_mid_pt(self.x, self.y, self.w, self.h, color)
end

-- This is outside of Ball:update so that balls can interact with
-- the players (bounce) before we check for a score going up. Fast balls
-- can appear (x-wise) to go through a player when they're really bouncing.
function Ball:handle_score_up(players)
  if self.x >  1 then players[1]:score_up(self) end
  if self.x < -1 then players[2]:score_up(self) end
end


return Ball