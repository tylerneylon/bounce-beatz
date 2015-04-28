--[[ beatz/beatz.lua

https://github.com/tylerneylon/beatz

This is a command-line audio track playing and editing module.

It is designed to work as both a stand-alone app and to
provide a programmatic interface to working with tracks and loops.

A *note* is a single sound.  A *loop* is a finite set of notes, along
with rhythmic data; musically, this is a finite set of measures.
A loop may optionally include the specification of which instrument
is meant to be used to play it.
A *track* is a collection of loops, along with optional instrumentation
and repeating data.

TODO Finalize this usage comment.

Projected usage:
  local beatz = require 'beatz'

  beatz.play('my_file.beatz')

  -- or
  
  my_track = beatz.load('my_file.beatz')
  my_track:play()

--]]

require 'beatz.strict'  -- Enforce careful global variable usage.

local beatz = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

-- Set up replacement code when this is run from within the Love game engine.
require 'beatz.add_love_handles'

local events     = require 'beatz.events'
local instrument = require 'beatz.instrument'
local Track      = require 'beatz.track'
local usleep     = require 'beatz.usleep'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- Variables shared between play_at_time and play_track.
local beats_per_sec, play_at_beat, notes, ind, inst
local loops_done, num_beats
local time = 0
local is_playing = false
local is_waiting = false

local note_cb


--------------------------------------------------------------------------------
-- Debug functions.
--------------------------------------------------------------------------------

local function pr(...)
  print(string.format(...))
end


--------------------------------------------------------------------------------
-- The environment used to load beatz files.
--------------------------------------------------------------------------------

