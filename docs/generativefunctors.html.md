[![Previous](previous_motif.svg)](extensiblevariants.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](extensionsyntax.html)

* * *

## ﻿12.15 Generative functors

(Introduced in OCaml 4.02)

| [module-expr](modules.html#module-expr)| ::=|  ...  
---|---|---  
 | ∣|  functor () -> [module-expr](modules.html#module-expr)  
 | ∣|  [module-expr](modules.html#module-expr) ()  
  
[definition](modules.html#definition)| ::=|  ...  
 | ∣|  module [module-name](names.html#module-name) { ( [module-name](names.html#module-name) : [module-type](modtypes.html#module-type) ) ∣ () } [ : [module-type](modtypes.html#module-type) ] = [module-expr](modules.html#module-expr)  
  
[module-type](modtypes.html#module-type)| ::=|  ...  
 | ∣|  [functor] () -> [module-type](modtypes.html#module-type)  
  
[specification](modtypes.html#specification)| ::=|  ...  
 | ∣|  module [module-name](names.html#module-name) { ( [module-name](names.html#module-name) : [module-type](modtypes.html#module-type) ) ∣ () } : [module-type](modtypes.html#module-type)  
  
  
A generative functor takes a unit () argument. In order to use it, one must
necessarily apply it to this unit argument, ensuring that all type components
in the result of the functor behave in a generative way, _i.e._ they are
different from types obtained by other applications of the same functor. This
is equivalent to taking an argument of signature sig end, and always applying
to struct end, but not to some defined module (in the latter case, applying
twice to the same module would return identical types).

As a side-effect of this generativity, one is allowed to unpack first-class
modules in the body of generative functors.

* * *

[![Previous](previous_motif.svg)](extensiblevariants.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](extensionsyntax.html)

