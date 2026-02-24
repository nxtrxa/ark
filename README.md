# ARK

### linux only

tiny VM that i started developing just for fun based on "BM" virtual machine developed by @Alexey Kutepov <https://github.com/tsoding/bm>

```console
$ c3c build -> compile the project, generating the ark binary file

$c3c run -- [run|build] [file in] [file out] -- [args]

$ build/ark [run|build|dksm] [file in] [file out] -- [args]
```

as input you can pass a .kasm file that will be interpreted and generate a bytecode file .ark.

## Components

### KASM

Assembly language used by the Virtual Machine.

### DKSM

Disassembler for KASM
