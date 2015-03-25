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
local events   = require 'events'
local font     = require 'font'
local sounds   = require 'sounds'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- How many beats have passed in the song.
local num_beats = 0

local sec_per_beat = 0.416666666


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function count_a_beat()
  num_beats = num_beats + 1
  events.add(sec_per_beat, count_a_beat)
end

local function gaarlicbread_color(let, num_let, grid, num_grid)
  local beats_of_let = {0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2}
  local beats_this_let = beats_of_let[let]
  if beats_this_let < num_beats then
    return draw.black
  else
    return draw.white
  end
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function title.update(dt)
end
 
function title.draw()
  draw.rect_w_mid_pt(0, 0, 2, 2, draw.white)

  font.draw_str('gaarlicbread', 0,  0.2, 0.5, 0, gaarlicbread_color)

  local presents_color = draw.gray
  if num_beats < 4 then presents_color = draw.white end
  font.draw_str('presents',     0, -0.2, 0.5, 0, presents_color)
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
events.add(sec_per_beat, count_a_beat)


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return title
