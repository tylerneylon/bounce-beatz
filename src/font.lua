--[[ bounce-beatz/src/font.lua

Data and drawing functions for a ridiculously simple boxy font
designed to be used in bounce-beatz.

This font has a fixed height of 5 units but is
variable width. Many characters will be 3 units in
width.

--]]

require 'strict'  -- Enforce careful global variable usage.


local font = {}


--------------------------------------------------------------------------------
-- Parameters.
--------------------------------------------------------------------------------

-- This size is expressed in the custom coord system of the draw module.
font.block_size = 0.02


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'


--------------------------------------------------------------------------------
-- Font data.
--------------------------------------------------------------------------------

font[0] = {{ 1, 1, 1 },
           { 1, 0, 1 },
           { 1, 0, 1 },
           { 1, 0, 1 },
           { 1, 1, 1 }}

font[1] = {{ 1, 1, 0 },
           { 0, 1, 0 },
           { 0, 1, 0 },
           { 0, 1, 0 },
           { 1, 1, 1 }}

font[2] = {{ 1, 1, 0 },
           { 0, 0, 1 },
           { 0, 1, 0 },
           { 1, 0, 0 },
           { 1, 1, 1 }}

font[3] = {{ 1, 1, 1 },
           { 0, 0, 1 },
           { 0, 1, 1 },
           { 0, 0, 1 },
           { 1, 1, 1 }}

font[4] = {{ 1, 0, 1 },
           { 1, 0, 1 },
           { 1, 1, 1 },
           { 0, 0, 1 },
           { 0, 0, 1 }}

font[5] = {{ 1, 1, 1 },
           { 1, 0, 0 },
           { 1, 1, 0 },
           { 0, 0, 1 },
           { 1, 1, 0 }}

font[6] = {{ 0, 1, 0 },
           { 1, 0, 0 },
           { 1, 1, 0 },
           { 1, 0, 1 },
           { 0, 1, 0 }}

font[7] = {{ 1, 1, 1 },
           { 0, 0, 1 },
           { 0, 0, 1 },
           { 0, 1, 0 },
           { 0, 1, 0 }}

font[8] = {{ 0, 1, 0 },
           { 1, 0, 1 },
           { 0, 1, 0 },
           { 1, 0, 1 },
           { 0, 1, 0 }}

font[9] = {{ 0, 1, 0 },
           { 1, 0, 1 },
           { 0, 1, 1 },
           { 0, 0, 1 },
           { 0, 1, 0 }}

font.a = {{ 0, 1, 0 },
          { 1, 0, 1 },
          { 1, 1, 1 },
          { 1, 0, 1 },
          { 1, 0, 1 }}

font.b = {{ 1, 1, 0 },
          { 1, 0, 1 },
          { 1, 1, 0 },
          { 1, 0, 1 },
          { 1, 1, 0 }}

font.c = {{ 0, 1, 1 },
          { 1, 0, 0 },
          { 1, 0, 0 },
          { 1, 0, 0 },
          { 0, 1, 1 }}

font.d = {{ 1, 1, 0 },
          { 1, 0, 1 },
          { 1, 0, 1 },
          { 1, 0, 1 },
          { 1, 1, 0 }}

font.e = {{ 1, 1, 1 },
          { 1, 0, 0 },
          { 1, 1, 0 },
          { 1, 0, 0 },
          { 1, 1, 1 }}

font.f = {{ 1, 1, 1 },
          { 1, 0, 0 },
          { 1, 1, 0 },
          { 1, 0, 0 },
          { 1, 0, 0 }}

font.g = {{ 0, 1, 1, 0 },
          { 1, 0, 0, 0 },
          { 1, 0, 1, 1 },
          { 1, 0, 0, 1 },
          { 0, 1, 1, 0 }}

font.h = {{ 1, 0, 1 },
          { 1, 0, 1 },
          { 1, 1, 1 },
          { 1, 0, 1 },
          { 1, 0, 1 }}

font.i = {{ 1, 1, 1 },
          { 0, 1, 0 },
          { 0, 1, 0 },
          { 0, 1, 0 },
          { 1, 1, 1 }}

font.j = {{ 1, 1, 1, 1 },
          { 0, 0, 1, 0 },
          { 0, 0, 1, 0 },
          { 1, 0, 1, 0 },
          { 0, 1, 0, 0 }}

font.k = {{ 1, 0, 0, 1 },
          { 1, 0, 1, 0 },
          { 1, 1, 0, 0 },
          { 1, 0, 1, 0 },
          { 1, 0, 0, 1 }}

