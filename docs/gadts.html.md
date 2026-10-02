[![Previous](previous_motif.svg)](overridingopen.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](bigarray.html)

* * *

## ﻿12.10 Generalized algebraic datatypes

Generalized algebraic datatypes, or GADTs, extend usual sum types in two ways:
constraints on type parameters may change depending on the value constructor,
and some type variables may be existentially quantified. They are described in
chapter [7](gadts-tutorial.html#c%3Agadts-tutorial).

(Introduced in OCaml 4.00)

| [constr-decl](typedecl.html#constr-decl)| ::=|  ...  
---|---|---  
 | ∣|  [constr-name](names.html#constr-name) : [ [constr-args](typedecl.html#constr-args) -> ] [typexpr](types.html#typexpr)  
  
[type-param](typedecl.html#type-param)| ::=|  ...  
 | ∣|  [[variance](typedecl.html#variance)] _  
  
Refutation cases. (Introduced in OCaml 4.03)

| matching-case| ::=|  [pattern](patterns.html#pattern) [when
[expr](expr.html#expr)] -> [expr](expr.html#expr)  
---|---|---  
 | ∣|  [pattern](patterns.html#pattern) -> .  
  
Explicit naming of existentials. (Introduced in OCaml 4.13.0)

| [pattern](patterns.html#pattern)| ::=|  ...  
---|---|---  
 | ∣|  [constr](names.html#constr) ( type { [typeconstr-name](names.html#typeconstr-name) }+ ) ( [pattern](patterns.html#pattern) )  
  
  
* * *

[![Previous](previous_motif.svg)](overridingopen.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](bigarray.html)

