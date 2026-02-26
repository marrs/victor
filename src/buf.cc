#include <stdlib.h>

struct Buf {
    char   *data;
    size_t  len;
    size_t  cap;
};

static int buf_init(Buf *buf) {
    buf->cap  = 256;
    buf->len  = 0;
    buf->data = (char *)malloc(buf->cap);
    return buf->data ? 0 : -1;
}

static void buf_free(Buf *buf) {
    free(buf->data);
}

static int buf_push(Buf *buf, char ch) {
    if (buf->len >= buf->cap - 1) {
        size_t ncap = buf->cap * 2;
        char *tmp = (char *)realloc(buf->data, ncap);
        if (!tmp) return -1;
        buf->data = tmp;
        buf->cap  = ncap;
    }
    buf->data[buf->len++] = ch;
    return 0;
}

static void buf_reset(Buf *buf) {
    buf->len = 0;
}
