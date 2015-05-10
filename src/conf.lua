--[[ bounce-beatz/src/conf.lua

Basic Love game configuration.

--]]

require 'strict'  -- Enforce careful global variable usage.


function love.conf(t)
  t.title         = 'bounce-beatz'
  t.identity      = 'bounce-beatz'

  t.window.width  = 1024
  t.window.height = 724

  -- Enable this to work with a smaller screen.
  --[[
  t.window.width  = 800
  t.window.height = 600
  --]]
end
