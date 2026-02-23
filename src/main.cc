#include <lua.hpp>
#include <stdio.h>

#include "util.cc"
#include "fennel-reader.cc"

// --- Entry point ---

int main(int argc, char **argv) {
    FILE *fp;
    if (argc > 1) {
        fp = fopen(argv[1], "r");
        if (!fp) {
            fprintf(stderr, "diagram: cannot open '%s'\n", argv[1]);
            return 1;
        }
    } else {
        fp = stdin;
    }

    lua_State *lua = luaL_newstate();
    luaL_openlibs(lua);

    if (luaL_loadfile(lua, "lib/fennel-1.6.1.lua") != LUA_OK ||
        lua_pcall(lua, 0, 1, 0) != LUA_OK) {
        fprintf(stderr, "diagram: cannot load fennel: %s\n", lua_tostring(lua, -1));
        if (argc > 1) fclose(fp);
        lua_close(lua);
        return 1;
    }
    lua_setglobal(lua, "__fennel");

    // Persistent environment: globals defined in one form are visible in the next
    if (luaL_dostring(lua, "__env = setmetatable({}, {__index = _G})") != LUA_OK) {
        fprintf(stderr, "diagram: cannot create env\n");
        if (argc > 1) fclose(fp);
        lua_close(lua);
        return 1;
    }

    Buf form;
    if (buf_init(&form) < 0) {
        fprintf(stderr, "diagram: out of memory\n");
        if (argc > 1) fclose(fp);
        lua_close(lua);
        return 1;
    }

    int status = 0;
    for (;;) {
        buf_reset(&form);

        int ret = read_form(fp, &form);
        if (ret == 1) break;
        if (ret < 0) {
            fprintf(stderr, "diagram: unexpected end of input\n");
            status = 1;
            break;
        }

        form.data[form.len] = '\0';

        lua_getglobal(lua, "__fennel");
        lua_getfield(lua, -1, "eval");
        lua_remove(lua, -2);

        lua_pushstring(lua, form.data);

        lua_newtable(lua);
        lua_getglobal(lua, "__env");
        lua_setfield(lua, -2, "env");

        if (lua_pcall(lua, 2, 1, 0) != LUA_OK) {
            fprintf(stderr, "diagram: %s\n", lua_tostring(lua, -1));
            lua_pop(lua, 1);
            status = 1;
            break;
        }

        if (lua_isstring(lua, -1)) {
            size_t rlen;
            const char *result = lua_tolstring(lua, -1, &rlen);
            fwrite(result, 1, rlen, stdout);
        }
        lua_pop(lua, 1);
    }

    buf_free(&form);
    if (argc > 1) fclose(fp);
    lua_close(lua);
    return status;
}
