#pragma once
#include <stdio.h>
#include <string.h>
#include <unistd.h>

struct Capture {
    int    saved_fd;
    FILE  *tmp;
    char   buf[4096];
};

static void capture_start(Capture *cap, int fd)
{
    fflush(fd == STDOUT_FILENO ? stdout : stderr);
    cap->saved_fd = dup(fd);
    cap->tmp = tmpfile();
    dup2(fileno(cap->tmp), fd);
}

static void capture_end(Capture *cap, int fd)
{
    fflush(fd == STDOUT_FILENO ? stdout : stderr);
    dup2(cap->saved_fd, fd);
    close(cap->saved_fd);
    rewind(cap->tmp);
    size_t n = fread(cap->buf, 1, sizeof(cap->buf) - 1, cap->tmp);
    cap->buf[n] = '\0';
    fclose(cap->tmp);
}

// Create a named temp file with a .ms extension containing content.
// path must be at least 32 bytes. Returns 0 on success, -1 on error.
static int make_fixture(char *path, const char *content)
{
    strcpy(path, "/tmp/vic-groff-XXXXXX.ms");
    int fd = mkstemps(path, 3);
    if (fd < 0) return -1;
    size_t len = strlen(content);
    if (write(fd, content, len) != (ssize_t)len) { close(fd); return -1; }
    close(fd);
    return 0;
}
