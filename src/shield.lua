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

function Shield:new(x)
  local s = {x = x}
  return setmetatable(s, {__index = self})
end

function Shield:draw()
  love.graphics.setColor({0, 200, 230})
  draw.line(self.x, -1, self.x, 1)
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Shield