function add_notes(track)
  local chars_per_beat = track.chars_per_beat
  if chars_per_beat == nil then error('Missing chars_per_beat value') end

  local track_str = track[1]
  if track_str == nil then error('Missing note data') end

  local notes = {}
  for i = 1, #track_str do
    local note = track_str:sub(i, i)
    if note ~= ' ' then
      local beat = (i - 1) / chars_per_beat
      if track.swing and beat % 1 == 0.5 then
        beat = beat + 0.1
      end
      notes[#notes + 1] = {beat, note}
    end
  end
  if not track.loops then
    local beat = #track_str / chars_per_beat
    notes[#notes + 1] = {beat, false}  -- Add an end mark.
  end

  track.notes = notes

  track.num_beats = #track_str / chars_per_beat
end

local function new_track(track)
  add_notes(track)
  table.insert(tracks, track)
  return track
end

local function get_new_load_env()
  local load_env = {
    -- Add standard library modules.
    table     = table,
    -- Add our own functions.
    add_notes = add_notes,
    new_track = new_track,
    -- Initialize globals (global within this table).
    tracks    = {}
  }
  -- Let all load_env functions easily call each other.
  for _, f in pairs(load_env) do
    if type(f) == 'function' then
      setfenv(f, load_env)
    end
  end
  return load_env
end


-- This function uses some module-level globals along with the given time to
-- play any sounds appropriate at this moment.
-- time is in seconds, and starts at 0 when the track begins.
local function play_at_time(time)
  if not is_playing then return end

  local beat = time * beats_per_sec

  while beat >= play_at_beat do
    local note = notes[ind][2]

    -- Check for an end mark in the track.
    if note == false then
      is_playing = false
      return
    end

    if note_cb then
      local action = note_cb(time, beat + 1, note)  -- Provide 1-indexed beats.
      if action == false then
        is_playing = false
        return
      elseif action == 'wait' then
        is_waiting = true
      elseif action == true then
        is_waiting = false
      else
        error('Unexpected note callback return value: ' .. tostring(action))
      end
    end

    if is_waiting then return end

    inst:play(note)
    ind = ind + 1
    if ind > #notes then
      ind = 1
      loops_done = loops_done + 1
    end
    play_at_beat = notes[ind][1] + loops_done * num_beats
  end
end

-- This expects params to have param strings as keys and default values as
-- values. The special string value 'no default' indicates that the track
-- itself is required to provide a value at some level. Missing top-level
-- parameters are first attempted to be filled in from lower in the track tree;
-- if that fails, parameters are given default values. Missing required
-- parameters result in an error.
local function ensure_track_has_params(track, params, level)
  level = level or 0  -- This is here to help with debugging.

  if track == nil then
    error('Track processing started without a track (nil value given)!')
  end

  for param, default in pairs(params) do
    if track[param] == nil then
      if type(track[1]) == 'table' then
        ensure_track_has_params(track[1], {[param] = default}, level + 1)
        track[param] = track[1][param]
      else
        if default == 'no default' then error('Missing parameter: ' .. param) end
        track[param] = default
      end
    end
  end
end

-- This expects two arrays as inputs.
local function append_table(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
end

-- This also handles the num_beats key.
local function ensure_track_has_notes(track)
  if track.notes then return end
  -- Assume the track is an array of subtracks.
  -- Get the notes as a sequence built from those.
  local num_beats = 0
  local notes = {}
  for i = 1, #track do
    ensure_track_has_notes(track[i])
    local subnotes = track[i].notes
    for _, note in ipairs(subnotes) do
      if note[2] then  -- Don't include end markers.
        notes[#notes + 1] = {note[1] + num_beats, note[2]}
      end
    end
    num_beats = num_beats + track[i].num_beats
  end
  -- Now add a final end marker.
  notes[#notes + 1] = {num_beats, false}
  track.notes       = notes
  track.num_beats   = num_beats
end

local function get_processed_main_track(data)
  local track = data.main_track
  if track == nil then track = data.tracks[1] end
  local params = {
    tempo      = 120,
    instrument = 'no default'
  }
  ensure_track_has_params(track, params)
  ensure_track_has_notes(track)
  track.is_main_track = true
  return track
end

local function loadfile_love_aware(file_path)
  if rawget(_G, 'love') then
    return love.filesystem.load(file_path)
  else
    return loadfile(file_path)
  end
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

-- Returns the data table resulting from running the file as a Lua file within
-- a new load environment (load_env).
function beatz.load(filename)

  -- Load and parse the file.
  local file_fn, err_msg = loadfile_love_aware(filename)
  if file_fn == nil then error(err_msg) end

  -- Process the file contents.
  local data = get_new_load_env()
  setfenv(file_fn, data)
  file_fn()

  return Track:new(data)
end

function beatz.play(filename)
  local data = beatz.load(filename)
  local track = get_processed_main_track(data)
  beatz.play_track(track)
end

-- Meant to be called from love.
function beatz.update(dt)
  if not is_waiting then
    time = time + dt
  end
  play_at_time(time)
end

-- A note callback is called like so:
-- action = cb(time, beat, notee)
--   [in] time    is in seconds since the song began
--   [in] beat    is in beats since the song began
--   [in] notee   is a string
--  [out] action  may be:
--        * true   = keep playing
--        * false  = stop playing
--        * 'wait' = enter waiting state
-- In the waiting state, no notes are played until true is received from the
-- note callback, which is called with every tick. The song time is also held
-- static during this time.
function beatz.set_note_callback(cb)
  note_cb = cb
end

function beatz.play_track(track)

  if not track.is_main_track then
    track = get_processed_main_track(track)
  end

  -- Load the instrument.
  local inst_name = track.instrument
  if inst_name == nil then error('No instrument assigned with track') end

  -- Gather notes and set initial playing variables.
  inst          = instrument.load(inst_name)
  notes         = track.notes
  num_beats     = track.num_beats
  ind           = 1
  loops_done    = 0
  play_at_beat  = notes[ind][1]
  is_playing    = true
  is_waiting    = false
  beats_per_sec = track.tempo / 60
  time          = 0

  -- Play loop.
  if not rawget(_G, 'love') then
    local delay_usec = 5 * 1000  -- Operate at 200 hz.
    while true do
      play_at_time(time)
      usleep(delay_usec)
      if not is_waiting then 
        time = time + delay_usec / 1e6
      end
    end
  end
end


--------------------------------------------------------------------------------
-- Support stand-alone usage.
--------------------------------------------------------------------------------

if arg then
  local filename = arg[#arg]
  if filename and #arg >= 2 then
    beatz.play(filename)
  end
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return beatz
