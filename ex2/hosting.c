/* newlib hosting - for bare-metal targets without an OS */
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/fcntl.h>
#include <sys/times.h>
#include <sys/errno.h>
#include <sys/time.h>
#include <stdio.h>

void _exit(int status)
{
    (void)status;
    for (;;)
        continue;
}

caddr_t _sbrk(int incr)
{ (void)incr; return 0; }

int _write(int file, char *ptr, int len)
{ (void)file; (void)ptr; (void)len; return -1; }

int _close(int file)
{ (void)file; return -1; }

int _read(int file, char *ptr, int len)
{ (void)file; (void)ptr; (void)len; return -1; }

int _lseek(int file, int ptr, int dir)
{ (void)file; (void)ptr; (void)dir; return -1; }

int _fstat(int file, struct stat *st)
{ (void)file; (void)st; return -1; }

int _isatty(int file)
{ (void)file; return -1; }
