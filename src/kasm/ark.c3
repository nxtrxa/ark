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
    foreach (idx, inst : self.program.instructions[:ARK_INST_LIMIT]) {
        if (!self.halted && self.ip < self.program.inst_count) {
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
    self.dump_stack();
    io::printfn("[%d INSTRUCTIONS EXECUTED]", inst_cout);
}

fn StackTrap Ark.execute_inst(&self){
    if (self.ip >= self.program.inst_count) return TRAP_INVALID_INST_ACCESS;

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

fn StackTrap Ark.push(&self @noalias, Qword_t op) @inline {
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

fn StackTrap Ark.inc(&self @noalias) {
    if (self.stack_size == 0) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size - 1]++;
    self.ip++;

    return TRAP_OK;
}

fn StackTrap Ark.dec(&self @noalias) {
    if (self.stack_size == 0) return TRAP_STACK_UNDERFLOW;

    self.stack[self.stack_size - 1]--;
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

macro usage() {
    io::eprintfn("USAGE: ark [build|run] [file in] [file out] -- [args]\nif [file out] is not provided, then it will have the same name as [file in] but with a .ark extension");
}

fn void Ark.parse_args(&self @noalias, String[] args) {
    if (args.len < 3) {
        io::eprintn("no arguments provided\nexpected at least two arguments.");
        usage();
        os::exit(1);
    }

    String[] cmd_args;
    String[] program_args;

    foreach (idx, arg : args) {
        if (arg.cmp("--")) {
            cmd_args = args[1:(idx - 1)];
            program_args = args[(idx + 1)..];
            break;
        } else {
            cmd_args = args[1:(args.len - 1)];
        }
    }

    self.program.mode.cast(cmd_args[0]);

    switch (self.program.mode) {
        case CmdMode.BUILD:
        case CmdMode.RUN:
            if (cmd_args.len > 2) {
                self.program.file_in = cmd_args[1];
                self.program.file_out = cmd_args[2];
                self.program.args = program_args;
            }
            else if (cmd_args.len == 2) {

                self.program.file_in = cmd_args[1];
                String file_out = self.program.file_in.replace(mem, "kasm", "ark");
                self.program.file_out = file_out;
                self.program.args = program_args;
            }
        case CmdMode.DKSM:
            if (cmd_args.len > 2) {
                self.program.file_in = cmd_args[1];
                self.program.file_out = cmd_args[2];
                self.program.args = program_args;
            }
            else if (cmd_args.len == 2) {
                self.program.file_in = cmd_args[1];
                String file_out = self.program.file_in.replace(mem, "ark", "kasm");
                self.program.file_out = file_out;
                self.program.args = program_args;
            }
    }

}

fn int Ark.build(&self @noalias) {
    if (!(is_ark_source_file(self.program.file_in))) {
        io::eprintfn("invalid [file in] type: %s, expected .kasm", self.program.file_in);
        os::exit(1);
    }
    if (!(is_ark_bytecode_file(self.program.file_out))) {
        io::eprintfn("invalid [file out] type: %s, expected .ark", self.program.file_in);
        os::exit(1);
    }

    if (catch exception = ark.compile(self.program.file_in)) {
        io::printfn("error: %s", exception);
        return 1;
    }
    if (catch exception = ark.lpif(self.program.file_out)) {
        io::printfn("error: %s", exception);
        return 1;
    }
    return 0;
}

fn int Ark.build_and_run(&self @noalias) {
    if (!(is_ark_bytecode_file(self.program.file_out))) {
        io::eprintfn("invalid file out type: %s, expected .ark", self.program.file_out);
        os::exit(1);
    }

    bool flag_dump_program = false;

    foreach (arg : self.program.args) {
        if (arg.cmp("dp")) {
            flag_dump_program = true;
        }
    }

    if (is_ark_bytecode_file(self.program.file_in)) {
        fault exception = @catch(ark.lpff(self.program.file_in));
        if (exception) {
            io::printfn("error: %s", exception);
            return 1;
        }
        self.run();
    }
    if (is_ark_source_file(self.program.file_in)) {
        fault exception = @catch(ark.compile(self.program.file_in));
        if (exception) {
            io::printfn("error: %s", exception);
            return 1;
        }
        if (catch lpif_exception = ark.lpif(self.program.file_out)) {
            io::printfn("error: %s", lpif_exception);
            return 1;
        }
        self.run();
    }
    if (flag_dump_program) {
        self.dump_program();
    }
    return 0;
}

<*
Disassembler for KASM
*>
fn int Ark.dksm(&self @noalias) {
    bool flag_print = false;

    foreach (arg : self.program.args) {
        if (arg.cmp("p")) {
            flag_print = true;
        }
    }

    fault lpff_exception = @catch(self.lpff(self.program.file_in));

    if (lpff_exception) {
        io::printfn("error: %s", lpff_exception);
        return 1;
    }

    File? f = file::open(self.program.file_out, "w");
    defer (void)f.close();

    if (catch exception = f) {
        io::printfn("error: %s", exception);
        return 1;
    }

    foreach (inst : self.program.instructions[:self.program.inst_count]) {
        if (flag_print) {
            io::printfn("%s %d", inst.type.inst2str, inst.op);
        }
        libc::fprintf(f.file, "%s %d\n", inst.type.inst2str.zstr_copy(tmem), inst.op);
    }

    io::printfn("file %s generated\n", self.program.file_out);

    return 0;
}
