--[[ bounce-beatz/src/vsbeatz.lua

Main interactions for the 1p vs beatz mode.

--]]

require 'strict'  -- Enforce careful global variable usage.

local vsbeatz = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local Ball     = require 'ball'
local beatz    = require 'beatz.beatz'
local draw     = require 'draw'
local Player   = require 'player'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- We use a coordinate system where (0, 0) is the middle of the screen, (-1, -1)
-- is the lower-left corner, and (1, 1) is the upper-right corner.

-- These will be set up in the initialization below.
local ball
local players

-- These determine the player movement speed.
local player_ddy = 30   -- Previously 26.
local player_dy  = 0.5  -- Previously 1.5.

-- This is set from vsbeatz.take_over.
local mode


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
end

local function start_smaller_drawing()
  local win_w, win_h = love.graphics.getDimensions()
  local h_scale = 0.9
  love.graphics.push()
  love.graphics.scale(1.0, h_scale)
  love.graphics.translate(0, win_h / 2 * (1 / h_scale - 1))
end

local function end_smaller_drawing()
  love.graphics.pop()
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function vsbeatz.update(dt)
  -- Move the ball.
  ball:update(dt)

  -- Move the players. This also handles ball collisions.
  for _, p in pairs(players) do
    p:update(dt, ball)
  end

  -- Handle any scoring that may have occurred.
  ball:handle_score_up(players)
end
 
function vsbeatz.draw()

  -- TEMP This is to help clearly see the extents of the window while
  --      developing this mode.
  local win_w, win_h = love.graphics.getDimensions()
  love.graphics.setColor({255, 0, 0})
  love.graphics.rectangle('fill', 0, 0, win_w, win_h)

  start_smaller_drawing()
  draw.borders()
  for _, p in pairs(players) do
    p:draw()
  end
  ball:draw()
  end_smaller_drawing()
end

function vsbeatz.keypressed(key, isrepeat)
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

function vsbeatz.keyreleased(key)
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

function note_callback(time, beat, note)
  print(string.format('note_callback(%g, %g, %s)', time, beat, note))
  return true
end

function vsbeatz.did_get_control()
  -- TEMP stuff for testing
  --beatz.set_note_callback(note_callback)
  --beatz.play('beatz/b.beatz')
end

-- TODO remove; and the mode variable
function vsbeatz.take_over(mode_name)
  mode = mode_name
  love.give_control_to(vsbeatz)
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

ball    = Ball:new({is_1p = true})
players = {Player:new(-0.8), Player:new(1.0, 2.0)}

for i = 1, 2 do
  players[i].do_draw_score = false
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return vsbeatz
