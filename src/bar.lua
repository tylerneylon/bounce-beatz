--[[ bounce-beatz/src/bar.lua

A class to capture the behavior of bounce bars.

Import this as capital Bar, since it's a type:

local Bar = require 'bar'

--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local dbg  = require 'dbg'
local draw = require 'draw'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local fade_beats = 0.5
local bg_level   = 50


--------------------------------------------------------------------------------
-- Debugging functions.
--------------------------------------------------------------------------------

local function pr(...)
  print(string.format(...))
end


--------------------------------------------------------------------------------
-- Supporting functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
end

local function clamp01(x)
  if x < 0 then return 0 end
  if x > 1 then return 1 end
  return x
end


--------------------------------------------------------------------------------
-- The Bar class.
--------------------------------------------------------------------------------

local Bar = {w = 0.05}

-- The input is the x-coord of the ball's center when it hits this bar.
-- The dx is the ball's x-velocity just *before* it hits.
function Bar:new(b, hit_x, ball_dx_at_hit, ball)
  assert(b and b.do_draw ~= nil and b.beat)

  b.x = hit_x + (self.w + ball.w) / 2 * sign(ball_dx_at_hit)

  --print('Set b.x to ', b.x) -- TEMP
  return setmetatable(b, {__index = self})
end

function Bar:update(ball, bounce_num)

  -- Avoid all bounces except for the properly-indexed one for this bar's note.
  if bounce_num ~= self.bounce_num then return 0 end

  local num_hits = 0

  local w = (self.w + ball.w) / 2
  local low_x = self.x - w
  local  hi_x = self.x + w

  if (low_x <= ball.x and ball.x <= hi_x)    or
     (ball.old_x < low_x and ball.x >  hi_x) or
     (ball.old_x >  hi_x and ball.x < low_x) then

    local bounce_pt = self.x - w * sign(ball.dx)
    -- TEMP
    --print('Bar-triggered bounce!')
    ball:reflect_bounce(bounce_pt)
    return 1  -- 1 for 1 bounce.
  end
  return 0  -- 0 for no bounces.
end

function Bar:bg_level(beat)
  if beat < self.beat then
    local start_beat = self.beat - dbg.bars_appear_at_beat_dist
    local beats_in = beat - start_beat
    if beats_in < fade_beats then
      return bg_level * clamp01(beats_in / fade_beats)
    else
      return bg_level
    end
  else
    local end_beat = self.beat + dbg.bars_appear_at_beat_dist
    local beats_from_end = end_beat - beat
    if beats_from_end < fade_beats then
      return bg_level * clamp01(beats_from_end / fade_beats)
    else
      return bg_level
    end
  end
end

-- Returns the position and width of a horizontal line drawn at the given
-- beat_dist with perspective.
function Bar:pos_of_beat_dist(beat_dist, top_y)
  if beat_dist < 0 then beat_dist = 0 end
  local y_perc = beat_dist / (beat_dist + 1)
  local x = (1 - y_perc) * self.x
  local y = top_y + y_perc * (1.1 - top_y)
  local w = (1 - y_perc) * self.w
  return x, y, w
end

function Bar:draw_outer_parts(beat, top_y)
  if beat < self.beat then
    local beat_dist = self.beat - beat

    local b = dbg.beats_early_bar_visible

    local x_hi, y_hi, w_hi = self:pos_of_beat_dist(beat_dist,     top_y)
    local x_lo, y_lo, w_lo = self:pos_of_beat_dist(beat_dist - b, top_y)

    draw.polygon(x_lo - w_lo / 2, y_lo,
                 x_hi - w_hi / 2, y_hi,
                 x_hi + w_hi / 2, y_hi,
                 x_lo + w_lo / 2, y_lo)

  end
end

function Bar:draw_main_part(beat, fg_or_bg)

  if not self.do_draw then return end

  local do_draw = true

  local level
  local beat_delta = self.beat - beat
  if beat_delta >= 0 and beat_delta < dbg.beats_early_bar_visible then
    level = 255
    do_draw = (fg_or_bg == 'fg')
  else
    level = self:bg_level(beat)
    do_draw = (fg_or_bg == 'bg')
  end
  local color = {level, level, level}

  if do_draw then
    draw.rect_w_mid_pt(self.x, 0,  -- x, y
                       self.w, 2,  -- w, h
                       color)
  end
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Bar
