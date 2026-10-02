[![Previous](previous_motif.svg)](classes.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](modules.html)

* * *

## ﻿11.10 Module types (module specifications)

  * [11.10.1 Simple module types](modtypes.html#ss%3Amty-simple)
  * [11.10.2 Signatures](modtypes.html#ss%3Amty-signatures)
  * [11.10.3 Functor types](modtypes.html#ss%3Amty-functors)
  * [11.10.4 The with operator](modtypes.html#ss%3Amty-with)

Module types are the module-level equivalent of type expressions: they specify
the general shape and type properties of modules.

| module-type| ::=|  [modtype-path](names.html#modtype-path)  
---|---|---  
 | ∣|  sig { specification [;;] } end  
 | ∣|  [functor] { ( [module-name](names.html#module-name) : module-type ) }+ -> module-type  
 | ∣|  module-type -> module-type  
 | ∣|  module-type with mod-constraint { and mod-constraint }   
 | ∣|  ( module-type )  
  
mod-constraint| ::=|  type [[type-params](typedecl.html#type-params)]
[typeconstr](names.html#typeconstr) [type-equation](typedecl.html#type-
equation) { [type-constraint](typedecl.html#type-constraint) }  
 | ∣|  module [module-path](names.html#module-path) = [extended-module-path](names.html#extended-module-path)  
  
  
| specification| ::=|  val [value-name](names.html#value-name) :
[typexpr](types.html#typexpr)  
---|---|---  
 | ∣|  external [value-name](names.html#value-name) : [typexpr](types.html#typexpr) = [external-declaration](intfc.html#external-declaration)  
 | ∣|  [type-definition](typedecl.html#type-definition)  
 | ∣|  exception [constr-decl](typedecl.html#constr-decl)  
 | ∣|  [class-specification](classes.html#class-specification)  
 | ∣|  [classtype-definition](classes.html#classtype-definition)  
 | ∣|  module [module-name](names.html#module-name) : module-type  
 | ∣|  module [module-name](names.html#module-name) { ( [module-name](names.html#module-name) : module-type ) } : module-type  
 | ∣|  module type [modtype-name](names.html#modtype-name)  
 | ∣|  module type [modtype-name](names.html#modtype-name) = module-type  
 | ∣|  open [module-path](names.html#module-path)  
 | ∣|  include module-type  
  
See also the following language extensions: [recovering the type of a
module](moduletypeof.html#s%3Amodule-type-of), [substitution inside a
signature](signaturesubstitution.html#s%3Asignature-substitution), [type-level
module aliases](modulealias.html#s%3Amodule-alias),
[attributes](attributes.html#s%3Aattributes), [extension
nodes](extensionnodes.html#s%3Aextension-nodes), [generative
functors](generativefunctors.html#s%3Agenerative-functors), and [module type
substitutions](signaturesubstitution.html#ss%3Amodule-type-substitution).

### ﻿11.10.1 Simple module types

The expression [modtype-path](names.html#modtype-path) is equivalent to the
module type bound to the name [modtype-path](names.html#modtype-path). The
expression ( module-type ) denotes the same type as module-type.

### ﻿11.10.2 Signatures

Signatures are type specifications for structures. Signatures sig … end are
collections of type specifications for value names, type names, exceptions,
module names and module type names. A structure will match a signature if the
structure provides definitions (implementations) for all the names specified
in the signature (and possibly more), and these definitions meet the type
requirements given in the signature.

An optional ;; is allowed after each specification in a signature. It serves
as a syntactic separator with no semantic meaning.

#### ﻿Value specifications

A specification of a value component in a signature is written val [value-
name](names.html#value-name) : [typexpr](types.html#typexpr), where [value-
name](names.html#value-name) is the name of the value and
[typexpr](types.html#typexpr) its expected type.

The form external [value-name](names.html#value-name) :
[typexpr](types.html#typexpr) = [external-declaration](intfc.html#external-
declaration) is similar, except that it requires in addition the name to be
implemented as the external function specified in [external-
declaration](intfc.html#external-declaration) (see chapter
[23](intfc.html#c%3Aintf-c)).

#### ﻿Type specifications

A specification of one or several type components in a signature is written
type [typedef](typedecl.html#typedef) { and [typedef](typedecl.html#typedef) }
and consists of a sequence of mutually recursive definitions of type names.

Each type definition in the signature specifies an optional type equation =
[typexpr](types.html#typexpr) and an optional type representation = [constr-
decl](typedecl.html#constr-decl) … or = { [field-decl](typedecl.html#field-
decl) … }. The implementation of the type name in a matching structure must be
compatible with the type expression specified in the equation (if given), and
have the specified representation (if given). Conversely, users of that
signature will be able to rely on the type equation or type representation, if
given. More precisely, we have the following four situations:

Abstract type: no equation, no representation.

       
Names that are defined as abstract types in a signature can be implemented in
a matching structure by any kind of type definition (provided it has the same
number of type parameters). The exact implementation of the type will be
hidden to the users of the structure. In particular, if the type is
implemented as a variant type or record type, the associated constructors and
fields will not be accessible to the users; if the type is implemented as an
abbreviation, the type equality between the type name and the right-hand side
of the abbreviation will be hidden from the users of the structure. Users of
the structure consider that type as incompatible with any other type: a fresh
type has been generated.

Type abbreviation: an equation = [typexpr](types.html#typexpr), no
representation.

       
The type name must be implemented by a type compatible with
[typexpr](types.html#typexpr). All users of the structure know that the type
name is compatible with [typexpr](types.html#typexpr).

New variant type or record type: no equation, a representation.

       
The type name must be implemented by a variant type or record type with
exactly the constructors or fields specified. All users of the structure have
access to the constructors or fields, and can use them to create or inspect
values of that type. However, users of the structure consider that type as
incompatible with any other type: a fresh type has been generated.

Re-exported variant type or record type: an equation, a representation.

       
This case combines the previous two: the representation of the type is made
visible to all users, and no fresh type is generated.

#### ﻿Exception specification

The specification exception [constr-decl](typedecl.html#constr-decl) in a
signature requires the matching structure to provide an exception with the
name and arguments specified in the definition, and makes the exception
available to all users of the structure.

#### ﻿Class specifications

A specification of one or several classes in a signature is written class
[class-spec](classes.html#class-spec) { and [class-spec](classes.html#class-
spec) } and consists of a sequence of mutually recursive definitions of class
names.

Class specifications are described more precisely in section
[11.9.4](classes.html#ss%3Aclass-spec).

#### ﻿Class type specifications

A specification of one or several class types in a signature is written class
type [classtype-def](classes.html#classtype-def) { and [classtype-
def](classes.html#classtype-def) } and consists of a sequence of mutually
recursive definitions of class type names. Class type specifications are
described more precisely in section [11.9.5](classes.html#ss%3Aclasstype).

#### ﻿Module specifications

A specification of a module component in a signature is written module
[module-name](names.html#module-name) : module-type, where [module-
name](names.html#module-name) is the name of the module component and module-
type its expected type. Modules can be nested arbitrarily; in particular,
functors can appear as components of structures and functor types as
components of signatures.

For specifying a module component that is a functor, one may write

module [module-name](names.html#module-name) ( name1 : module-type1 ) … (
namen : module-typen ) : module-type

instead of

module [module-name](names.html#module-name) : ( name1 : module-type1 ) … (
namen : module-typen ) -> module-type

#### ﻿Module type specifications

A module type component of a signature can be specified either as a manifest
module type or as an abstract module type.

An abstract module type specification module type [modtype-
name](names.html#modtype-name) allows the name [modtype-
name](names.html#modtype-name) to be implemented by any module type in a
matching signature, but hides the implementation of the module type to all
users of the signature.

A manifest module type specification module type [modtype-
name](names.html#modtype-name) = module-type requires the name [modtype-
name](names.html#modtype-name) to be implemented by the module type module-
type in a matching signature, but makes the equality between [modtype-
name](names.html#modtype-name) and module-type apparent to all users of the
signature.

#### ﻿Opening a module path

The expression open [module-path](names.html#module-path) in a signature does
not specify any components. It simply affects the parsing of the following
items of the signature, allowing components of the module denoted by [module-
path](names.html#module-path) to be referred to by their simple names name
instead of path accesses [module-path](names.html#module-path) . name. The
scope of the open stops at the end of the signature expression.

#### ﻿Including a signature

The expression include module-type in a signature performs textual inclusion
of the components of the signature denoted by module-type. It behaves as if
the components of the included signature were copied at the location of the
include. The module-type argument must refer to a module type that is a
signature, not a functor type.

### ﻿11.10.3 Functor types

The module type expression [functor] ( [module-name](names.html#module-name) :
module-type1 ) -> module-type2 is the type of functors (functions from modules
to modules) that take as argument a module of type module-type1 and return as
result a module of type module-type2. The module type module-type2 can use the
name [module-name](names.html#module-name) to refer to type components of the
actual argument of the functor. If the type module-type2 does not depend on
type components of [module-name](names.html#module-name), the module type
expression can be simplified with the alternative short syntax module-type1 ->
module-type2 . No restrictions are placed on the type of the functor argument;
in particular, a functor may take another functor as argument (“higher-order”
functor).

When the result module type is itself a functor,

( name1 : module-type1 ) -> … -> ( namen : module-typen ) -> module-type

one may use the abbreviated form

( name1 : module-type1 ) … ( namen : module-typen ) -> module-type

### ﻿11.10.4 The with operator

Assuming module-type denotes a signature, the expression module-type with mod-
constraint { and mod-constraint } denotes the same signature where type
equations have been added to some of the type specifications, as described by
the constraints following the with keyword. The constraint type [[type-
parameters](classes.html#type-parameters)] [typeconstr](names.html#typeconstr)
= [typexpr](types.html#typexpr) adds the type equation =
[typexpr](types.html#typexpr) to the specification of the type component named
[typeconstr](names.html#typeconstr) of the constrained signature. The
constraint module [module-path](names.html#module-path) = [extended-module-
path](names.html#extended-module-path) adds type equations to all type
components of the sub-structure denoted by [module-path](names.html#module-
path), making them equivalent to the corresponding type components of the
structure denoted by [extended-module-path](names.html#extended-module-path).

For instance, if the module type name S is bound to the signature

    
    
            sig type t module M: (sig type u end) end
    

then S with type t=int denotes the signature

    
    
            sig type t=int module M: (sig type u end) end
    

and S with module M = N denotes the signature

    
    
            sig type t module M: (sig type u=N.u end) end
    

A functor taking two arguments of type S that share their t component is
written

    
    
            functor (A: S) (B: S with type t = A.t) ...
    

Constraints are added left to right. After each constraint has been applied,
the resulting signature must be a subtype of the signature before the
constraint was applied. Thus, the with operator can only add information on
the type components of a signature, but never remove information.

* * *

[![Previous](previous_motif.svg)](classes.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](modules.html)

