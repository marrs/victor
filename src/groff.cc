#include <libgen.h>
#include <stdio.h>
#include <string.h>
#include <lua.hpp>

// Extract stem from filepath: "path/to/report.ms" -> "report"
// Writes into out[outlen]. Returns out.
static char *groff_stem(const char *filepath, char *out, size_t outlen)
{
    char tmp[4096];
    strncpy(tmp, filepath, sizeof(tmp) - 1);
    tmp[sizeof(tmp) - 1] = '\0';
    const char *base = basename(tmp);
    strncpy(out, base, outlen - 1);
    out[outlen - 1] = '\0';
    char *dot = strrchr(out, '.');
    if (dot) *dot = '\0';
    return out;
}

// Process a groff file: scan for .VIC/.ENDVIC blocks, evaluate each as Fennel,
// write EPS to CWD, emit modified groff (with .PSPIC) to stdout.
// Returns 0 on success, -1 on error.
static int process_groff(lua_State *lua, const char *filepath)
{
    FILE *f = fopen(filepath, "r");
    if (!f) {
        char msg[4096];
        snprintf(msg, sizeof(msg), "cannot open '%s'", filepath);
        String_Result res = string_result(LOG_ERROR, "groff/cannot-open", msg, nullptr);
        print_err("groff", res);
        return -1;
    }

    char stem[4096];
    groff_stem(filepath, stem, sizeof(stem));

    int vic_counter = 0;
    int in_vic = 0;
    Buf vic_code;
    if (buf_init(&vic_code) < 0) {
        String_Result res = string_result(LOG_ERROR, "groff/out-of-memory",
                                          "out of memory", nullptr);
        print_err("groff", res);
        fclose(f);
        return -1;
    }

    char line[4096];
    while (fgets(line, sizeof(line), f)) {
        size_t len = strlen(line);

        if (!in_vic) {
            if (strncmp(line, ".VIC", 4) == 0 &&
                    (line[4] == '\n' || line[4] == '\r' ||
                     line[4] == '\0' || line[4] == ' ')) {
                in_vic = 1;
                buf_reset(&vic_code);
                const char *prefix = "(do ";
                for (const char *p = prefix; *p; ++p)
                    buf_push(&vic_code, *p);
            } else if (strncmp(line, ".ENDVIC", 7) == 0 &&
                    (line[7] == '\n' || line[7] == '\r' ||
                     line[7] == '\0' || line[7] == ' ')) {
                String_Result res = string_result(LOG_WARNING, "groff/orphan-endvic",
                                                  "orphan .ENDVIC", nullptr);
                print_err("groff", res);
                fwrite(line, 1, len, stdout);
            } else {
                fwrite(line, 1, len, stdout);
            }
        } else {
            if (strncmp(line, ".ENDVIC", 7) == 0 &&
                    (line[7] == '\n' || line[7] == '\r' ||
                     line[7] == '\0' || line[7] == ' ')) {
                in_vic = 0;

                buf_push(&vic_code, ')');
                buf_push(&vic_code, '\0');

                if (fennel_eval_retain(lua, vic_code.data) == 0) {
                    if (lua_isstring(lua, -1)) {
                        size_t epslen;
                        const char *eps = lua_tolstring(lua, -1, &epslen);
                        char eps_path[8192];
                        snprintf(eps_path, sizeof(eps_path), "%s.%d.eps",
                                 stem, vic_counter);
                        FILE *ef = fopen(eps_path, "w");
                        if (!ef) {
                            char msg[8208];
                            snprintf(msg, sizeof(msg), "cannot write '%s'", eps_path);
                            String_Result res = string_result(LOG_ERROR,
                                "groff/eps-write-failed", msg, nullptr);
                            print_err("groff", res);
                        } else {
                            fwrite(eps, 1, epslen, ef);
                            fclose(ef);
                            fprintf(stdout, ".PSPIC %s\n", eps_path);
                        }
                    } else {
                        char msg[64];
                        snprintf(msg, sizeof(msg),
                                 "VIC block %d produced no string", vic_counter);
                        String_Result res = string_result(LOG_ERROR,
                            "groff/no-string", msg, nullptr);
                        print_err("groff", res);
                        fprintf(stdout, ".\\\" VIC block %d: no output\n", vic_counter);
                    }
                    lua_pop(lua, 1);
                } else {
                    char err_msg[4096];
                    strncpy(err_msg, lua_tostring(lua, -1), sizeof(err_msg) - 1);
                    err_msg[sizeof(err_msg) - 1] = '\0';
                    lua_pop(lua, 1);
                    String_Result res = string_result(LOG_ERROR,
                        "groff/fennel-error", err_msg, nullptr);
                    print_err("groff", res);
                    fprintf(stdout, ".\\\" VIC block %d failed\n", vic_counter);
                }

                ++vic_counter;
                buf_reset(&vic_code);
            } else {
                for (size_t i = 0; i < len; i++) {
                    if (buf_push(&vic_code, line[i]) < 0) {
                        String_Result res = string_result(LOG_ERROR,
                            "groff/out-of-memory", "out of memory", nullptr);
                        print_err("groff", res);
                        fclose(f);
                        buf_free(&vic_code);
                        return -1;
                    }
                }
            }
        }
    }

    if (in_vic) {
        String_Result res = string_result(LOG_WARNING,
            "groff/unterminated-vic", "unterminated .VIC block", nullptr);
        print_err("groff", res);
    }

    fclose(f);
    buf_free(&vic_code);
    return 0;
}
