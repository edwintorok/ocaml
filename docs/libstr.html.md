[![Previous](previous_motif.svg)](libunix.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](runtime_events.html)

* * *

# Chapter 33 The str library: regular expressions and string processing

The str library provides high-level string processing functions, some based on
regular expressions. It is intended to support the kind of file processing
that is usually performed with scripting languages such as awk, perl or sed.

Programs that use the str library must be linked as follows:

    
    
            ocamlc other options -I +str str.cma other files
            ocamlopt other options  -I +str str.cmxa other files
    

For interactive use of the str library, do:

    
    
            ocamlmktop -o mytop str.cma
            ./mytop
    

or (if dynamic linking of C libraries is supported on your platform), start
ocaml and type

# #directory "+str";;

# #load "str.cma";;

  * [Module Str](libref/Str.html): regular expressions and string processing 

* * *

[![Previous](previous_motif.svg)](libunix.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](runtime_events.html)

