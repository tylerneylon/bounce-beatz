--[[ bounce-beatz/src/bar.lua

A class to capture the behavior of bounce bars.

Import this as capital Bar, since it's a type:

local Bar = require 'bar'

--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw = require 'draw'


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


--------------------------------------------------------------------------------
-- The Bar class.
--------------------------------------------------------------------------------

local Bar = {w = 0.05}

-- The input is the x-coord of the ball's center when it hits this bar.
-- The dx is the ball's x-velocity just *before* it hits.
function Bar:new(b, hit_x, ball_dx_at_hit, ball)
  assert(b and b.do_draw ~= nil and b.beat)

  b.x = hit_x + (self.w + ball.w) / 2 * sign(ball_dx_at_hit)

  print('Set b.x to ', b.x) -- TEMP
  return setmetatable(b, {__index = self})
end

function Bar:update(ball, beat)

  -- Avoid bounces that are definitely too early for this bar's note.
  if self.beat - beat > 0.1 then return end

  local num_hits = 0

  local w = (self.w + ball.w) / 2
  local low_x = self.x - w
  local  hi_x = self.x + w

  if (low_x <= ball.x and ball.x <= hi_x)    or
     (ball.old_x < low_x and ball.x >  hi_x) or
     (ball.old_x >  hi_x and ball.x < low_x) then

    local bounce_pt = self.x - w * sign(ball.dx)
    ball:bounce(0, bounce_pt, 0, 0)
    return 1  -- 1 for 1 bounce.
  end
  return 0  -- 0 for no bounces.
end

function Bar:draw()

  if not self.do_draw then return end

  --pr('From Bar:draw, self.x = %g', self.x)

  love.graphics.setColor(draw.magenta)  -- TEMP I hope.
  draw.rect_w_mid_pt(self.x, 0,  -- x, y
                     self.w, 2)  -- w, h
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Bar
