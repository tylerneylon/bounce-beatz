--[[ bounce-beatz/src/vsbeatz.lua

Main interactions for the 1p vs beatz mode.

--]]

require 'strict'  -- Enforce careful global variable usage.

local vsbeatz = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local Ball     = require 'ball'
local Bar      = require 'bar'
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

local track
local next_bar_ind = 1

-- This is a map: <beat> -> <bar>, where <beat> is the beat number on which the
-- corresponding note is expected to play.
local bars = {}


--------------------------------------------------------------------------------
-- Debugging functions.
--------------------------------------------------------------------------------

local function pr(...)
  print(string.format(...))
end


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

local function mod_w_bounce(x)
  local val
  if -1 <= x and x <= 1 then
    val = x
    pr('mod_w_bounce(%g) = %g', x, val)
    return val
  end
  if x < 0 then
    --return 1 - mod_w_bounce(1 - x)
    val = -mod_w_bounce(-x)
    pr('mod_w_bounce(%g) = %g', x, val)
    return val
  end
  local num_bounces = math.floor((x - 1) / 2) + 1
  if num_bounces % 2 == 0 then
    --return (x - 1) % 2 - 1
    val = (x - 1) % 2 - 1
  else
    --return 1 - (x - 1) % 2
    val = 1 - (x - 1) % 2
  end
  pr('mod_w_bounce(%g) = %g', x, val)
  return val
end

local function update_bounce_bars()
  if not track or not track.main_track then return end

  local pb = track.main_track.playback
  if not pb.is_playing then return end

  -- Remove bars whose notes have already played.
  for beat in pairs(bars) do
    if pb.beat > beat then bars[beat] = nil end
  end

  -- In this code block, I'm treating virtual coords as meters (m).
  local ball_dx = ball.dx
  while next_bar_ind <= #pb.notes do
    local note = pb.notes[next_bar_ind]
    local delta_b = note[1] - pb.beat
    if delta_b > 10 then break end

    local delta_s = delta_b / pb.beats_per_sec
    local delta_m = delta_s * ball_dx  -- This is a signed result in meters.
    local x = ball.x + delta_m

    -- hit_x is the edge between the ball and the bar when they will hit.
    local hit_x = mod_w_bounce(ball.x + delta_m + ball.w / 2 * sign(ball_dx))

    pr('Adding a bar with hit_x = %g; ball_dx = %g', hit_x, ball_dx)

    local bar = Bar:new(hit_x, ball_dx)
    bars[note[1]] = bar

    next_bar_ind = next_bar_ind + 1
  end
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

  update_bounce_bars()
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
  for _, bar in pairs(bars) do
    bar:draw()
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
  --print(string.format('note_callback(%g, %g, %s)', time, beat, note))
  if ball.num_hits == 0 then
    return 'wait'
  end

  -- TEMP
  --[[
  if note ~= 'a' then
    ball:bounce(0, ball.x, false, 0)
  end
  --]]

  return true
end

function vsbeatz.did_get_control()

  -- Calculate the tempo we'll play at. Our goal is exactly one bar = 4 beats
  -- between two consecutive player hits for the main player. This is the same
  -- as two beats per screen width.
  
  local w = players[2]:bounce_pt(ball) - players[1]:bounce_pt(ball)
  local sec_per_w     = w / math.abs(ball.dx)
  local beats_per_sec = 2 / sec_per_w
  local tempo         = beats_per_sec * 60

  beatz.set_note_callback(note_callback)
  track = beatz.load('beatz/b.beatz')
  track:set_tempo(tempo)
  track:play()
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
