--[[ bounce-beatz/src/battle.lua

Main interactions for the battle mode.

--]]

require 'strict'  -- Enforce careful global variable usage.

local battle = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local anim     = require 'anim'
local audio    = require 'audio'
local Ball     = require 'ball'
local dbg      = require 'dbg'
local draw     = require 'draw'
local events   = require 'events'
local msg      = require 'msg'
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

-- This is set from battle.take_over.
local mode

local winner
local clock


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function sign(x)
  if x > 0 then return 1 end
  return -1
end

local function pr(...)
  print(string.format(...))
end

local function handle_victory()
  anim.player_exploding_perc = 0
  local opts = {duration = 5.0, go_past_end = true}
  anim.change_to('player_exploding_perc', 1.0, opts)
  players[3 - winner].pl_mode = '1p_pl'  -- Allow the loser to explode.
  audio.death:play()

  events.add(1.0, function () audio.applause:play() end)
end

local function start_new_game()
  anim.player_exploding_perc = 0
  -- Cancel any ongoing animation of this value.
  anim.change_to('player_exploding_perc', 0, {duration = 0})

  ball    = Ball:new()
  players = {Player:new(-0.8), Player:new(0.8)}
  winner  = nil
  clock   = 0
end

local function draw_tutorial()
  pr('draw tutorial')
  msg.draw_key(-0.2,  0.2, 'q')
  msg.draw_key(-0.2, -0.2, 'q')
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function battle.update(dt)
  clock = clock + dt

  -- There's no more control after someone wins.
  if winner ~= nil then return end

  -- Move the ball.
  ball:update(dt)

  -- Move the players. This also handles ball collisions.
  for _, p in pairs(players) do
    p:update(dt, ball)
  end

  -- Handle any scoring that may have occurred.
  ball:handle_missed_ball(players)

  -- Check for the victory condition.
  for pl_ind, pl in pairs(players) do
    if pl.score >= dbg.pts_to_win then
      winner = pl_ind
      handle_victory()
    end
  end
end
 
function battle.draw()
  draw.borders()
  draw.center_line()

  draw_tutorial()
  
  for _, p in pairs(players) do
    p:draw()
  end

  if winner == nil then
    ball:draw()
  else
    local text = string.format('player %d wins', winner)
    msg.draw(text)
    msg.draw_at_bottom('press r to play again')
  end
end

function battle.keypressed(key, isrepeat)
  -- We don't care about auto-repeat key siganls.
  if isrepeat then return end

  if winner ~= nil and key == 'r' then
    start_new_game()
  end

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

function battle.did_get_control()
  audio.vs_bkg:setLooping(true)
  audio.vs_bkg:play()
end

function battle.take_over(mode_name)
  mode = mode_name
  love.give_control_to(battle)
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

ball    = Ball:new()
players = {Player:new(-0.8), Player:new(0.8)}
winner  = nil


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return battle
