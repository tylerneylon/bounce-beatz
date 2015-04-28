--[[ beatz/track.lua

https://github.com/tylerneylon/beatz

A class to encapsulate track methods.

For now this is a little dirty as some track-specific functionality is in
beatz.lua.

--]]

require 'beatz.strict'  -- Enforce careful global variable usage.


local Track = {}


--------------------------------------------------------------------------------
-- Public methods.
--------------------------------------------------------------------------------

function Track:new(t)
  t = t or {}
  return setmetatable(t, {__index = self})
end

function Track:set_tempo(new_tempo)
  local beatz = require 'beatz.beatz'
  local main_track = beatz.get_processed_main_track(self)
  main_track.tempo = new_tempo
end

function Track:play()
  -- This is required here to avoid a require cycle.
  local beatz = require 'beatz.beatz'
  beatz.play_track(self)
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Track
