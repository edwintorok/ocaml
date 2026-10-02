[![Previous](previous_motif.svg)](toplevel.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](native.html)

* * *

# Chapter 15 The runtime system (ocamlrun)

  * [15.1 Overview](runtime.html#s%3Aocamlrun-overview)
  * [15.2 Options](runtime.html#s%3Aocamlrun-options)
  * [15.3 Dynamic loading of shared libraries](runtime.html#s%3Aocamlrun-dllpath)
  * [15.4 Common errors](runtime.html#s%3Aocamlrun-common-errors)

The ocamlrun command executes bytecode files produced by the linking phase of
the ocamlc command.

## ﻿15.1 Overview

The ocamlrun command comprises three main parts: the bytecode interpreter,
that actually executes bytecode files; the memory allocator and garbage
collector; and a set of C functions that implement primitive operations such
as input/output.

The usage for ocamlrun is:

    
    
            ocamlrun options bytecode-executable arg1 ... argn
    

The first non-option argument is taken to be the name of the file containing
the executable bytecode. (That file is searched in the executable path as well
as in the current directory.) The remaining arguments are passed to the OCaml
program, in the string array Sys.argv. Element 0 of this array is the name of
the bytecode executable file; elements 1 to n are the remaining arguments arg1
to argn.

> Windows: On Windows, the OCaml runtime expands the * and ? wildcards in
> arguments before anything else. The string array Sys.argv is constructed
> using the expanded arguments. To avoid this behaviour, a custom entry point
> can be written in C, as outlined in section
> [23.7.5](intfc.html#ss%3Amain-c).

As mentioned in chapter [13](comp.html#c%3Acamlc), the bytecode executable
files produced by the ocamlc command are self-executable, and manage to launch
the ocamlrun command on themselves automatically. That is, assuming a.out is a
bytecode executable file,

    
    
            a.out arg1 ... argn
    

works exactly as

    
    
            ocamlrun a.out arg1 ... argn
    

Notice that it is not possible to pass options to ocamlrun when invoking a.out
directly.

> Windows: Under several versions of Windows, bytecode executable files are
> self-executable only if their name ends in .exe. It is recommended to always
> give .exe names to bytecode executables, e.g. compile with ocamlc -o
> myprog.exe ... rather than ocamlc -o myprog ....

## ﻿15.2 Options

The following command-line options are recognized by ocamlrun.

-b
     When the program aborts due to an uncaught exception, print a detailed “back trace” of the execution, showing where the exception was raised and which function calls were outstanding at this point. The back trace is printed only if the bytecode executable contains debugging information, i.e. was compiled and linked with the -g option to ocamlc set. This is equivalent to setting the b flag in the OCAMLRUNPARAM environment variable (see below). 
-config
     Print the version number of ocamlrun and a detailed summary of its configuration, then exit. 
-I dir
     Search the directory dir for dynamically-loaded libraries, in addition to the standard search path (see section 15.3). 
-m
     Print the magic number of the bytecode executable given as argument and exit. 
-M
     Print the magic number expected for bytecode executables by this version of the runtime and exit. 
-p
     Print the names of the primitives known to this version of ocamlrun and exit. 
-t
     Increments the trace level for the debug runtime (ignored otherwise). 
-v
     Direct the memory manager to print some progress messages on standard error. This is equivalent to setting v=61 in the OCAMLRUNPARAM environment variable (see below). 
-version
     Print version string and exit. 
-vnum
     Print short version number and exit.

The following environment variables are also consulted:

CAML_LD_LIBRARY_PATH

     Additional directories to search for dynamically-loaded libraries (see section 15.3).
OCAMLLIB

     The directory containing the OCaml standard library. (If OCAMLLIB is not set, CAMLLIB will be used instead.) Used to locate the ld.conf configuration file for dynamic loading (see section 15.3). If not set, default to the library directory specified when compiling OCaml.
OCAMLRUNPARAM

     Set the runtime system options and garbage collection parameters. (If OCAMLRUNPARAM is not set, CAMLRUNPARAM will be used instead.) This variable must be a sequence of parameter specifications separated by commas. For convenience, commas at the beginning of the variable are ignored, and multiple runs of commas are interpreted as a single one. A parameter specification is an option letter followed by an = sign, a decimal number (or an hexadecimal number prefixed by 0x), and an optional multiplier. The options are documented below; the options l, m, M, n, o, s, v correspond to fields of the control record documented in [Module Gc](libref/Gc.html). 

b

     (backtrace) Trigger the printing of a stack backtrace when an uncaught exception aborts the program. An optional argument can be provided: b=0 turns backtrace printing off; b=1 is equivalent to b and turns backtrace printing on; b=2 turns backtrace printing on and forces the runtime system to load debugging information at program startup time instead of at backtrace printing time. b=2 can be used if the runtime is unable to load debugging information at backtrace printing time, for example if there are no file descriptors available. 
c

     (cleanup_on_exit) If set to 1, the runtime will be shut down gracefully on exit (see caml_shutdown in section [23.7.6](intfc.html#ss%3Ac-embedded-code)). The option also enables pooling (as in caml_startup_pooled). This mode can be used to detect leaks with a third-party memory debugger. No attempt is made to shut down the runtime if there is more than one domain alive at exit. 
d

     (max_domains) Maximum number of domains that can be active concurrently. Defaults to 128 on 64-bit platforms and 16 on 32-bit platforms. 
e

     (runtime_events_log_wsize) Size of the per-domain runtime events ring buffers in log powers of two words. Defaults to 16, giving 64k word or 512kb buffers on 64-bit systems. 
l

     (stack_limit) The limit (in words) of the stack size. This is relevant to both the byte-code runtime and the native code runtime: OCaml always uses its own stack and not the operating system’s stack. 
S

     (thread_system_stack_size) The minimum system stack size (in bytes) for new threads. This can be useful for threads that call FFI code that needs a larger system stack. 
m

     (custom_minor_ratio) Bound on floating garbage for out-of-heap memory held by custom values in the minor heap. A minor GC is triggered when this much memory is held by custom values located in the minor heap. Expressed as a percentage of minor heap size. Default: 100\. Note: this only applies to values allocated with caml_alloc_custom_mem. 
M

     (custom_major_ratio) Target ratio of floating garbage to major heap size for out-of-heap memory held by custom values (e.g. bigarrays) located in the major heap. The GC speed is adjusted to try to use this much memory for dead values that are not yet collected. Expressed as a percentage of major heap size. Default: 44\. Note: this only applies to values allocated with caml_alloc_custom_mem. 
n

     (custom_minor_max_size) Maximum amount of out-of-heap memory for each custom value allocated in the minor heap. When a custom value is allocated on the minor heap and holds more than this many bytes, only this value is counted against custom_minor_ratio and the rest is directly counted against custom_major_ratio. Default: 8192 bytes. Note: this only applies to values allocated with caml_alloc_custom_mem. 
o

     (space_overhead) The main major GC speed setting. See the Gc module documentation for details. 
p

     (parser trace) Turn on debugging support for ocamlyacc-generated parsers. When this option is on, the pushdown automaton that executes the parsers prints a trace of its actions. This option takes no argument. 
R

     (randomize) Turn on randomization of all hash tables by default (see [Hashtbl](libref/Hashtbl.html)). This option takes no argument. 
s

     (minor_heap_size) Size of the minor heap. (in words) 
t

     Set the trace level for the debug runtime (ignored by the standard runtime). 
v

     (verbose) What GC messages to print to stderr. This is a sum of values selected from the following: 

1 (= 0x001)

     Start and end of major GC cycle. 
2 (= 0x002)

     Minor collection and major GC slice. 
4 (= 0x004)

     Growing and shrinking of the heap. 
8 (= 0x008)

     Resizing of stacks and memory manager tables. 
16 (= 0x010)

     Heap compaction. 
32 (= 0x020)

     Change of GC parameters. 
64 (= 0x040)

     Computation of major GC slice size. 
128 (= 0x080)

     Calling of finalization functions 
256 (= 0x100)

     Startup messages (loading the bytecode executable file, resolving shared libraries). 
512 (= 0x200)

     Computation of compaction-triggering condition. 
1024 (= 0x400)

     Output GC statistics at program exit. 
2048 (= 0x800)

     GC debugging messages. 
4096 (= 0x1000)

     Address space reservation changes. 
V

     (verify_heap) runs an integrity check on the heap just after the completion of a major GC cycle 
W

     Print runtime warnings to stderr (such as Channel opened on file dies without being closed, unflushed data, etc.) 

The multiplier is k, M, or G, for multiplication by 210, 220, and 230
respectively. If the option letter is not recognized, the whole parameter is
ignored; if the equal sign or the number is missing, the value is taken as 1;
if the multiplier is not recognized, it is ignored.

For example, on a 32-bit machine, under bash the command

    
    
            export OCAMLRUNPARAM='b,s=256k,v=0x015'
    

tells a subsequent ocamlrun to print backtraces for uncaught exceptions, set
its initial minor heap size to 1 megabyte and print a message at the start of
each major GC cycle, when the heap size changes, and when compaction is
triggered.

CAMLRUNPARAM

     If OCAMLRUNPARAM is not found in the environment, then CAMLRUNPARAM will be used instead. If CAMLRUNPARAM is also not found, then the default values will be used.
PATH

     List of directories searched to find the bytecode executable file. 

## ﻿15.3 Dynamic loading of shared libraries

On platforms that support dynamic loading, ocamlrun can link dynamically with
C shared libraries (DLLs) providing additional C primitives beyond those
provided by the standard runtime system. The names for these libraries are
provided at link time as described in section
[23.1.4](intfc.html#ss%3Adynlink-c-code)), and recorded in the bytecode
executable file; ocamlrun, then, locates these libraries and resolves
references to their primitives when the bytecode executable program starts.

The ocamlrun command searches shared libraries in the following directories,
in the order indicated:

  1. Directories specified on the ocamlrun command line with the -I option. 
  2. Directories specified in the CAML_LD_LIBRARY_PATH environment variable. 
  3. Directories specified at link-time via the -dllpath option to ocamlc. (These directories are recorded in the bytecode executable file.) 
  4. Directories specified in the file ld.conf. This file resides in the OCaml standard library directory, and lists directory names (one per line) to be searched. Typically, it contains only one line naming the stublibs subdirectory of the OCaml standard library directory. Users can add there the names of other directories containing frequently-used shared libraries; however, for consistency of installation, we recommend that shared libraries are installed directly in the system stublibs directory, rather than adding lines to the ld.conf file. ocamlrun will add lines from ld.conf files found in the directories pointed to by OCAMLLIB, CAMLLIB and the standard library directory, in that order. 
  5. Default directories searched by the system dynamic loader. Under Unix, these generally include /lib and /usr/lib, plus the directories listed in the file /etc/ld.so.conf and the environment variable LD_LIBRARY_PATH. Under Windows, these include the Windows system directories, plus the directories listed in the PATH environment variable. 

## ﻿15.4 Common errors

This section describes and explains the most frequently encountered error
messages.

filename: no such file or directory

     If filename is the name of a self-executable bytecode file, this means that either that file does not exist, or that it failed to run the ocamlrun bytecode interpreter on itself. The second possibility indicates that OCaml has not been properly installed on your system.
Cannot exec ocamlrun

     (When launching a self-executable bytecode file.) The ocamlrun could not be found in the executable path. Check that OCaml has been properly installed on your system.
Cannot find the bytecode file

     The file that ocamlrun is trying to execute (e.g. the file given as first non-option argument to ocamlrun) either does not exist, or is not a valid executable bytecode file.
Truncated bytecode file

     The file that ocamlrun is trying to execute is not a valid executable bytecode file. Probably it has been truncated or mangled since created. Erase and rebuild it.
Uncaught exception

     The program being executed contains a “stray” exception. That is, it raises an exception at some point, and this exception is never caught. This causes immediate termination of the program. The name of the exception is printed, along with its string, byte sequence, and integer arguments (arguments of more complex types are not correctly printed). To locate the context of the uncaught exception, compile the program with the -g option and either run it again under the ocamldebug debugger (see chapter [20](debugger.html#c%3Adebugger)), or run it with ocamlrun -b or with the OCAMLRUNPARAM environment variable set to b=1.
Out of memory

     The program being executed requires more memory than available. Either the program builds excessively large data structures; or the program contains too many nested function calls, and the stack overflows. In some cases, your program is perfectly correct, it just requires more memory than your machine provides. In other cases, the “out of memory” message reveals an error in your program: non-terminating recursive function, allocation of an excessively large array, string or byte sequence, attempts to build an infinite list or other data structure, …

To help you diagnose this error, run your program with the -v option to
ocamlrun, or with the OCAMLRUNPARAM environment variable set to v=63. If it
displays lots of “Growing stack…” messages, this is probably a looping
recursive function. If it displays lots of “Growing heap…” messages, with the
heap size growing slowly, this is probably an attempt to construct a data
structure with too many (infinitely many?) cells. If it displays few “Growing
heap…” messages, but with a huge increment in the heap size, this is probably
an attempt to build an excessively large array, string or byte sequence.

* * *

[![Previous](previous_motif.svg)](toplevel.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](native.html)

