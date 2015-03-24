--[[ bounce-beatz/src/battle.lua

Main interactions for the battle mode.

--]]

require 'strict'  -- Enforce careful global variable usage.

local battle = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local Ball     = require 'ball'
local draw     = require 'draw'
local Player   = require 'player'
local sounds   = require 'sounds'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- We use a coordinate system where (0, 0) is the middle of the screen, (-1, -1)
-- is the lower-left corner, and (1, 1) is the upper-right corner.

-- These will be set up in the initialization below.
local ball
local players

-- These determine the player movement speed.
local player_ddy = 26
local player_dy  = 1.5


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function battle.update(dt)
  -- Move the ball.
  ball:update(dt)

  -- Move the players. This also handles ball collisions.
  for _, p in pairs(players) do
    p:update(dt, ball)
  end

  -- Handle any scoring that may have occurred.
  ball:handle_score_up(players)
end
 
function battle.draw()
  draw.borders()
  draw.center_line()
  
  for _, p in pairs(players) do
    p:draw()
  end

  ball:draw()
end

function battle.keypressed(key, isrepeat)
  -- We don't care about auto-repeat key siganls.
  if isrepeat then return end

  -- The controls are: [QA for player 1] [PL for player 2].
  local actions = {
    q = {p = players[1], sign =  1},
    a = {p = players[1], sign = -1},
    p = {p = players[2], sign =  1},
    l = {p = players[2], sign = -1}
  }
  actions.s = actions.a

  local action = actions[key]
  if not action then return end

  local pl = action.p
  pl.ddy = action.sign * player_ddy
  pl.dy  = action.sign * player_dy
end

function battle.keyreleased(key)
  local actions = {
    q = {p = players[1], sign =  1},
    a = {p = players[1], sign = -1},
    p = {p = players[2], sign =  1},
    l = {p = players[2], sign = -1}
  }
  actions.s = actions.a

  local action = actions[key]
  if not action then return end

  -- Ignore key releases that are not active, such as the player pressing
  -- down on Q, down on A, then releasing Q. A is still active.
  local pl = action.p
  if sign(pl.ddy) ~= action.sign then return end

  pl:stop_at(pl.y)
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

ball    = Ball:new()
players = {Player:new(-0.8), Player:new(0.8)}


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return battle
