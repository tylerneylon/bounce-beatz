--[[ bounce-beatz/src/events.lua

Meant to be used as:
  local events = require 'events'

  events.add(1.0, my_fn, param1, param2)  -- Any # params is ok, including 0.

It's important to call events.update from love.update:
  function love.update(dt)
    events.update(dt)
    -- other update code
  end

If this is used along with the anim module, call
anim.update before events.update.

--]]

require 'strict'  -- Enforce careful global variable usage.


local events = {}


-------------------------------------------------------------------------------
-- Internal variables and functions.
-------------------------------------------------------------------------------

local clock = 0
local next_number_id = 1
local event_ids_by_time = {}  -- an array with values = an event_id.
local events_by_id = {}  -- A dict with key = event_id, value = event table.

local function insert(event_id)
  local event = events_by_id[event_id]
  local e = event_ids_by_time
  local i = 1
  while i <= #e and events_by_id[e[i]].time < event.time do
    i = i + 1
  end
  table.insert(event_ids_by_time, i, event_id)
end

local function remove(event_id)
  local e = event_ids_by_time
  for i = 1, #e do
    if e[i] == event_id then
      table.remove(event_ids_by_time, i)
      return
    end
  end
end


-------------------------------------------------------------------------------
-- Public functions.
-------------------------------------------------------------------------------

function events.add(delay, callback, ...)
  local event_id = next_number_id
  next_number_id = next_number_id + 1
  local event = {time = clock + delay, callback = callback, params = {...}}
  events_by_id[event_id] = event
  insert(event_id)  -- Inserts into event_ids_by_time.
  return event_id
end

function events.cancel(event_id)
  local e = events_by_id[event_id]
  if e == nil then
    return false, string.format('events error: no event with id %s', event_id)
  end
  remove(event_id)  -- Removes from event_ids_by_time.
  events_by_id[event_id] = nil
  return true
end

function events.update(dt)
  clock = clock + dt
  local e_ids = event_ids_by_time
  while #e_ids > 0 and events_by_id[e_ids[1]].time < clock do
    local event = events_by_id[e_ids[1]]
    event.callback(unpack(event.params))
    events.cancel(e_ids[1])
  end
end

return events
