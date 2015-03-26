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
-- We start negative since the metronome ticks before the draw function is
-- called.
local num_beats   = -0.5
local num_eighths = -1

-- This is based 144 quarters per minute (so it's 60/288).
local sec_per_eighth = 0.2083333

local num_rows = 10

local melody_eighths = {
  -- Measure 1.
  6, 7,
  -- Measure 2.
  8, 10, 11, 12, 14, 15,
  -- Measure 3.
  16, 18, 20,
  -- Measure 5.
  38, 39,
  -- Measure 6.
  40, 42, 43, 44, 46,
  -- Measure 7.
  48,
  -- Measure 9.
  70, 71,
  -- Measure 10.
  72, 74, 75, 76, 78,
  -- Measure 11.
  80,
  -- Measure 13.
  102, 103,
  -- Measure 14.
  104, 106, 107, 108, 110, 111,
  -- Measure 15.
  112, 114, 116,
  -- Measure 17.
  134, 135,
  -- Measure 18.
  136, 138, 139, 140, 142, 143,
  -- Measure 19.
  144, 146, 148,
  -- Measure 21.
  166, 167,
  -- Measure 22.
  168, 170, 171, 172, 174,
  -- Measure 23.
  176}


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function metronome_tick()
  num_eighths = num_eighths + 1
  num_beats   = num_beats   + 0.5

  if num_eighths == 0 then
    sounds.beatz01:play()
  end

  --[[ This may be useful for debugging.
  if num_beats == math.floor(num_beats) then
    print('num_beats =', num_beats)
  end
  --]]

  -- We want to start fading rows after 4 beats = start of 2nd measure.
  local row = (num_beats) / 4
  local fade_time = 5.0  -- Normally 5.0; change to help debug.
  if row == math.floor(row) then
    if 1 <= row and row <= (num_rows / 2) then
      anim.change_to('row_levels.' .. row, 0, {duration = fade_time})
    end
  end
end

local grid_map

local function setup_grid_map_of_len(len)
  -- This is a linear-time Fisher-Yates shuffle.
  -- I find this to be less confusing than the Kansas City shuffle.
  grid_map = {}
  for i = 1, len do
    grid_map[i] = i
  end
  for i = 1, len do
    local j = math.random(i, len)
    grid_map[i], grid_map[j] = grid_map[j], grid_map[i]
  end
end

local function gaarlicbread_color(let, num_let, grid, num_grid)
  local beats_of_let = {0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2}
  local beats_this_let = beats_of_let[let]
  if beats_this_let <= math.floor(num_beats) then
    return draw.black
  else
    return draw.white
  end
end

local function title_color(let, num_let, grid, num_grid)
  -- Apply a random map to the grid index.
  if grid_map == nil then setup_grid_map_of_len(num_grid) end
  grid = grid_map[grid]

  local index = math.ceil(grid * #melody_eighths / num_grid)
  local tick_of_grid = melody_eighths[index]
  if tick_of_grid <= num_eighths then
    return draw.cyan
  end
  return draw.white
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
  if num_beats < 3 then presents_color = draw.white end
  font.draw_str('presents',     0, -0.2, 0.5, 1, presents_color)

  -- Draw the title.
  local opts = {block_size = 0.04, grid_size = 0.033}
  font.draw_str('bounce-beatz', 0, 0, 0.5, 0.5, title_color, opts)
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

events.add_repeating(sec_per_eighth, metronome_tick)

anim.row_levels = {}
for i = 1, (num_rows / 2) do
  anim.row_levels[i] = 255
end

--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return title
