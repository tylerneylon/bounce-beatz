--[[ bounce-beatz/src/shield.lua

A class to encapsulate shield behavior.

Import this as capital Shield, since it's a type:

local Shield = require 'shield'

--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'


--------------------------------------------------------------------------------
-- Supporting functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
end


--------------------------------------------------------------------------------
-- The Shield class.
--------------------------------------------------------------------------------

local Shield = {}

function Shield:new(player)
  local s = {player = player, num_hearts = 3}
  s.x = player.x - player.w * 0.4
  return setmetatable(s, {__index = self})
end

function Shield:draw()
  love.graphics.setColor({0, 200, 230})
  draw.line(self.x, -1, self.x, 1)
end

-- The purpose of this function is to notice as soon as the ball as no chance
-- of hitting the player, but before the ball is considered off-screen.
function Shield:update(dt, ball)
  local pl = self.player
  if ball.x < pl.x - pl.w / 2 then
    ball:reflect_bounce(pl:bounce_pt(ball))
    self.num_hearts = self.num_hearts - 1
    print('num_hearts =', self.num_hearts)
    return 1  -- 1 = one bounce.
  end
  return 0  -- 0 = no bounces.
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Shield
