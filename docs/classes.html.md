[![Previous](previous_motif.svg)](typedecl.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](modtypes.html)

* * *

## ﻿11.9 Classes

  * [11.9.1 Class types](classes.html#ss%3Aclasses%3Aclass-types)
  * [11.9.2 Class expressions](classes.html#ss%3Aclass-expr)
  * [11.9.3 Class definitions](classes.html#ss%3Aclass-def)
  * [11.9.4 Class specifications](classes.html#ss%3Aclass-spec)
  * [11.9.5 Class type definitions](classes.html#ss%3Aclasstype)

Classes are defined using a small language, similar to the module language.

### ﻿11.9.1 Class types

Class types are the class-level equivalent of type expressions: they specify
the general shape and type properties of classes.

| class-type| ::=|  [[?][label-name](lex.html#label-name):]
[typexpr](types.html#typexpr) -> class-type  
---|---|---  
 | ∣|  class-body-type  
  
class-body-type| ::=|  object [( [typexpr](types.html#typexpr) )] { class-
field-spec } end  
 | ∣|  [[ [typexpr](types.html#typexpr) { , [typexpr](types.html#typexpr) } ]] [classtype-path](names.html#classtype-path)  
 | ∣|  let open [module-path](names.html#module-path) in class-body-type  
  
class-field-spec| ::=|  inherit class-body-type  
 | ∣|  val [mutable] [virtual] [inst-var-name](names.html#inst-var-name) : [typexpr](types.html#typexpr)  
 | ∣|  val virtual mutable [inst-var-name](names.html#inst-var-name) : [typexpr](types.html#typexpr)  
 | ∣|  method [private] [virtual] [method-name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr)  
 | ∣|  method virtual private [method-name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr)  
 | ∣|  constraint [typexpr](types.html#typexpr) = [typexpr](types.html#typexpr)  
  
See also the following language extensions:
[attributes](attributes.html#s%3Aattributes) and [extension
nodes](extensionnodes.html#s%3Aextension-nodes).

#### ﻿Simple class expressions

The expression [classtype-path](names.html#classtype-path) is equivalent to
the class type bound to the name [classtype-path](names.html#classtype-path).
Similarly, the expression [ [typexpr](types.html#typexpr)1 , …
[typexpr](types.html#typexpr)n ] [classtype-path](names.html#classtype-path)
is equivalent to the parametric class type bound to the name [classtype-
path](names.html#classtype-path), in which type parameters have been
instantiated to respectively [typexpr](types.html#typexpr)1,
…[typexpr](types.html#typexpr)n.

#### ﻿Class function type

The class type expression [typexpr](types.html#typexpr) -> class-type is the
type of class functions (functions from values to classes) that take as
argument a value of type [typexpr](types.html#typexpr) and return as result a
class of type class-type.

#### ﻿Class body type

The class type expression object [( [typexpr](types.html#typexpr) )] { class-
field-spec } end is the type of a class body. It specifies its instance
variables and methods. In this type, [typexpr](types.html#typexpr) is matched
against the self type, therefore providing a name for the self type.

A class body will match a class body type if it provides definitions for all
the components specified in the class body type, and these definitions meet
the type requirements given in the class body type. Furthermore, all methods
either virtual or public present in the class body must also be present in the
class body type (on the other hand, some instance variables and concrete
private methods may be omitted). A virtual method will match a concrete
method, which makes it possible to forget its implementation. An immutable
instance variable will match a mutable instance variable.

#### ﻿Local opens

Local opens are supported in class types since OCaml 4.06.

#### ﻿Inheritance

The inheritance construct inherit class-body-type provides for inclusion of
methods and instance variables from other class types. The instance variable
and method types from class-body-type are added into the current class type.

#### ﻿Instance variable specification

A specification of an instance variable is written val [mutable] [virtual]
[inst-var-name](names.html#inst-var-name) : [typexpr](types.html#typexpr),
where [inst-var-name](names.html#inst-var-name) is the name of the instance
variable and [typexpr](types.html#typexpr) its expected type. The flag mutable
indicates whether this instance variable can be physically modified. The flag
virtual indicates that this instance variable is not initialized. It can be
initialized later through inheritance.

An instance variable specification will hide any previous specification of an
instance variable of the same name.

#### ﻿Method specification

The specification of a method is written method [private] [method-
name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr), where
[method-name](names.html#method-name) is the name of the method and [poly-
typexpr](types.html#poly-typexpr) its expected type, possibly polymorphic. The
flag private indicates that the method cannot be accessed from outside the
object.

The polymorphism may be left implicit in public method specifications: any
type variable which is not bound to a class parameter and does not appear
elsewhere inside the class specification will be assumed to be universal, and
made polymorphic in the resulting method type. Writing an explicit polymorphic
type will disable this behaviour.

If several specifications are present for the same method, they must have
compatible types. Any non-private specification of a method forces it to be
public.

#### ﻿Virtual method specification

A virtual method specification is written method [private] virtual [method-
name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr), where
[method-name](names.html#method-name) is the name of the method and [poly-
typexpr](types.html#poly-typexpr) its expected type.

#### ﻿Constraints on type parameters

The construct constraint [typexpr](types.html#typexpr)1 =
[typexpr](types.html#typexpr)2 forces the two type expressions to be equal.
This is typically used to specify type parameters: in this way, they can be
bound to specific type expressions.

### ﻿11.9.2 Class expressions

Class expressions are the class-level equivalent of value expressions: they
evaluate to classes, thus providing implementations for the specifications
expressed in class types.

| class-expr| ::=|  [class-path](names.html#class-path)  
---|---|---  
 | ∣|  [ [typexpr](types.html#typexpr) { , [typexpr](types.html#typexpr) } ] [class-path](names.html#class-path)  
 | ∣|  ( class-expr )  
 | ∣|  ( class-expr : class-type )  
 | ∣|  class-expr { [argument](expr.html#argument) }+  
 | ∣|  fun { [parameter](expr.html#parameter) }+ -> class-expr  
 | ∣|  let [rec] [let-binding](expr.html#let-binding) { and [let-binding](expr.html#let-binding) } in class-expr  
 | ∣|  object class-body end  
 | ∣|  let open [module-path](names.html#module-path) in class-expr  
  
  
| class-field| ::=|  inherit class-expr [as [lowercase-
ident](lex.html#lowercase-ident)]  
---|---|---  
 | ∣|  inherit! class-expr [as [lowercase-ident](lex.html#lowercase-ident)]   
 | ∣|  val [mutable] [inst-var-name](names.html#inst-var-name) [: [typexpr](types.html#typexpr)] = [expr](expr.html#expr)  
 | ∣|  val! [mutable] [inst-var-name](names.html#inst-var-name) [: [typexpr](types.html#typexpr)] = [expr](expr.html#expr)  
 | ∣|  val [mutable] virtual [inst-var-name](names.html#inst-var-name) : [typexpr](types.html#typexpr)  
 | ∣|  val virtual mutable [inst-var-name](names.html#inst-var-name) : [typexpr](types.html#typexpr)  
 | ∣|  method [private] [method-name](names.html#method-name) { [parameter](expr.html#parameter) } [: [typexpr](types.html#typexpr)] = [expr](expr.html#expr)  
 | ∣|  method! [private] [method-name](names.html#method-name) { [parameter](expr.html#parameter) } [: [typexpr](types.html#typexpr)] = [expr](expr.html#expr)  
 | ∣|  method [private] [method-name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr) = [expr](expr.html#expr)  
 | ∣|  method! [private] [method-name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr) = [expr](expr.html#expr)  
 | ∣|  method [private] virtual [method-name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr)  
 | ∣|  method virtual private [method-name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr)  
 | ∣|  constraint [typexpr](types.html#typexpr) = [typexpr](types.html#typexpr)  
 | ∣|  initializer [expr](expr.html#expr)  
  
See also the following language extensions: [locally abstract
types](locallyabstract.html#s%3Alocally-abstract),
[attributes](attributes.html#s%3Aattributes) and [extension
nodes](extensionnodes.html#s%3Aextension-nodes).

#### ﻿Simple class expressions

The expression [class-path](names.html#class-path) evaluates to the class
bound to the name [class-path](names.html#class-path). Similarly, the
expression [ [typexpr](types.html#typexpr)1 , … [typexpr](types.html#typexpr)n
] [class-path](names.html#class-path) evaluates to the parametric class bound
to the name [class-path](names.html#class-path), in which type parameters have
been instantiated respectively to [typexpr](types.html#typexpr)1,
…[typexpr](types.html#typexpr)n.

The expression ( class-expr ) evaluates to the same module as class-expr.

The expression ( class-expr : class-type ) checks that class-type matches the
type of class-expr (that is, that the implementation class-expr meets the type
specification class-type). The whole expression evaluates to the same class as
class-expr, except that all components not specified in class-type are hidden
and can no longer be accessed.

#### ﻿Class application

Class application is denoted by juxtaposition of (possibly labeled)
expressions. It denotes the class whose constructor is the first expression
applied to the given arguments. The arguments are evaluated as for expression
application, but the constructor itself will only be evaluated when objects
are created. In particular, side-effects caused by the application of the
constructor will only occur at object creation time.

#### ﻿Class function

The expression fun [[?][label-name](lex.html#label-
name):][pattern](patterns.html#pattern) -> class-expr evaluates to a function
from values to classes. When this function is applied to a value v, this value
is matched against the pattern [pattern](patterns.html#pattern) and the result
is the result of the evaluation of class-expr in the extended environment.

Conversion from functions with default values to functions with patterns only
works identically for class functions as for normal functions.

The expression

fun [parameter](expr.html#parameter)1 … [parameter](expr.html#parameter)n ->
class-expr

is a short form for

fun [parameter](expr.html#parameter)1 -> … fun
[parameter](expr.html#parameter)n -> [expr](expr.html#expr)

#### ﻿Local definitions

The let and let rec constructs bind value names locally, as for the core
language expressions.

If a local definition occurs at the very beginning of a class definition, it
will be evaluated when the class is created (just as if the definition was
outside of the class). Otherwise, it will be evaluated when the object
constructor is called.

#### ﻿Local opens

Local opens are supported in class expressions since OCaml 4.06.

#### ﻿Class body

| class-body| ::=|  [( [pattern](patterns.html#pattern) [:
[typexpr](types.html#typexpr)] )] { class-field }  
---|---|---  
  
The expression object class-body end denotes a class body. This is the
prototype for an object : it lists the instance variables and methods of an
object of this class.

A class body is a class value: it is not evaluated at once. Rather, its
components are evaluated each time an object is created.

In a class body, the pattern ( [pattern](patterns.html#pattern) [:
[typexpr](types.html#typexpr)] ) is matched against self, therefore providing
a binding for self and self type. Self can only be used in method and
initializers.

Self type cannot be a closed object type, so that the class remains
extensible.

Since OCaml 4.01, it is an error if the same method or instance variable name
is defined several times in the same class body.

#### ﻿Inheritance

The inheritance construct inherit class-expr allows reusing methods and
instance variables from other classes. The class expression class-expr must
evaluate to a class body. The instance variables, methods and initializers
from this class body are added into the current class. The addition of a
method will override any previously defined method of the same name.

An ancestor can be bound by appending as [lowercase-ident](lex.html#lowercase-
ident) to the inheritance construct. [lowercase-ident](lex.html#lowercase-
ident) is not a true variable and can only be used to select a method, i.e. in
an expression [lowercase-ident](lex.html#lowercase-ident) # [method-
name](names.html#method-name). This gives access to the method [method-
name](names.html#method-name) as it was defined in the parent class even if it
is redefined in the current class. The scope of this ancestor binding is
limited to the current class. The ancestor method may be called from a
subclass but only indirectly.

#### ﻿Instance variable definition

The definition val [mutable] [inst-var-name](names.html#inst-var-name) =
[expr](expr.html#expr) adds an instance variable [inst-var-
name](names.html#inst-var-name) whose initial value is the value of expression
[expr](expr.html#expr). The flag mutable allows physical modification of this
variable by methods.

An instance variable can only be used in the methods and initializers that
follow its definition.

Since version 3.10, redefinitions of a visible instance variable with the same
name do not create a new variable, but are merged, using the last value for
initialization. They must have identical types and mutability. However, if an
instance variable is hidden by omitting it from an interface, it will be kept
distinct from other instance variables with the same name.

#### ﻿Virtual instance variable definition

A variable specification is written val [mutable] virtual [inst-var-
name](names.html#inst-var-name) : [typexpr](types.html#typexpr). It specifies
whether the variable is modifiable, and gives its type.

Virtual instance variables were added in version 3.10.

#### ﻿Method definition

A method definition is written method [method-name](names.html#method-name) =
[expr](expr.html#expr). The definition of a method overrides any previous
definition of this method. The method will be public (that is, not private) if
any of the definition states so.

A private method, method private [method-name](names.html#method-name) =
[expr](expr.html#expr), is a method that can only be invoked on self (from
other methods of the same object, defined in this class or one of its
subclasses). This invocation is performed using the expression [value-
name](names.html#value-name) # [method-name](names.html#method-name), where
[value-name](names.html#value-name) is directly bound to self at the beginning
of the class definition. Private methods do not appear in object types. A
method may have both public and private definitions, but as soon as there is a
public one, all subsequent definitions will be made public.

Methods may have an explicitly polymorphic type, allowing them to be used
polymorphically in programs (even for the same object). The explicit
declaration may be done in one of three ways: (1) by giving an explicit
polymorphic type in the method definition, immediately after the method name,
_i.e._ method [private] [method-name](names.html#method-name) : { '
[ident](lex.html#ident) }+ . [typexpr](types.html#typexpr) =
[expr](expr.html#expr); (2) by a forward declaration of the explicit
polymorphic type through a virtual method definition; (3) by importing such a
declaration through inheritance and/or constraining the type of _self_.

Some special expressions are available in method bodies for manipulating
instance variables and duplicating self:

| [expr](expr.html#expr)| ::=|  …  
---|---|---  
 | ∣|  [inst-var-name](names.html#inst-var-name) <- [expr](expr.html#expr)  
 | ∣|  {< [ [inst-var-name](names.html#inst-var-name) = [expr](expr.html#expr) { ; [inst-var-name](names.html#inst-var-name) = [expr](expr.html#expr) } [;] ] >}  
  
The expression [inst-var-name](names.html#inst-var-name) <-
[expr](expr.html#expr) modifies in-place the current object by replacing the
value associated to [inst-var-name](names.html#inst-var-name) by the value of
[expr](expr.html#expr). Of course, this instance variable must have been
declared mutable.

The expression {< [inst-var-name](names.html#inst-var-name)1 =
[expr](expr.html#expr)1 ; … ; [inst-var-name](names.html#inst-var-name)n =
[expr](expr.html#expr)n >} evaluates to a copy of the current object in which
the values of instance variables [inst-var-name](names.html#inst-var-name)1,
…, [inst-var-name](names.html#inst-var-name)n have been replaced by the values
of the corresponding expressions [expr](expr.html#expr)1, …,
[expr](expr.html#expr)n.

#### ﻿Virtual method definition

A method specification is written method [private] virtual [method-
name](names.html#method-name) : [poly-typexpr](types.html#poly-typexpr). It
specifies whether the method is public or private, and gives its type. If the
method is intended to be polymorphic, the type must be explicitly polymorphic.

#### ﻿Explicit overriding

Since Ocaml 3.12, the keywords inherit!, val! and method! have the same
semantics as inherit, val and method, but they additionally require the
definition they introduce to be overriding. Namely, method! requires [method-
name](names.html#method-name) to be already defined in this class, val!
requires [inst-var-name](names.html#inst-var-name) to be already defined in
this class, and inherit! requires class-expr to override some definitions. If
no such overriding occurs, an error is signaled.

As a side-effect, these 3 keywords avoid the warnings 7 (method override) and
13 (instance variable override). Note that warning 7 is disabled by default.

#### ﻿Constraints on type parameters

The construct constraint [typexpr](types.html#typexpr)1 =
[typexpr](types.html#typexpr)2 forces the two type expressions to be equals.
This is typically used to specify type parameters: in that way they can be
bound to specific type expressions.

#### ﻿Initializers

A class initializer initializer [expr](expr.html#expr) specifies an expression
that will be evaluated whenever an object is created from the class, once all
its instance variables have been initialized.

### ﻿11.9.3 Class definitions

| class-definition| ::=|  class class-binding { and class-binding }  
---|---|---  
  
class-binding| ::=|  [virtual] [[ type-parameters ]] [class-
name](names.html#class-name) { [parameter](expr.html#parameter) } [: class-
type] = class-expr  
  
type-parameters| ::=|  ' [ident](lex.html#ident) { , ' [ident](lex.html#ident)
}  
  
A class definition class class-binding { and class-binding } is recursive.
Each class-binding defines a [class-name](names.html#class-name) that can be
used in the whole expression except for inheritance. It can also be used for
inheritance, but only in the definitions that follow its own.

A class binding binds the class name [class-name](names.html#class-name) to
the value of expression class-expr. It also binds the class type [class-
name](names.html#class-name) to the type of the class, and defines two type
abbreviations : [class-name](names.html#class-name) and # [class-
name](names.html#class-name). The first one is the type of objects of this
class, while the second is more general as it unifies with the type of any
object belonging to a subclass (see section [11.4](types.html#sss%3Atypexpr-
sharp-types)).

#### ﻿Virtual class

A class must be flagged virtual if one of its methods is virtual (that is,
appears in the class type, but is not actually defined). Objects cannot be
created from a virtual class.

#### ﻿Type parameters

The class type parameters correspond to the ones of the class type and of the
two type abbreviations defined by the class binding. They must be bound to
actual types in the class definition using type constraints. So that the
abbreviations are well-formed, type variables of the inferred type of the
class must either be type parameters or be bound in the constraint clause.

### ﻿11.9.4 Class specifications

| class-specification| ::=|  class class-spec { and class-spec }  
---|---|---  
  
class-spec| ::=|  [virtual] [[ type-parameters ]] [class-
name](names.html#class-name) : class-type  
  
This is the counterpart in signatures of class definitions. A class
specification matches a class definition if they have the same type parameters
and their types match.

### ﻿11.9.5 Class type definitions

| classtype-definition| ::=|  class type classtype-def { and classtype-def }  
---|---|---  
  
classtype-def| ::=|  [virtual] [[ type-parameters ]] [class-
name](names.html#class-name) = class-body-type  
  
A class type definition class [class-name](names.html#class-name) = class-
body-type defines an abbreviation [class-name](names.html#class-name) for the
class body type class-body-type. As for class definitions, two type
abbreviations [class-name](names.html#class-name) and # [class-
name](names.html#class-name) are also defined. The definition can be
parameterized by some type parameters. If any method in the class type body is
virtual, the definition must be flagged virtual.

Two class type definitions match if they have the same type parameters and
they expand to matching types.

* * *

[![Previous](previous_motif.svg)](typedecl.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](modtypes.html)

