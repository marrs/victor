#include <lua.hpp>
#include <stdint.h>
#include <stdio.h>

// Lua binding for glyph_name(font_name, codepoint) → err, result
// Pushes two values: err (nil or table) and result (string or nil)
static int l_glyph_name(lua_State *lua)
{
    const char *font_name = luaL_checkstring(lua, 1);
    uint32_t    codepoint = (uint32_t)luaL_checkinteger(lua, 2);

    String_Result res = glyph_name(font_name, codepoint);

    const char *level_str;
    switch (res.err.level) {
        case LOG_ERROR:   level_str = "error";   break;
        case LOG_WARNING: level_str = "warning"; break;
        case LOG_INFO:    level_str = "info";    break;
        default:          level_str = nullptr;   break;
    }

    if (level_str) {
        lua_newtable(lua);
        lua_pushstring(lua, level_str);
        lua_setfield(lua, -2, "level");
        lua_pushstring(lua, res.err.code);
        lua_setfield(lua, -2, "type");
        lua_pushstring(lua, res.err.msg);
        lua_setfield(lua, -2, "msg");
    } else {
        lua_pushnil(lua);
    }

    if (res.result) {
        lua_pushstring(lua, res.result);
    } else {
        lua_pushnil(lua);
    }

    return 2;
}

// Evaluate a Fennel form using __env. Leaves string result on the Lua stack.
// Returns 0 on success, -1 on error (pops error from stack and logs it).
static int fennel_eval_retain(lua_State *lua, const char *form)
{
    lua_getglobal(lua, "__fennel");
    lua_getfield(lua, -1, "eval");
    lua_remove(lua, -2);
    lua_pushstring(lua, form);
    lua_newtable(lua);
    lua_getglobal(lua, "__env");
    lua_setfield(lua, -2, "env");
    if (lua_pcall(lua, 2, 1, 0) != LUA_OK) {
        return -1;  // error message left on stack for caller
    }
    return 0;  // result left on stack
}

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

    // Register a searcher that checks fennel's macro-loaded cache first.
    // Modules already compiled by import-macros are returned directly, avoiding
    // a second compilation in runtime scope (where quasiquotes are illegal).
    const char *searcher_code =
        "table.insert(package.searchers, function(modname)\n"
        "  local cached = __fennel['macro-loaded'][modname]\n"
        "  if cached then return function() return cached end end\n"
        "  return __fennel.searcher(modname)\n"
        "end)\n";
    if (luaL_dostring(lua, searcher_code) != LUA_OK) {
        fprintf(stderr, "diagram: cannot install fennel searcher: %s\n", lua_tostring(lua, -1));
        lua_close(lua);
        return NULL;
    }

    // Persistent environment: globals defined in one form are visible in the next
    if (luaL_dostring(lua, "__env = setmetatable({}, {__index = _G})") != LUA_OK) {
        fprintf(stderr, "diagram: cannot create env\n");
        lua_close(lua);
        return NULL;
    }

    lua_pushcfunction(lua, l_glyph_name);
    lua_setglobal(lua, "glyph_name");

    return lua;
}

// Evaluate an entire Fennel file using fennel.dofile.
// Writes any string result to stdout. Returns 0 on success, -1 on error.
static int fennel_dofile(lua_State *lua, const char *path) {
    lua_getglobal(lua, "__fennel");
    lua_getfield(lua, -1, "dofile");
    lua_remove(lua, -2);

    lua_pushstring(lua, path);

    // {allowedGlobals = false} — disable strict global checking
    // (macro expansions reference globals like __tests that are unknown at the call site)
    lua_newtable(lua);
    lua_pushboolean(lua, 0);
    lua_setfield(lua, -2, "allowedGlobals");

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
