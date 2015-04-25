// beatz/c/usleep.c
//
// A Lua C module (written in C, called from Lua) for OS-friendly sleeping
// that can be used, for example, in a thread-consuming loop that you don't
// want to kill a cpu.
//
// Example usage:
//   usleep = require 'usleep'
//   while true do
//     -- Do some work.
//     usleep(10000)  -- Sleep for about 10ms; operating at about 100 hz.
//   end
//
//

#include "luajit/lua.h"
#include "luajit/lauxlib.h"

#include <unistd.h>


///////////////////////////////////////////////////////////////////////////////
// Internal functions.
///////////////////////////////////////////////////////////////////////////////

int lua_usleep(lua_State *L) {
  lua_Integer usec = luaL_checkinteger(L, 1);
  usleep(usec);
  return 0;
}


///////////////////////////////////////////////////////////////////////////////
// Public functions, and data for them.
///////////////////////////////////////////////////////////////////////////////

int luaopen_beatz_usleep(lua_State *L) {
  lua_pushcfunction(L, lua_usleep);
  return 1;
}

