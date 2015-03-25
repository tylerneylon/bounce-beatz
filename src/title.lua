--[[ bounce-beatz/src/title.lua

Main interactions for the title/menu screen.

--]]

require 'strict'  -- Enforce careful global variable usage.

local title = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local anim     = require 'anim'
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

local num_rows = 10


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function count_a_beat()
  num_beats = num_beats + 1
  events.add(sec_per_beat, count_a_beat)

  -- We want to start fading rows on beat 5.
  local row = (num_beats) / 4
  if row == math.floor(row) then
    if 1 <= row and row <= (num_rows / 2) then
      anim.change_to('row_levels.' .. row, 0, {duration = 5.0})
    end
  end
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
  -- Draw fading-out rows.
  local row_height = 2 / num_rows
  for i = 1, (num_rows / 2) do
    -- We'll draw so that i = 1 is for the middle two rows.
    local level = math.floor(anim.row_levels[i])
    local c = {level, level, level}
    draw.rect_w_mid_pt(0,  (i - 0.5) * row_height, 2, row_height, c)
    draw.rect_w_mid_pt(0, -(i - 0.5) * row_height, 2, row_height, c)
  end

  -- Draw gaarlicbread presents text.
  font.draw_str('gaarlicbread', 0,  0.2, 0.5, 0, gaarlicbread_color)
  local presents_color = draw.black
  if num_beats < 4 then presents_color = draw.white end
  font.draw_str('presents',     0, -0.2, 0.5, 1, presents_color)

  -- Draw the title.
  font.draw_str('bounce-beatz', 0, 0, 0.5, 0.5, draw.white, 0.04)
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

anim.row_levels = {}
for i = 1, (num_rows / 2) do
  anim.row_levels[i] = 255
end

--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return title
