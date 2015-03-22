--[[ bounce-beatz/src/sounds.lua

Module to load and manage all game sounds.

--]]

require 'strict'  -- Enforce careful global variable usage.


local sounds = {}


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


--------------------------------------------------------------------------------
-- Supporting functions.
--------------------------------------------------------------------------------

local function load_named_sounds(names, sounds, num_src)
  for _, name in pairs(names) do
    local filename = 'audio/' .. name .. '.wav'
    sounds[name] = ReplayableSource:new(filename, 'static', num_src)
  end
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

-- Set up low-replayable sounds.
local names = {'point', 'good1', 'good2'}
load_named_sounds(names, sounds)


-- Set up high-replayable sounds.
local names = {'ball_hit', 'ball_edge_hit'}
-- By experimentation, apparently 10 instances is enough to cover a ball moving
-- at top speed.
load_named_sounds(names, sounds, 10)

return sounds
