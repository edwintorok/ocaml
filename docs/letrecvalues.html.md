[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](recursivemodules.html)

* * *

## ﻿12.1 Recursive definitions of values

(Introduced in Objective Caml 1.00)

As mentioned in section [11.7.2](expr.html#sss%3Aexpr-localdef), the let rec
binding construct, in addition to the definition of recursive functions, also
supports a certain class of recursive definitions of non-functional values,
such as

let rec name1 = 1 :: name2 and name2 = 2 :: name1 in [expr](expr.html#expr)

which binds name1 to the cyclic list 1::2::1::2::…, and name2 to the cyclic
list 2::1::2::1::…Informally, the class of accepted definitions consists of
those definitions where the defined names occur only inside function bodies or
as argument to a data constructor.

More precisely, consider the expression:

let rec name1 = [expr](expr.html#expr)1 and … and namen =
[expr](expr.html#expr)n in [expr](expr.html#expr)

It will be accepted if each one of [expr](expr.html#expr)1 …
[expr](expr.html#expr)n is statically constructive with respect to name1 …
namen, is not immediately linked to any of name1 … namen, and is not an array
constructor whose arguments have abstract type.

An expression e is said to be _statically constructive with respect to_ the
variables name1 … namen if at least one of the following conditions is true:

  * e has no free occurrence of any of name1 … namen
  * e is a variable 
  * e has the form fun … -> … 
  * e has the form function … -> … 
  * e has the form lazy ( … )
  * e has one of the following forms, where each one of [expr](expr.html#expr)1 … [expr](expr.html#expr)m is statically constructive with respect to name1 … namen, and [expr](expr.html#expr)0 is statically constructive with respect to name1 … namen, xname1 … xnamem: 
    * let [rec] xname1 = [expr](expr.html#expr)1 and … and xnamem = [expr](expr.html#expr)m in [expr](expr.html#expr)0
    * let module … in [expr](expr.html#expr)1
    * [constr](names.html#constr) ([expr](expr.html#expr)1, … , [expr](expr.html#expr)m)
    * `[tag-name](names.html#tag-name) ([expr](expr.html#expr)1, … , [expr](expr.html#expr)m)
    * [| [expr](expr.html#expr)1; … ; [expr](expr.html#expr)m |]
    * { [field](names.html#field)1 = [expr](expr.html#expr)1; … ; [field](names.html#field)m = [expr](expr.html#expr)m }
    * { [expr](expr.html#expr)1 with [field](names.html#field)2 = [expr](expr.html#expr)2; … ; [field](names.html#field)m = [expr](expr.html#expr)m } where [expr](expr.html#expr)1 is not immediately linked to name1 … namen
    * ( [expr](expr.html#expr)1, … , [expr](expr.html#expr)m )
    * [expr](expr.html#expr)1; … ; [expr](expr.html#expr)m

An expression e is said to be _immediately linked to_ the variable name in the
following cases:

  * e is name
  * e has the form [expr](expr.html#expr)1; … ; [expr](expr.html#expr)m where [expr](expr.html#expr)m is immediately linked to name
  * e has the form let [rec] xname1 = [expr](expr.html#expr)1 and … and xnamem = [expr](expr.html#expr)m in [expr](expr.html#expr)0 where [expr](expr.html#expr)0 is immediately linked to name or to one of the xnamei such that [expr](expr.html#expr)i is immediately linked to name. 

* * *

[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](recursivemodules.html)

