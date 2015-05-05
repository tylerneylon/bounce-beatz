--[[ bounce-beatz/src/vsbeatz.lua

Main interactions for the 1p vs beatz mode.

--]]

require 'strict'  -- Enforce careful global variable usage.

local vsbeatz = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local anim     = require 'anim'
local audio    = require 'audio'
local Ball     = require 'ball'
local Bar      = require 'bar'
local beatz    = require 'beatz.beatz'
local dbg      = require 'dbg'
local draw     = require 'draw'
local font     = require 'font'
local Player   = require 'player'
local Shield   = require 'shield'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- We use a coordinate system where (0, 0) is the middle of the screen, (-1, -1)
-- is the lower-left corner, and (1, 1) is the upper-right corner.

-- These will be set up in the initialization below.
local ball
local players
local shield

-- These determine the player movement speed.
local player_ddy = 30   -- Previously 26.
local player_dy  = 0.5  -- Previously 1.5.

-- This is set from vsbeatz.take_over.
local mode

local track
local next_bar_ind = 2

-- This is a map: <beat> -> <bar>, where <beat> is the beat number on which the
-- corresponding note is expected to play.
local bars = {}

local last_planned_hit_beat
local last_planned_hit_x
local last_planned_hit_dx  -- This is the ball's velocity after the hit.
local last_planned_bounce_num = 1

local num_unplayed_bounces = 0
local next_bounce_num      = 1

local ideal_beats_per_sec

-- This can be 'playing', 'won', or 'lost.
local game_state = 'playing'
local was_last_note_played = false


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

local function get_x_from_note_names(note_names)
  if type(note_names) == 'table' then
    for _, note_name in pairs(note_names) do
      local x = get_x_from_note_names(note_name)
      if x then return x end
    end
  else
    local note_name = note_names  -- To clarify it's a single name.
    if note_name == 'x' then return players[1]:bounce_pt(ball) end
    if note_name == 'y' then return players[2]:bounce_pt(ball) end
  end
end

local function handle_num_bounces(num_bounces)
  num_unplayed_bounces = num_unplayed_bounces + num_bounces
  next_bounce_num      = next_bounce_num      + num_bounces
end

local function update_bounce_bars()
  if not track or not track.main_track then return end

  local pb = track.main_track.playback
  if not pb.is_playing then return end

  -- Check for any ball/bar hits and remove old bars.
  for beat, bar in pairs(bars) do
    local num_bounces = bar:update(ball, next_bounce_num)
    handle_num_bounces(num_bounces)

    if num_bounces > 0 then
      bars[beat] = nil
    end
  end

  -- In this code block, I'm treating virtual coords as meters (m).
  while next_bar_ind <= #pb.notes do
    local note = pb.notes[next_bar_ind]
    local delta_b = note[1] - pb.beat
    if delta_b > 10 then break end

    --pr('Considering a note with delta_b = %g', delta_b)

    --[[
    if note[2] then
      io.write('note = ')
      if type(note[2]) == 'string' then
        io.write('"', note[2], '"\n')
      else
        io.write('{')
        for i, n in ipairs(note[2]) do
          if i > 1 then io.write(', ') end
          io.write('"', n, '"')
        end
      io.write('}\n')
      end
    end
    --]]

    delta_b = note[1] - last_planned_hit_beat
    local delta_s = delta_b / ideal_beats_per_sec

    -- This is a signed result in meters.
    local delta_m = delta_s * last_planned_hit_dx
    local hit_x   = last_planned_hit_x + delta_m

    -- Some notes have designated hit points that override what we calculate.
    local do_draw     = true
    local x_from_note = get_x_from_note_names(note[2])
    if x_from_note then
      --pr('x_from_note = %g', x_from_note)
      hit_x   = x_from_note
      do_draw = false
    end

    if not x_from_note then
      --[[
      pr('Adding a bar with hit_x = %g; ball_dx = %g; do_draw = %s',
         hit_x, last_planned_hit_dx, tostring(do_draw))
         --]]

      local bar_info = {
        do_draw    = do_draw,
        beat       = note[1],
        bounce_num = last_planned_bounce_num + 1
      }
      local bar = Bar:new(bar_info, hit_x, last_planned_hit_dx, ball)
      bars[note[1]] = bar
    else
      --pr('Skipping adding a bar as it\'s either the player or end-wall')
    end

    last_planned_hit_x      = hit_x
    last_planned_hit_dx     = -1 * last_planned_hit_dx
    last_planned_hit_beat   = note[1]
    last_planned_bounce_num = last_planned_bounce_num + 1

    next_bar_ind = next_bar_ind + 1
  end
end

local function handle_game_over()
  game_state = 'lost'
  anim.player_exploding_perc = 0
  anim.change_to('player_exploding_perc', 1.0, {duration = 5.0})
  audio.death:play()
