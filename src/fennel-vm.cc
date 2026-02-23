#include <lua.hpp>
#include <stdio.h>

// Initialise a Lua state with standard libs and Fennel loaded.
// Returns the state on success, NULL on error.
static lua_State *fennel_init() {
    lua_State *lua = luaL_newstate();
    luaL_openlibs(lua);

    if (luaL_loadfile(lua, "lib/fennel-1.6.1.lua") != LUA_OK ||
        lua_pcall(lua, 0, 1, 0) != LUA_OK) {
        fprintf(stderr, "diagram: cannot load fennel: %s\n", lua_tostring(lua, -1));
        lua_close(lua);
        return NULL;
    }
    lua_setglobal(lua, "__fennel");

    // Persistent environment: globals defined in one form are visible in the next
    if (luaL_dostring(lua, "__env = setmetatable({}, {__index = _G})") != LUA_OK) {
        fprintf(stderr, "diagram: cannot create env\n");
        lua_close(lua);
        return NULL;
    }

    return lua;
}

// Evaluate a Fennel form. Writes any string result to stdout.
// Returns 0 on success, -1 on error.
static int fennel_eval(lua_State *lua, const char *form) {
    lua_getglobal(lua, "__fennel");
    lua_getfield(lua, -1, "eval");
    lua_remove(lua, -2);

    lua_pushstring(lua, form);

    lua_newtable(lua);
    lua_getglobal(lua, "__env");
    lua_setfield(lua, -2, "env");

    if (lua_pcall(lua, 2, 1, 0) != LUA_OK) {
        fprintf(stderr, "diagram: %s\n", lua_tostring(lua, -1));
        lua_pop(lua, 1);
        return -1;
    }

    if (lua_isstring(lua, -1)) {
        size_t rlen;
        const char *result = lua_tolstring(lua, -1, &rlen);
        fwrite(result, 1, rlen, stdout);
    }
    lua_pop(lua, 1);
    return 0;
}
