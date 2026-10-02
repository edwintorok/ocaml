[![Previous](previous_motif.svg)](modulealias.html)
[![Up](contents_motif.svg)](extn.html) [![Next](next_motif.svg)](gadts.html)

* * *

## ﻿12.9 Overriding in open statements

(Introduced in OCaml 4.01)

| [definition](modules.html#definition)| ::=|  ...  
---|---|---  
 | ∣|  open! [module-path](names.html#module-path)  
  
[specification](modtypes.html#specification)| ::=|  ...  
 | ∣|  open! [module-path](names.html#module-path)  
  
[expr](expr.html#expr)| ::=|  ...  
 | ∣|  let open! [module-path](names.html#module-path) in [expr](expr.html#expr)  
  
class-body-type| ::=|  ...  
 | ∣|  let open! [module-path](names.html#module-path) in [class-body-type](classes.html#class-body-type)  
  
class-expr| ::=|  ...  
 | ∣|  let open! [module-path](names.html#module-path) in [class-expr](classes.html#class-expr)  
  
  
Since OCaml 4.01, open statements shadowing an existing identifier (which is
later used) trigger the warning 44. Adding a ! character after the open
keyword indicates that such a shadowing is intentional and should not trigger
the warning.

This is also available (since OCaml 4.06) for local opens in class expressions
and class type expressions.

* * *

[![Previous](previous_motif.svg)](modulealias.html)
[![Up](contents_motif.svg)](extn.html) [![Next](next_motif.svg)](gadts.html)

