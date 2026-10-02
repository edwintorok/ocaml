[![Previous](previous_motif.svg)](debugger.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](profil.html)

* * *

# Chapter 21 Native debugging (gdb, lldb)

  * [21.1 Overview](native-debugger.html#s%3Anative-debugger-overview)
  * [21.2 Compiling for Debugging](native-debugger.html#s%3Anative-debugger-compilation)
  * [21.3 Using GDB](native-debugger.html#s%3Anative-debugger-gdb)
  * [21.4 Using LLDB](native-debugger.html#s%3Anative-debugger-lldb)

## ﻿21.1 Overview

This chapter describes the support for debugging OCaml executables built with
the native-code compiler ocamlopt, using standard native debuggers like GDB or
LLDB. We will call this _native debugging_ , in contrast to bytecode debugging
supported via ocamldebug (chapter [20](debugger.html#c%3Adebugger)).

Native debugging is supported on Linux, macOS, and FreeBSD platforms. Windows
support is not currently available.

### ﻿21.1.1 DWARF

OCaml uses the [DWARF](http://dwarfstd.org/) debugging format to describe the
debugging information it generates. DWARF is a debugging information format
used by many compilers and debuggers to support source-level debugging. It is
used in the ELF and Mach-O executable formats.

The debugging information includes two key components:

Call Frame Information (CFI): Describes how to unwind the call stack to
generate backtraces. OCaml’s CFI information spans across language boundaries-
from OCaml code into C runtime functions and through Foreign Function
Interface (FFI) calls when the foreign language also provides CFI data.

Source Line Mapping: Maps each machine instruction back to its originating
source location, enabling debuggers to display OCaml source code and
supporting source-level stepping. For example, the instruction at memory
address 0xdeadbeef might map to myprogram.ml:42.

OCaml defines its own calling convention detailing how arguments are passed to
functions, how values are returned from functions, and how registers are used.
This information is architecture specific and is documented in the source code
files _asmcomp/ <ARCH>/proc.ml_ for each architecture.

### ﻿21.1.2 Name Mangling

When OCaml compiles source code, it transforms language constructs like
functions and module names into _mangled names_ that appear in the final
executable. These mangled names serve several purposes:

  * They ensure symbol uniqueness in the compiled binary 
  * They encode module structure and namespace information 
  * They appear in debugger output such as backtraces and symbol lists 
  * They can be used to set breakpoints when source file information isn’t available 

Current mangling scheme for OCaml 5.3 onwards:

  * Linux: caml<MODULE_NAME>.<FUNCTION_NAME>_<NNN>
  * macOS and Windows MSVC: caml<MODULE_NAME>$<FUNCTION_NAME>_<NNN>

where NNN is a unique generated number.

Example: A function fib in module MyMath might become camlMyMath.fib_271 on
Linux or camlMyMath$fib_271 on macOS.

Note: OCaml versions before 5.1.1 used double underscores:
caml<MODULE_NAME>__<FUNCTION_NAME>_<NNN>.

### ﻿21.1.3 Frame Pointers

Frame pointers provide an alternative method for debuggers to walk the call
stack. OCaml supports frame pointers on AMD64 and ARM64 platforms.

With frame pointers, each function maintains a _frame pointer_ that points to
the base of its stack frame (the memory region allocated for that function’s
local variables and call information also known as the activation frame or
activation record). By chaining these pointers together with return addresses,
debuggers can reconstruct the complete call stack.

Frame pointers are optional (not necessary for debugging), and must be
explicitly enabled during compiler configuration (see Profiling section
[22.2.2](profil.html#s%3Aocamlprof-compiling-perf) for details).

## ﻿21.2 Compiling for Debugging

Before debugging OCaml programs, the native compiler ocamlopt must be
installed with CFI support, which it is by default. You can also explicitly
control this with the \--enable-cfi configure flag when building the compiler.

To perform source-level debugging, compile all code with the -g flag, this
records DWARF information for exception backtraces, and generates line
information for mapping between assembly and source locations in OCaml.
Compiling with -g entails no runtime penalty but will generate larger binaries
as they include sections for debugging information. Note that OCaml libraries
and other dependencies, need to be compiled with DWARF debugging information,
failure to do so will lose source-level debugging features for those sections
of code.

Debuggers need access to source files referenced in the DWARF information. For
dependencies, consider using opam’s build directory preservation:

    
    
    # First tell opam to keep the source code
    $ export OPAMKEEPBUILDDIR=1
    
    # Then, reinstall the packages to force redownloading the sources
    $ opam switch reinstall
    
    # Source code for packages will appear inside the opam switch
    # in a build directory. e.g. _opam/.opam-switch/build/ for a
    # local switch or ~/.opam/<switch_name>/.opam-switch/build
    

The following sections demonstrate debugging OCaml programs with GDB and LLDB,
showing common workflows and expected outputs.

## ﻿21.3 Using GDB

Here we walk through debugging a simple OCaml program using GDB on Linux,
showing the commands to use and the expected outputs. Note this session uses
Ubuntu 24.04 LTS on AMD64 with OCaml 5.4.

Consider the following program:

(* fib.ml *) let rec fib n = if n = 0 then 0 else if n = 1 then 1 else fib
(n-1) + fib (n-2) let main () = let r = fib 20 in Printf.printf "fib(20) = %d"
r let _ = main ()

Compile this program with ocamlopt like so:

    
    
    $ ocamlopt -g -o fib.exe fib.ml
    $ ./fib.exe 20
    fib(20) = 6765
    

When run this program prints the 20th Fibonacci number. The use of recursion
is an excuse to inspect the call stack. Startup a GDB session for this
program:

    
    
    $ gdb ./fib.exe
    

Breakpoints can be set using either the mangled names produced by the compiler
or a combination of file name and line number. For example:

    
    
    (gdb) break camlFib.fib_     # press tab
    (gdb) break camlFib.fib_271  # 271 happens to be the unique number generated
    Breakpoint 1 at 0x3cd50: file fib.ml, line 2.
    
    (gdb) break fib.ml:7         # breakpoint for main function
    Breakpoint 2 at 0x3cdc0: file fib.ml, line 7.
    

Now we can run the program and print a backtrace.

    
    
    (gdb) run
    Starting program: fib.exe
    [Thread debugging using libthread_db enabled]
    Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
    
    Breakpoint 2, camlFib.main_273 () at fib.ml:7
    7	let main () =
    (gdb) continue
    Continuing.
    
    Breakpoint 1, camlFib.fib_271 () at fib.ml:2
    2	let rec fib n =
    (gdb) backtrace
    #0  camlFib.fib_270 () at fib.ml:2
    #1  0x0000555555590de1 in camlFib.main_273 () at fib.ml:7
    #2  0x0000555555590e86 in camlFib.entry () at fib.ml:11
    #3  0x000055555558eaa7 in caml_program ()
    #4  <signal handler called>
    #5  0x00005555555de126 in caml_startup_common (pooling=<optimised out>, argv=0x7fffffffe3f8)
        at runtime/startup_nat.c:132
    #6  caml_startup_common (argv=0x7fffffffe3f8, pooling=<optimised out>) at runtime/startup_nat.c:88
    #7  0x00005555555de19f in caml_startup_exn (argv=<optimised out>) at runtime/startup_nat.c:139
    #8  caml_startup (argv=<optimised out>) at runtime/startup_nat.c:144
    #9  caml_main (argv=<optimised out>) at runtime/startup_nat.c:151
    #10 0x000055555558e892 in main (argc=<optimised out>, argv=<optimised out>) at runtime/main.c:37
    

There is also basic support for printing OCaml values using the built-in
Python scripting in GDB and
[tools/gdb.py](https://github.com/ocaml/ocaml/blob/trunk/tools/gdb.py). Either
find that file in your opam switch e.g.  /.opam/5.4.0/.opam-
switch/sources/ocaml-compiler.5.4.0/tools/gdb.py or download it from GitHub.
Then load it into GDB using ‘source‘.

    
    
    (gdb) source ~/.opam/5.4.0/.opam-switch/sources/ocaml-compiler.5.4.0/tools/gdb.py
    OCaml support module loaded. Values of type 'value' will now
    print as OCaml values, there is a $Array() convenience function,
    and an 'ocaml' command is available for heap exploration
    (see 'help ocaml' for more information).
    
    (gdb) p (value)$rax
    $1 = caml:14
    
    

We can also print other kinds of OCaml values. In order to illustrate this,
consider the following program:

(* test_blocks.ml *) type t = {s : string; i : int} let main a b =
print_endline "Hello, world!"; print_endline a; print_endline b.s let _ = main
"foo" {s = "bar"; i = 42}

Compile this program with ocamlopt and load it into GDB:

    
    
    $ ocamlopt -g -o test_blocks.exe test_blocks.ml
    $ gdb ./test_blocks.exe
    (gdb) source ~/.opam/5.4.0/.opam-switch/sources/ocaml-compiler.5.4.0/tools/gdb.py
    ...
    (gdb) break camlTest_blocks.main_273
    Breakpoint 1 at 0x16db0: file test_blocks.ml, line 4.
    (gdb) run
    ...
    Breakpoint 1, camlTest_blocks.main_273 () at test_blocks.ml:4
    4	let main a b =
    (gdb) p (value)$rax      # Print out the first argument to main
    $1 = caml(-):'foo'<3>
    (gdb) p (value)$rbx      # Then print the second argument
    $2 = caml(-):('bar', 42) = {caml(-):'bar'<3>, caml:42}
    

Note the use of AMD64 register names: $rax and $rbx to access the first and
second arguments to a function. This follows the OCaml calling convention on
AMD64 where $rax to $r13 hold OCaml function arguments and $rax holds function
results. Consult the asmcomp/<ARCH>/proc.ml file for a specific architecture
for further information about OCaml calling conventions.

Executables may not include exact information about where to find the source
code used to build them for various reasons. In GDB this appears as an absence
of source listings and a ‘No such file or directory‘ warning message. In this
case GDB supports different ways to tell it where to find the sources. Consult
GDB’s [Source
Path](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Source-Path.html)
documentation for full details.

Returning to fib.exe from earlier, the source file has been copied to
/tmp/fib.ml where GDB will not find it. Here we use the GDB command directory
to tell GDB where to find the source files for fib.ml and the OCaml standard
library.

    
    
    $ gdb ./fib.exe
    ...
    (gdb) break camlFib.main_276
    (gdb) break camlStdlib__Printf.fprintf_431
    (gdb) run
    ...
    Breakpoint 1, 0x00005555555921b0 in camlFib.main () at fib.ml:7
    warning: 9	fib.ml: No such file or directory
    # Update directories to search for source files for fib.ml and OCaml
    (gdb) directory /tmp ~/.opam/5.4.0/.opam-switch/sources/ocaml-compiler.5.4.0/
    Source directories searched: /tmp:/home/user/.opam/5.4.0/.opam-switch/sources/ocaml-compiler.5.4.0:$cdir:$cwd
    (gdb) list
    4	  else if n = 1 then 1
    5	  else fib (n-1) + fib (n-2)
    6
    7	let main () =
    8	  let r = fib 20 in
    9	  Printf.printf "fib(20) = %d" r
    10
    11	let _ = main ()
    

### ﻿21.3.1 GDB Commands

Summary of interesting OCaml specific GDB commands:

break locspec

     Set a breakpoint at all of the code locations matching locspec, e.g., Using the mangled OCaml names or specifying the linenum in the source file as filename:linenum.
backtrace

     Print the backtrace of the entire stack. This will include OCaml source references identifying which stack frame maps to a source location, e.g., fib.ml:4.
disassemble addresses

     Display a range of addresses as machine instructions. Typically used with the mangled OCaml names to display the assembly for a function.
info frame

     This command prints a verbose description of the selected stack frame.
list linenum

     Print lines centered around line number linenum in the current source file. This will print the source code for OCaml and the OCaml runtime written in C.
directory dirname

     Add directory dirname to the front of the source path, several directory names can be supplied separated by :. Useful when directories change between compilation and a debug session.

See the [Debugging with
GDB](https://sourceware.org/gdb/current/onlinedocs/gdb.html/) documentation
for more details. In general the features described above work with OCaml,
failing that GDB will fall back to assembly language debugging. GDB is
expected to work on all supported Linux architectures.

## ﻿21.4 Using LLDB

Here we will walk through debugging the earlier fib example using LLDB on
Linux. Startup an LLDB session using the fib.exe from earlier. Note this
session uses Ubuntu 24.04 LTS on ARM64 with OCaml 5.4.

    
    
    $ lldb ./fib.exe
    Current executable set to 'fib.exe' (aarch64).
    (lldb)
    

Breakpoints can be set using the OCaml mangled names or using a combination of
file name and line number. For example:

    
    
    (lldb) breakpoint set -n camlFib.fib        # press tab for autocomplete
    (lldb) breakpoint set -n camlFib.fib_271
    Breakpoint 2: where = fib.exe`camlFib.fib_271 + 80, address = 0x0000000000052360
    (lldb) breakpoint set -f fib.ml -l 7         # breakpoint for line 7 in fib.ml
    Breakpoint 2: where = fib.exe`camlFib.main_272, address = 0x0000000000051088
    (lldb)
    

Now we can run the program.

    
    
    (lldb) run
    ...
    Process 11391 stopped
    * thread #1, name = 'fib.exe', stop reason = breakpoint 2.1
        frame #0: 0x0000aaaaaaaf1088 fib.exe`camlFib.main_272 at fib.ml:7
       4   	  else if n = 1 then 1
       5   	  else fib (n-1) + fib (n-2)
       6
    -> 7   	let main () =
       8   	  let r = fib 20 in
       9   	  Printf.printf "fib(20) = %d" r
       10
    ...
    (lldb) continue
    Process 28032 resuming
    Process 28032 stopped
    * thread #1, name = 'fib.exe', stop reason = breakpoint 2.1
        frame #0: 0x0000aaaaaaaf2360 fib.exe`camlFib.fib_271 at fib.ml:5
       2   	let rec fib n =
       3   	  if n = 0 then 0
       4   	  else if n = 1 then 1
    -> 5   	  else fib (n-1) + fib (n-2)
       6
       7   	let main () =
       8   	  let r = fib 20 in
    
    (lldb) bt               # Print a backtrace
    * thread #1, name = 'fib.exe', stop reason = breakpoint 2.1
      * frame #0: 0x0000aaaaaaaf2360 fib.exe`camlFib.fib_271 at fib.ml:5
        frame #1: 0x0000aaaaaaaf23d0 fib.exe`camlFib.main_273 at fib.ml:8
        frame #2: 0x0000aaaaaaaf2490 fib.exe`camlFib.entry at fib.ml:11
        frame #3: 0x0000aaaaaaaef748 fib.exe`caml_program + 480
        frame #4: 0x0000aaaaaab4ab90 fib.exe`caml_start_program + 132
        frame #5: 0x0000aaaaaab4a5f8 fib.exe`caml_startup_common [inlined] caml_startup_common(pooling=-1430712272, argv=0x0000000000000010) at startup_nat.c:127:9
        frame #6: 0x0000aaaaaab4a528 fib.exe`caml_startup_common(argv=0x0000000000000010, pooling=-1430712272) at startup_nat.c:86:7
        frame #7: 0x0000aaaaaab4a670 fib.exe`caml_main [inlined] caml_startup_exn(argv=<unavailable>) at startup_nat.c:134:10
        frame #8: 0x0000aaaaaab4a66c fib.exe`caml_main [inlined] caml_startup(argv=<unavailable>) at startup_nat.c:139:15
        frame #9: 0x0000aaaaaab4a66c fib.exe`caml_main(argv=<unavailable>) at startup_nat.c:146:3
        frame #10: 0x0000aaaaaaaef3d0 fib.exe`main(argc=<unavailable>, argv=<unavailable>) at main.c:37:3
        frame #11: 0x0000fffff7d784c4 libc.so.6`__libc_start_call_main(main=(fib.exe`main at main.c:31:1), argc=1, argv=0x0000fffffffffc98) at libc_start_call_main.h:58:16
        frame #12: 0x0000fffff7d78598 libc.so.6`__libc_start_main_impl(main=0x0000aaaaaaba0e68, argc=1, argv=0x0000fffffffffc98, init=<unavailable>, fini=<unavailable>, rtld_fini=<unavailable>, stack_end=<unavailable>) at libc-start.c:360:3
        frame #13: 0x0000aaaaaaaef470 fib.exe`_start + 48
    

There is basic support for printing OCaml values using the built-in Python
scripting in LLDB and
[tools/lldb.py](https://github.com/ocaml/ocaml/blob/trunk/tools/lldb.py).
Either find that file in your opam switch e.g.  /.opam/5.4.0/.opam-
switch/sources/ocaml-compiler.5.4.0/tools/lldb.py or download it from github.
Then load it into LLDB using command.

    
    
    (lldb) command script import ~/.opam/5.4.0/.opam-switch/sources/ocaml-compiler.5.4.0/tools/lldb.py
    OCaml support module loaded. Values of type 'value' will now
    print as OCaml values, and an 'ocaml' command is available for
    heap exploration (see 'help ocaml' for more information).
    (lldb)  p (value)$x0
    (value) 41 caml:20
    (lldb)
    

Note: above we are using an ARM64 Linux machine, so our first argument is
passed in the first register x0.

We can also print out all kinds of OCaml values. Reusing the test_blocks.exe
program, startup a new LLDB session:

    
    
    $ lldb ./test_blocks.exe
    ...
    (lldb) command script import ~/.opam/5.4.0/.opam-switch/sources/ocaml-compiler.5.4.0/tools/gdb.py
    OCaml support module loaded. Values of type 'value' will now
    print as OCaml values, and an 'ocaml' command is available for
    heap exploration (see 'help ocaml' for more information).
    (lldb) breakpoint set -n camlTest_blocks.main_274
    Breakpoint 1: where = test_blocks.exe`camlTest_blocks.main_274 + 44, address = 0x000000000001a6fc
    (lldb) run
    ...
    Process 15536 stopped
    * thread #1, name = 'test_blocks.exe', stop reason = breakpoint 1.1
        frame #0: 0x0000aaaaaaaba6fc test_blocks.exe`camlTest_blocks.main_274 at test_blocks.ml:5
       2   	type t = {s : string; i : int}
       3
       4   	let main a b =
    -> 5   	  print_endline "Hello, world!";
       6   	  print_endline a;
       7   	  print_endline b.s
       8
    ...
    (lldb) p (value)$x0
    (value) 187649984957416 caml(-):'Hello, world!'<13>
    (lldb) p (value)$x1
    (value) 187649984957360 caml(-):('bar', 42)
    

Here we use the ARM64 registers named $x0 and $x1 to access the first and
second arguments to a function. This follows the OCaml calling convention on
ARM64 where $x0 to $x15 hold OCaml function arguments. Consult the
asmcomp/<ARCH>/proc.ml file for a specific architecture for further
information about OCaml calling conventions.

LLDB supports a feature for specifying how to find the sources. In an LLDB
session, using settings set target.source-map /tmp/build /my/src/path remaps
the build directory to a source directory and supports multiple pairs of from
to.

For example, copying the source file fib.ml to /tmp/fib.ml and using an opam
switch for OCaml 5.4.

    
    
    $ lldb ./fib.exe
    (lldb) target create "./fib.exe"
    Current executable set to '/home/user/fib.exe' (x86_64).
    (lldb) br s -n camlStdlib__Printf.fprintf_431
    Breakpoint 1: where = fib.exe`camlStdlib__Printf.fprintf_431 + 16, address = 0x000000000007ddb0
    (lldb) br s -f fib.ml -l 9
    Breakpoint 2: where = fib.exe`camlFib.main_276 + 66, address = 0x00000000000482c2
    (lldb) run
    Process 95112 launched: '/home/user/fib.exe' (x86_64)
    Process 95112 stopped
    * thread #1, name = 'fib.exe', stop reason = breakpoint 1.1
        frame #0: 0x00005555555d1db0 fib.exe`camlStdlib__Printf.fprintf_431 at printf.ml:27:21
    # No source listing displayed for printf.ml file.
    $ settings set target.source-map /home/user/ /tmp /home/user/.opam/5.4.0/.opam-switch/build/ocaml-variants.5.4.0/ /home/user/.opam/5.4.0/.opam-switch/sources/ocaml-variants.5.4.0/
    

### ﻿21.4.1 LLDB Commands

Summary of interesting OCaml specific LLDB commands:

breakpoint set -n symbol

     Set a breakpoint at code location matching symbol, e.g, Using the mangled OCaml name.
breakpoint set -f filename -l linenum

     Set a breakpoint at linenum in filename, e.g., fib.ml:7
breakpoint set -a address

     Set a breakpoint on a memory address.
backtrace

     Print the backtrace of the entire stack. This will include OCaml source references identifying which stack frame maps to a source location.
disassemble

     Disassemble specified instructions in the current target. Useful options include -n plus mangled OCaml name to disassemble a specific function and -a plus an address to disassemble function containing this address.
frame info

     List information about the current stack frame in the current thread.
source

     Commands for examining source code described by debug information for the current target process.
settings set target.source-mapfrom to

     Remaps from source paths to a new source path which is used when locating source code to display alongside a debugged program. Multiple pairs of from to mappings are supported.

In general the features described above work with OCaml, failing that LLDB
will fall back to assembly language debugging. LLDB is expected to work on all
supported Linux architectures.

* * *

[![Previous](previous_motif.svg)](debugger.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](profil.html)

