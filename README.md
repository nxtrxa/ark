# ARK

### linux only

tiny VM that i started developing just for fun based on "BM" virtual machine developed by @Alexey Kutepov <https://github.com/tsoding/bm>

```console
$ c3c build -> compile the project, generating the ark binary file

$c3c run -- [run|build] [file in] [file out]

$ build/ark [run|build] [file in] [file out]

as input you can pass a .kasm file that will be interpreted and generate a bytecode file .ark.
