[![Previous](previous_motif.svg)](libdynlink.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](manual079.html)

* * *

# Chapter 37 Recently removed or moved libraries (Graphics, Bigarray, Num,
LablTk)

  * [37.1 The Graphics Library](old.html#s%3Agraphics-removed)
  * [37.2 The Bigarray Library](old.html#s%3Abigarray-moved)
  * [37.3 The Num Library](old.html#sec707)
  * [37.4 The Labltk Library and OCamlBrowser](old.html#s%3Alabltk-removed)

This chapter describes three libraries which were formerly part of the OCaml
distribution (Graphics, Num, and LablTk), and a library which has now become
part of OCaml’s standard library, and is documented there (Bigarray).

## ﻿37.1 The Graphics Library

Since OCaml 4.09, the graphics library is distributed as an external package.
Its new home is:

[https://github.com/ocaml/graphics](https://github.com/ocaml/graphics)

If you are using the opam package manager, you should install the
corresponding graphics package:

    
    
            opam install graphics
    

Before OCaml 4.09, this package simply ensures that the graphics library was
installed by the compiler, and starting from OCaml 4.09 this package
effectively provides the graphics library.

## ﻿37.2 The Bigarray Library

As of OCaml 4.07, the bigarray library has been integrated into OCaml’s
standard library.

The bigarray functionality may now be found in the standard library [Bigarray
module](libref/Bigarray.html), except for the map_file function which is now
part of the [Unix library](libunix.html#c%3Aunix). The documentation has been
integrated into the documentation for the standard library.

The legacy bigarray library bundled with the compiler is a compatibility
library with exactly the same interface as before, i.e. with map_file
included.

We strongly recommend that you port your code to use the standard library
version instead, as the changes required are minimal.

If you choose to use the compatibility library, you must link your programs as
follows:

    
    
            ocamlc other options bigarray.cma other files
            ocamlopt other options bigarray.cmxa other files
    

For interactive use of the bigarray compatibility library, do:

    
    
            ocamlmktop -o mytop bigarray.cma
            ./mytop
    

or (if dynamic linking of C libraries is supported on your platform), start
ocaml and type #load "bigarray.cma";;.

## ﻿37.3 The Num Library

The num library implements integer arithmetic and rational arithmetic in
arbitrary precision. It was split off the core OCaml distribution starting
with the 4.06.0 release, and can now be found at
[https://github.com/ocaml/num](https://github.com/ocaml/num).

New applications that need arbitrary-precision arithmetic should use the
Zarith library
([https://github.com/ocaml/Zarith](https://github.com/ocaml/Zarith)) instead
of the Num library, and older applications that already use Num are encouraged
to switch to Zarith. Zarith delivers much better performance than Num and has
a nicer API.

## ﻿37.4 The Labltk Library and OCamlBrowser

Since OCaml version 4.02, the OCamlBrowser tool and the Labltk library are
distributed separately from the OCaml compiler. The project is now hosted at
[https://github.com/garrigue/labltk](https://github.com/garrigue/labltk).

* * *

[![Previous](previous_motif.svg)](libdynlink.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](manual079.html)

