#include <stdio.h>

enum Log_Level {
    LOG_NONE    = 0,
    LOG_ERROR   = 1,
    LOG_WARNING = 2,
    LOG_INFO    = 3,
};

static Log_Level LOG_LEVEL = LOG_WARNING;

struct Error {
    int         level; // LOG_NONE on success; LOG_ERROR, LOG_WARNING, or LOG_INFO otherwise
    const char *code;
    const char *msg;
};

struct String_Result {
    Error       err;
    const char *result; // string on success; "" on warning; nullptr on error
};

static String_Result string_result(int level, const char *code,
                                   const char *msg, const char *result)
{
    String_Result res;
    res.err.level = level;
    res.err.code  = code;
    res.err.msg   = msg;
    res.result    = result;
    return res;
}

static void print_err(const String_Result &res)
{
    if (res.err.level > 0 && res.err.level <= (int)LOG_LEVEL) {
        fprintf(stderr, "[glyph_name] %s: %s\n", res.err.code, res.err.msg);
    }
}
