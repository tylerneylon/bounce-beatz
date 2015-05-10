--[[ beatz/instrument.lua

https://github.com/tylerneylon/beatz

A class to capture a single instrument.

On disk, an instrument is a set of sound files kept together in a single subdir
of the instruments dir.

Sample usage:

  instrument = require 'instrument'

  -- This loads all wav files in the dir instruments/my_drumkit.
  drums = instrument.load('my_drumkit')
  drums:play('a')         -- Play the sound from the file 'a.wav'.
  drums:play({'a', 'b'})  -- Play two sounds simultaneously.
  
--]]

require 'beatz.strict'  -- Enforce careful global variable usage.

local dir     = require 'beatz.dir'
local rsounds = require 'beatz.rsounds'


local instrument = {}


-------------------------------------------------------------------------------
-- Class interface.
-------------------------------------------------------------------------------

local Instrument = {}

function Instrument:new()
  local new_inst = {sounds = {}}
  return setmetatable(new_inst, {__index = self})
end

function Instrument:play(name)
  if type(name) == 'table' then
    for _, n in pairs(name) do
      self.sounds[n]:play()
    end
  else
    self.sounds[name]:play()
  end
end


-------------------------------------------------------------------------------
-- Public functions.
-------------------------------------------------------------------------------

function instrument.load(inst_name)
  local inst = Instrument:new()

  local dir_path = 'beatz/instruments/' .. inst_name
  local wav_pattern = '(.*)%.wav$'
  for filename in dir.open(dir_path) do
    local name = filename:match(wav_pattern)
    if name then
      local file_path = dir_path .. '/' .. filename
      inst.sounds[name] = rsounds.load(file_path, 20)
    end
  end

  return inst
end


-------------------------------------------------------------------------------
-- Return.
-------------------------------------------------------------------------------

return instrument
