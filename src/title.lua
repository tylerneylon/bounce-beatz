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
--[[ Uncomment this line for a sped up intro (music is the same speed).
sec_per_eighth = 0.02
--]]

local menu_choice = 1  -- Which option is currently selected.
local menu_lines  = {'1p vs', '2p vs'}

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
      if row == 1 then
        anim.change_to('title_min', 80, {duration = 20.0})
      end
    end
  end
end

-- Variables for use in the title coloring.
local grid_map
local grid_colors

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

local function color_clamp(val)
  if val <   0 then return   0 end
  if val > 255 then return 255 end
  return val
end

local function setup_grid_colors(len)
  grid_colors = {}
  local base_color = {0, 200, 230}
  local max_offset = 90
  for i = 1, len do
    local c = {}
    for j = 1, 3 do
      c[j] = color_clamp(base_color[j] + math.random(-max_offset, max_offset))
    end
    grid_colors[i] = c
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

local function max(...)
  local vals = {...}
  local m = vals[1]
  for i = 2, #vals do
    if vals[i] > m then m = vals[i] end
  end
  return m
end

local function title_color(let, num_let, grid, num_grid)
  -- Apply a random map to the grid index.
  if grid_map == nil then setup_grid_map_of_len(num_grid) end
  grid = grid_map[grid]

  if grid_colors == nil then setup_grid_colors(num_grid) end

  local index = math.ceil(grid * #melody_eighths / num_grid)
  local tick_of_grid = melody_eighths[index]
  if tick_of_grid <= num_eighths then
    return grid_colors[grid]
  end
  local level1 = anim.row_levels[1]
  local level2 = anim.title_min
  local level = max(level1, level2)
  return {level, level, level}
end

local abs = math.abs -- Conveniently shorter name.

local function draw_menu()
  local y_off = -0.6  -- The y offset of the menu's center.

  -- Determine the color.
  local level = max(anim.row_levels[4], 100)
  local color = {level, level, level}

  -- Draw the surrounding rectangle.
  local border_size = 0.02
  local border_w, border_h = 1, 0.4 - 2 * border_size
  local sx, sy = 1, 0
  for i = 1, 4 do
    local mid_x, mid_y = sx * border_w / 2, y_off + sy * border_h / 2
    sx, sy = -sy, sx
    local w, h = abs(sx) * border_w, abs(sy) * border_h
          w, h = w + border_size,    h + border_size
    draw.rect_w_mid_pt(mid_x, mid_y, w, h, color)
  end

  -- Draw the options.
  local block_size = 0.02
  local opts = {block_size = block_size}
  local line_height = 5 * block_size
  local leading = line_height + 2 * block_size
  local total_height = line_height * #menu_lines + 2 * block_size
  -- Start y at the middle of the top-most line.
  local top_y = y_off + (total_height - line_height) / 2
  local y = top_y
  for i = 1, #menu_lines do
    local x_align, y_align = 0.5, 0.5  -- We pass in the center/middle pt.
    font.draw_str(menu_lines[i], 0, y, x_align, y_align, color, opts)
    y = y - leading
  end

  -- Show which option is currently selected.
  y = top_y - (menu_choice - 1) * leading
  font.draw_str('>', -border_w / 2, y, 0, 0.5, color, opts)
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

  draw_menu()
end

function title.keypressed(key, isrepeat)

  --[[ TODO
  --   Make an early keypress skip the intro animation; the bad thing
  --   would be to have the menu working without it being visible yet.
  --   Which is what we currently have.
  --]]

  if key == 'down' and menu_choice < #menu_lines then
    menu_choice = menu_choice + 1
  end

  if key == 'up' and menu_choice > 1 then
    menu_choice = menu_choice - 1
  end

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

anim.title_min = 20


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return title
