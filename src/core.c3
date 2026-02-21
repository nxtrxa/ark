module ark;

enum InstType : Word_t (String inst2str) {
    INST_NOP         = "nop",
    INST_PUSH        = "push",
    INST_POP         = "pop",
    INST_MUL         = "mul",
    INST_MLA         = "mla",
    INST_DIV         = "div",
    INST_DVA         = "dia",
    INST_ADD         = "add",
    INST_ADDA        = "adda",
    INST_SUB         = "sub",
    INST_SBA         = "sba",
    INST_MOV         = "mov",
    INST_CMP         = "cmp",
    INST_JMP         = "jmp",
    INST_JPE         = "jpe",
    INST_JNE         = "jne",
    INST_HALT        = "halt",
}

enum StackTrap : usz (String trap2str) {
    TRAP_OK = "OK",
    TRAP_UNKOWN_ENTRY_POINT = "ENTRY POINT NOW FOUND",
    TRAP_STACK_OVERFLOW = "STACK OVERFLOW",
    TRAP_STACK_UNDERFLOW = "STACK UNDERFLOW",
    TRAP_DIV_BY_ZERO = "DIVISION BY ZERO",
    TRAP_INVALID_OP = "INVALID OP",
    TRAP_INVALID_INST = "INVALID INSTRUCTION",
    TRAP_INVALID_INST_ACCESS = "INVALID INSTRUCTION ACCESS",
    TRAP_UNREACHABLE_STATEMENT = "UNREACHABLE STATEMENT",
    TRAP_HALTED = "VM HALTED",
    TRAP_INVALID_JMP_ADDR = "INVALID JUMP ADDRESS",
    TRAP_INVALID_JNE = "INVALID JUMP IF NOT EQUAL",
    TRAP_INVALID_JPE = "INVALID JUMP IF EQUAL",
    TRAP_FAILED_TO_LOAD_PROGRAM = "FAILED TO LOAD PROGRAM",
    TRAP_PROGRAM_RUNOUT_MEMORY = "PROGRAM_RUNOUT_MEMORY",
}

enum Cmd : short (String to_str)  {
    BUILD = "build",
    RUN = "run",
}

typedef Qword_t = inline long;
typedef Dword_t = inline int;
typedef Word_t = inline short;
typedef Byte_t = inline char;

const usz ARK_STACK_CAP = 1024U;
const usz ARK_PROGRAM_CAP = 1024U;
const usz ARK_INST_LIMIT = 32U;
const usz ARK_FILE_SIZE_LIMT = 1024U;

enum RegisterType : Byte_t
{
    GENERAL_PURPOSE,
    SPECIAL_PURPOSE,
    FLOATING_POINT,
    VECTOR
}

struct Registers {
    union register_value {
        ulong u64;
        long i64;
        double f64;
        Byte_t[8] bytes;
    }

    struct register_metadata {
        RegisterType type;
        bool empty;
        bool read_only;
        Byte_t[5] _padding;
    }

    Qword_t rax;
    Qword_t rbx;
    Qword_t rcx;
    Qword_t rdx;
    Qword_t rsi;
    Qword_t rdi;
    Qword_t rsp;
    Qword_t rbp;
    Qword_t rip;
    Qword_t rtp;
    Dword_t r8;
    Dword_t r9;
    Dword_t r10;
    Dword_t r11;
    Dword_t r12;
    Dword_t r13;
    Dword_t r14;
    Dword_t r15;
}

struct Ark {
    Qword_t[ARK_STACK_CAP] stack;
    usz stack_size;
    Instruction[ARK_PROGRAM_CAP] program;
    usz program_size;
    usz program_file_size;
    usz program_inst_count;
    usz ip;
    bool halted;
}

struct Program {
    Instruction[ARK_PROGRAM_CAP] program;
    usz program_file_size;
    usz program_inst_count;
}

struct Instruction {
    InstType type;
    Qword_t op;
}

struct String_View {
    char* str;
    usz len;
}

macro Type @reinterpret_cast(#xs) <Type> {
    return *(Type*)&&#xs;
}

macro Instruction inst(InstType it, long op) {
    return { it, (Qword_t)op };
}

macro push($op) {
    return (Instruction) {
        .type = INST_PUSH,
            .op = $op,
    };
}

macro pop() {
    return (Instruction) {
        .type = INST_POP,
    };
}

macro add() {
    return (Instruction) {
        .type = INST_ADD,
    };
}

macro adda() {
    return (Instruction) {
        .type = INST_ADDA,
    };
}

macro sub() {
    return (Instruction) {
        .type = INST_SUB,
    };
}

macro sba() {
    return (Instruction) {
        .type = INST_SBA,
    };
}

macro mul() {
    return (Instruction) {
        .type = INST_MUL,
    };
}

macro mla() {
    return (Instruction) {
        .type = INST_MLA,
    };
}

macro div() {
    return (Instruction) {
        .type = INST_DIV,
    };
}

macro dva() {
    return (Instruction) {
        .type = INST_DVA,
    };
}

macro cmp() {
    return (Instruction) {
        .type = INST_CMP,
    };
}

macro jmp($addr) {
    return (Instruction) {
        .type = INST_JMP,
            .op = $addr,
    };
}

macro jpe($addr) {
    return (Instruction) {
        .type = INST_JPE,
            .op = $addr,
    };
}
macro jne($addr) {
    return (Instruction) {
        .type = INST_JNE,
            .op = $addr,
    };
}

macro halt() {
    return (Instruction) {
        .type = INST_HALT,
    };
}

fn bool is_ark_bytecode_file(String fpath) {
    String ext = fpath.split(mem, ".")[1];
    return ext == "ark";
}

fn bool is_ark_source_file(String fpath) {
    String ext = fpath.split(mem, ".")[1];
     return ext == "kasm";
}
