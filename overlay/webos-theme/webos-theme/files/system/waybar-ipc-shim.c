#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <stdio.h>
#include <stddef.h>

/* Waybar 0.15 sends "dispatch workspace N" over the Hyprland IPC socket.
 * Hyprland 0.57 evaluates that as Lua hl.dispatch(workspace N) and rejects it.
 * Rewrite it to the valid Lua dispatcher form on the way out. */
static void rewrite(const char *in, size_t n, char *out, size_t cap) {
    static const char prefix[] = "dispatch workspace ";
    const char *num;
    if (n <= sizeof(prefix) - 1 || memcmp(in, prefix, sizeof(prefix) - 1) != 0) {
        memcpy(out, in, n);
        out[n] = '\0';
        return;
    }
    num = in + sizeof(prefix) - 1;
    snprintf(out, cap, "dispatch hl.dsp.focus({ workspace = %s })", num);
}

ssize_t write(int fd, const void *buf, size_t count) {
    static ssize_t (*real)(int, const void *, size_t);
    char tmp[512];
    if (!real) real = dlsym(RTLD_NEXT, "write");
    if (count > 0 && count < sizeof(tmp)) {
        rewrite((const char *)buf, count, tmp, sizeof(tmp));
        if (strcmp(tmp, (const char *)buf) != 0)
            return real(fd, tmp, strlen(tmp));
    }
    return real(fd, buf, count);
}

ssize_t send(int fd, const void *buf, size_t n, int flags) {
    static ssize_t (*real)(int, const void *, size_t, int);
    char tmp[512];
    if (!real) real = dlsym(RTLD_NEXT, "send");
    if (n > 0 && n < sizeof(tmp)) {
        rewrite((const char *)buf, n, tmp, sizeof(tmp));
        if (strcmp(tmp, (const char *)buf) != 0)
            return real(fd, tmp, strlen(tmp), flags);
    }
    return real(fd, buf, n, flags);
}
