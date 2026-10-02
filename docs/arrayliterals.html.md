[![Previous](previous_motif.svg)](effects.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](labeledtuples.html)

* * *

## ﻿12.25 Type-directed disambiguation of array literals

(Introduced in OCaml 5.4)

Since OCaml 5.4, array literal syntax [| e1 ; e2 ; ... ; eN |] can be used to
denote values of type floatarray or 'a Iarray.t as well as 'a array, both in
expression and pattern positions. This syntax is also used to display
floatarray and 'a Iarray.t values in the toplevel.

The compiler matches the expected type of the expression or pattern with the
type of the literal, in a manner analogous to the disambiguation of
constructors and record fields (see [1.4.1](coreexamples.html#ss%3Arecord-and-
variant-disambiguation)).

In the absence of an expected type, array literals are assumed to be of type
'a array.

In the following examples, the array literals are assigned type floatarray:

let _ : floatarray = [|42.|];;

\- : floatarray = [|42.|]

let _ = ([|42.|] : floatarray);;

\- : floatarray = [|42.|]

let _ = Float.Array.length [|42.|];;

\- : int = 1

Immutable arrays (here int Iarray.t) can be constructed in exactly the same
way:

let _ : _ Iarray.t = [|42|];;

\- : int Iarray.t = [|42|]

let _ = ([|42|] : _ Iarray.t );;

\- : int Iarray.t = [|42|]

let _ = Iarray.length [|42|];;

\- : int = 1

The same disambiguation mechanism is used for array literals appearing in
patterns:

let f : floatarray -> _ = function | [| 42. |] -> "It's a floatarray containing one element" | _ -> "Also a floatarray" ;;

val f : floatarray -> string = <fun>

In the example below, x is assigned type float array:

let x = [|42.|];;

val x : float array = [|42.|]

However, the following does not work:

let f a = match a with | [| _ |] -> Float.Array.length a | _ -> 42 ;;

Error: The value a has type 'a array but an expression was expected of type
Float.Array.t = floatarray

let f b (a : floatarray) = if b then [|42.|] else a ;;

Error: The value a has type floatarray but an expression was expected of type
float array

Here the information learned from the use of a as a floatarray cannot be
propagated back to the array literal. In general, expected type information
cannot be propagated “backwards”.

In the following example, type disambiguation works because the type
information learned in the then branch of the conditional is propagated to the
else branch, which occurs “later”.

let f b (a : floatarray) = if b then a else [|42.|];;

val f : bool -> floatarray -> floatarray = <fun>

Such cases trigger warning 18 not-principal, if enabled.

* * *

[![Previous](previous_motif.svg)](effects.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](labeledtuples.html)

