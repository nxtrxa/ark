#include "string_view.h"


// [[nodiscard]] extern inline string_view cstr_to_sv(char* cstr) {
//     return (string_view) {
//         .len = strlen(cstr),
//         .str = cstr,
//     };
// }

[[nodiscard]] extern string_view sv_trim(string_view sv) {
    return sv_trim_left(sv_trim_right(sv));
}

[[nodiscard]] extern string_view sv_trim_left(string_view sv) {
    int i = 0;
    while (isspace((unsigned char)sv.str[i])) {
        i++;
    }

    return (string_view) {
        .len = sv.len - i,
        .str = sv.str + i,
    };
}

[[nodiscard]] extern string_view sv_trim_right(string_view sv) {
    int i = sv.len - 1;
    while (isspace((unsigned char)sv.str[i])) {
        i--;
    }

    return (string_view) {
        .len = i + 1,
        .str = sv.str,
    };
}

[[nodiscard]] extern string_view chop_by_delim(string_view sv, char del) {
    int i = 0;
    while (sv.str[i] != del) {
        i++;
    }

    return (string_view) {
        .len = i,
        .str = sv.str,
    };
}


[[nodiscard]] extern bool sv_cmp(string_view sv, string_view other ) {
    if (sv.len != other.len) return false;

    return memcmp(sv.str, other.str, sv.len) == 0;
}
