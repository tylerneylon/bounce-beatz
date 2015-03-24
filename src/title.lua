--[[ bounce-beatz/src/title.lua

Main interactions for the title/menu screen.

--]]

require 'strict'  -- Enforce careful global variable usage.

local title = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local battle   = require 'battle'
local draw     = require 'draw'
local sounds   = require 'sounds'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function title.update(dt)
end
 
function title.draw()
  local color = {128, 128, 0}
  draw.rect_w_mid_pt(0, 0, 2, 2, color)
end

function title.keypressed(key, isrepeat)
  if key == 'return' then
    love.give_control_to(battle)
  end
end

function title.keyreleased(key)
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return title
