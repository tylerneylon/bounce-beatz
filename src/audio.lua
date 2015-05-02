--[[ bounce-beatz/src/audio.lua

Module to load and manage all game audio.

--]]

require 'strict'  -- Enforce careful global variable usage.


local audio = {}


--------------------------------------------------------------------------------
-- Set up a replay-able class.
--------------------------------------------------------------------------------

-- The value of num_sources here is the default. It can be changed on a per-case
-- basis by using the optional third parameter to ReplayableSource:new.
local ReplayableSource = {num_sources = 3, play_next = 1}

function ReplayableSource:new(filename, mode, num_src)
  local src = {}
  setmetatable(src, {__index = self})
  src.num_sources = num_src  -- Preserves delegation in num_src = nil case.

  src.raw_sources = {}
  for i = 1, src.num_sources do
    src.raw_sources[i] = love.audio.newSource(filename, mode)
  end

  return src
end

function ReplayableSource:play()
  local raw_src = self.raw_sources[self.play_next]
  raw_src:play()
  self.play_next = (self.play_next % self.num_sources) + 1
end

function ReplayableSource:stop()
  for i = 1, #self.raw_sources do
    self.raw_sources[i]:stop()
  end
end


--------------------------------------------------------------------------------
-- Supporting functions.
--------------------------------------------------------------------------------

local function load_named_sounds(names, audio, num_src, ext)
  ext = ext or '.wav'
  for _, name in pairs(names) do
    local filename = 'audio/' .. name .. ext
    audio[name] = ReplayableSource:new(filename, 'static', num_src)
  end
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

-- Set up low-replayable sounds.
local names = {'point', 'good1', 'good2', 'death'}
load_named_sounds(names, audio)

-- Set up high-replayable sounds.
local names = {'ball_hit', 'ball_edge_hit'}
-- By experimentation, apparently 10 instances is enough to cover a ball moving
-- at top speed.
load_named_sounds(names, audio, 10)

-- Set up mp3-based sfx.
load_named_sounds({'spark'}, audio, 3, '.mp3')

-- Set up songs.
local names = {'beatz01'}
load_named_sounds(names, audio, 1, '.mp3')


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return audio
