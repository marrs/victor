#include <stdio.h>

struct Error {
    const char *level; // "error" or "warning"; nullptr on success
    const char *type;
    const char *msg;
};

struct String_Result {
    Error       err;
    const char *result; // string on success; "" on warning; nullptr on error
};

static String_Result string_result(const char *level, const char *type,
                                   const char *msg,   const char *result)
{
    String_Result res;
    res.err    = {level, type, msg};
    res.result = result;
    return res;
}

static void print_err(const String_Result &res)
{
    if (!res.err.level) {
        fprintf(stderr, "[glyph_name] err=nil result=%s\n", res.result);
    } else if (!res.result) {
        fprintf(stderr, "[glyph_name] err=%s: %s\n", res.err.type, res.err.msg);
    } else {
        fprintf(stderr, "[glyph_name] err=%s: %s result=%s\n",
                res.err.type, res.err.msg, res.result);
    }
}

