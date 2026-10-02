[![Previous](previous_motif.svg)](modtypes.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](compunit.html)

* * *

## ﻿11.11 Module expressions (module implementations)

  * [11.11.1 Simple module expressions](modules.html#ss%3Amexpr-simple)
  * [11.11.2 Structures](modules.html#ss%3Amexpr-structures)
  * [11.11.3 Functors](modules.html#ss%3Amexpr-functors)

Module expressions are the module-level equivalent of value expressions: they
evaluate to modules, thus providing implementations for the specifications
expressed in module types.

| module-expr| ::=|  [module-path](names.html#module-path)  
---|---|---  
 | ∣|  struct [ module-items ] end  
 | ∣|  functor { ( [module-name](names.html#module-name) : [module-type](modtypes.html#module-type) ) }+ -> module-expr  
 | ∣|  module-expr ( module-expr )  
 | ∣|  ( module-expr )  
 | ∣|  ( module-expr : [module-type](modtypes.html#module-type) )  
  
module-items| ::=|  { ;; } ( definition ∣ [expr](expr.html#expr) ) { { ;; } (
definition ∣ ;; [expr](expr.html#expr)) } { ;; }  
  
module-definition| ::=|  module [module-name](names.html#module-name) { (
[module-name](names.html#module-name) : [module-type](modtypes.html#module-
type) ) } [ : [module-type](modtypes.html#module-type) ] = module-expr  
  
local-definition| ::=|  external [value-name](names.html#value-name) :
[typexpr](types.html#typexpr) = [external-declaration](intfc.html#external-
declaration)  
 | ∣|  [type-definition](typedecl.html#type-definition)  
 | ∣|  [exception-definition](typedecl.html#exception-definition)  
 | ∣|  [class-definition](classes.html#class-definition)  
 | ∣|  [classtype-definition](classes.html#classtype-definition)  
 | ∣|  module-definition  
 | ∣|  module type [modtype-name](names.html#modtype-name) = [module-type](modtypes.html#module-type)  
 | ∣|  open [module-path](names.html#module-path)  
  
definition| ::=|  let [rec] [let-binding](expr.html#let-binding) { and [let-
binding](expr.html#let-binding) }  
 | ∣|  include module-expr  
 | ∣|  local-definition  
  
  
See also the following language extensions: [recursive
modules](recursivemodules.html#s%3Arecursive-modules), [first-class
modules](firstclassmodules.html#s%3Afirst-class-modules), [overriding in open
statements](overridingopen.html#s%3Aexplicit-overriding-open),
[attributes](attributes.html#s%3Aattributes), [extension
nodes](extensionnodes.html#s%3Aextension-nodes) and [generative
functors](generativefunctors.html#s%3Agenerative-functors).

### ﻿11.11.1 Simple module expressions

The expression [module-path](names.html#module-path) evaluates to the module
bound to the name [module-path](names.html#module-path).

The expression ( module-expr ) evaluates to the same module as module-expr.

The expression ( module-expr : [module-type](modtypes.html#module-type) )
checks that the type of module-expr is a subtype of [module-
type](modtypes.html#module-type), that is, that all components specified in
[module-type](modtypes.html#module-type) are implemented in module-expr, and
their implementation meets the requirements given in [module-
type](modtypes.html#module-type). In other terms, it checks that the
implementation module-expr meets the type specification [module-
type](modtypes.html#module-type). The whole expression evaluates to the same
module as module-expr, except that all components not specified in [module-
type](modtypes.html#module-type) are hidden and can no longer be accessed.

### ﻿11.11.2 Structures

Structures struct … end are collections of definitions for value names, type
names, exceptions, module names and module type names. The definitions are
evaluated in the order in which they appear in the structure. The scopes of
the bindings performed by the definitions extend to the end of the structure.
As a consequence, a definition may refer to names bound by earlier definitions
in the same structure.

For compatibility with toplevel phrases (chapter
[14](toplevel.html#c%3Acamllight)), optional ;; are allowed after and before
each definition in a structure. These ;; have no semantic meanings. Similarly,
an [expr](expr.html#expr) preceded by ;; is allowed as a component of a
structure. It is equivalent to let _ = [expr](expr.html#expr), i.e.
[expr](expr.html#expr) is evaluated for its side-effects but is not bound to
any identifier. If [expr](expr.html#expr) is the first component of a
structure, the preceding ;; can be omitted.

#### ﻿Value definitions

A value definition let [rec] [let-binding](expr.html#let-binding) { and [let-
binding](expr.html#let-binding) } bind value names in the same way as a let …
in … expression (see section [11.7.2](expr.html#sss%3Aexpr-localdef)). The
value names appearing in the left-hand sides of the bindings are bound to the
corresponding values in the right-hand sides.

A value definition external [value-name](names.html#value-name) :
[typexpr](types.html#typexpr) = [external-declaration](intfc.html#external-
declaration) implements [value-name](names.html#value-name) as the external
function specified in [external-declaration](intfc.html#external-declaration)
(see chapter [23](intfc.html#c%3Aintf-c)).

#### ﻿Type definitions

A definition of one or several type components is written type
[typedef](typedecl.html#typedef) { and [typedef](typedecl.html#typedef) } and
consists of a sequence of mutually recursive definitions of type names.

#### ﻿Exception definitions

Exceptions are defined with the syntax exception [constr-
decl](typedecl.html#constr-decl) or exception [constr-name](names.html#constr-
name) = [constr](names.html#constr).

#### ﻿Class definitions

A definition of one or several classes is written class [class-
binding](classes.html#class-binding) { and [class-binding](classes.html#class-
binding) } and consists of a sequence of mutually recursive definitions of
class names. Class definitions are described more precisely in section
[11.9.3](classes.html#ss%3Aclass-def).

#### ﻿Class type definitions

A definition of one or several classes is written class type [classtype-
def](classes.html#classtype-def) { and [classtype-def](classes.html#classtype-
def) } and consists of a sequence of mutually recursive definitions of class
type names. Class type definitions are described more precisely in section
[11.9.5](classes.html#ss%3Aclasstype).

#### ﻿Module definitions

The basic form for defining a module component is module [module-
name](names.html#module-name) = module-expr, which evaluates module-expr and
binds the result to the name [module-name](names.html#module-name).

One can write

module [module-name](names.html#module-name) : [module-
type](modtypes.html#module-type) = module-expr

instead of

module [module-name](names.html#module-name) = ( module-expr : [module-
type](modtypes.html#module-type) ).

Another derived form is

module [module-name](names.html#module-name) ( name1 : [module-
type](modtypes.html#module-type)1 ) … ( namen : [module-
type](modtypes.html#module-type)n ) = module-expr

which is equivalent to

module [module-name](names.html#module-name) = functor ( name1 : [module-
type](modtypes.html#module-type)1 ) -> … -> module-expr

#### ﻿Module type definitions

A definition for a module type is written module type [modtype-
name](names.html#modtype-name) = [module-type](modtypes.html#module-type). It
binds the name [modtype-name](names.html#modtype-name) to the module type
denoted by the expression [module-type](modtypes.html#module-type).

#### ﻿Opening a module path

The expression open [module-path](names.html#module-path) in a structure does
not define any components nor perform any bindings. It simply affects the
parsing of the following items of the structure, allowing components of the
module denoted by [module-path](names.html#module-path) to be referred to by
their simple names name instead of path accesses [module-
path](names.html#module-path) . name. The scope of the open stops at the end
of the structure expression.

#### ﻿Including the components of another structure

The expression include module-expr in a structure re-exports in the current
structure all definitions of the structure denoted by module-expr. For
instance, if you define a module S as below

module S = struct type t = int let x = 2 end

defining the module B as

module B = struct include S let y = (x + 1 : t) end

is equivalent to defining it as

module B = struct type t = S.t let x = S.x let y = (x + 1 : t) end

The difference between open and include is that open simply provides short
names for the components of the opened structure, without defining any
components of the current structure, while include also adds definitions for
the components of the included structure.

### ﻿11.11.3 Functors

#### ﻿Functor definition

The expression functor ( [module-name](names.html#module-name) : [module-
type](modtypes.html#module-type) ) -> module-expr evaluates to a functor that
takes as argument modules of the type [module-type](modtypes.html#module-
type)1, binds [module-name](names.html#module-name) to these modules,
evaluates module-expr in the extended environment, and returns the resulting
modules as results. No restrictions are placed on the type of the functor
argument; in particular, a functor may take another functor as argument
(“higher-order” functor).

When the result module expression is itself a functor,

functor ( name1 : [module-type](modtypes.html#module-type)1 ) -> … -> functor
( namen : [module-type](modtypes.html#module-type)n ) -> module-expr

one may use the abbreviated form

functor ( name1 : [module-type](modtypes.html#module-type)1 ) … ( namen :
[module-type](modtypes.html#module-type)n ) -> module-expr

#### ﻿Functor application

The expression module-expr1 ( module-expr2 ) evaluates module-expr1 to a
functor and module-expr2 to a module, and applies the former to the latter.
The type of module-expr2 must match the type expected for the arguments of the
functor module-expr1.

* * *

[![Previous](previous_motif.svg)](modtypes.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](compunit.html)

