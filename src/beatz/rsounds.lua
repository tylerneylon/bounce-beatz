--[[ beatz/rsounds.lua

https://github.com/tylerneylon/beatz

A wrapper around the sounds module to make it easier to play overlapping copies
of a single sound.

TODO Add usage comments.

--]]

require 'strict'  -- Enforce careful global variable usage.


local sounds = require 'beatz.sounds'

local rsounds = {}


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
    --print(string.format('Loaded "%s" to %s', file_path, tostring(src.raw_sources[i])))
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
