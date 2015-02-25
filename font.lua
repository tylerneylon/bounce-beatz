--[[ font.lua

Data for a ridiculously simple font
designed to be used in pong-love, the pong clone.

This font has a fixed height of 5 units but is
variable width. Many characters will be 3 units in
width.

--]]

local font = {}

font[0] = {{ 1, 1, 1 },
           { 1, 0, 1 },
           { 1, 0, 1 },
           { 1, 0, 1 },
           { 1, 1, 1 }}

font[1] = {{ 1, 1, 0 },
           { 0, 1, 0 },
           { 0, 1, 0 },
           { 0, 1, 0 },
           { 1, 1, 1 }}

font[2] = {{ 0, 1, 0 },
           { 1, 0, 1 },
           { 0, 0, 1 },
           { 0, 1, 0 },
           { 1, 1, 1 }}

font[3] = {{ 1, 1, 0 },
           { 0, 0, 1 },
           { 0, 1, 1 },
           { 0, 0, 1 },
           { 1, 1, 0 }}

font[4] = {{ 1, 0, 1 },
           { 1, 0, 1 },
           { 1, 1, 1 },
           { 0, 0, 1 },
           { 0, 0, 1 }}

font[5] = {{ 1, 1, 1 },
           { 1, 0, 0 },
           { 1, 1, 0 },
           { 0, 0, 1 },
           { 1, 1, 0 }}

font[6] = {{ 0, 1, 0 },
           { 1, 0, 0 },
           { 1, 1, 0 },
           { 1, 0, 1 },
           { 0, 1, 0 }}

font[7] = {{ 1, 1, 1 },
           { 0, 0, 1 },
           { 0, 0, 1 },
           { 0, 1, 0 },
           { 0, 1, 0 }}

font[8] = {{ 0, 1, 0 },
           { 1, 0, 1 },
           { 0, 1, 0 },
           { 1, 0, 1 },
           { 0, 1, 0 }}

font[9] = {{ 0, 1, 0 },
           { 1, 0, 1 },
           { 0, 1, 1 },
           { 0, 0, 1 },
           { 0, 1, 0 }}

return font
