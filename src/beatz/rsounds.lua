--[[ beatz/rsounds.lua

https://github.com/tylerneylon/beatz

A wrapper around the sounds module to make it easier to play overlapping copies
of a single sound. This is useful, for example, for sound effects in games that
may overlap.

Sample usage:

  local rsounds = require 'rsounds'

  local num_simult_plays = 10
  local my_sound = rsounds.load(file_path, num_simult_plays)
  for i = 1, num_simult_plays do
    my_sound:play()  -- Start a 20 second sound.
    sleep(1)
  end
  -- Now we have 10 copies all playing at about a 1 second offset.

--]]

require 'beatz.strict'  -- Enforce careful global variable usage.


local sounds = require 'beatz.sounds'

local rsounds = {}


-------------------------------------------------------------------------------
-- Debugging functions.
-------------------------------------------------------------------------------

local function pr(...)
  print(string.format(...))
end


--------------------------------------------------------------------------------
-- Set up a replay-able class.
--------------------------------------------------------------------------------

-- The value of num_sources here is the default. It can be changed on a per-case
-- basis by using the optional third parameter to ReplayableSound:new.
local ReplayableSound = {num_sources = 3, play_next = 1}

function ReplayableSound:new(file_path, mode, num_src)
  local src = {}
  setmetatable(src, {__index = self})
  src.num_sources = num_src  -- Preserves delegation in num_src = nil case.

  src.raw_sources = {}
  for i = 1, src.num_sources do
    src.raw_sources[i] = sounds.load(file_path)
  end

  return src
end

function ReplayableSound:play()
  local raw_src = self.raw_sources[self.play_next]
  raw_src:play()
  self.play_next = (self.play_next % self.num_sources) + 1
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function rsounds.load(file_path, num_src)
  return ReplayableSound:new(file_path, num_src)
end

return rsounds
