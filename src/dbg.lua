--[[ bounce-beatz/src/dbg.lua

Debug parameters.

This file exists so we can easily turn on and off
certain features useful for debugging.

--]]

require 'strict'  -- Enforce careful global variable usage.


local dbg = {}

-- Controls default new-ball behavior; set this to false for normal operation.
dbg.is_ball_weird = false
dbg.start_dx = 4
dbg.start_dy = 0

dbg.is_fast_1p_mode = false

-- This value is only used outside of is_fast_1p_mode.
dbg.init_num_hearts = 3  -- This is normally 3.

-- If dbg.cycles_per_frame = 1, then it's full speed (normal operation), if
-- it's = 2, then we're at half speed, etc.
dbg.cycles_per_frame = 1
dbg.frame_offset = 0

return dbg