font.l = {{ 1, 0, 0 },
          { 1, 0, 0 },
          { 1, 0, 0 },
          { 1, 0, 0 },
          { 1, 1, 1 }}

font.m = {{ 1, 0, 0, 0, 1 },
          { 1, 1, 0, 1, 1 },
          { 1, 0, 1, 0, 1 },
          { 1, 0, 0, 0, 1 },
          { 1, 0, 0, 0, 1 }}

font.n = {{ 1, 0, 0, 1 },
          { 1, 1, 0, 1 },
          { 1, 1, 0, 1 },
          { 1, 0, 1, 1 },
          { 1, 0, 0, 1 }}

font.o = {{ 0, 1, 0 },
          { 1, 0, 1 },
          { 1, 0, 1 },
          { 1, 0, 1 },
          { 0, 1, 0 }}

font.p = {{ 1, 1, 0 },
          { 1, 0, 1 },
          { 1, 1, 0 },
          { 1, 0, 0 },
          { 1, 0, 0 }}

font.q = {{ 0, 1, 0 },
          { 1, 0, 1 },
          { 1, 0, 1 },
          { 0, 1, 0 },
          { 0, 0, 1 }}

font.r = {{ 1, 1, 0 },
          { 1, 0, 1 },
          { 1, 1, 0 },
          { 1, 1, 0 },
          { 1, 0, 1 }}

font.s = {{ 0, 1, 1 },
          { 1, 0, 0 },
          { 0, 1, 0 },
          { 0, 0, 1 },
          { 1, 1, 0 }}

font.t = {{ 1, 1, 1 },
          { 0, 1, 0 },
          { 0, 1, 0 },
          { 0, 1, 0 },
          { 0, 1, 0 }}

font.u = {{ 1, 0, 1 },
          { 1, 0, 1 },
          { 1, 0, 1 },
          { 1, 0, 1 },
          { 1, 1, 1 }}

font.v = {{ 1, 0, 1 },
          { 1, 0, 1 },
          { 1, 0, 1 },
          { 0, 1, 0 },
          { 0, 1, 0 }}

font.w = {{ 1, 0, 0, 0, 1 },
          { 1, 0, 0, 0, 1 },
          { 1, 0, 1, 0, 1 },
          { 0, 1, 0, 1, 0 },
          { 0, 1, 0, 1, 0 }}

font.x = {{ 1, 0, 1 },
          { 1, 0, 1 },
          { 0, 1, 0 },
          { 1, 0, 1 },
          { 1, 0, 1 }}

font.y = {{ 1, 0, 1 },
          { 1, 0, 1 },
          { 0, 1, 0 },
          { 0, 1, 0 },
          { 0, 1, 0 }}

font.z = {{ 1, 1, 1 },
          { 0, 0, 1 },
          { 0, 1, 0 },
          { 1, 0, 0 },
          { 1, 1, 1 }}

-- Make digits visible via string keys as well.

for k, v in pairs(font) do
  if type(k) == 'number' then
    font[tostring(k)] = v
  end
end


--------------------------------------------------------------------------------
-- Font-drawing functions.
--------------------------------------------------------------------------------

function font.get_str_size(s)
  local w = 0
  local h = 0
  for i = 1, #s do
    local c = s:sub(i, i)
    local char_data = font[c]
    if char_data == nil then
      print('Warning: no font data for character ' .. c)
    else
      local c_height = #char_data
      if c_height > h then h = c_height end
      local c_width = #char_data[1]
      w = w + c_width
      if i > 1 then w = w + 1 end  -- For the inter-char space.
    end
  end
  return w, h
end

function font.draw_char(c, x, y, color)
  local w, h = font.get_str_size(c)
  local char_data = font[c]
  for row = 1, #char_data do
    for col = 1, #char_data[1] do
      if char_data[row][col] == 1 then
        local this_x = x + (col - 1) * font.block_size
        local this_y = y + (h - row) * font.block_size
        draw.rect(this_x, this_y, font.block_size, font.block_size, color)
      end
    end
  end
end

-- Both x_align and y_align are expected to be either
-- 0, 0.5, or 1 for near-0, centered, or near-1 alignment.
function font.draw_str(s, x, y, x_align, y_align, color)
  local w, h = font.get_str_size(s)
  x = x - w * font.block_size * x_align
  y = y - h * font.block_size * y_align
  for i = 1, #s do
    local c = s:sub(i, i)
    font.draw_char(c, x, y, color)
    x = x + (font.get_str_size(c) + 1) * font.block_size
  end
end


return font
