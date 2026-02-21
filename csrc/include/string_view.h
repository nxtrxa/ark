#ifndef STRING_VIEW_H
#define STRING_VIEW_H

#include <string.h>
#include <stdint.h>
#include <ctype.h>

typedef struct {
    size_t len;
    char* str;
} string_view;

// [[nodiscard]] extern inline string_view cstr_to_sv(char* cstr);
[[nodiscard]] extern string_view sv_trim(string_view sv);
[[nodiscard]] extern string_view sv_trim_left(string_view sv);
[[nodiscard]] extern string_view sv_trim_right(string_view sv);
[[nodiscard]] extern string_view chop_by_delim(string_view sv, char del);
[[nodiscard]] extern bool sv_cmp(string_view sv, string_view other );

#endif // STRING_VIEW_H
