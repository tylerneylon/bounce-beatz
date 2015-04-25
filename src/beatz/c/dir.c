// beatz/c/dir.c
//
// A Lua C module (written in C, called from Lua) for iterating over a list of
// file names in a dir.
//
// Example usage:
//   dir = require 'dir'
//   for filename in dir.open('path/to/dir') do
//     print(filename)
//   end
//
// Much of this code is from chapter 30 of the book Programming in Lua, 3rd ed.
//

#include "luajit/lua.h"
#include "luajit/lauxlib.h"

#include <dirent.h>
#include <errno.h>
#include <string.h>


// This is the Lua registry key for the dir metatable.
#define dir_mt "dir_mt"


///////////////////////////////////////////////////////////////////////////////
// Forward function declarations.
///////////////////////////////////////////////////////////////////////////////

static int dir_iter(lua_State *L);


///////////////////////////////////////////////////////////////////////////////
// Internal/metatable Lua functions.
///////////////////////////////////////////////////////////////////////////////

// This function opens a directory and returns an iterator that can be used
// in a Lua for loop; or raises an error if the dir can't be opened.
static int l_dir(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);

  DIR **d = (DIR **)lua_newuserdata(L, sizeof(DIR *));

  // The metatable dir_mt is set up when the module is first loaded.
  luaL_getmetatable(L, dir_mt);
  lua_setmetatable(L, -2);

  *d = opendir(path);
  if (*d == NULL) {
    // This doesn't return.
    luaL_error(L, "can't open %s: %s", path, strerror(errno));
  }

  lua_pushcclosure(L, dir_iter, 1);
  return 1;
}

static int dir_iter(lua_State *L) {
  DIR *d = *(DIR **)lua_touserdata(L, lua_upvalueindex(1));
  struct dirent *entry;
  if ((entry = readdir(d)) != NULL) {
    lua_pushstring(L, entry->d_name);
    return 1;
  }
  return 0;  // Iteration has ended.
}

static int dir_gc(lua_State*L) {
  DIR *d = *(DIR **)lua_touserdata(L, 1);
  if (d) closedir(d);
  return 0;
}


///////////////////////////////////////////////////////////////////////////////
// Public functions, and data for them.
///////////////////////////////////////////////////////////////////////////////

static const struct luaL_Reg dirlib [] = {
  {"open", l_dir},
  {NULL, NULL}
};

int luaopen_beatz_dir(lua_State *L) {

  // Set up our metatable dir_mt.
  luaL_newmetatable(L, dir_mt);
  lua_pushcfunction(L, dir_gc);
  lua_setfield(L, -2, "__gc");

  // Register the one public function we have, `open`.
  luaL_register(L, "dir", dirlib);
  return 1;
}
