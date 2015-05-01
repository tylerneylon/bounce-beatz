--[[ bounce-beatz/src/shield.lua

A class to encapsulate shield behavior.

Import this as capital Shield, since it's a type:

local Shield = require 'shield'

--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local anim     = require 'anim'
local audio    = require 'audio'
local draw     = require 'draw'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- Determine the granularity of the heart sprites.
local grid_cells_w, grid_cells_h = 12, 12

-- These are random directions for the blocky pixels used to draw hearts.
-- The dirs are used to animate hearts as they disappear, and are set during
-- initialization.
local rand_dirs = {}

--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
end

local function norm(pt)
  return math.sqrt(pt[1] ^ 2 + pt[2] ^ 2)
end

local function dist(pt1, pt2)
  return norm({pt1[1] - pt2[1], pt1[2] - pt2[2]})
end

local function pr(...)
  print(string.format(...))
end

-- The last paramater, the "bye-bye percentage" is used to draw hearts that are
-- being animated as going away.
local function draw_heart(grid_x, grid_y, bye_perc)
  -- The w/h ratio of 3/5 looks good.
  local grid_w, grid_h =  0.09,  0.15
  local cell_w, cell_h = grid_w / grid_cells_w, grid_h / grid_cells_h

  bye_perc = bye_perc or 0
  local col_level = 255 * (1 - bye_perc)
  local color = {col_level, col_level, col_level}


  -- Calculate the positional parameters for the triangle and circles.
  local floor = math.floor
  local tri_top = floor(grid_cells_h * 0.6)
  local mid_y = floor(grid_cells_h * 0.5)
  local mid_x1 = floor(grid_cells_w * 0.25)
  local mid_x2 = grid_cells_w - mid_x1
  local circ_r = dist({mid_x1, mid_y}, {0, tri_top})
  
  -- These x, y coords are within the grid itself.
  for x = 1, grid_cells_w do
    for y = 1, grid_cells_h do

      local do_draw = false

      if y <= tri_top then
        -- Draw the triangle.
        local row_width = y / tri_top * grid_cells_w
        local row_margin = floor((grid_cells_w - row_width) / 2)
        if x > row_margin and x < (grid_cells_w - row_margin) then
          do_draw = true
        end
      else
        -- Draw the circles.
        local d1 = dist({x, y}, {mid_x1, mid_y})
        local d2 = dist({x, y}, {mid_x2, mid_y})
        if d1 <= circ_r or d2 <= circ_r then
          do_draw = true
        end
      end

      if do_draw then
        draw.rect(grid_x + (x - 1) * cell_w + rand_dirs[x][y][1] * bye_perc,
                  grid_y + (y - 1) * cell_h + rand_dirs[x][y][2] * bye_perc,
                  cell_w,
                  cell_h,
                  color)
      end
    end
  end
end


--------------------------------------------------------------------------------
-- The Shield class.
--------------------------------------------------------------------------------

local Shield = {}

function Shield:new(player)
  local s = {player = player, num_hearts = 3}
  s.x = player.x - player.w * 0.4
  anim.shield_brightness = 0
  anim.shield_level      = 1
  return setmetatable(s, {__index = self})
end

function Shield:draw()

  local b   = anim.shield_brightness  -- Between 0 and 1.
  local lev = anim.shield_level       -- Between 0 and 1.
  local color = {
      0 * lev * (1 - b) + 255 * b,
    200 * lev * (1 - b) + 255 * b,
    230 * lev * (1 - b) + 255 * b}

  love.graphics.setColor(color)
  draw.line(self.x, -1, self.x, 1)

  -- Draw the hearts.
  local y0 =  -1.1
  local dy =   0.2
  for i = 1, self.num_hearts do
    local y = y0 + i * dy
    draw_heart(-0.95, y)
  end

  if anim.bye_heart_perc and anim.bye_heart_perc < 1.0 then
    local y = y0 + anim.bye_heart_ind * dy
    draw_heart(-0.95, y, anim.bye_heart_perc)
  end

end

-- The purpose of this function is to notice as soon as the ball has no chance
-- of hitting the player, but before the ball is considered off-screen.
function Shield:update(dt, ball)

  if self.num_hearts <= 0 then return 0 end

  local pl = self.player
  if ball.x < pl.x - pl.w / 2 then

    audio.spark:play()

    anim.shield_brightness = 1
    anim.change_to('shield_brightness', 0, {duration = 1.0})

    anim.bye_heart_ind  = self.num_hearts
    anim.bye_heart_perc = 0.0
    anim.change_to('bye_heart_perc', 1.0, {duration = 0.5})

    ball:reflect_bounce(pl:bounce_pt(ball))
    self.num_hearts = self.num_hearts - 1
    print('num_hearts =', self.num_hearts)

    if self.num_hearts == 0 then
      anim.change_to('shield_level', 0, {duration = 1.0})
    end

    return 1  -- 1 = one bounce.
  end
  return 0  -- 0 = no bounces.
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

for x = 1, grid_cells_w do
  rand_dirs[x] = {}
  for y = 1, grid_cells_h do
    rand_dirs[x][y] = {math.random() - 0.5, math.random() - 0.5}
  end
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Shield
