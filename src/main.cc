#include <stdio.h>

#include "util.cc"
#include "buf.cc"
#include "font.cc"
#include "fennel-reader.cc"
#include "fennel-vm.cc"
#include "groff.cc"

int main(int argc, char **argv) {
    lua_State *lua = fennel_init();
    if (!lua) return 1;

    int status = 0;

    if (argc > 1) {
        if (strcmp(argv[1], "groff") == 0) {
            if (argc < 3) {
                fprintf(stderr, "Usage: victor groff <file>\n");
                status = 1;
            } else {
                status = process_groff(lua, argv[2]) < 0 ? 1 : 0;
            }
        } else {
            status = (fennel_dofile(lua, argv[1]) < 0) ? 1 : 0;
        }
    } else {
        Buf form;
        if (buf_init(&form) < 0) {
            fprintf(stderr, "diagram: out of memory\n");
            lua_close(lua);
            return 1;
        }

        for (;;) {
            buf_reset(&form);

            int ret = read_form(stdin, &form);
            if (ret == 1) break;
            if (ret < 0) {
                fprintf(stderr, "diagram: unexpected end of input\n");
                status = 1;
                break;
            }

            form.data[form.len] = '\0';

            if (fennel_eval(lua, form.data) < 0) {
                status = 1;
                break;
            }
        }

        buf_free(&form);
    }

    lua_close(lua);
    return status;
}
