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

function Bar:new(hit_x, ball_dx_at_hit)
  local b = {}
  b.x = hit_x + self.w / 2 * sign(ball_dx_at_hit)
  print('Set b.x to ', b.x) -- TEMP
  return setmetatable(b, {__index = self})
end

function Bar:update(ball)
end

function Bar:draw()

  --pr('From Bar:draw, self.x = %g', self.x)

  love.graphics.setColor(draw.white)
  draw.rect_w_mid_pt(self.x, 0,  -- x, y
                     self.w, 2)  -- w, h
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Bar
