--[[ beatz/strict.lua

Throw an error when a global is defined in a function or when
an undeclared global is referenced in a function.

There are a number of files similar to this one available
online, as well as described in the Programming in Lua book.
This is based on all of those influences.

--]]

local mt = getmetatable(_G)

if mt == nil then
  mt = {}
  setmetatable(_G, mt)
end

-- We hard-code that arg is declared so we can refer to it without
-- having to explicitly define it.
mt.__declared = {arg = true}

-- This returns what kind of function is 2 stack levels up.
local function what()
  -- We inspect the function 2 stack levels above us (so 3 above the getinfo
  -- call). The "S" means we want `source` and friends, including `what`.
  local d = debug.getinfo(3, "S")
  return d and d.what or "C"
end

mt.__newindex = function(t, n, v)
  if not mt.__declared[n] then
    local w = what()
    if w ~= "main" and w ~= "C" then
      error("Attempt to assign to undeclared global '" .. n .. "'", 2)
    end
    mt.__declared[n] = true
  end
  rawset(t, n, v)
end

mt.__index = function(t, n)
  if not mt.__declared[n] and what() ~= "C" then
    error("Use of undeclared global '" .. n .. "'", 2)
  end
  return rawget(t, n)
end
