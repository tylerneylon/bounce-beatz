--[[ bounce-beatz/src/shield.lua

A class to encapsulate shield behavior.

Import this as capital Shield, since it's a type:

local Shield = require 'shield'

--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'


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

local function draw_heart(grid_x, grid_y)
  -- The w/h ratio of 3/5 looks good.
  local grid_w, grid_h =  0.09,  0.15

  local grid_cells_w, grid_cells_h = 12, 12  -- Num cells.
  local cell_w, cell_h = grid_w / grid_cells_w, grid_h / grid_cells_h

  local floor = math.floor

  -- Calculate the positional parameters for the triangle and circles.
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
        draw.rect(grid_x + (x - 1) * cell_w,
                  grid_y + (y - 1) * cell_h,
                  cell_w,
                  cell_h,
                  draw.white)
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
  return setmetatable(s, {__index = self})
end

function Shield:draw()

  -- If they have no hearts, there's nothing to draw!
  if self.num_hearts <= 0 then return end

  love.graphics.setColor({0, 200, 230})
  draw.line(self.x, -1, self.x, 1)

  -- Draw the hearts.
  local y  =  -0.9
  local dy =   0.2
  for i = 1, self.num_hearts do
    draw_heart(-0.95, y)
    y = y + dy
  end
end

-- The purpose of this function is to notice as soon as the ball as no chance
-- of hitting the player, but before the ball is considered off-screen.
function Shield:update(dt, ball)
  local pl = self.player
  if ball.x < pl.x - pl.w / 2 then
    ball:reflect_bounce(pl:bounce_pt(ball))
    self.num_hearts = self.num_hearts - 1
    print('num_hearts =', self.num_hearts)
    return 1  -- 1 = one bounce.
  end
  return 0  -- 0 = no bounces.
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Shield
