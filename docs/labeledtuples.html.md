[![Previous](previous_motif.svg)](arrayliterals.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](externaltypes.html)

* * *

## ﻿12.26 Labeled tuples

(Introduced in OCaml 5.4)

| [typexpr](types.html#typexpr)| ::=|  ...  
---|---|---  
 | ∣|  [[label-name](lex.html#label-name):] [typexpr](types.html#typexpr) { * [[label-name](lex.html#label-name):][typexpr](types.html#typexpr) }+  
  
[expr](expr.html#expr)| ::=|  ...  
 | ∣|  [~[label-name](lex.html#label-name):] [expr](expr.html#expr) { , [~[label-name](lex.html#label-name):] [expr](expr.html#expr) }+  
  
[pattern](patterns.html#pattern)| ::=|  ...  
 | ∣|  [~[label-name](lex.html#label-name):] [pattern](patterns.html#pattern) { , [~[label-name](lex.html#label-name):] [pattern](patterns.html#pattern) }+  
  
  
Since OCaml 5.4, tuple fields are optionally labeled. This feature is
conceptually dual to labeled function arguments, allowing you to give a
helpful name to constructed values where labeled function arguments permit
giving a helpful name to parameters.

Here is a motivating example where we want to compute two values from a list
and be careful not to mix them up:

let sum_and_product ints = let init = ~sum:0, ~product:1 in List.fold_left
(fun (~sum, ~product) elem -> let sum = elem + sum in let product = elem *
product in ~sum, ~product) init ints

val sum_and_product : int list -> sum:int * product:int = <fun>

This example shows the use of labeled tuples in types and patterns. They may
be punned like record elements or function arguments.

In types, tuple labels are written similarly to function argument labels. For
example, the function argument to fold_left in the previous example has the
type:

    
    
    (sum:int * product:int) -> int -> sum:int * product:int
    

Labeled tuples can be useful anytime you want to use names to explain or
disambiguate the elements of a tuple, but declaring a new record feels too
heavy.

Tuples may be partially labeled, which can be useful when some elements of the
tuple share a type and need disambiguation, but others don’t. For example:

type min_max_avg = min:int * max:int * float

#### ﻿Reordering and partial patterns

Like records, labeled tuple patterns may be reordered or partial. The compiler
only supports reordering / partial matching when it knows the type of the
pattern from its context.

So, for example, we can write:

let lt = ~x:0, ~y:42 let twice_y = let ~y, .. = lt in y * 2

val lt : x:int * y:int = (~x:0, ~y:42) val twice_y : int = 84

When the type is not known (in the same sense that we require a type to be
known to disambiguate among constructors), the compiler will reject a partial
pattern. For example, this program

let get_y t = let ~y, .. = t in y

Error: Could not determine the type of this partial tuple pattern.

This example could be fixed by adding a type annotation to the function’s
parameter.

Labels may not be repeated in a tuple. However, unlabeled elements can be
thought of as all sharing the same unique label. When matching on such a
tuple, the first unlabeled element in the pattern is bound to the first
unlabeled element in the value, and so on. As a result, it’s also possible to
partially match on an unlabeled tuple to retrieve the first few elements.

#### ﻿Limitations

Parentheses are necessary to disambiguate functions types with labeled
arguments from function types with labeled tuple arguments when the first
element of the tuple has a label.

Unlike records, reordering is not supported in labeled tuple expressions, even
when the type is known. This is similar to the way the function definition for
a function with labeled arguments must bind the arguments in the same order as
the type.

Labeled tuples do not support projection (extracting an element of the tuple
by label).

#### ﻿Relationship to flexible records

Labeled tuples are similar in spirit to SML’s flexible records. The primary
difference is that SML records are canonically ordered based on label name,
while labeled tuples are not. So, for example, x:int * y:bool and y:bool *
x:int are different types in OCaml, corresponding to two different orderings
of the fields in the runtime block. In SML, the corresponding record types are
considered equal and the runtime block is always ordered with the x field
first.

* * *

[![Previous](previous_motif.svg)](arrayliterals.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](externaltypes.html)

