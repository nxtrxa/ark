
#include "ark_loader.h"

/*
 * @Load the bytecode generated from Ark.lpif
 * @return the program`s size
 *
 * TODO: re-implement this function in C3
 */
[[nodiscard]]  size_t __LPFF(void* restrict PROGRAM, size_t ARK_INSTRUCTION_SIZE, size_t ARK_PROGRAM_CAP, char*  FILE_PATH ) {
    FILE* f = fopen(FILE_PATH, "rb");

    if (!f) {
        fprintf(stderr, "FAILED TO OPEN FILE: %s\n", FILE_PATH);
        exit(1);
    }


    if (fseek(f, 0, SEEK_END) < 0) {
        fprintf(stderr, "FAILED TO SEEK TO END OF FILE: %s\n", FILE_PATH);
        exit(1);
    }

    long fsz = ftell(f);
    if (fsz < 0) {
        fprintf(stderr, "FAILED TO GET FILE SIZE: %s : %s\n", FILE_PATH, strerror(errno));
        exit(1);
    }

    rewind(f);

    if ((size_t)fsz % ARK_INSTRUCTION_SIZE != 0) {
        fprintf(stderr, "INVALID PROGRAM FILE SIZE\n");
        exit(1);
    }

    size_t instruction_count = (size_t)fsz / ARK_INSTRUCTION_SIZE;

    if (instruction_count > ARK_PROGRAM_CAP) {
        fprintf(stderr, "PROGRAM TOO LARGE\n");
        exit(1);
    }

    size_t program_size = fread(PROGRAM, ARK_INSTRUCTION_SIZE, (fsz / ARK_INSTRUCTION_SIZE), f);

    if (program_size == 0) {
        fprintf(stderr, "FAILED TO READ FILE: %s\n", FILE_PATH);
        exit(1);
    }

    if (ferror(f)) {
        fprintf(stderr, "FAILED TO READ FILE: %s : %s\n", FILE_PATH, strerror(errno));
        exit(1);
    }

    return program_size;
}

[[nodiscard]]  string_view __RFIM(char* FILE_PATH) {
    FILE* f = fopen(FILE_PATH, "r");

    if (!f) {
        fprintf(stderr, "FAILDE TO OPEN FILE: %s", FILE_PATH, strerror(errno));
        exit(1);
    }

    if (fseek(f, 0, SEEK_END) < 0) {
        fprintf(stderr, "FAILED TO SEEK TO END OF FILE: %s", FILE_PATH, strerror(errno));
        exit(1);
    }

    long fsz = ftell(f);

    rewind(f);

    char* buf = malloc(fsz);

    size_t program_size = fread(buf, 1, fsz, f);

    if (ferror(f)) {
        fprintf(stderr, "FAILED TO READ FILE: %s : %s", FILE_PATH, strerror(errno));
        exit(1);
    }

    return (string_view) {
        .len = program_size,
            .str = buf,
    };
}
