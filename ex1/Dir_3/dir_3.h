#pragma once

/* Note due to "dual TOP" there are multiple definitions possible here - TODO */
#if defined(BUILD_ex1_Dir_3) || defined(BUILD_Dir_3) /* export symbols if building in this directory */
#define DIR3_EXPORT __attribute__ ((visibility("default")))
#else
#define DIR3_EXPORT
#endif

void DIR3_EXPORT function_dir_3_file1(void);

