[![Previous](previous_motif.svg)](doccomments.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](emptyvariants.html)

* * *

## ﻿12.19 Extended indexing operators

  * [12.19.1 Multi-index notation](indexops.html#ss%3Amultiindexing)

(Introduced in 4.06)

| dot-ext| ::=|  
---|---|---  
 | ∣|  dot-operator-char { [operator-char](lex.html#operator-char) }   
  
dot-operator-char| ::=|  ! ∣ ? ∣ [core-operator-char](lex.html#core-operator-
char) ∣ % ∣ :  
  
[expr](expr.html#expr)| ::=|  ...  
 | ∣|  [expr](expr.html#expr) . [[module-path](names.html#module-path) .] dot-ext ( ( [expr](expr.html#expr) ) ∣ [ [expr](expr.html#expr) ] ∣ { [expr](expr.html#expr) } ) [ <- [expr](expr.html#expr) ]   
  
operator-name| ::=|  ...  
 | ∣|  . dot-ext (() ∣ [] ∣ {}) [<-]   
  
  
This extension provides syntactic sugar for getting and setting elements for
user-defined indexed types. For instance, we can define python-like
dictionaries with

module Dict = struct include Hashtbl let ( .%{} ) tabl index = find tabl index
let ( .%{}<\- ) tabl index value = add tabl index value end let dict = let
dict = Dict.create 10 in let () = dict.Dict.%{"one"} <\- 1; let open Dict in
dict.%{"two"} <\- 2 in dict

# dict.Dict.%{"one"};;

\- : int = 1

# let open Dict in dict.%{"two"};;

\- : int = 2

### ﻿12.19.1 Multi-index notation

| [expr](expr.html#expr)| ::=|  ...  
---|---|---  
 | ∣|  [expr](expr.html#expr) . [[module-path](names.html#module-path) .] dot-ext ( [expr](expr.html#expr) { ; [expr](expr.html#expr) }+ ) [ <- [expr](expr.html#expr) ]   
 | ∣|  [expr](expr.html#expr) . [[module-path](names.html#module-path) .] dot-ext [ [expr](expr.html#expr) { ; [expr](expr.html#expr) }+ ] [ <- [expr](expr.html#expr) ]   
 | ∣|  [expr](expr.html#expr) . [[module-path](names.html#module-path) .] dot-ext { [expr](expr.html#expr) { ; [expr](expr.html#expr) }+ } [ <- [expr](expr.html#expr) ]   
  
operator-name| ::=|  ...  
 | ∣|  . dot-ext ((;..) ∣ [;..] ∣ {;..}) [<-]   
  
  
Multi-index are also supported through a second variant of indexing operators

let (.%[;..]) = Bigarray.Genarray.get let (.%{;..}) = Bigarray.Genarray.get
let (.%(;..)) = Bigarray.Genarray.get

which is called when an index literals contain a semicolon separated list of
expressions with two and more elements:

let sum x y = x.%[1;2;3] + y.%[1;2] (* is equivalent to *) let sum x y =
(.%[;..]) x [|1;2;3|] + (.%[;..]) y [|1;2|]

In particular this multi-index notation makes it possible to uniformly handle
indexing Genarray and other implementations of multidimensional arrays.

module A = Bigarray.Genarray let (.%{;..}) = A.get let (.%{;..}<\- ) = A.set
let (.%{ }) a k = A.get a [|k|] let (.%{ }<-) a k x = A.set a [|k|] x let
syntax_compare vec mat t3 t4 = vec.%{0} = A.get vec [|0|] && mat.%{0;0} =
A.get mat [|0;0|] && t3.%{0;0;0} = A.get t3 [|0;0;0|] && t4.%{0;0;0;0} =
t4.{0,0,0,0}

Beware that the differentiation between the multi-index and single index
operators is purely syntactic: multi-index operators are restricted to index
expressions that contain one or more semicolons ;. For instance,

let pair vec mat = vec.%{0}, mat.%{0;0}

is equivalent to

let pair vec mat = (.%{ }) vec 0, (.%{;..}) mat [|0;0|]

Notice that in the vec case, we are calling the single index operator, (.%{}),
and not the multi-index variant, (.{;..}). For this reason, it is expected
that most users of multi-index operators will need to define conjointly a
single index variant

let (.%{;..}) = A.get let (.%{ }) a k = A.get a [|k|]

to handle both cases uniformly.

* * *

[![Previous](previous_motif.svg)](doccomments.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](emptyvariants.html)

