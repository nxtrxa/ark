module ark::kasm;
import std;
import libc;
enum TokenType : const Word_t
{
    TOKEN_LPAREN    = 40,
    TOKEN_RPAREN    = 41,
    TOKEN_LBRACE    = 123,
    TOKEN_RBRACE    = 125,
    TOKEN_DOT       = 46,
    TOKEN_SEMICOLON = 59,
    TOKEN_STAR      = 42,
    TOKEN_IDENTIFIER = 264,
    TOKEN_STRING     = 265,
    TOKEN_NUMBER     = 266,
    TOKEN_FLOAT      = 267,
    TOKEN_NIL    = 275,
    TOKEN_RETURN = 278,
    TOKEN_ERROR  = 284,
    TOKEN_EOF    = 285
}
const TokenType[256] CHAR_TO_TOKEN = {
    ['('] = TOKEN_LPAREN,
    [')'] = TOKEN_RPAREN,
    ['{'] = TOKEN_LBRACE,
    ['}'] = TOKEN_RBRACE,
    ['.'] = TOKEN_DOT,
    [';'] = TOKEN_SEMICOLON,
    ['*'] = TOKEN_STAR,
    ['\0'] = TOKEN_EOF
};

struct Token {
    TokenType type;
    uint line;
    uint column;
    uint length;
    union value
    {
        ulong int_value;
        double float_value;
        uint string_index;
    }
    String start;
}

// fn String? lexer(Splitter source) {
//
// }
