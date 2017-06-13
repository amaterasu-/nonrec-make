#include <stdio.h>
#include <unistd.h>

int main(int argc, char** argv)
{
    char path[1024];
    int i;

    if (getcwd(path, sizeof(path)))
    {
        printf("This test was run from %s\n", path);
    }

    for (i = 0; i < argc; ++i)
    {
        printf("argv[%d]='%s'\n", i, argv[i]);
    }

    printf("This test passes\n");
    return 0;
}
