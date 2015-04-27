--[[ beatz/instrument.lua

https://github.com/tylerneylon/beatz

A class to capture a single instrument.

On disk, an instrument is a set of sound files kept together in a single subdir
of the instruments dir.

TODO Clarify actual usage.

Projected usage:

  -- This is to load audio files in the dir instruments/my_drumkit.
  instrument = require 'instrument'
  drums = instrument.load('my_drumkit')
  drums:play('a')

--]]

require 'beatz.strict'  -- Enforce careful global variable usage.

local dir     = require 'beatz.dir'
local rsounds = require 'beatz.rsounds'


local instrument = {}

-------------------------------------------------------------------------------
-- Internal variables and functions.
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Class interface.
-------------------------------------------------------------------------------

local Instrument = {}

function Instrument:new()
  local new_inst = {sounds = {}}
  return setmetatable(new_inst, {__index = self})
end

function Instrument:play(name)
  --print(string.format('Instrument:play(%s)', name))
  self.sounds[name]:play()
end


-------------------------------------------------------------------------------
-- Working space: LOVE-based replacement for dir.open.
-------------------------------------------------------------------------------

--[=[
local d = dir.open

-- This is an iterator that can replace dir.open when used from a love file.
local function d(path)
  local items = love.filesystem.getDirectoryItems(path)
  --[[
  print('items =', items)
  print('#items =', #items)
  print(string.format('From path "%s" got the items:', path))
  for k, v in pairs(items) do
    print(k, v)
  end
  --]]
  local i = 0
  return function ()
    i = i + 1
    if items[i] then return items[i] end
  end
end
--]=]

-------------------------------------------------------------------------------
-- Public functions.
-------------------------------------------------------------------------------

function instrument.load(inst_name)
  local inst = Instrument:new()

  -- TEMP
  local dir_path = 'beatz/instruments/' .. inst_name
  local wav_pattern = '(.*)%.wav$'
  --print('dir_path =', dir_path)
  for filename in dir.open(dir_path) do
    --print(string.format('subdir iter: Considering filename "%s"', filename))
    local name = filename:match(wav_pattern)
    if name then
      local file_path = dir_path .. '/' .. filename
      inst.sounds[name] = rsounds.load(file_path, 20)
    end
  end

  return inst
end


return instrument
