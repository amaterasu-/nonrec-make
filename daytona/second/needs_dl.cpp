#include "needs_dl.h"

#include <dlfcn.h>

int uses_dl()
{
    void* dl = dlopen(0, RTLD_NOW | RTLD_LOCAL);

    int ret = 1;
    if (dl)
    {
        ret = 0;
        dlclose(dl);
    }

    return ret;
}
