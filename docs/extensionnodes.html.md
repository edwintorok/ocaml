[![Previous](previous_motif.svg)](attributes.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](extensiblevariants.html)

* * *

## ﻿12.13 Extension nodes

  * [12.13.1 Built-in extension nodes](extensionnodes.html#ss%3Abuiltin-extension-nodes)

(Introduced in OCaml 4.02, infix notations for constructs other than
expressions added in 4.03, infix notation (e1 ;%ext e2) added in 4.04. )

Extension nodes are generic placeholders in the syntax tree. They are rejected
by the type-checker and are intended to be “expanded” by external tools such
as -ppx rewriters.

Extension nodes share the same notion of identifier and payload as attributes
[12.12](attributes.html#s%3Aattributes).

The first form of extension node is used for “algebraic” categories:

| extension| ::=|  [% [attr-id](attributes.html#attr-id) [attr-
payload](attributes.html#attr-payload) ]  
---|---|---  
  
[expr](expr.html#expr)| ::=|  ...  
 | ∣|  extension  
  
[typexpr](types.html#typexpr)| ::=|  ...  
 | ∣|  extension  
  
[pattern](patterns.html#pattern)| ::=|  ...  
 | ∣|  extension  
  
[module-expr](modules.html#module-expr)| ::=|  ...  
 | ∣|  extension  
  
[module-type](modtypes.html#module-type)| ::=|  ...  
 | ∣|  extension  
  
class-expr| ::=|  ...  
 | ∣|  extension  
  
class-type| ::=|  ...  
 | ∣|  extension  
  
  
A second form of extension node can be used in structures and signatures, both
in the module and object languages:

| item-extension| ::=|  [%% [attr-id](attributes.html#attr-id) [attr-
payload](attributes.html#attr-payload) ]  
---|---|---  
  
[definition](modules.html#definition)| ::=|  ...  
 | ∣|  item-extension  
  
[specification](modtypes.html#specification)| ::=|  ...  
 | ∣|  item-extension  
  
class-field-spec| ::=|  ...  
 | ∣|  item-extension  
  
[class-field](classes.html#class-field)| ::=|  ...  
 | ∣|  item-extension  
  
  
An infix form is available for extension nodes when the payload is of the same
kind (expression with expression, pattern with pattern ...).

Examples:

    
    
    let%foo x = 2 in x + 1     === [%foo let x = 2 in x + 1]
    begin%foo ... end          === [%foo begin ... end]
    x ;%foo 2                  === [%foo x; 2]
    module%foo M = ..          === [%%foo module M = ... ]
    val%foo x : t              === [%%foo: val x : t]
    

When this form is used together with the infix syntax for attributes, the
attributes are considered to apply to the payload:

    
    
    fun%foo[@bar] x -> x + 1 === [%foo (fun x -> x + 1)[@bar ] ];
    

An additional shorthand let%foo x in ... is available for convenience when
extension nodes are used to implement binding operators (See
[12.23.4](bindingops.html#ss%3Aletops-punning)).

Furthermore, quoted strings {|...|} can be combined with extension nodes to
embed foreign syntax fragments. Those fragments can be interpreted by a
preprocessor and turned into OCaml code without requiring escaping quotes. A
syntax shortcut is available for them:

    
    
    {%%foo|...|}               === [%%foo{|...|}]
    let x = {%foo|...|}        === let x = [%foo{|...|}]
    let y = {%foo bar|...|bar} === let y = [%foo{bar|...|bar}]
    

For instance, you can use {%sql|...|} to represent arbitrary SQL statements –
assuming you have a ppx-rewriter that recognizes the %sql extension.

Note that the word-delimited form, for example {sql|...|sql}, should not be
used for signaling that an extension is in use. Indeed, the user cannot see
from the code whether this string literal has different semantics than they
expect. Moreover, giving semantics to a specific delimiter limits the freedom
to change the delimiter to avoid escaping issues.

### ﻿12.13.1 Built-in extension nodes

(Introduced in OCaml 4.03)

Some extension nodes are understood by the compiler itself:

  * ocaml.extension_constructor or extension_constructor extensions take as payload a constructor from an extensible variant type (see [12.14](extensiblevariants.html#s%3Aextensible-variants)) and return its extension constructor slot.

type t = .. type t += X of int | Y of string let x = [%extension_constructor X] let y = [%extension_constructor Y]

# x <> y;;

\- : bool = true

  * ocaml.atomic.loc or atomic.loc extensions take as payload an OCaml expression denoting an atomic location. See [9.7.2](parallelism.html#s%3Aatomic-record-fields) for more details. 

* * *

[![Previous](previous_motif.svg)](attributes.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](extensiblevariants.html)

