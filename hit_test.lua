--[[ bounce-beatz/hit_test.lua

Functions to test for collisions.

--]]

local hit_test = {}


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local do_dbg_print = false


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function min(...)
  local t = {...}
  local m = t[1]
  for _, value in pairs(t) do
    if value < m then m = value end
  end
  return m
end

local function max(...)
  local t = {...}
  local m = t[1]
  for _, value in pairs(t) do
    if value > m then m = value end
  end
  return m
end

-- This is an iterator over the line segments bordering a box.
-- box is expected to have keys mid_{x,y} and half_{w,h}.
local function box_borders(box)

  -- This maps zero to a given output; otherwise it's the identity.
  local function s_map(start, zero_repl)
    return (start == 0 and zero_repl or start)
  end

  -- (x_sign, y_sign) is the normal of the border we'll return.
  local x_sign, y_sign = 1, 0
  local num_calls = 0

  return function()

    num_calls = num_calls + 1
    if num_calls == 5 then return nil end

    local b = {}  -- The border.

    local sx, sy = s_map(x_sign, -1), s_map(y_sign, -1)
    b.x1 = box.mid_x + sx * box.half_w
    b.y1 = box.mid_y + sy * box.half_h
    local sx, sy = s_map(x_sign,  1), s_map(y_sign,  1)
    b.x2 = box.mid_x + sx * box.half_w
    b.y2 = box.mid_y + sy * box.half_h

    -- Rotate (x_sign, y_sign).
    x_sign, y_sign = -y_sign, x_sign

    return b
  end
end

local function pr_line(line, prefix)
  prefix = prefix or ''
  if #prefix > 0 then prefix = prefix .. ': ' end
  print(string.format('%s(%g, %g) -> (%g, %g)',
                      prefix,
                      line.x1, line.y1,
                      line.x2, line.y2))
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function hit_test.line_segments(line1, line2)

  -- line1 is (x1, y1) + t * (dx1, dy1)
  local  x1,  y1 = line1.x1,      line1.y1
  local dx1, dy1 = line1.x2 - x1, line1.y2 - y1

  -- line2 is (x2, y2) + t * (dx2, dy2)
  local  x2,  y2 = line2.x1,      line2.y1
  local dx2, dy2 = line2.x2 - x2, line2.y2 - y2

  -- Special handling for parallel lines / points.
  if dx1 * dy2 == dx2 * dy1 then
    local ax, ay = dx1, dy1  -- a = vector in dir of lines
    -- Avoid allowing a to be the zero vector.
    if (ax == 0 and ay == 0) then ax, ay = dx2, dy2 end
    if (ax == 0 and ay == 0) then ax, ay =   1,   0 end
    local bx, by = -ay, ax   -- b = vector orth to a

    if do_dbg_print then
      pr_line(line1, 'line1')
      pr_line(line2, 'line2')
      print('ax =', ax, 'ay =', ay)
    end

    -- If <b, p1> ~= <b, p2>, then they don't meet.
    if bx * x1 + by * y1 ~= bx * x2 + by * y2 then
      return false
    end

    -- Find the extents (from, to) of the lines along vector a.
    local from1 =         ax *  x1 + ay *  y1
    local   to1 = from1 + ax * dx1 + ay * dy1
    local from2 =         ax *  x2 + ay *  y2
    local   to2 = from2 + ax * dx2 + ay * dy2

    if do_dbg_print then
      print('from/to pairs:')
      print(from1, to1, from2, to2)
    end

    return (not (max(from1, to1) < min(from2, to2)) and
            not (max(from2, to2) < min(from1, to1)))
  end

  local t1, t2
  if dx1 == 0 then
    -- If either dx2 or dy1 were 0, then the above if would have handled it.
    t2 = (x1 - x2) / dx2
    t1 = (y2 - y1 + t2 * dy2) / dy1
  else
    -- If w == 0, then the above if would have handled it.
    local w  = dx2 * dy1 / dx1 - dy2
    t2 = (y2 - y1 - (x2 - x1) * dy1 / dx1) / w
    t1 = (x2 - x1 + t2 * dx2) / dx1
  end

  return (0 <= t1 and t1 <= 1 and
          0 <= t2 and t2 <= 1)
end


-- This tests for a collision between an axis-aligned box and a line segment.
-- box is a table with keys mid_x, mid_y, half_w, half_h
-- line_segment is a table with keys x1, y1, x2, y2
function hit_test.box_and_line(box, line_segment)
  -- Check if either endpoint is inside the box.
  if math.abs(line_segment.x1 - box.mid_x) < box.half_w and
     math.abs(line_segment.y1 - box.mid_y) < box.half_h then
    return true
  end

  -- Check if the line intersects any of the border lines.
  for border in box_borders(box) do
    if hit_test.line_segments(line_segment, border) then
      return true
    end
  end
  return false
end

return hit_test
