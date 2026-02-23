#include <stdio.h>
#include <stdlib.h>

static void stream(FILE *in) {
    char buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0)
        fwrite(buf, 1, n, stdout);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *f = fopen(argv[1], "rb");
        if (!f) {
            fprintf(stderr, "diagram: cannot open '%s'\n", argv[1]);
            return 1;
        }
        stream(f);
        fclose(f);
    } else {
        stream(stdin);
    }
    return 0;
}
