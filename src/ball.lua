--[[ bounce-beatz/src/ball.lua

A class to encapsulate ball behavior.

Import this as capital Ball, since it's a type:

local Ball = require 'ball'

--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local dbg    = require 'dbg'
local draw   = require 'draw'
local audio  = require 'audio'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local colors = {draw.cyan, draw.green, draw.yellow}

-- These are the number of bounces (aka hits) where a ball's value goes up.
local pt_thresholds = {8, 16}

-- We play these sounds when the ball achieves value 2 or 3.
local value_up_sounds = {false, audio.good1, audio.good2}

local dx_1p = 3.0


--------------------------------------------------------------------------------
-- Supporting functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return  1 end
  if x < 0 then return -1 end
  return 0
end

--------------------------------------------------------------------------------
-- The Ball class.
--------------------------------------------------------------------------------

local Ball = {size = 0.04}

function Ball:new(ball, dx_sign)
  assert(self ~= ball)

  local dx_sign  = math.random(2) * 2 - 3  -- Randomly -1 or +1.
  local dy_sign  = math.random(2) * 2 - 3
  local start_dx = 0.6
  local start_dy = 0.4

  if dbg.is_ball_weird then
    start_dx, start_dy = dbg.start_dx, dbg.start_dy
  end

  ball = ball or {}

  if ball.is_1p then
    dx_sign  = -1
    start_dx = dx_1p
  end

  ball.x,     ball.y     = 0, 0
  ball.old_x, ball.old_y = 0, 0
  ball.dx,    ball.dy    = start_dx * dx_sign, start_dy * dy_sign
  ball.w,     ball.h     = self.size, self.size
  ball.num_hits          = 0
  ball.spin_angle        = 0

  return setmetatable(ball, {__index = self})
end

-- This is a relatively boring version of Ball:bounce that simply bounces off
-- at the same angle in came in at.
function Ball:reflect_bounce(bounce_pt)

  assert(type(bounce_pt) == 'number')

  self.x = bounce_pt - (self.x - bounce_pt)
  self.did_bounce = true
  -- This is expected to only be called in 1p mode, so there's no speedup.
  self.dx = -self.dx
end

-- hit_pt is expected to be in the range [-1, 1], and determines the
-- angle that the ball bounces away at.
-- bounce_pt is the x-coord at which the ball bounces.
function Ball:bounce(hit_pt, bounce_pt, is_edge_hit, spin)

  assert(type(hit_pt) == 'number')
  assert(type(spin)   == 'number')

  -- Update x based on the bounce.
  self.x = bounce_pt - (self.x - bounce_pt)

  -- Determine the theoretical new spin angle.
  -- This is theoretical because we haven't yet considered the old spin.
  local max_angle      =  0.1
  local min_angle      = -max_angle
  local new_spin_angle = -0.02 * spin
  if new_spin_angle > max_angle then new_spin_angle = max_angle end
  if new_spin_angle < min_angle then new_spin_angle = min_angle end
  if is_edge_hit then new_spin_angle = 0 end

  -- Determine how the old and new spin affect the bounce angle.
  local angle_scale = 2  -- Default value for zero spin influence.

  -- Set up spin_badness in the range [0, 1].
  local spin_badness = math.abs(new_spin_angle + self.spin_angle) * 10
  spin_badness = spin_badness * (math.abs(self.spin_angle) / max_angle)
  if spin_badness > 1 then spin_badness = 1 end

  -- We take the sqrt to make slight spin errors more meaningful.
  angle_scale = angle_scale * (1 - math.sqrt(spin_badness))

  -- Effect a slight speed-up with each player bounce.
  local speedup = 1.12
  self.dx = -speedup * self.dx
  self.dy = angle_scale * hit_pt
  local max_dx = 10
  if self.is_1p then max_dx = dx_1p end
  if math.abs(self.dx) > max_dx then
    self.dx = sign(self.dx) * max_dx
  end

  -- If they got the spin right, then the ball has some spin.
  self.spin_angle = (1 - spin_badness) * new_spin_angle

  -- Mark the bounce so it can't happen twice in one update cycle.
  -- This can theoretically be a problem at extremely high speeds.
  self.did_bounce = true

  -- Update num_hits and play a sound if the ball's value went up.
  local old_value = self:value()
  self.num_hits   = self.num_hits + 1
  local new_value = self:value()
  if new_value > old_value then
    value_up_sounds[new_value]:play()
  end

  if not self.is_1p then
    -- Play the hit sound.
    local sound = is_edge_hit and audio.ball_edge_hit or audio.ball_hit
    sound:play()
  end
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
  if self.is_1p then return 1 end
  local value = 1
  for _, threshold in ipairs(pt_thresholds) do
    if self.num_hits >= threshold then value = value + 1 end
  end
  return value
end

function Ball:draw()
  local color = colors[self:value()]
  draw.rotated_rect(self.x, self.y, self.w, self.h, color, self.spin_angle)
end

-- This is outside of Ball:update so that balls can interact with
-- the players (bounce) before we check for a score going up. Fast balls
-- can appear (x-wise) to go through a player when they're really bouncing.
-- The return value is truthy iff a ball was missed.
function Ball:handle_missed_ball(players, shield)

  -- Death is not possible if there's a shield with any hearts left.
  if shield and shield.num_hearts > 0 then return end

  local pl_score_up = false

  if self.x >  1 then pl_score_up = 1 end
  if self.x < -1 then pl_score_up = 2 end

  if pl_score_up then players[pl_score_up]:score_up(self) end

  return pl_score_up
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

if dbg.is_fast_1p_mode then
  dx_1p = dx_1p * 3
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Ball