end

local function handle_game_won()
  game_state = 'won'
  audio.applause:play()
end

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

local function draw_game_over()

  local w, h        = 1.3, 0.7
  local margin      = 0.1
  local border_size = 0.05  -- The border is outside the box.

  -- Modify the height and find the text_y to nicely fit the text.
  local text = 'death\nengulfs you like a warm\nblanket on a cold cold night\n'
  local text_w = w - 2 * margin
  local text_h, text_margin = draw_multiline_str_below_y(text, text_w, 0, false)
  text_h = math.abs(text_h)
  h = text_h + text_margin  -- text_h already accounts for the top margin.
  -- In calculating text_y, we want it to be text_h / 2 - text_margin.
  local text_y = h / 2

  -- Draw a black background with a white border.
  draw.rect_w_mid_pt(0, 0, w, h, draw.black)
  local bord_w, bord_h = w + border_size, h + border_size
  local corner = {(w + border_size) / 2, (h + border_size) / 2}
  local dir = {1, 0}
  for i = 1, 4 do
    draw.rect_w_mid_pt(dir[1] * corner[1],
                       dir[2] * corner[2], 
                       math.abs(dir[2]) * bord_w + border_size,
                       math.abs(dir[1]) * bord_h + border_size,
                       draw.white)
    dir[1], dir[2] = -dir[2], dir[1]
  end

  -- Draw the text.
  draw_multiline_str_below_y(text, text_w, text_y)
end

local function note_callback(time, beat, note, next_note)
  --[[
  pr('note_callback(%g, %g, %s, %s)',
     time, beat, tostring(note), tostring(next_note))
  --]]
  
  if ball.num_hits == 0 then
    return 'wait'
  end

  if num_unplayed_bounces > 0 then
    num_unplayed_bounces = num_unplayed_bounces - 1

    if next_note == false then
      local pb = track.main_track.playback
      anim.ending_perc = 0
      anim.change_to('ending_perc', 1, {duration = 1 / pb.beats_per_sec})
      was_last_note_played = true
    end

    return true
  else
    return 'wait'
  end

  return true
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function vsbeatz.update(dt)

  if game_state ~= 'playing' then return end

  -- Move the ball.
  ball:update(dt)

  -- Move the players. This also handles ball collisions.
  for _, p in pairs(players) do
    handle_num_bounces(p:update(dt, ball))
  end

  handle_num_bounces(shield:update(dt, ball))

  -- Handle any scoring that may have occurred.
  local was_ball_missed = ball:handle_missed_ball(players, shield)

  if was_last_note_played and ball.x > 1 then
    handle_game_won()
  elseif was_ball_missed then
    handle_game_over()
  end

  update_bounce_bars()
end
 
function vsbeatz.draw()

  --[[
  -- TEMP This is to help clearly see the extents of the window while
  --      developing this mode.
  local win_w, win_h = love.graphics.getDimensions()
  love.graphics.setColor({30, 0, 0})
  love.graphics.rectangle('fill', 0, 0, win_w, win_h)
  --]]

  start_smaller_drawing()
  shield:draw()
  for _, p in pairs(players) do
    p:draw()
  end

  local beat = 0
  if track and track.main_track then
    beat = track.main_track.playback.beat
  end

  for _, bar in pairs(bars) do
    bar:draw(beat)
  end

  if game_state == 'playing' then ball:draw() end
  draw.borders()
  end_smaller_drawing()

  if game_state == 'lost' then
    draw_game_over()
  end

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

function vsbeatz.did_get_control()

  -- Calculate the tempo we'll play at. Our goal is exactly one bar = 4 beats
  -- between two consecutive player hits for the main player. This is the same
  -- as two beats per screen width.
  
  local w = players[2]:bounce_pt(ball) - players[1]:bounce_pt(ball)
  local sec_per_w     = w / math.abs(ball.dx)
  ideal_beats_per_sec = 2 / sec_per_w
  local tempo         = ideal_beats_per_sec * 60

  if dbg.is_fast_1p_mode then
    tempo = tempo * 3
  end

  -- Slightly speed up the tempo to help account for precision errors.
  -- It's easier for us to in-real-time-slow-down beatz than to speed it up.
  tempo = tempo * 1.1

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
local is_1p = true
-- The 1.2 value here is temporary for debugging. Normally we leave that
-- parameter blank so Player will use the default height.
players = {Player:new(-0.8, 0.6, '1p_pl'), Player:new(1.0, 2.0, '1p_bar')}

shield = Shield:new(players[1])

for i = 1, 2 do
  players[i].do_draw_score = false
end

last_planned_hit_beat = 0
last_planned_hit_x    = players[1]:bounce_pt(ball)
last_planned_hit_dx   = math.abs(ball.dx)


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return vsbeatz
