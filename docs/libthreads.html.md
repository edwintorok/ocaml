[![Previous](previous_motif.svg)](runtime_events.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](libdynlink.html)

* * *

# Chapter 35 The threads library

The threads library allows concurrent programming in OCaml. It provides
multiple threads of control (also called lightweight processes) that execute
concurrently in the same memory space. Threads communicate by in-place
modification of shared data structures, or by sending and receiving data on
communication channels.

The threads library is implemented on top of the threading facilities provided
by the operating system: POSIX 1003.1c threads for Linux, MacOS, and other
Unix-like systems; Win32 threads for Windows. Only one thread at a time is
allowed to run OCaml code on a particular domain
[9.5.1](parallelism.html#s%3Apar_systhread_interaction). Hence, opportunities
for parallelism are limited to the parts of the program that run system or C
library code. However, threads provide concurrency and can be used to
structure programs as several communicating processes. Threads also
efficiently support concurrent, overlapping I/O operations.

Programs that use threads must be linked as follows:

    
    
            ocamlc -I +unix -I +threads other options unix.cma threads.cma other files
            ocamlopt -I +unix -I +threads other options unix.cmxa threads.cmxa other files
    

Compilation units that use the threads library must also be compiled with the
-I +threads option (see chapter [13](comp.html#c%3Acamlc)).

  * [Module Thread](libref/Thread.html): lightweight threads 
  * [Module Event](libref/Event.html): first-class synchronous communication 

* * *

[![Previous](previous_motif.svg)](runtime_events.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](libdynlink.html)

