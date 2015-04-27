--[[ beatz/add_love_handles.lua

https://github.com/tylerneylon/beatz

This is a love-aware script that adds hooks, aka handlers, that replace C
modules with constructed modules that wrap Love-provided functionality.
It is expected to be required from beatz before any of the C modules it
replaces.

This is useful because it allows love users to simply copy this code over to
their project without having to install any of the C modules separately; in
which case they'd either have to install a platform-specific compiled file, or
compile it themself.

--]]

-- Set up replacement code when this is run from within the Love game engine.
if rawget(_G, 'love') then

  -- Throw an error if any of these modules have already been loaded.
  local mod_names = {'dir', 'sounds', 'usleep'}
  for _, mod_name in pairs(mod_names) do
    local full_name = 'beatz.' .. mod_name
    if package.loaded[full_name] then
      error('module ' .. full_name .. ' has been loaded too early')
    end
  end

  -- Replace the dir module.
  local function dir_open(path)
    local items = love.filesystem.getDirectoryItems(path)
    local i = 0
    return function ()
      i = i + 1
      if items[i] then return items[i] end
    end
  end
  package.loaded['beatz.dir'] = {open = dir_open}

  -- Replace the sound module.
  local function sounds_load(file_path)
    return love.audio.newSource(file_path, 'static')
  end
  package.loaded['beatz.sounds'] = {load = sounds_load}

  -- Replace the usleep module, which is not used when love is present as we
  -- use love's run loop instead of our own.
  package.loaded['beatz.usleep'] = {}

end
