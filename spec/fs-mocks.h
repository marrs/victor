#pragma once
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

struct Fs_Mock_State {
    bool fopen_write_fail; // fail the next fopen call opened for writing
};

Fs_Mock_State fs_mock;

static void fs_mock_reset()
{
    fs_mock = {};
}

extern "C" FILE *fopen(const char *path, const char *mode)
{
    typedef FILE *(*real_fopen_t)(const char *, const char *);
    static real_fopen_t real_fopen = (real_fopen_t)dlsym(RTLD_NEXT, "fopen");
    if (fs_mock.fopen_write_fail && strchr(mode, 'w')) {
        fs_mock.fopen_write_fail = false;
        return nullptr;
    }
    return real_fopen(path, mode);
}
