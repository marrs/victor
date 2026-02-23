#include <stdio.h>
#include <stdlib.h>

#include "util.cc"

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
