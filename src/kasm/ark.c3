module ark;

import std;
import libc;

faultdef PROGRAM_RUNOUT_MEMORY, FAILED_TO_OPEN_FILE, FAILED_TO_WRITE_TO_FILE, FAILED_TO_READ_FROM_FILE, FAILED_TO_PARSE_FILE, COMPILATION_ERROR, FILE_NOT_FOUND;

<*
load program from memory
*>
fn void? Ark.lpfm(&self @noalias, Instruction[] program @noalias) {
    if (program.len > ARK_PROGRAM_CAP) return PROGRAM_RUNOUT_MEMORY~;
    mem::copy(&self.program.instructions, program.ptr, $sizeof(program[0]) * program.len);
    self.program.inst_count = program.len;
    self.ip = 0;
    self.halted = false;
}

<*
read file into memory
*>
fn String? Ark.rfim(&self @noalias, String fpath) {
    if (try File f = file::open(fpath, "r")) {
        defer (void)f.close();

        usz fsz = file::get_size(fpath)!;
        char* buf = mem::malloc(fsz);

        (void)f.read(buf[:fsz]);
        self.program.file_size = fsz;

        return (String)buf[:fsz];
    }
    return FILE_NOT_FOUND~;
}


extern fn CULong __lpff(void* __program @noalias, CULong __ark_instruction_size, CULong __ark_program_cap, ZString __file_path) @extern("__LPFF");
extern fn String_View __rfim(ZString fpath) @extern("__RFIM");

<*
load program into file
*>
fn void? Ark.lpif(&self @noalias, String fpath) {
    if (try f = file::open(fpath, "wb")) {
        defer (void)f.close();
        if (try f.write(@reinterpret_cast{char[]}(&self.program)[:self.program.inst_count * @inst_size(self)])) {
            io::printfn("file %s generated\n", fpath);
        } else {
            return FAILED_TO_WRITE_TO_FILE~;
        }
        return;
    }
    return FAILED_TO_OPEN_FILE~;
}

<*
load program from file
*>
fn void? Ark.lpff(&self @noalias, String fpath) {
    if (try f = file::open(fpath, "rb")) {
        self.program.file_size = file::get_size(fpath)!;
        io::printfn("file size: %d\n", self.program.file_size);
        char* buf = mem::malloc(self.program.file_size);
        if (try f.read(buf[:self.program.file_size])) {
            self.lpfm(@reinterpret_cast{Instruction[]}(buf[:self.program.file_size / @inst_size(self)]))!;
        }
        return;
    }
    return FAILED_TO_READ_FROM_FILE~;
}


fn void? Ark.compile(&self @noalias, String fpath) {
    String? src = self.rfim(fpath);
    if (catch exception = src) {
        io::eprintn(exception);
        os::exit(1);
    }
    return self.lpfm(kasm::parser(src.trim()));
}

fn void Ark.run(&self) {
    uint inst_cout = 0;
    io::printn("instruction\toperands");
    foreach (idx, inst : self.program.instructions[:ARK_INST_LIMIT]) {
        if (!self.halted && self.ip < self.program.inst_count) {
            io::printfn("%s\t\t%s", self.program.instructions[self.ip].type.inst2str, self.program.instructions[self.ip].op);
            StackTrap st = self.execute_inst();
            inst_cout++;
            if (st != TRAP_OK) {
                io::eprintn(st.trap2str);
                self.dump_stack();
                self.free();
                os::exit(1);
            }
        }
    }
    io::printfn("[%d INSTRUCTIONS EXECUTED]", inst_cout);
}

fn StackTrap Ark.execute_inst(&self){
    if (self.ip >= self.program.inst_count) return TRAP_INVALID_INST_ACCESS;

    // if (self.program.instructions[0].type != INST_ENTRY_POINT) {
    //     return TRAP_UNKOWN_ENTRY_POINT;
    // }

    Instruction inst = self.program.instructions[self.ip];


    switch (inst.type) {
        case INST_NOP:
            return TRAP_OK;

        case INST_PUSH:
            return self.push(inst.op);

        case INST_POP:
            return self.pop();

        case INST_MUL:
            return self.mul();

        case INST_DIV:
            return self.div();

        case INST_DVA:
            return self.dva();

        case INST_MLA:
            return self.mla();

        case INST_ADD:
            return self.add();

        case INST_ADDA:
            return self.adda();

        case INST_SUB:
            return self.sub();

        case INST_SBA:
            return self.sba();

        case INST_MOV:
            return self.mov(inst.op);

        case INST_CMP:
            return self.cmp();

        case INST_JMP:
            if (inst.op >= self.program.inst_count) return TRAP_INVALID_INST_ACCESS;
            self.ip = inst.op;
            return TRAP_OK;

        case INST_JPE:
            return self.jpe(inst.op);

        case INST_JNE:
            return self.jne(inst.op);

        case INST_HALT:
            self.halted = true;
            return TRAP_HALTED;

        default:
            return TRAP_INVALID_INST;
    }
}

