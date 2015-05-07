--[[ bounce-beatz/src/msg.lua

A module to help display text-based overlay boxes.

--]]

require 'strict'  -- Enforce careful global variable usage.

local msg = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'
local font     = require 'font'


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

-- This draws string s centered, taking up width w, and on the line below the
-- line whose bottom is y0. The return value is the y value of the new line's
-- baseline. Also returns the size of the top margin.
local function draw_str_below_y(s, w, y0, do_draw)
  if do_draw == nil then do_draw = true end
  local s_w, s_h   = font.get_str_size(s)
  local block_size = w / s_w
  local opts       = {block_size = block_size}
  local top_margin = s_h * block_size * 0.3
  local y0 =    y0 - s_h * block_size * 1.3
  if do_draw then
    font.draw_str(s,
                  0, y0,   -- anchor point
                  0.5, 0,  -- x-centered, y-bottom
                  draw.white, opts)
  end
  return y0, top_margin
end

-- This expects the input string to end in a newline; it splits s at newlines
-- and draws them similarly to draw_str_below_y.
local function draw_multiline_str_below_y(multi_s, w, y0, do_draw)
  if do_draw == nil then do_draw = true end
  local top_margin = nil
  for s in multi_s:gmatch('(.-)\n') do
    local margin
    y0, margin = draw_str_below_y(s, w, y0, do_draw)
    if top_margin == nil then top_margin = margin end
  end
  return y0, top_margin
end

-- Draws a black background with an outside-the-box white border.
-- (x, y) is the center point; w, h give the size.
local function draw_frame(x, y, w, h, border_size)
  draw.rect_w_mid_pt(x, y, w, h, draw.black)
  local bord_w, bord_h = w + border_size, h + border_size
  local corner = {(w + border_size) / 2, (h + border_size) / 2}
  local dir = {1, 0}
  for i = 1, 4 do
    draw.rect_w_mid_pt(x + dir[1] * corner[1],
                       y + dir[2] * corner[2], 
                       math.abs(dir[2]) * bord_w + border_size,
                       math.abs(dir[1]) * bord_h + border_size,
                       draw.white)
    dir[1], dir[2] = -dir[2], dir[1]
  end
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function msg.draw(text)

  local _, num_newlines = text:gsub('\n', '')
  if num_newlines == 0 then
    text = text .. '\n'
  end

  local w, h        = 1.3, 0.7
  local margin      = 0.1
  local border_size = 0.02  -- The border is outside the box.

  -- Modify the height and find the text_y to nicely fit the text.
  local text_w = w - 2 * margin
  local text_h, text_margin = draw_multiline_str_below_y(text, text_w, 0, false)
  text_h = math.abs(text_h)
  h = text_h + text_margin  -- text_h already accounts for the top margin.
  -- In calculating text_y, we want it to be text_h / 2 - text_margin.
  local text_y = h / 2

  -- Draw a black background with a white border.
  draw_frame(0, 0, w, h, border_size)

  -- Draw the text.
  draw_multiline_str_below_y(text, text_w, text_y)
end

function msg.draw_at_bottom(text)
  local w           = 0.8
  local margin      = 0.1
  local border_size = 0.01

  local text_w = w - 2 * margin
  local text_h, text_margin = draw_str_below_y(text, text_w, 0, false)
  text_h = math.abs(text_h)
  local h = text_h + text_margin  -- text_h already accounts for the top margin.

  local text_y = -1 + text_h

  -- The + 0.01 is to avoid the bottom of the frame from appearing at all.
  draw_frame(0, h / 2 - 1, w, h + 0.01, border_size)

  draw_str_below_y(text, text_w, text_y)
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return msg

