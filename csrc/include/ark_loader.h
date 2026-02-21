#ifndef ARK_LOADER_H
#define ARK_LOADER_H
#include <stdio.h>
#include <errno.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>

#include "string_view.h"

#define ARRAY_SIZE(xs) sizeof(xs) / sizeof(*(xs))

[[nodiscard]] extern size_t __LPFF(void* restrict PROGRAM,
        size_t ARK_INSTRUCTION_SIZE,
        size_t ARK_PROGRAM_CAP,
        char* FILE_PATH );
[[nodiscard]] extern string_view __RFIM(char* FILE_PATH);
#endif


