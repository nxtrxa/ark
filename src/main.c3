module ark;

import std;
import libc;

Ark ark = {};

fn int main(String[] args) {
    if (args.len < 2) {
        io::eprintn("no arguments");
        io::eprintfn("USAGE: ark [build|run] [file in] [file out] -- [args]");
        os::exit(1);
    }
    switch (args[1]) {
        case Cmd.BUILD.to_str:
            if (args.len < 4) {
                io::eprintn("BUILD: expects 2 arguments");
                io::eprintfn("USAGE: ark [build] [file in] [file out] -- [args]");
                os::exit(1);
            }
            if (is_ark_source_file(args[2])) {
                if (catch excuse = ark.compile(args[2])) {
                    io::eprintn(excuse);
                    os::exit(1);
                }
                if ( catch excuse = ark.lpif(&ark.program, args[3])) {
                    io::eprintn(excuse);
                    os::exit(1);
                }
            } else {
                io::eprintn("BUILD: expects a .ark source file");
                os::exit(1);
            }
        case Cmd.RUN.to_str:
            if (is_ark_bytecode_file(args[2])) {
                if (args.len < 3) {
                    io::eprintn("RUN: expects 2 arguments");
                    io::eprintfn("USAGE: ark [run] [file.ark in]|[file.kasm in] [file.ark out] -- [args]");
                    os::exit(1);
                }
                if (try ark.lpff(args[2])){
                    ark.run();
                    ark.dump_stack();
                    // ark.dump_program();
                }
                break;
            }
            else if (is_ark_source_file(args[2])) {
                if (args.len < 4) {
                    io::eprintn("RUN: expects 2 arguments");
                    io::eprintfn("USAGE: ark [run] [file.ark in]|[file.kasm in] [file.ark out] -- [args]");
                    os::exit(1);
                }
                if (catch excuse = ark.compile(args[2])) {
                    break;
                }

                ark.run();

                if ( catch excuse = ark.lpif(&ark.program, args[3])) {
                    io::eprintn(excuse);
                    os::exit(1);
                }

                ark.dump_stack();
                // ark.dump_program();
                break;
            }
            else {
                io::eprintn("RUN: expects a .kasm|.ark file");
                os::exit(1);
            }
        default:
            io::eprintfn("INVALID ARGUMENT: %s", args[1]);
            io::eprintfn("USAGE: ark [build|run] [file in] [file out] -- [args]");
            os::exit(1);
    }
    return 0;
}
