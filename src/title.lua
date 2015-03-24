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
local font     = require 'font'
local sounds   = require 'sounds'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

-- TEMP to help debug the color callback in the font module
local function gaarlicbread_color(let, num_let, grid, num_grid)
  local colors = {draw.black, draw.cyan, draw.gray, draw.green, draw.yellow}
  local c = colors[grid % (#colors) + 1]

  return c
end

--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function title.update(dt)
end
 
function title.draw()
  draw.rect_w_mid_pt(0, 0, 2, 2, draw.white)

  font.draw_str('gaarlicbread', 0,  0.2, 0.5, 0, gaarlicbread_color)
  font.draw_str('presents',     0, -0.2, 0.5, 0, draw.gray)
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

sounds.beatz01:play()


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return title
