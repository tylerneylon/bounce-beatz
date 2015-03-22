--[[ bounce-beatz/src/anim.lua

Meant to be used as:
  local anim = require 'anim' 

  anim.my_value = 1.0
  anim.change_to('my_value', 2.0, {duration = 1.0})
  if anim.is_changing('my_value') then whatever() end

This module expects there to be a global called clock
which is updated as below.
It's also important to call anim.update from love.update:

  function love.update(dt)
    clock = clock + dt
    anim.update()
    -- other update code
  end

--]]

require 'strict'  -- enforce careful global variable usage.


local anim = {}


-------------------------------------------------------------------------------
-- Internal state and functions.
-------------------------------------------------------------------------------

local state = {}

local function dot_split(s)
  local a, b = s:find(".", 1, true)
  if a == nil then return s, '' end
  return s:sub(1, a - 1), s:sub(a + 1)
end

local function get_value_from_table(name, tab)
  local first, rest = dot_split(name)
  if tonumber(first) then first = tonumber(first) end
  local t = tab[first]
  if t == nil or #rest == 0 then return t end
  return get_value_from_table(rest, t)
end

local function set_value_in_table(name, val, tab)
  local first, rest = dot_split(name)
  if tonumber(first) then first = tonumber(first) end
  if #rest == 0 then
    tab[first] = val
    return
  end
  set_value_in_table(rest, val, tab[first])
end

local function get_value(name)
  return get_value_from_table(name, M)
end

local function set_value(name, val)
  set_value_in_table(name, val, M)
end


-------------------------------------------------------------------------------
-- Public functions.
-------------------------------------------------------------------------------

function anim.is_changing(name)
  if state[name] == nil then return false end
  local s = state[name]
  if clock < s.start_time then return false end
  return clock <= s.end_time
end

function anim.change_to(name, dst, opts)
  -- For now I only expect opts to have opts.duration, but in the future it
  -- might have opts.end_time or opts.speed.
  local val = get_value(name)
  if val == nil then
    print('Error: anim.change_to called on unknown name "' .. name .. '"')
    os.exit(1)
  end
  local s = {}
  s.start_pos = val
  s.end_pos = dst
  s.start_time = clock
  if opts.start then s.start_time = opts.start end
  s.end_time = s.start_time + opts.duration -- / 5.0
  if opts.callback then
    s.callback = opts.callback
  end
  s.is_complete = false
  state[name] = s
end

function anim.change_if_new(name, dst, opts)
  if get_value(name) == nil then
    print('Error: anim.change_if_new called on unknown name "' .. name .. '"')
    os.exit(1)
  end
  if state[name] == nil or
     not anim.is_changing(name) or
     state[name].end_pos ~= dst then
    anim.change_to(name, dst, opts)
  end
end

function anim.update()
  for name, s in pairs(state) do
    if anim.is_changing(name) then
      if s.start_time == s.end_time then
        set_value(name, s.end_pos)
      else
        local perc_done = (clock - s.start_time) / (s.end_time - s.start_time)
        set_value(name, s.start_pos + perc_done * (s.end_pos - s.start_pos))
      end
    else
      if clock > s.end_time and not s.is_complete then
        set_value(name, s.end_pos)
        s.is_complete = true
        if s.callback then s.callback() end
      end
    end
  end
end

return anim
