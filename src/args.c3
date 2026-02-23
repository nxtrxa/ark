module ark;

import std;

macro CmdMode.cast(&self, String arg) {
    if (!(arg.cmp("build")) && !(arg.cmp("run"))) {
        io::eprintfn("invalid mode: %s\n", arg);
        os::exit(1);
    }
    if (arg == "build") *self = CmdMode.BUILD;
    if (arg == "run") *self = CmdMode.RUN;
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
    if (args.len > 3) {
        self.program.mode.cast(args[1]);
        self.program.file_in = args[2];
        self.program.file_out = args[3];
        // self.program.args = args[4..];
    }
    else if (args.len == 3) {
        String file_out = args[2].replace(mem, "kasm", "ark");

        self.program.mode.cast(args[1]);
        self.program.file_in = args[2];
        self.program.file_out = file_out;
        // self.program.args = args[2..];
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
        io::eprintfn("invalid file out type: %s, expected .ark", self.program.file_in);
        os::exit(1);
    }

    if (is_ark_bytecode_file(self.program.file_in)) {
        fault exception = @catch(ark.lpff(self.program.file_in));
        if (exception) {
            io::printfn("error: %s", exception);
            return 1;
        }
        ark.run();
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
        ark.run();
    }
    return 0;
}


