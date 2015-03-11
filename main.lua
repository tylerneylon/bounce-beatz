--[[ pong-love/main.lua

This is the classic game pong.

# Roadmap

Anytime items

[ ] Support overlapping sound effects
[ ] Split into modules (ball, player, draw, font)

Phase I   : Human vs human gameplay (1P battle)

[x] New sound for edge hits
[ ] Spin
[ ] More points for long-lasting balls

Phase I.(half) : title and menu screen

[ ] Add a title screen
[ ] Add a play-mode menu

Phase II  : Human vs computer AI    (2P battle)

Phase III : Levels                  (Beats)

[ ] Add power-ups.

Done!
 * Draw the score in a more classic huge-pixely manner.
 * Improve collision detection so balls can't go
   through players. Note: This isn't perfect but I believe it's robust
   enough that in actual human play the ball won't pass through a player.
   (Because it will never be going fast enough to hit a bug.)

--]]


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local Ball     = require 'ball'
local dbg      = require 'dbg'
local draw     = require 'draw'
local font     = require 'font'
local Player   = require 'player'
local sounds   = require 'sounds'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- We use a coordinate system where (0, 0) is the middle of the screen, (-1, -1)
-- is the lower-left corner, and (1, 1) is the upper-right corner.

-- These will be set up in love.load.
local ball
local players  -- This will be set up in love.load.


--------------------------------------------------------------------------------
-- Supporting functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
end


--------------------------------------------------------------------------------
-- Love-based functions.
--------------------------------------------------------------------------------

function love.load()
  ball    = Ball:new()
  players = {Player:new(-0.8), Player:new(0.8)}
end

function love.update(dt)
  -- Support debug slow-down.
  dbg.frame_offset = (dbg.frame_offset + 1) % dbg.cycles_per_frame
  if dbg.frame_offset ~= 0 then return end

  -- Move the ball.
  ball:update(dt)

  -- Move the players. This also handles ball collisions.
  for _, p in pairs(players) do
    p:update(dt, ball)
  end

  -- Handle any scoring that may have occurred.
  ball:handle_score_up(players)
end

function love.draw()
  draw.borders()
  draw.center_line()
  
  for _, p in pairs(players) do
    p:draw()
  end

  ball:draw()
end

-- This is the player movement speed.
local player_ddy = 16
local player_dy  = 2.5

function love.keypressed(key, isrepeat)
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

function love.keyreleased(key)
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
