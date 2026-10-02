[![Previous](previous_motif.svg)](moduleexamples.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](lablexamples.html)

* * *

# Chapter 3 Objects in OCaml

  * [3.1 Classes and objects](objectexamples.html#s%3Aclasses-and-objects)
  * [3.2 Immediate objects](objectexamples.html#s%3Aimmediate-objects)
  * [3.3 Reference to self](objectexamples.html#s%3Areference-to-self)
  * [3.4 Initializers](objectexamples.html#s%3Ainitializers)
  * [3.5 Virtual methods](objectexamples.html#s%3Avirtual-methods)
  * [3.6 Private methods](objectexamples.html#s%3Aprivate-methods)
  * [3.7 Class interfaces](objectexamples.html#s%3Aclass-interfaces)
  * [3.8 Inheritance](objectexamples.html#s%3Ainheritance)
  * [3.9 Multiple inheritance](objectexamples.html#s%3Amultiple-inheritance)
  * [3.10 Parameterized classes](objectexamples.html#s%3Aparameterized-classes)
  * [3.11 Polymorphic methods](objectexamples.html#s%3Apolymorphic-methods)
  * [3.12 Using coercions](objectexamples.html#s%3Ausing-coercions)
  * [3.13 Functional objects](objectexamples.html#s%3Afunctional-objects)
  * [3.14 Cloning objects](objectexamples.html#s%3Acloning-objects)
  * [3.15 Recursive classes](objectexamples.html#s%3Arecursive-classes)
  * [3.16 Binary methods](objectexamples.html#s%3Abinary-methods)
  * [3.17 Friends](objectexamples.html#s%3Afriends)

(Chapter written by Jérôme Vouillon, Didier Rémy and Jacques Garrigue)

  
  

This chapter gives an overview of the object-oriented features of OCaml.

Note that the relationship between object, class and type in OCaml is
different than in mainstream object-oriented languages such as Java and C++,
so you shouldn’t assume that similar keywords mean the same thing. Object-
oriented features are used much less frequently in OCaml than in those
languages. OCaml has alternatives that are often more appropriate, such as
modules and functors. Indeed, many OCaml programs do not use objects at all.

## ﻿3.1 Classes and objects

The class point below defines one instance variable x and two methods get_x
and move. The initial value of the instance variable is 0. The variable x is
declared mutable, so the method move can change its value.

# class point = object val mutable x = 0 method get_x = x method move d = x
<\- x + d end;;

class point : object val mutable x : int method get_x : int method move : int
-> unit end

We now create a new point p, instance of the point class.

# let p = new point;;

val p : point = <obj>

Note that the type of p is point. This is an abbreviation automatically
defined by the class definition above. It stands for the object type <get_x :
int; move : int -> unit>, listing the methods of class point along with their
types.

We now invoke some methods of p:

# p#get_x;;

\- : int = 0

# p#move 3;;

\- : unit = ()

# p#get_x;;

\- : int = 3

The evaluation of the body of a class only takes place at object creation
time. Therefore, in the following example, the instance variable x is
initialized to different values for two different objects.

# let x0 = ref 0;;

val x0 : int ref = {contents = 0}

# class point = object val mutable x = incr x0; !x0 method get_x = x method
move d = x <\- x + d end;;

class point : object val mutable x : int method get_x : int method move : int
-> unit end

# new point#get_x;;

\- : int = 1

# new point#get_x;;

\- : int = 2

The class point can also be abstracted over the initial values of the x
coordinate.

# class point = fun x_init -> object val mutable x = x_init method get_x = x
method move d = x <\- x + d end;;

class point : int -> object val mutable x : int method get_x : int method move
: int -> unit end

Like in function definitions, the definition above can be abbreviated as:

# class point x_init = object val mutable x = x_init method get_x = x method
move d = x <\- x + d end;;

class point : int -> object val mutable x : int method get_x : int method move
: int -> unit end

An instance of the class point is now a function that expects an initial
parameter to create a point object:

# new point;;

\- : int -> point = <fun>

# let p = new point 7;;

val p : point = <obj>

The parameter x_init is, of course, visible in the whole body of the
definition, including methods. For instance, the method get_offset in the
class below returns the position of the object relative to its initial
position.

# class point x_init = object val mutable x = x_init method get_x = x method
get_offset = x - x_init method move d = x <\- x + d end;;

class point : int -> object val mutable x : int method get_offset : int method
get_x : int method move : int -> unit end

Expressions can be evaluated and bound before defining the object body of the
class. This is useful to enforce invariants. For instance, points can be
automatically adjusted to the nearest point on a grid, as follows:

# class adjusted_point x_init = let origin = (x_init / 10) * 10 in object val
mutable x = origin method get_x = x method get_offset = x - origin method move
d = x <\- x + d end;;

class adjusted_point : int -> object val mutable x : int method get_offset :
int method get_x : int method move : int -> unit end

(One could also raise an exception if the x_init coordinate is not on the
grid.) In fact, the same effect could be obtained here by calling the
definition of class point with the value of the origin.

# class adjusted_point x_init = point ((x_init / 10) * 10);;

class adjusted_point : int -> point

An alternate solution would have been to define the adjustment in a special
allocation function:

# let new_adjusted_point x_init = new point ((x_init / 10) * 10);;

val new_adjusted_point : int -> point = <fun>

However, the former pattern is generally more appropriate, since the code for
adjustment is part of the definition of the class and will be inherited.

This ability provides class constructors as can be found in other languages.
Several constructors can be defined this way to build objects of the same
class but with different initialization patterns; an alternative is to use
initializers, as described below in section 3.4.

## ﻿3.2 Immediate objects

There is another, more direct way to create an object: create it without going
through a class.

The syntax is exactly the same as for class expressions, but the result is a
single object rather than a class. All the constructs described in the rest of
this section also apply to immediate objects.

# let p = object val mutable x = 0 method get_x = x method move d = x <\- x +
d end;;

val p : < get_x : int; move : int -> unit > = <obj>

# p#get_x;;

\- : int = 0

# p#move 3;;

\- : unit = ()

# p#get_x;;

\- : int = 3

Unlike classes, which cannot be defined inside an expression, immediate
objects can appear anywhere, using variables from their environment.

# let minmax x y = if x < y then object method min = x method max = y end else
object method min = y method max = x end;;

val minmax : 'a -> 'a -> < max : 'a; min : 'a > = <fun>

Immediate objects have two weaknesses compared to classes: their types are not
abbreviated, and you cannot inherit from them. But these two weaknesses can be
advantages in some situations, as we will see in sections 3.3 and 3.10.

## ﻿3.3 Reference to self

A method or an initializer can invoke methods on self (that is, the current
object). For that, self must be explicitly bound, here to the variable s (s
could be any identifier, even though we will often choose the name self.)

# class printable_point x_init = object (s) val mutable x = x_init method
get_x = x method move d = x <\- x + d method print = print_int s#get_x end;;

class printable_point : int -> object val mutable x : int method get_x : int
method move : int -> unit method print : unit end

# let p = new printable_point 7;;

val p : printable_point = <obj>

# p#print;;

7- : unit = ()

Dynamically, the variable s is bound at the invocation of a method. In
particular, when the class printable_point is inherited, the variable s will
be correctly bound to the object of the subclass.

A common problem with self is that, as its type may be extended in subclasses,
you cannot fix it in advance. Here is a simple example.

# let ints = ref [];;

val ints : '_weak1 list ref = {contents = []}

# class my_int = object (self) method n = 1 method register = ints := self ::
!ints end ;;

Error: The value self has type < n : int; register : 'a; .. > but an
expression was expected of type 'weak1 Self type cannot escape its class

You can ignore the first two lines of the error message. What matters is the
last one: putting self into an external reference would make it impossible to
extend it through inheritance. We will see in section 3.12 a workaround to
this problem. Note however that, since immediate objects are not extensible,
the problem does not occur with them.

# let my_int = object (self) method n = 1 method register = ints := self ::
!ints end;;

val my_int : < n : int; register : unit > = <obj>

## ﻿3.4 Initializers

Let-bindings within class definitions are evaluated before the object is
constructed. It is also possible to evaluate an expression immediately after
the object has been built. Such code is written as an anonymous hidden method
called an initializer. Therefore, it can access self and the instance
variables.

# class printable_point x_init = let origin = (x_init / 10) * 10 in object
(self) val mutable x = origin method get_x = x method move d = x <\- x + d
method print = print_int self#get_x initializer print_string "new point at ";
self#print; print_newline () end;;

class printable_point : int -> object val mutable x : int method get_x : int
method move : int -> unit method print : unit end

# let p = new printable_point 17;;

new point at 10 val p : printable_point = <obj>

Initializers cannot be overridden. On the contrary, all initializers are
evaluated sequentially. Initializers are particularly useful to enforce
invariants. Another example can be seen in section
[8.1](advexamples.html#s%3Aextended-bank-accounts).

## ﻿3.5 Virtual methods

It is possible to declare a method without actually defining it, using the
keyword virtual. This method will be provided later in subclasses. A class
containing virtual methods must be flagged virtual, and cannot be instantiated
(that is, no object of this class can be created). It still defines type
abbreviations (treating virtual methods as other methods.)

# class virtual abstract_point x_init = object (self) method virtual get_x :
int method get_offset = self#get_x - x_init method virtual move : int -> unit
end;;

class virtual abstract_point : int -> object method get_offset : int method
virtual get_x : int method virtual move : int -> unit end

# class point x_init = object inherit abstract_point x_init val mutable x =
x_init method get_x = x method move d = x <\- x + d end;;

class point : int -> object val mutable x : int method get_offset : int method
get_x : int method move : int -> unit end

Instance variables can also be declared as virtual, with the same effect as
with methods.

# class virtual abstract_point2 = object val mutable virtual x : int method
move d = x <\- x + d end;;

class virtual abstract_point2 : object val mutable virtual x : int method move
: int -> unit end

# class point2 x_init = object inherit abstract_point2 val mutable x = x_init
method get_offset = x - x_init end;;

class point2 : int -> object val mutable x : int method get_offset : int
method move : int -> unit end

## ﻿3.6 Private methods

Private methods are methods that do not appear in object interfaces. They can
only be invoked from other methods of the same object.

# class restricted_point x_init = object (self) val mutable x = x_init method
get_x = x method private move d = x <\- x + d method bump = self#move 1 end;;

class restricted_point : int -> object val mutable x : int method bump : unit
method get_x : int method private move : int -> unit end

# let p = new restricted_point 0;;

val p : restricted_point = <obj>

# p#move 10 ;;

Error: This expression has type restricted_point = < bump : unit; get_x : int
> It has no method move

# p#bump;;

\- : unit = ()

Note that this is not the same thing as private and protected methods in Java
or C++, which can be called from other objects of the same class. This is a
direct consequence of the independence between types and classes in OCaml: two
unrelated classes may produce objects of the same type, and there is no way at
the type level to ensure that an object comes from a specific class. However a
possible encoding of friend methods is given in section 3.17.

Private methods are inherited (they are by default visible in subclasses),
unless they are hidden by signature matching, as described below.

Private methods can be made public in a subclass.

# class point_again x = object (self) inherit restricted_point x method
virtual move : _ end;;

class point_again : int -> object val mutable x : int method bump : unit
method get_x : int method move : int -> unit end

The annotation virtual here is only used to mention a method without providing
its definition. Since we didn’t add the private annotation, this makes the
method public, keeping the original definition.

An alternative definition is

# class point_again x = object (self : < move : _; ..> ) inherit
restricted_point x end;;

class point_again : int -> object val mutable x : int method bump : unit
method get_x : int method move : int -> unit end

The constraint on self’s type is requiring a public move method, and this is
sufficient to override private.

One could think that a private method should remain private in a subclass.
However, since the method is visible in a subclass, it is always possible to
pick its code and define a method of the same name that runs that code, so yet
another (heavier) solution would be:

# class point_again x = object inherit restricted_point x as super method move
= super#move end;;

class point_again : int -> object val mutable x : int method bump : unit
method get_x : int method move : int -> unit end

Of course, private methods can also be virtual. Then, the keywords must appear
in this order: method private virtual.

## ﻿3.7 Class interfaces

Class interfaces are inferred from class definitions. They may also be defined
directly and used to restrict the type of a class. Like class declarations,
they also define a new type abbreviation.

# class type restricted_point_type = object method get_x : int method bump :
unit end;;

class type restricted_point_type = object method bump : unit method get_x :
int end

# fun (x : restricted_point_type) -> x;;

\- : restricted_point_type -> restricted_point_type = <fun>

In addition to program documentation, class interfaces can be used to
constrain the type of a class. Both concrete instance variables and concrete
private methods can be hidden by a class type constraint. Public methods and
virtual members, however, cannot.

# class restricted_point' x = (restricted_point x : restricted_point_type);;

class restricted_point' : int -> restricted_point_type

Or, equivalently:

# class restricted_point' = (restricted_point : int ->
restricted_point_type);;

class restricted_point' : int -> restricted_point_type

The interface of a class can also be specified in a module signature, and used
to restrict the inferred signature of a module.

# module type POINT = sig class restricted_point' : int -> object method get_x
: int method bump : unit end end;;

module type POINT = sig class restricted_point' : int -> object method bump :
unit method get_x : int end end

# module Point : POINT = struct class restricted_point' = restricted_point
end;;

module Point : POINT

## ﻿3.8 Inheritance

We illustrate inheritance by defining a class of colored points that inherits
from the class of points. This class has all instance variables and all
methods of class point, plus a new instance variable c and a new method color.

# class colored_point x (c : string) = object inherit point x val c = c method
color = c end;;

class colored_point : int -> string -> object val c : string val mutable x :
int method color : string method get_offset : int method get_x : int method
move : int -> unit end

# let p' = new colored_point 5 "red";;

val p' : colored_point = <obj>

# p'#get_x, p'#color;;

\- : int * string = (5, "red")

A point and a colored point have incompatible types, since a point has no
method color. However, the function get_succ_x below is a generic function
applying method get_x to any object p that has this method (and possibly some
others, which are represented by an ellipsis in the type). Thus, it applies to
both points and colored points.

# let get_succ_x p = p#get_x + 1;;

val get_succ_x : < get_x : int; .. > -> int = <fun>

# get_succ_x p + get_succ_x p';;

\- : int = 8

Methods need not be declared previously, as shown by the example:

# let set_x p = p#set_x;;

val set_x : < set_x : 'a; .. > -> 'a = <fun>

# let incr p = set_x p (get_succ_x p);;

val incr : < get_x : int; set_x : int -> 'a; .. > -> 'a = <fun>

## ﻿3.9 Multiple inheritance

Multiple inheritance is allowed. Only the last definition of a method is kept:
the redefinition in a subclass of a method that was visible in the parent
class overrides the definition in the parent class. Previous definitions of a
method can be reused by binding the related ancestor. Below, super is bound to
the ancestor printable_point. The name super is a pseudo value identifier that
can only be used to invoke a super-class method, as in super#print.

# class printable_colored_point y c = object (self) val c = c method color = c
inherit printable_point y as super method! print = print_string "(";
super#print; print_string ", "; print_string (self#color); print_string ")"
end;;

class printable_colored_point : int -> string -> object val c : string val
mutable x : int method color : string method get_x : int method move : int ->
unit method print : unit end

# let p' = new printable_colored_point 17 "red";;

new point at (10, red) val p' : printable_colored_point = <obj>

# p'#print;;

(10, red)- : unit = ()

A private method that has been hidden in the parent class is no longer
visible, and is thus not overridden. Since initializers are treated as private
methods, all initializers along the class hierarchy are evaluated, in the
order they are introduced.

Note that for clarity’s sake, the method print is explicitly marked as
overriding another definition by annotating the method keyword with an
exclamation mark !. If the method print were not overriding the print method
of printable_point, the compiler would raise an error:

# object method! m = () end;;

Error: The method m has no previous definition

This explicit overriding annotation also works for val and inherit:

# class another_printable_colored_point y c c' = object (self) inherit
printable_point y inherit! printable_colored_point y c val! c = c' end;;

class another_printable_colored_point : int -> string -> string -> object val
c : string val mutable x : int method color : string method get_x : int method
move : int -> unit method print : unit end

## ﻿3.10 Parameterized classes

Reference cells can be implemented as objects. The naive definition fails to
typecheck:

# class oref x_init = object val mutable x = x_init method get = x method set
y = x <\- y end;;

Error: Some type variables are unbound in this type: class oref : 'a -> object
val mutable x : 'a method get : 'a method set : 'a -> unit end The method get
has type 'a where 'a is unbound

The reason is that at least one of the methods has a polymorphic type (here,
the type of the value stored in the reference cell), thus either the class
should be parametric, or the method type should be constrained to a
monomorphic type. A monomorphic instance of the class could be defined by:

# class oref (x_init:int) = object val mutable x = x_init method get = x
method set y = x <\- y end;;

class oref : int -> object val mutable x : int method get : int method set :
int -> unit end

Note that since immediate objects do not define a class type, they have no
such restriction.

# let new_oref x_init = object val mutable x = x_init method get = x method
set y = x <\- y end;;

val new_oref : 'a -> < get : 'a; set : 'a -> unit > = <fun>

On the other hand, a class for polymorphic references must explicitly list the
type parameters in its declaration. Class type parameters are listed between [
and ]. The type parameters must also be bound somewhere in the class body by a
type constraint.

# class ['a] oref x_init = object val mutable x = (x_init : 'a) method get = x
method set y = x <\- y end;;

class ['a] oref : 'a -> object val mutable x : 'a method get : 'a method set :
'a -> unit end

# let r = new oref 1 in r#set 2; (r#get);;

\- : int = 2

The type parameter in the declaration may actually be constrained in the body
of the class definition. In the class type, the actual value of the type
parameter is displayed in the constraint clause.

# class ['a] oref_succ (x_init:'a) = object val mutable x = x_init + 1 method
get = x method set y = x <\- y end;;

class ['a] oref_succ : 'a -> object constraint 'a = int val mutable x : int
method get : int method set : int -> unit end

Let us consider a more complex example: define a circle, whose center may be
any kind of point. We put an additional type constraint in method move, since
no free variables must remain unaccounted for by the class type parameters.

# class ['a] circle (c : 'a) = object val mutable center = c method center =
center method set_center c = center <\- c method move = (center#move : int ->
unit) end;;

class ['a] circle : 'a -> object constraint 'a = < move : int -> unit; .. >
val mutable center : 'a method center : 'a method move : int -> unit method
set_center : 'a -> unit end

An alternate definition of circle, using a constraint clause in the class
definition, is shown below. The type #point used below in the constraint
clause is an abbreviation produced by the definition of class point. This
abbreviation unifies with the type of any object belonging to a subclass of
class point. It actually expands to < get_x : int; move : int -> unit; .. >.
This leads to the following alternate definition of circle, which has slightly
stronger constraints on its argument, as we now expect center to have a method
get_x.

# class ['a] circle (c : 'a) = object constraint 'a = #point val mutable
center = c method center = center method set_center c = center <\- c method
move = center#move end;;

class ['a] circle : 'a -> object constraint 'a = #point val mutable center :
'a method center : 'a method move : int -> unit method set_center : 'a -> unit
end

The class colored_circle is a specialized version of class circle that
requires the type of the center to unify with #colored_point, and adds a
method color. Note that when specializing a parameterized class, the instance
of type parameter must always be explicitly given. It is again written between
[ and ].

# class ['a] colored_circle c = object constraint 'a = #colored_point inherit
['a] circle c method color = center#color end;;

class ['a] colored_circle : 'a -> object constraint 'a = #colored_point val
mutable center : 'a method center : 'a method color : string method move : int
-> unit method set_center : 'a -> unit end

## ﻿3.11 Polymorphic methods

While parameterized classes may be polymorphic in their contents, they are not
enough to allow polymorphism of method use.

A classical example is defining an iterator.

# List.fold_left;;

\- : ('acc -> 'a -> 'acc) -> 'acc -> 'a list -> 'acc = <fun>

# class ['a] intlist (l : int list) = object method empty = (l = []) method
fold f (accu : 'a) = List.fold_left f accu l end;;

class ['a] intlist : int list -> object method empty : bool method fold : ('a
-> int -> 'a) -> 'a -> 'a end

At first look, we seem to have a polymorphic iterator, however this does not
work in practice.

# let l = new intlist [1; 2; 3];;

val l : '_weak2 intlist = <obj>

# l#fold (fun x y -> x+y) 0;;

\- : int = 6

# l;;

\- : int intlist = <obj>

# l#fold (fun s x -> s ^ Int.to_string x ^ " ") "" ;;

Error: The value s has type int but an expression was expected of type string

Our iterator works, as shows its first use for summation. However, since
objects themselves are not polymorphic (only their constructors are), using
the fold method fixes its type for this individual object. Our next attempt to
use it as a string iterator fails.

The problem here is that quantification was wrongly located: it is not the
class we want to be polymorphic, but the fold method. This can be achieved by
giving an explicitly polymorphic type in the method definition.

# class intlist (l : int list) = object method empty = (l = []) method fold :
'a. ('a -> int -> 'a) -> 'a -> 'a = fun f accu -> List.fold_left f accu l
end;;

class intlist : int list -> object method empty : bool method fold : ('a ->
int -> 'a) -> 'a -> 'a end

# let l = new intlist [1; 2; 3];;

val l : intlist = <obj>

# l#fold (fun x y -> x+y) 0;;

\- : int = 6

# l#fold (fun s x -> s ^ Int.to_string x ^ " ") "";;

\- : string = "1 2 3 "

As you can see in the class type shown by the compiler, while polymorphic
method types must be fully explicit in class definitions (appearing
immediately after the method name), quantified type variables can be left
implicit in class descriptions. Why require types to be explicit? The problem
is that (int -> int -> int) -> int -> int would also be a valid type for fold,
and it happens to be incompatible with the polymorphic type we gave (automatic
instantiation only works for toplevel types variables, not for inner
quantifiers, where it becomes an undecidable problem.) So the compiler cannot
choose between those two types, and must be helped.

However, the type can be completely omitted in the class definition if it is
already known, through inheritance or type constraints on self. Here is an
example of method overriding.

# class intlist_rev l = object inherit intlist l method! fold f accu =
List.fold_left f accu (List.rev l) end;;

The following idiom separates description and definition.

# class type ['a] iterator = object method fold : ('b -> 'a -> 'b) -> 'b -> 'b
end;;

# class intlist' l = object (self : int #iterator) method empty = (l = [])
method fold f accu = List.fold_left f accu l end;;

Note here the (self : int #iterator) idiom, which ensures that this object
implements the interface iterator.

Polymorphic methods are called in exactly the same way as normal methods, but
you should be aware of some limitations of type inference. Namely, a
polymorphic method can only be called if its type is known at the call site.
Otherwise, the method will be assumed to be monomorphic, and given an
incompatible type.

# let sum lst = lst#fold (fun x y -> x+y) 0;;

val sum : < fold : (int -> int -> int) -> int -> 'a; .. > -> 'a = <fun>

# sum l ;;

Error: The value l has type intlist = < empty : bool; fold : 'a. ('a -> int ->
'a) -> 'a -> 'a > but an expression was expected of type < fold : (int -> int
-> int) -> int -> 'b; .. > The method fold has type 'a. ('a -> int -> 'a) ->
'a -> 'a, but the expected method type was (int -> int -> int) -> int -> 'b

The workaround is easy: you should put a type constraint on the parameter.

# let sum (lst : _ #iterator) = lst#fold (fun x y -> x+y) 0;;

val sum : int #iterator -> int = <fun>

Of course the constraint may also be an explicit method type. Only occurrences
of quantified variables are required.

# let sum lst = (lst : < fold : 'a. ('a -> _ -> 'a) -> 'a -> 'a; .. >)#fold
(+) 0;;

val sum : < fold : 'a. ('a -> int -> 'a) -> 'a -> 'a; .. > -> int = <fun>

Another use of polymorphic methods is to allow some form of implicit subtyping
in method arguments. We have already seen in section 3.8 how some functions
may be polymorphic in the class of their argument. This can be extended to
methods.

# class type point0 = object method get_x : int end;;

class type point0 = object method get_x : int end

# class distance_point x = object inherit point x method distance : 'a.
(#point0 as 'a) -> int = fun other -> abs (other#get_x - x) end;;

class distance_point : int -> object val mutable x : int method distance :
#point0 -> int method get_offset : int method get_x : int method move : int ->
unit end

# let p = new distance_point 3 in (p#distance (new point 8), p#distance (new
colored_point 1 "blue"));;

\- : int * int = (5, 2)

Note here the special syntax (#point0 as 'a) we have to use to quantify the
extensible part of #point0. As for the variable binder, it can be omitted in
class specifications. If you want polymorphism inside object field it must be
quantified independently.

# class multi_poly = object method m1 : 'a. (< n1 : 'b. 'b -> 'b; .. > as 'a)
-> _ = fun o -> o#n1 true, o#n1 "hello" method m2 : 'a 'b. (< n2 : 'b -> bool;
.. > as 'a) -> 'b -> _ = fun o x -> o#n2 x end;;

class multi_poly : object method m1 : < n1 : 'b. 'b -> 'b; .. > -> bool *
string method m2 : < n2 : 'b -> bool; .. > -> 'b -> bool end

In method m1, o must be an object with at least a method n1, itself
polymorphic. In method m2, the argument of n2 and x must have the same type,
which is quantified at the same level as 'a.

## ﻿3.12 Using coercions

Subtyping is never implicit. There are, however, two ways to perform
subtyping. The most general construction is fully explicit: both the domain
and the codomain of the type coercion must be given.

We have seen that points and colored points have incompatible types. For
instance, they cannot be mixed in the same list. However, a colored point can
be coerced to a point, hiding its color method:

# let colored_point_to_point cp = (cp : colored_point :> point);;

val colored_point_to_point : colored_point -> point = <fun>

# let p = new point 3 and q = new colored_point 4 "blue";;

val p : point = <obj> val q : colored_point = <obj>

# let l = [p; (colored_point_to_point q)];;

val l : point list = [<obj>; <obj>]

An object of type t can be seen as an object of type t' only if t is a subtype
of t'. For instance, a point cannot be seen as a colored point.

# (p : point :> colored_point);;

Error: Type point = abstract_point is not a subtype of colored_point = < color
: string; get_offset : int; get_x : int; move : int -> unit > The first object
type has no method color

Indeed, narrowing coercions without runtime checks would be unsafe. Runtime
type checks might raise exceptions, and they would require the presence of
type information at runtime, which is not the case in the OCaml system. For
these reasons, there is no such operation available in the language.

Be aware that subtyping and inheritance are not related. Inheritance is a
syntactic relation between classes while subtyping is a semantic relation
between types. For instance, the class of colored points could have been
defined directly, without inheriting from the class of points; the type of
colored points would remain unchanged and thus still be a subtype of points.

The domain of a coercion can often be omitted. For instance, one can define:

# let to_point cp = (cp :> point);;

val to_point : #point -> point = <fun>

In this case, the function colored_point_to_point is an instance of the
function to_point. This is not always true, however. The fully explicit
coercion is more precise and is sometimes unavoidable. Consider, for example,
the following class:

# class c0 = object method m = {< >} method n = 0 end;;

class c0 : object ('a) method m : 'a method n : int end

The object type c0 is an abbreviation for <m : 'a; n : int> as 'a. Consider
now the type declaration:

# class type c1 = object method m : c1 end;;

class type c1 = object method m : c1 end

The object type c1 is an abbreviation for the type <m : 'a> as 'a. The
coercion from an object of type c0 to an object of type c1 is correct:

# fun (x:c0) -> (x : c0 :> c1);;

\- : c0 -> c1 = <fun>

However, the domain of the coercion cannot always be omitted. In that case,
the solution is to use the explicit form. Sometimes, a change in the class-
type definition can also solve the problem

# class type c2 = object ('a) method m : 'a end;;

class type c2 = object ('a) method m : 'a end

# fun (x:c0) -> (x :> c2);;

\- : c0 -> c2 = <fun>

While class types c1 and c2 are different, both object types c1 and c2 expand
to the same object type (same method names and types). Yet, when the domain of
a coercion is left implicit and its co-domain is an abbreviation of a known
class type, then the class type, rather than the object type, is used to
derive the coercion function. This allows leaving the domain implicit in most
cases when coercing from a subclass to its superclass. The type of a coercion
can always be seen as below:

# let to_c1 x = (x :> c1);;

val to_c1 : < m : #c1; .. > -> c1 = <fun>

# let to_c2 x = (x :> c2);;

val to_c2 : #c2 -> c2 = <fun>

Note the difference between these two coercions: in the case of to_c2, the
type #c2 = < m : 'a; .. > as 'a is polymorphically recursive (according to the
explicit recursion in the class type of c2); hence the success of applying
this coercion to an object of class c0. On the other hand, in the first case,
c1 was only expanded and unrolled twice to obtain < m : < m : c1; .. >; .. >
(remember #c1 = < m : c1; .. >), without introducing recursion. You may also
note that the type of to_c2 is #c2 -> c2 while the type of to_c1 is more
general than #c1 -> c1. This is not always true, since there are class types
for which some instances of #c are not subtypes of c, as explained in section
3.16. Yet, for parameterless classes the coercion (_ :> c) is always more
general than (_ : #c :> c).

A common problem may occur when one tries to define a coercion to a class c
while defining class c. The problem is due to the type abbreviation not being
completely defined yet, and so its subtypes are not clearly known. Then, a
coercion (_ :> c) or (_ : #c :> c) is taken to be the identity function, as in

# fun x -> (x :> 'a);;

\- : 'a -> 'a = <fun>

As a consequence, if the coercion is applied to self, as in the following
example, the type of self is unified with the closed type c (a closed object
type is an object type without ellipsis). This would constrain the type of
self be closed and is thus rejected. Indeed, the type of self cannot be
closed: this would prevent any further extension of the class. Therefore, a
type error is generated when the unification of this type with another type
would result in a closed object type.

# class c = object method m = 1 end and d = object (self) inherit c method n =
2 method as_c = (self :> c) end;;

Error: This expression cannot be coerced to type c = < m : int >; it has type
< as_c : c; m : int; n : int; .. > but is here used with type c Self type
cannot escape its class

However, the most common instance of this problem, coercing self to its
current class, is detected as a special case by the type checker, and properly
typed.

# class c = object (self) method m = (self :> c) end;;

class c : object method m : c end

This allows the following idiom, keeping a list of all objects belonging to a
class or its subclasses:

# let all_c = ref [];;

val all_c : '_weak3 list ref = {contents = []}

# class c (m : int) = object (self) method m = m initializer all_c := (self :>
c) :: !all_c end;;

class c : int -> object method m : int end

This idiom can in turn be used to retrieve an object whose type has been
weakened:

# let rec lookup_obj obj = function [] -> raise Not_found | obj' :: l -> if (obj :> < >) = (obj' :> < >) then obj' else lookup_obj obj l ;;

val lookup_obj : < .. > -> (< .. > as 'a) list -> 'a = <fun>

# let lookup_c obj = lookup_obj obj !all_c;;

val lookup_c : < .. > -> < m : int > = <fun>

The type < m : int > we see here is just the expansion of c, due to the use of
a reference; we have succeeded in getting back an object of type c.

  
The previous coercion problem can often be avoided by first defining the
abbreviation, using a class type:

# class type c' = object method m : int end;;

class type c' = object method m : int end

# class c : c' = object method m = 1 end and d = object (self) inherit c
method n = 2 method as_c = (self :> c') end;;

class c : c' and d : object method as_c : c' method m : int method n : int end

It is also possible to use a virtual class. Inheriting from this class
simultaneously forces all methods of c to have the same type as the methods of
c'.

# class virtual c' = object method virtual m : int end;;

class virtual c' : object method virtual m : int end

# class c = object (self) inherit c' method m = 1 end;;

class c : object method m : int end

One could think of defining the type abbreviation directly:

# type c' = <m : int>;;

However, the abbreviation #c' cannot be defined directly in a similar way. It
can only be defined by a class or a class-type definition. This is because a
#-abbreviation carries an implicit anonymous variable .. that cannot be
explicitly named. The closer you get to it is:

# type 'a c'_class = 'a constraint 'a = < m : int; .. >;;

with an extra type variable capturing the open object type.

## ﻿3.13 Functional objects

It is possible to write a version of class point without assignments on the
instance variables. The override construct {< ... >} returns a copy of “self”
(that is, the current object), possibly changing the value of some instance
variables.

# class functional_point y = object val x = y method get_x = x method move d =
{< x = x + d >} method move_to x = {< x >} end;;

class functional_point : int -> object ('a) val x : int method get_x : int
method move : int -> 'a method move_to : int -> 'a end

# let p = new functional_point 7;;

val p : functional_point = <obj>

# p#get_x;;

\- : int = 7

# (p#move 3)#get_x;;

\- : int = 10

# (p#move_to 15)#get_x;;

\- : int = 15

# p#get_x;;

\- : int = 7

As with records, the form {< x >} is an elided version of {< x = x >} which
avoids the repetition of the instance variable name. Note that the type
abbreviation functional_point is recursive, which can be seen in the class
type of functional_point: the type of self is 'a and 'a appears inside the
type of the method move.

The above definition of functional_point is not equivalent to the following:

# class bad_functional_point y = object val x = y method get_x = x method move
d = new bad_functional_point (x+d) method move_to x = new bad_functional_point
x end;;

class bad_functional_point : int -> object val x : int method get_x : int
method move : int -> bad_functional_point method move_to : int ->
bad_functional_point end

While objects of either class will behave the same, objects of their
subclasses will be different. In a subclass of bad_functional_point, the
method move will keep returning an object of the parent class. On the
contrary, in a subclass of functional_point, the method move will return an
object of the subclass.

Functional update is often used in conjunction with binary methods as
illustrated in section [8.2.1](advexamples.html#ss%3Astring-as-class).

## ﻿3.14 Cloning objects

Objects can also be cloned, whether they are functional or imperative. The
library function Oo.copy makes a shallow copy of an object. That is, it
returns a new object that has the same methods and instance variables as its
argument. The instance variables are copied but their contents are shared.
Assigning a new value to an instance variable of the copy (using a method
call) will not affect instance variables of the original, and conversely. A
deeper assignment (for example if the instance variable is a reference cell)
will of course affect both the original and the copy.

The type of Oo.copy is the following:

# Oo.copy;;

\- : (< .. > as 'a) -> 'a = <fun>

The keyword as in that type binds the type variable 'a to the object type < ..
>. Therefore, Oo.copy takes an object with any methods (represented by the
ellipsis), and returns an object of the same type. The type of Oo.copy is
different from type < .. > -> < .. > as each ellipsis represents a different
set of methods. Ellipsis actually behaves as a type variable.

# let p = new point 5;;

val p : point = <obj>

# let q = Oo.copy p;;

val q : point = <obj>

# q#move 7; (p#get_x, q#get_x);;

\- : int * int = (5, 12)

In fact, Oo.copy p will behave as p#copy assuming that a public method copy
with body {< >} has been defined in the class of p.

Objects can be compared using the generic comparison functions = and <>. Two
objects are equal if and only if they are physically equal. In particular, an
object and its copy are not equal.

# let q = Oo.copy p;;

val q : point = <obj>

# p = q, p = p;;

\- : bool * bool = (false, true)

Other generic comparisons such as (<, <=, ...) can also be used on objects.
The relation < defines an unspecified but strict ordering on objects. The
ordering relationship between two objects is fixed permanently once the two
objects have been created, and it is not affected by mutation of fields.

Cloning and override have a non empty intersection. They are interchangeable
when used within an object and without overriding any field:

# class copy = object method copy = {< >} end;;

class copy : object ('a) method copy : 'a end

# class copy = object (self) method copy = Oo.copy self end;;

class copy : object ('a) method copy : 'a end

Only the override can be used to actually override fields, and only the
Oo.copy primitive can be used externally.

Cloning can also be used to provide facilities for saving and restoring the
state of objects.

# class backup = object (self : 'mytype) val mutable copy = None method save = copy <\- Some {< copy = None >} method restore = match copy with Some x -> x | None -> self end;;

class backup : object ('a) val mutable copy : 'a option method restore : 'a
method save : unit end

The above definition will only backup one level. The backup facility can be
added to any class by using multiple inheritance.

# class ['a] backup_ref x = object inherit ['a] oref x inherit backup end;;

class ['a] backup_ref : 'a -> object ('b) val mutable copy : 'b option val
mutable x : 'a method get : 'a method restore : 'b method save : unit method
set : 'a -> unit end

# let rec get p n = if n = 0 then p # get else get (p # restore) (n-1);;

val get : (< get : 'b; restore : 'a; .. > as 'a) -> int -> 'b = <fun>

# let p = new backup_ref 0 in p # save; p # set 1; p # save; p # set 2; [get p
0; get p 1; get p 2; get p 3; get p 4];;

\- : int list = [2; 1; 1; 1; 1]

We can define a variant of backup that retains all copies. (We also add a
method clear to manually erase all copies.)

# class backup = object (self : 'mytype) val mutable copy = None method save = copy <\- Some {< >} method restore = match copy with Some x -> x | None -> self method clear = copy <\- None end;;

class backup : object ('a) val mutable copy : 'a option method clear : unit
method restore : 'a method save : unit end

# class ['a] backup_ref x = object inherit ['a] oref x inherit backup end;;

class ['a] backup_ref : 'a -> object ('b) val mutable copy : 'b option val
mutable x : 'a method clear : unit method get : 'a method restore : 'b method
save : unit method set : 'a -> unit end

# let p = new backup_ref 0 in p # save; p # set 1; p # save; p # set 2; [get p
0; get p 1; get p 2; get p 3; get p 4];;

\- : int list = [2; 1; 0; 0; 0]

## ﻿3.15 Recursive classes

Recursive classes can be used to define objects whose types are mutually
recursive.

# class window = object val mutable top_widget = (None : widget option) method
top_widget = top_widget end and widget (w : window) = object val window = w
method window = window end;;

class window : object val mutable top_widget : widget option method top_widget
: widget option end and widget : window -> object val window : window method
window : window end

Although their types are mutually recursive, the classes widget and window are
themselves independent.

## ﻿3.16 Binary methods

A binary method is a method which takes an argument of the same type as self.
The class comparable below is a template for classes with a binary method leq
of type 'a -> bool where the type variable 'a is bound to the type of self.
Therefore, #comparable expands to < leq : 'a -> bool; .. > as 'a. We see here
that the binder as also allows writing recursive types.

# class virtual comparable = object (_ : 'a) method virtual leq : 'a -> bool
end;;

class virtual comparable : object ('a) method virtual leq : 'a -> bool end

We then define a subclass money of comparable. The class money simply wraps
floats as comparable objects.1 We will extend money below with more
operations. We have to use a type constraint on the class parameter x because
the primitive <= is a polymorphic function in OCaml. The inherit clause
ensures that the type of objects of this class is an instance of #comparable.

# class money (x : float) = object inherit comparable val repr = x method
value = repr method leq p = repr <= p#value end;;

class money : float -> object ('a) val repr : float method leq : 'a -> bool
method value : float end

Note that the type money is not a subtype of type comparable, as the self type
appears in contravariant position in the type of method leq. Indeed, an object
m of class money has a method leq that expects an argument of type money since
it accesses its value method. Considering m of type comparable would allow a
call to method leq on m with an argument that does not have a method value,
which would be an error.

Similarly, the type money2 below is not a subtype of type money.

# class money2 x = object inherit money x method times k = {< repr = k *. repr
>} end;;

class money2 : float -> object ('a) val repr : float method leq : 'a -> bool
method times : float -> 'a method value : float end

It is however possible to define functions that manipulate objects of type
either money or money2: the function min will return the minimum of any two
objects whose type unifies with #comparable. The type of min is not the same
as #comparable -> #comparable -> #comparable, as the abbreviation #comparable
hides a type variable (an ellipsis). Each occurrence of this abbreviation
generates a new variable.

# let min (x : #comparable) y = if x#leq y then x else y;;

val min : (#comparable as 'a) -> 'a -> 'a = <fun>

This function can be applied to objects of type money or money2.

# (min (new money 1.3) (new money 3.1))#value;;

\- : float = 1.3

# (min (new money2 5.0) (new money2 3.14))#value;;

\- : float = 3.14

More examples of binary methods can be found in sections
[8.2.1](advexamples.html#ss%3Astring-as-class) and
[8.2.3](advexamples.html#ss%3Aset-as-class).

Note the use of override for method times. Writing new money2 (k *. repr)
instead of {< repr = k *. repr >} would not behave well with inheritance: in a
subclass money3 of money2 the times method would return an object of class
money2 but not of class money3 as would be expected.

The class money could naturally carry another binary method. Here is a direct
definition:

# class money x = object (self : 'a) val repr = x method value = repr method
print = print_float repr method times k = {< repr = k *. x >} method leq (p :
'a) = repr <= p#value method plus (p : 'a) = {< repr = x +. p#value >} end;;

class money : float -> object ('a) val repr : float method leq : 'a -> bool
method plus : 'a -> 'a method print : unit method times : float -> 'a method
value : float end

## ﻿3.17 Friends

The above class money reveals a problem that often occurs with binary methods.
In order to interact with other objects of the same class, the representation
of money objects must be revealed, using a method such as value. If we remove
all binary methods (here plus and leq), the representation can easily be
hidden inside objects by removing the method value as well. However, this is
not possible as soon as some binary method requires access to the
representation of objects of the same class (other than self).

# class safe_money x = object (self : 'a) val repr = x method print =
print_float repr method times k = {< repr = k *. x >} end;;

class safe_money : float -> object ('a) val repr : float method print : unit
method times : float -> 'a end

Here, the representation of the object is known only to a particular object.
To make it available to other objects of the same class, we are forced to make
it available to the whole world. However we can easily restrict the visibility
of the representation using the module system.

# module type MONEY = sig type t class c : float -> object ('a) val repr : t
method value : t method print : unit method times : float -> 'a method leq :
'a -> bool method plus : 'a -> 'a end end;;

# module Euro : MONEY = struct type t = float class c x = object (self : 'a)
val repr = x method value = repr method print = print_float repr method times
k = {< repr = k *. x >} method leq (p : 'a) = repr <= p#value method plus (p :
'a) = {< repr = x +. p#value >} end end;;

Another example of friend functions may be found in section
[8.2.3](advexamples.html#ss%3Aset-as-class). These examples occur when a group
of objects (here objects of the same class) and functions should see each
others internal representation, while their representation should be hidden
from the outside. The solution is always to define all friends in the same
module, give access to the representation and use a signature constraint to
make the representation abstract outside the module.

* * *

1

    

floats are an approximation of decimal numbers, they are unsuitable for use in
most monetary calculations as they may introduce errors.

* * *

[![Previous](previous_motif.svg)](moduleexamples.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](lablexamples.html)

