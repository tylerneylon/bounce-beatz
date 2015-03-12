--[[ pong-love/sounds.lua

Module to load and manage all game sounds.

--]]

local sounds = {}


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

local sound_names = {'ball_hit', 'ball_edge_hit', 'point', 'good1', 'good2'}

for _, name in pairs(sound_names) do
  local filename = 'audio/' .. name .. '.wav'
  sounds[name] = love.audio.newSource(filename, 'static')
end


return sounds
