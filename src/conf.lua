--[[ bounce-beatz/src/conf.lua

Basic Love game configuration.

--]]

require 'strict'  -- Enforce careful global variable usage.


function love.conf(t)
  t.title    = 'bounce-beatz'
  t.identity = 'bounce-beatz'
end
