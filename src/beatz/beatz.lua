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
local usleep     = require 'beatz.usleep'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

-- Variables shared between play_at_time and play_track.
local beats_per_sec, play_at_beat, notes, ind, inst
local loops_done, num_beats
local time = 0
local is_playing = false


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
  if beat < play_at_beat then return end

  local note = notes[ind][2]

  -- Check for an end mark in the track.
  if note == false then
    is_playing = false
    return
  end

  inst:play(note)
  ind = ind + 1
  if ind > #notes then
    ind = 1
    loops_done = loops_done + 1
  end
  play_at_beat = notes[ind][1] + loops_done * num_beats
end

local function play_track(track)
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
  beats_per_sec = 4.2
  time          = 0

  -- Play loop.
  if not rawget(_G, 'love') then
    local delay_usec = 5 * 1000  -- Operate at 200 hz.
    while true do
      play_at_time(time)
      usleep(delay_usec)
      time = time + delay_usec / 1e6
    end
  end
end

local function ensure_track_has_instrument(track)
  if track.instrument then return end
  -- Assume the track is an array of subtracks.
  -- Get an instrument from the first one of them we can.
  local t = track[1]
  ensure_track_has_instrument(t)
  track.instrument = t.instrument
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
  ensure_track_has_instrument(track)
  ensure_track_has_notes(track)
  return track
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

-- Returns the data table resulting from running the file as a Lua file within
-- a new load environment (load_env).
function beatz.load(filename)
  -- Load and parse the file.
  local file_fn, err_msg = loadfile(filename)
  if file_fn == nil then error(err_msg) end

  -- Process the file contents.
  local data = get_new_load_env()
  setfenv(file_fn, data)
  file_fn()

  return data
end

function beatz.play(filename)
  local data = beatz.load(filename)
  local track = get_processed_main_track(data)
  play_track(track)
end

-- Meant to be called from love.
function beatz.update(dt)
  time = time + dt
  play_at_time(time)
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
