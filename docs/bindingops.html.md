[![Previous](previous_motif.svg)](generalizedopens.html)
[![Up](contents_motif.svg)](extn.html) [![Next](next_motif.svg)](effects.html)

* * *

## ﻿12.23 Binding operators

  * [12.23.1 Examples](bindingops.html#ss%3Aletop-examples)
  * [12.23.2 Conventions](bindingops.html#ss%3Aletops-conventions)
  * [12.23.3 General desugaring rules](bindingops.html#ss%3Aletop-rules)
  * [12.23.4 Short notation for variable bindings (let-punning)](bindingops.html#ss%3Aletops-punning)

(Introduced in 4.08.0)

| let-operator| ::=|  
---|---|---  
 | ∣|  let ([core-operator-char](lex.html#core-operator-char) ∣ <) { [dot-operator-char](indexops.html#dot-operator-char) }   
  
and-operator| ::=|  
 | ∣|  and ([core-operator-char](lex.html#core-operator-char) ∣ <) { [dot-operator-char](indexops.html#dot-operator-char) }   
  
operator-name | ::=|  ...   
 | ∣|  let-operator  
 | ∣|  and-operator  
  
letop-binding | ::=|  [pattern](patterns.html#pattern) = [expr](expr.html#expr)  
 | ∣|  [value-name](names.html#value-name)  
  
[expr](expr.html#expr)| ::=|  ...  
 | ∣|  let-operator letop-binding { and-operator letop-binding } in [expr](expr.html#expr)  
  
  
Binding operators offer syntactic sugar to expose library functions under (a
variant of) the familiar syntax of standard keywords. Currently supported
“binding operators” are let<op> and and<op>, where <op> is an operator symbol,
for example and+$.

Binding operators were introduced to offer convenient syntax for working with
monads and applicative functors; for those, we propose conventions using
operators * and + respectively. They may be used for other purposes, but one
should keep in mind that each new unfamiliar notation introduced makes
programs harder to understand for non-experts. We expect that new conventions
will be developed over time on other families of operator.

### ﻿12.23.1 Examples

Users can define _let operators_ :

let ( let* ) o f = match o with | None -> None | Some x -> f x let return x = Some x

val ( let* ) : 'a option -> ('a -> 'b option) -> 'b option = <fun> val return
: 'a -> 'a option = <fun>

and then apply them using this convenient syntax:

let find_and_sum tbl k1 k2 = let* x1 = Hashtbl.find_opt tbl k1 in let* x2 =
Hashtbl.find_opt tbl k2 in return (x1 + x2)

val find_and_sum : ('a, int) Hashtbl.t -> 'a -> 'a -> int option = <fun>

which is equivalent to this expanded form:

let find_and_sum tbl k1 k2 = ( let* ) (Hashtbl.find_opt tbl k1) (fun x1 -> (
let* ) (Hashtbl.find_opt tbl k2) (fun x2 -> return (x1 + x2)))

val find_and_sum : ('a, int) Hashtbl.t -> 'a -> 'a -> int option = <fun>

Users can also define _and operators_ :

module ZipSeq = struct type 'a t = 'a Seq.t open Seq let rec return x = fun () -> Cons(x, return x) let rec prod a b = fun () -> match a (), b () with | Nil, _ | _, Nil -> Nil | Cons(x, a), Cons(y, b) -> Cons((x, y), prod a b) let ( let\+ ) f s = map s f let ( and\+ ) a b = prod a b end

module ZipSeq : sig type 'a t = 'a Seq.t val return : 'a -> 'a Seq.t val prod
: 'a Seq.t -> 'b Seq.t -> ('a * 'b) Seq.t val ( let\+ ) : 'a Seq.t -> ('a ->
'b) -> 'b Seq.t val ( and\+ ) : 'a Seq.t -> 'b Seq.t -> ('a * 'b) Seq.t end

to support the syntax:

open ZipSeq let sum3 z1 z2 z3 = let\+ x1 = z1 and\+ x2 = z2 and\+ x3 = z3 in
x1 + x2 + x3

val sum3 : int Seq.t -> int Seq.t -> int Seq.t -> int Seq.t = <fun>

which is equivalent to this expanded form:

open ZipSeq let sum3 z1 z2 z3 = ( let\+ ) (( and\+ ) (( and\+ ) z1 z2) z3)
(fun ((x1, x2), x3) -> x1 + x2 + x3)

val sum3 : int Seq.t -> int Seq.t -> int Seq.t -> int Seq.t = <fun>

### ﻿12.23.2 Conventions

An applicative functor should provide a module implementing the following
interface:

module type Applicative_syntax = sig type 'a t val ( let\+ ) : 'a t -> ('a ->
'b) -> 'b t val ( and\+ ): 'a t -> 'b t -> ('a * 'b) t end

where (let+) is bound to the map operation and (and+) is bound to the monoidal
product operation.

A monad should provide a module implementing the following interface:

module type Monad_syntax = sig include Applicative_syntax val ( let* ) : 'a t
-> ('a -> 'b t) -> 'b t val ( and* ): 'a t -> 'b t -> ('a * 'b) t end

where (let*) is bound to the bind operation, and (and*) is also bound to the
monoidal product operation.

### ﻿12.23.3 General desugaring rules

The form

    
    
    let<op0>
      x1 = e1
    and<op1>
      x2 = e2
    and<op2>
      x3 = e3
    in e
    

desugars into

    
    
    ( let<op0> )
      (( and<op2> )
        (( and<op1> )
          e1
          e2)
        e3)
      (fun ((x1, x2), x3) -> e)
    

This of course works for any number of nested and-operators. One can express
the general rule by repeating the following simplification steps:

  * The first and-operator in 

let<op0> x1 = e1 and<op1> x2 = e2 and... in e

can be desugared into a function application

let<op0> (x1, x2) = ( and<op1> ) e1 e2 and... in e.

  * Once all and-operators have been simplified away, the let-operator in 

let<op> x1 = e1 in e

can be desugared into an application

( let<op> ) e1 (fun x1 -> e).

Note that the grammar allows mixing different operator symbols in the same
binding (<op0>, <op1>, <op2> may be distinct), but we strongly recommend APIs
where let-operators and and-operators working together use the same symbol.

### ﻿12.23.4 Short notation for variable bindings (let-punning)

(Introduced in 4.13.0)

When the expression being bound is a variable, it can be convenient to use the
shorthand notation let+ x in ..., which expands to let+ x = x in .... This
notation, also known as let-punning, allows the sum3 function above can be
written more concisely as:

open ZipSeq let sum3 z1 z2 z3 = let\+ z1 and\+ z2 and\+ z3 in z1 + z2 + z3

val sum3 : int Seq.t -> int Seq.t -> int Seq.t -> int Seq.t = <fun>

This notation is also supported for extension nodes, expanding let%foo x in
... to let%foo x = x in .... However, to avoid confusion, this notation is not
supported for plain let bindings.

* * *

[![Previous](previous_motif.svg)](generalizedopens.html)
[![Up](contents_motif.svg)](extn.html) [![Next](next_motif.svg)](effects.html)

