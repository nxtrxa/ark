module ark::kasm;

import std;
import libc;

faultdef FAILED_TO_PARSE_FILE,
         FAILED_TO_PARSE_INSTRUCTION,
         FAILED_TO_PARSE_TOKEN,
         FAILED_TO_PARSE_TOKENS,
         FAILED_IN_LEXER_STAGE;

fn bool String.cmp(&self, String other) {
    if (self.len != other.len) return false;

    return libc::memcmp(self.ptr, other.ptr, self.len) == 0;
}


fn Instruction[]? parser(String source) {
    Splitter ssrc = source.tokenize("\n");

    Instruction* program = mem::malloc(source.len);
    usz inst_count;

    while (ssrc.current < ssrc.string.len) {
        program[inst_count++] = parse_inst(ssrc.next().trim_charset()!)!;
    }
    return program[:inst_count];
}

fn Instruction? parse_inst(String line) {
    String[] tokens = line.split(mem, " ");
    if (tokens.len != 2) {
        io::eprintfn("INVALID TOKENS: %s", tokens);
        return FAILED_TO_PARSE_INSTRUCTION~;
    }

    long op = tokens[1].to_integer($typeof(op))!;

    switch (tokens[0]) {
        case "push":   return ark::inst(INST_PUSH, op);
        case "pop":    return ark::pop();
        case "add":    return ark::add();
        case "adda":   return ark::adda();
        case "mul":    return ark::mul();
        case "mla":    return ark::mla();
        case "sub":    return ark::sub();
        case "sba":    return ark::sba();
        case "div":    return ark::div();
        case "dva":    return ark::dva();
        // case "mov":    return ark::mov(op);
        case "cmp":    return ark::cmp();
        case "jmp":    return ark::inst(INST_JMP, op);
        case "jpe":    return ark::inst(INST_JPE, op);
        case "jne":    return ark::inst(INST_JNE, op);
        case "halt":   return ark::halt();
    }
    return FAILED_TO_PARSE_INSTRUCTION~;
}
