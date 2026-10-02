[![Previous](previous_motif.svg)](extensionnodes.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](generativefunctors.html)

* * *

## ﻿12.14 Extensible variant types

  * [12.14.1 Private extensible variant types](extensiblevariants.html#ss%3Aprivate-extensible)

(Introduced in OCaml 4.02)

| [type-representation](typedecl.html#type-representation)| ::=|  ...  
---|---|---  
 | ∣|  = ..  
  
[specification](modtypes.html#specification)| ::=|  ...  
 | ∣|  type [[type-params](typedecl.html#type-params)] [typeconstr](names.html#typeconstr) type-extension-spec  
  
[definition](modules.html#definition)| ::=|  ...  
 | ∣|  type [[type-params](typedecl.html#type-params)] [typeconstr](names.html#typeconstr) type-extension-def  
  
type-extension-spec| ::=|  += [private] [|] [constr-decl](typedecl.html#constr-decl) { | [constr-decl](typedecl.html#constr-decl) }   
  
type-extension-def| ::=|  += [private] [|] constr-def { | constr-def }   
  
constr-def| ::=|  [constr-decl](typedecl.html#constr-decl)  
 | ∣|  [constr-name](names.html#constr-name) = [constr](names.html#constr)  
  
  
Extensible variant types are variant types which can be extended with new
variant constructors. Extensible variant types are defined using ... New
variant constructors are added using +=.

module Expr = struct type attr = .. type attr += Str of string type attr += | Int of int | Float of float end

Pattern matching on an extensible variant type requires a default case to
handle unknown variant constructors:

let to_string = function | Expr.Str s -> s | Expr.Int i -> Int.to_string i | Expr.Float f -> string_of_float f | _ -> "?"

A preexisting example of an extensible variant type is the built-in exn type
used for exceptions. Indeed, exception constructors can be declared using the
type extension syntax:

type exn += Exc of int

Extensible variant constructors can be rebound to a different name. This
allows exporting variants from another module.

# let not_in_scope = Str "Foo";;

Error: Unbound constructor Str

type Expr.attr += Str = Expr.Str

# let now_works = Str "foo";;

val now_works : Expr.attr = Expr.Str "foo"

Extensible variant constructors can be declared private. As with regular
variants, this prevents them from being constructed directly by constructor
application while still allowing them to be de-structured in pattern-matching.

module B : sig type Expr.attr += private Bool of int val bool : bool ->
Expr.attr end = struct type Expr.attr += Bool of int let bool p = if p then
Bool 1 else Bool 0 end

# let inspection_works = function | B.Bool p -> (p = 1) | _ -> true;;

val inspection_works : Expr.attr -> bool = <fun>

# let construction_is_forbidden = B.Bool 1;;

Error: Cannot use private constructor Bool to create values of type Expr.attr

### ﻿12.14.1 Private extensible variant types

(Introduced in OCaml 4.06)

| [type-representation](typedecl.html#type-representation)| ::=|  ...  
---|---|---  
 | ∣|  = private ..  
  
  
Extensible variant types can be declared private. This prevents new
constructors from being declared directly, but allows extension constructors
to be referred to in interfaces.

module Msg : sig type t = private .. module MkConstr (X : sig type t end) :
sig type t += C of X.t end end = struct type t = .. module MkConstr (X : sig
type t end) = struct type t += C of X.t end end

* * *

[![Previous](previous_motif.svg)](extensionnodes.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](generativefunctors.html)

