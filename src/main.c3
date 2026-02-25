module ark;

import std;
import libc;

Ark ark = {};

fn int main(String[] args) {
    ark.parse_args(args);
    switch (ark.program.mode) {
        case CmdMode.BUILD:
            return ark.build();
        case CmdMode.RUN:
            return ark.build_and_run();
        case CmdMode.DKSM:
            return ark.dksm();
        default:
            io::eprintfn("INVALID ARGUMENTS: %s", args);
            os::exit(1);
    }
}
