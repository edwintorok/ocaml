[![Previous](previous_motif.svg)](stdlib.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](libunix.html)

* * *

# Chapter 31 The compiler front-end

This chapter describes the OCaml front-end, which declares the abstract syntax
tree used by the compiler, provides a way to parse, print and pretty-print
OCaml code, and ultimately allows one to write abstract syntax tree
preprocessors invoked via the -ppx flag (see chapters
[13](comp.html#c%3Acamlc) and [16](native.html#c%3Anativecomp)).

It is important to note that the exported front-end interface follows the
evolution of the OCaml language and implementation, and thus does not provide
any backwards compatibility guarantees.

The front-end is a part of compiler-libs library. Programs that use the
compiler-libs library should be built as follows:

    
    
            ocamlfind ocamlc other options -package compiler-libs.common other files
            ocamlfind ocamlopt other options -package compiler-libs.common other files
    

Use of the ocamlfind utility is recommended. However, if this is not possible,
an alternative method may be used:

    
    
            ocamlc other options -I +compiler-libs ocamlcommon.cma other files
            ocamlopt other options -I +compiler-libs ocamlcommon.cmxa other files
    

For interactive use of the compiler-libs library, start ocaml and type  
#load "compiler-libs/ocamlcommon.cma";;.

  * [Module Ast_helper](compilerlibref/Ast_helper.html): helper functions for AST construction 
  * [Module Ast_mapper](compilerlibref/Ast_mapper.html): -ppx rewriter interface 
  * [Module Asttypes](compilerlibref/Asttypes.html): auxiliary types used by Parsetree 
  * [Module Location](compilerlibref/Location.html): source code locations 
  * [Module Longident](compilerlibref/Longident.html): long identifiers 
  * [Module Parse](compilerlibref/Parse.html): OCaml syntax parsing 
  * [Module Parsetree](compilerlibref/Parsetree.html): OCaml syntax tree 
  * [Module Pprintast](compilerlibref/Pprintast.html): OCaml syntax printing 

* * *

[![Previous](previous_motif.svg)](stdlib.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](libunix.html)

