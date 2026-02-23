#include <stdio.h>

#include "util.cc"
#include "fennel-reader.cc"
#include "fennel-vm.cc"

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

    lua_State *lua = fennel_init();
    if (!lua) {
        if (argc > 1) fclose(fp);
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

        if (fennel_eval(lua, form.data) < 0) {
            status = 1;
            break;
        }
    }

    buf_free(&form);
    if (argc > 1) fclose(fp);
    lua_close(lua);
    return status;
}
