[![Previous](previous_motif.svg)](signaturesubstitution.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](overridingopen.html)

* * *

## ﻿12.8 Type-level module aliases

(Introduced in OCaml 4.02)

| [specification](modtypes.html#specification)| ::=|  ...  
---|---|---  
 | ∣|  module [module-name](names.html#module-name) = [module-path](names.html#module-path)  
  
The above specification, inside a signature, only matches a module definition
equal to [module-path](names.html#module-path). Conversely, a type-level
module alias can be matched by itself, or by any supertype of the type of the
module it references.

There are several restrictions on [module-path](names.html#module-path):

  1. it should be of the form M0.M1...Mn (_i.e._ without functor applications); 
  2. inside the body of a functor, M0 should not be one of the functor parameters; 
  3. inside a recursive module definition, M0 should not be one of the recursively defined modules. 

Such specifications are also inferred. Namely, when P is a path satisfying the
above constraints,

module N = P

has type

module N = P

Type-level module aliases are used when checking module path equalities. That
is, in a context where module name N is known to be an alias for P, not only
these two module paths check as equal, but F(N) and F(P) are also recognized
as equal. In the default compilation mode, this is the only difference with
the previous approach of module aliases having just the same module type as
the module they reference.

When the compiler flag -no-alias-deps is enabled, type-level module aliases
are also exploited to avoid introducing dependencies between compilation
units. Namely, a module alias referring to a module inside another compilation
unit does not introduce a link-time dependency on that compilation unit, as
long as it is not dereferenced; it still introduces a compile-time dependency
if the interface needs to be read, _i.e._ if the module is a submodule of the
compilation unit, or if some type components are referred to. Additionally,
accessing a module alias introduces a link-time dependency on the compilation
unit containing the module referenced by the alias, rather than the
compilation unit containing the alias. Note that these differences in link-
time behavior may be incompatible with the previous behavior, as some
compilation units might not be extracted from libraries, and their side-
effects ignored.

These weakened dependencies make possible to use module aliases in place of
the -pack mechanism. Suppose that you have a library Mylib composed of modules
A and B. Using -pack, one would issue the command line

    
    
    ocamlc -pack a.cmo b.cmo -o mylib.cmo
    

and as a result obtain a Mylib compilation unit, containing physically A and B
as submodules, and with no dependencies on their respective compilation units.
Here is a concrete example of a possible alternative approach:

  1. Rename the files containing A and B to Mylib__A and Mylib__B. 
  2. Create a packing interface Mylib.ml, containing the following lines. 
         
         module A = Mylib__A
         module B = Mylib__B
         

  3. Compile Mylib.ml using -no-alias-deps, and the other files using -no-alias-deps and -open Mylib (the last one is equivalent to adding the line open! Mylib at the top of each file). 
         
         ocamlc -c -no-alias-deps Mylib.ml
         ocamlc -c -no-alias-deps -open Mylib Mylib__*.mli Mylib__*.ml
         

  4. Finally, create a library containing all the compilation units, and export all the compiled interfaces. 
         
         ocamlc -a Mylib*.cmo -o Mylib.cma
         

This approach lets you access A and B directly inside the library, and as
Mylib.A and Mylib.B from outside. It also has the advantage that Mylib is no
longer monolithic: if you use Mylib.A, only Mylib__A will be linked in, not
Mylib__B.

Note the use of double underscores in Mylib__A and Mylib__B. These were chosen
on purpose; the compiler uses the following heuristic when printing paths:
given a path Lib__fooBar, if Lib.FooBar exists and is an alias for
Lib__fooBar, then the compiler will always display Lib.FooBar instead of
Lib__fooBar. This way the long Mylib__ names stay hidden and all the user sees
is the nicer dot names. This is how the OCaml standard library is compiled.

* * *

[![Previous](previous_motif.svg)](signaturesubstitution.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](overridingopen.html)