fn StackTrap Ark.push (&self @noalias, Qword_t op) @inline {
    if (self.stack_size >= ARK_STACK_CAP) return TRAP_STACK_OVERFLOW;
    self.stack[self.stack_size++] = op;
    self.ip++;
    return TRAP_OK;
}

fn StackTrap Ark.pop(&self @noalias) @inline {
    if (self.stack_size == 0) return TRAP_STACK_UNDERFLOW;

    self.stack_size--;
    self.stack[self.stack_size] = 0;
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.mov (&self @noalias, Qword_t op) @inline {
    self.stack[self.stack_size] = 0;
    // assert(0 && "TODO: mov instructin function handler");
    return TRAP_OK;
}

fn StackTrap Ark.mul(&self @noalias) @inline {
    if (self.stack_size <= 1) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size - 2] *= self.stack[self.stack_size - 1];
    self.stack_size--;
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.mla(&self @noalias) @inline {
    if (self.stack_size <= 1) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size++] = self.stack[self.stack_size - 2] * self.stack[self.stack_size - 1];
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.div(&self @noalias) @inline {

    if (self.stack_size == 0) return TRAP_STACK_UNDERFLOW;
    if (self.stack[self.stack_size - 1] == 0) return TRAP_DIV_BY_ZERO;

    self.stack[self.stack_size - 2] /= self.stack[self.stack_size - 1];
    self.stack_size--;
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.dva(&self @noalias) @inline {
    if (self.stack_size == 0) return TRAP_STACK_UNDERFLOW;
    if (self.stack[self.stack_size - 1] == 0) return TRAP_DIV_BY_ZERO;

    self.stack[self.stack_size++] = (Qword_t)(self.stack[self.stack_size - 2] / self.stack[self.stack_size - 1]);
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.add(&self @noalias) @inline {
    if (self.stack_size <= 1) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size - 2] += self.stack[self.stack_size - 1];
    self.stack_size--;
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.adda(&self @noalias) @inline {
    if (self.stack_size <= 1) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size++] = self.stack[self.stack_size - 2] + self.stack[self.stack_size - 1];
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.sub(&self @noalias) @inline {
    if (self.stack_size <= 1) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size - 2] -= self.stack[self.stack_size - 1];
    self.stack_size--;
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.sba(&self @noalias) @inline {
    if (self.stack_size <= 1) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size++] = self.stack[self.stack_size - 2] - self.stack[self.stack_size - 1];
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.cmp(&self @noalias) @inline {
    if (self.stack_size <= 1) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size - 2] = (Qword_t)(self.stack[self.stack_size - 1] == self.stack[self.stack_size - 2]);
    self.stack_size--;
    self.stack[self.stack_size] = 0;
    self.ip++;
    return TRAP_OK;
}

fn StackTrap Ark.jpe (&self @noalias, Qword_t addr) @inline {
    if (self.stack_size == 0) return TRAP_STACK_UNDERFLOW;
    if (addr >= self.program.inst_count) return TRAP_INVALID_INST_ACCESS;

    if (self.stack[self.stack_size - 1] == 1) {
        self.ip = addr;
        self.stack[self.stack_size--] = 0;
        return TRAP_OK;
    }
    else if (self.stack[self.stack_size - 1] == 0) {
        self.ip++;
        self.stack[self.stack_size--] = 0;
        return TRAP_OK;
    } else {
        return TRAP_INVALID_JPE;
    }
}

fn StackTrap Ark.jne (&self @noalias, Qword_t addr) @inline {
    if (self.stack_size == 0) return TRAP_STACK_UNDERFLOW;
    if (addr >= self.program.inst_count) return TRAP_INVALID_INST_ACCESS;

    if (self.stack[self.stack_size - 1] == 1) {
        self.ip++;
        self.stack[self.stack_size--] = 0;
        return TRAP_OK;
    }
    else if (self.stack[self.stack_size - 1] == 0) {
        self.ip = addr;
        return TRAP_OK;
    } else {
        return TRAP_INVALID_JNE;
    }
}

fn usz Ark.free(&self @noalias) {
    usz old_stack_size = self.stack_size;
    self.stack = {};
    io::printfn("STACK FREED\n");
    return old_stack_size;
}

fn void Ark.dump_stack(&self @noalias) {
    io::printf("\nStack cappacity: %d\nStack size: %d:\nStack pointer: %d\n",
            ARK_STACK_CAP, self.stack_size, self.ip);
    io::printn("Stack:");
    if (self.stack_size > 0) {
        foreach_r(elem : self.stack[:self.stack_size]) {
            io::printfn("\t%d", elem);
        }
    } else {
        io::printn("\t[empty]");
    }

    // io::printn(self.stack);
}

fn void Ark.dump_program(&self @noalias) {
    io::printn("\ninstructions:\n");
    foreach (inst : self.program.instructions[:self.program.inst_count]) {
        io::printfn("%s\t\t%s", inst.type.inst2str, inst.op);
    }

    io::printfn("Program size: %d", self.program.file_size);
    io::printfn("Number of instructions: %d", self.program.inst_count);
}
