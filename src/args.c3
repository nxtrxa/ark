module ark;

import std;
import libc;

macro CmdMode.cast(&self, String arg) {
    if (!(arg.cmp("build")) && !(arg.cmp("run")) && !(arg.cmp("dksm"))) {
        io::eprintfn("invalid mode: %s\n", arg);
        os::exit(1);
    }
    if (arg == "build") *self = CmdMode.BUILD;
    if (arg == "run") *self = CmdMode.RUN;
    if (arg == "dksm") *self = CmdMode.DKSM;
}

fn bool is_ark_bytecode_file(String fpath) {
    if (fpath.ends_with(".ark")) {
        return true;
    } else {
        return false;
    }
}

fn bool is_ark_source_file(String fpath) {
    if (fpath.ends_with(".kasm")) {
        return true;
    } else {
        return false;
    }
}

fn void Ark.parse_args(&self @noalias, String[] args) {
    if (args.len < 3) {
        io::eprintn("no arguments provided\nexpected at least two arguments.");
        io::eprintfn("USAGE: ark [build|run] [file in] [file out] -- [args]\nif [file out] is not provided, then it will have the same name as [file in] but with a .ark extension");
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
                self.program.file_out = cmd_args[2];
            }
            else if (cmd_args.len == 2) {

                self.program.file_in = cmd_args[1];
                String file_out = self.program.file_in.replace(mem, "kasm", "ark");
                self.program.file_out = file_out;
                self.program.args = program_args;
            }
        case CmdMode.DKSM:

            self.program.file_in = cmd_args[1];
            String file_out = self.program.file_in.replace(mem, "ark", "kasm");
            self.program.file_out = file_out;
            self.program.args = program_args;
    }

}

fn int Ark.build(&self @noalias) {
    if (!(is_ark_source_file(self.program.file_in))) {
        io::eprintfn("invalid file in type: %s, expected .kasm", self.program.file_in);
        os::exit(1);
    }
    if (!(is_ark_bytecode_file(self.program.file_out))) {
        io::eprintfn("invalid file out type: %s, expected .ark", self.program.file_in);
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

    bool flag_dump_stack = false;
    bool flag_dump_program = false;

    foreach (arg : self.program.args) {
        if (arg.cmp("ds")) {
            flag_dump_stack = true;
        }
        if (arg.cmp("dp")) {
            flag_dump_program = true;
        }
    }

    io::printfn("args: %s", self.program.args);

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
    if (flag_dump_stack) {
        self.dump_stack();
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
