--[[ bounce-beatz/src/main.lua

This is a table-tennis-like game.

# Roadmap

Anytime items

[x] Support overlapping sound effects
[x] Split into modules (ball, player, draw, font)

Phase I   : Human vs human gameplay (1P battle)

[x] New sound for edge hits
[x] Spin
[x] More points for long-lasting balls

Phase I.(half) : title and menu screen

[x] Add a title screen
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

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local anim   = require 'anim'
local dbg    = require 'dbg'
local events = require 'events'
local title  = require 'title'


--------------------------------------------------------------------------------
-- Love-based functions.
--------------------------------------------------------------------------------

-- This is a function we add to let anyone change modes.
function love.give_control_to(mode)
  local fn_names = {'draw', 'keypressed', 'keyreleased'}
  for _, fn_name in pairs(fn_names) do
    love[fn_name] = mode[fn_name]
  end
  love.mode_update = mode.update
end

function love.load()
  love.give_control_to(title)
end

function love.update(dt)
  -- Support debug slow-down.
  dbg.frame_offset = (dbg.frame_offset + 1) % dbg.cycles_per_frame
  if dbg.frame_offset ~= 0 then return end

  -- Hooks for module run loops.
  anim.update(dt)
  events.update(dt)

  -- This is the mode-specific update functions.
  love.mode_update(dt)
end
