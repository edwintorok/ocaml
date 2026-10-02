[![Previous](previous_motif.svg)](extensionsyntax.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](doccomments.html)

* * *

## ﻿12.17 Inline records

(Introduced in OCaml 4.03)

|  constr-args| ::=|  ...  
---|---|---  
 | ∣|  [record-decl](typedecl.html#record-decl)  
  
  
The arguments of sum-type constructors can now be defined using the same
syntax as records. Mutable and polymorphic fields are allowed. GADT syntax is
supported. Attributes can be specified on individual fields.

Syntactically, building or matching constructors with such an inline record
argument is similar to working with a unary constructor whose unique argument
is a declared record type. A pattern can bind the inline record as a pseudo-
value, but the record cannot escape the scope of the binding and can only be
used with the dot-notation to extract or modify fields or to build new
constructor values.

type t = | Point of {width: int; mutable x: float; mutable y: float} | Other let v = Point {width = 10; x = 0.; y = 0.} let scale l = function | Point p -> Point {p with x = l *. p.x; y = l *. p.y} | Other -> Other let print = function | Point {x; y; _} -> Printf.printf "%f/%f" x y | Other -> () let reset = function | Point p -> p.x <\- 0.; p.y <\- 0. | Other -> ()

let invalid = function | Point p -> p

Error: This form is not allowed as the type of the inlined record could
escape.

* * *

[![Previous](previous_motif.svg)](extensionsyntax.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](doccomments.html)

