[![Previous](previous_motif.svg)](coreexamples.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](objectexamples.html)

* * *

# Chapter 2 The module system

  * [2.1 Structures](moduleexamples.html#s%3Amodule%3Astructures)
  * [2.2 Signatures](moduleexamples.html#s%3Asignature)
  * [2.3 Functors](moduleexamples.html#s%3Afunctors)
  * [2.4 Functors and type abstraction](moduleexamples.html#s%3Afunctors-and-abstraction)
  * [2.5 Modules and separate compilation](moduleexamples.html#s%3Aseparate-compilation)

This chapter introduces the module system of OCaml.

## ﻿2.1 Structures

A primary motivation for modules is to package together related definitions
(such as the definitions of a data type and associated operations over that
type) and enforce a consistent naming scheme for these definitions. This
avoids running out of names or accidentally confusing names. Such a package is
called a _structure_ and is introduced by the struct…end construct, which
contains an arbitrary sequence of definitions. The structure is usually given
a name with the module binding. For instance, here is a structure packaging
together a type of FIFO queues and their operations:

# module Fifo = struct type 'a queue = { front: 'a list; rear: 'a list } let make front rear = match front with | [] -> { front = List.rev rear; rear = [] } | _ -> { front; rear } let empty = { front = []; rear = [] } let is_empty = function { front = []; _ } -> true | _ -> false let add x q = make q.front (x :: q.rear) exception Empty let top = function | { front = []; _ } -> raise Empty | { front = x :: _; _ } -> x let pop = function | { front = []; _ } -> raise Empty | { front = _ :: f; rear = r } -> make f r end;;

module Fifo : sig type 'a queue = { front : 'a list; rear : 'a list; } val
make : 'a list -> 'a list -> 'a queue val empty : 'a queue val is_empty : 'a
queue -> bool val add : 'a -> 'a queue -> 'a queue exception Empty val top :
'a queue -> 'a val pop : 'a queue -> 'a queue end

Outside the structure, its components can be referred to using the “dot
notation”, that is, identifiers qualified by a structure name. For instance,
Fifo.add is the function add defined inside the structure Fifo and Fifo.queue
is the type queue defined in Fifo.

# Fifo.add "hello" Fifo.empty;;

\- : string Fifo.queue = {Fifo.front = ["hello"]; rear = []}

Another possibility is to open the module, which brings all identifiers
defined inside the module into the scope of the current structure.

# open Fifo;;

# add "hello" empty;;

\- : string Fifo.queue = {front = ["hello"]; rear = []}

Opening a module enables lighter access to its components, at the cost of
making it harder to identify in which module an identifier has been defined.
In particular, opened modules can shadow identifiers present in the current
scope, potentially leading to confusing errors:

# let empty = [] open Fifo;;

val empty : 'a list = []

# let x = 1 :: empty ;;

Error: The value empty has type 'a Fifo.queue but an expression was expected
of type int list

A partial solution to this conundrum is to open modules locally, making the
components of the module available only in the concerned expression. This can
also make the code both easier to read (since the open statement is closer to
where it is used) and easier to refactor (since the code fragment is more
self-contained). Two constructions are available for this purpose:

# let open Fifo in add "hello" empty;;

\- : string Fifo.queue = {front = ["hello"]; rear = []}

and

# Fifo.(add "hello" empty);;

\- : string Fifo.queue = {front = ["hello"]; rear = []}

In the second form, when the body of a local open is itself delimited by
parentheses, braces or bracket, the parentheses of the local open can be
omitted. For instance,

# Fifo.[empty] = Fifo.([empty]);;

\- : bool = true

# Fifo.[|empty|] = Fifo.([|empty|]);;

\- : bool = true

# Fifo.{ contents = empty } = Fifo.({ contents = empty });;

\- : bool = true

This second form also works for patterns:

# let at_most_one_element x = match x with | Fifo.{ front = ([] | [_]); rear = [] } -> true | _ -> false ;;

val at_most_one_element : 'a Fifo.queue -> bool = <fun>

It is also possible to copy the components of a module inside another module
by using an include statement. This can be particularly useful to extend
existing modules. As an illustration, we could add functions that return an
optional value rather than an exception when the queue is empty.

# module FifoOpt = struct include Fifo let top_opt q = if is_empty q then None
else Some(top q) let pop_opt q = if is_empty q then None else Some(pop q)
end;;

module FifoOpt : sig type 'a queue = 'a Fifo.queue = { front : 'a list; rear :
'a list; } val make : 'a list -> 'a list -> 'a queue val empty : 'a queue val
is_empty : 'a queue -> bool val add : 'a -> 'a queue -> 'a queue exception
Empty val top : 'a queue -> 'a val pop : 'a queue -> 'a queue val top_opt : 'a
queue -> 'a option val pop_opt : 'a queue -> 'a queue option end

## ﻿2.2 Signatures

Signatures are interfaces for structures. A signature specifies which
components of a structure are accessible from the outside, and with which
type. It can be used to hide some components of a structure (e.g. local
function definitions) or export some components with a restricted type. For
instance, the signature below specifies the queue operations empty, add, top
and pop, but not the auxiliary function make. Similarly, it makes the queue
type abstract (by not providing its actual representation as a concrete type).
This ensures that users of the Fifo module cannot violate data structure
invariants that operations rely on, such as “if the front list is empty, the
rear list must also be empty”.

# module type FIFO = sig type 'a queue (* now an abstract type *) val empty :
'a queue val add : 'a -> 'a queue -> 'a queue val top : 'a queue -> 'a val pop
: 'a queue -> 'a queue exception Empty end;;

module type FIFO = sig type 'a queue val empty : 'a queue val add : 'a -> 'a
queue -> 'a queue val top : 'a queue -> 'a val pop : 'a queue -> 'a queue
exception Empty end

Restricting the Fifo structure to this signature results in another view of
the Fifo structure where the make function is not accessible and the actual
representation of queues is hidden:

# module AbstractQueue = (Fifo : FIFO);;

module AbstractQueue : FIFO

# AbstractQueue.make [1] [2;3] ;;

Error: Unbound value AbstractQueue.make

# AbstractQueue.add "hello" AbstractQueue.empty;;

\- : string AbstractQueue.queue = <abstr>

The restriction can also be performed during the definition of the structure,
as in

    
    
    module Fifo = (struct ... end : FIFO);;
    

An alternate syntax is provided for the above:

    
    
    module Fifo : FIFO = struct ... end;;
    

Like for modules, it is possible to include a signature to copy its components
inside the current signature. For instance, we can extend the FIFO signature
with the top_opt and pop_opt functions:

# module type FIFO_WITH_OPT = sig include FIFO val top_opt: 'a queue -> 'a
option val pop_opt: 'a queue -> 'a queue option end;;

module type FIFO_WITH_OPT = sig type 'a queue val empty : 'a queue val add :
'a -> 'a queue -> 'a queue val top : 'a queue -> 'a val pop : 'a queue -> 'a
queue exception Empty val top_opt : 'a queue -> 'a option val pop_opt : 'a
queue -> 'a queue option end

## ﻿2.3 Functors

Functors are “functions” from modules to modules. Functors let you create
parameterized modules and then provide other modules as parameter(s) to get a
specific implementation. For instance, a Set module implementing sets as
sorted lists could be parameterized to work with any module that provides an
element type and a comparison function compare (such as OrderedString):

# type comparison = Less | Equal | Greater;;

type comparison = Less | Equal | Greater

# module type ORDERED_TYPE = sig type t val compare: t -> t -> comparison
end;;

module type ORDERED_TYPE = sig type t val compare : t -> t -> comparison end

# module Set = functor (Elt: ORDERED_TYPE) -> struct type element = Elt.t type set = element list let empty = [] let rec add x s = match s with [] -> [x] | hd::tl -> match Elt.compare x hd with Equal -> s (* x is already in s *) | Less -> x :: s (* x is smaller than all elements of s *) | Greater -> hd :: add x tl let rec member x s = match s with [] -> false | hd::tl -> match Elt.compare x hd with Equal -> true (* x belongs to s *) | Less -> false (* x is smaller than all elements of s *) | Greater -> member x tl end;;

module Set : (Elt : ORDERED_TYPE) -> sig type element = Elt.t type set =
element list val empty : 'a list val add : Elt.t -> Elt.t list -> Elt.t list
val member : Elt.t -> Elt.t list -> bool end

By applying the Set functor to a structure implementing an ordered type, we
obtain set operations for this type:

# module OrderedString = struct type t = string let compare x y = if x = y
then Equal else if x < y then Less else Greater end;;

module OrderedString : sig type t = string val compare : 'a -> 'a ->
comparison end

# module StringSet = Set(OrderedString);;

module StringSet : sig type element = OrderedString.t type set = element list
val empty : 'a list val add : OrderedString.t -> OrderedString.t list ->
OrderedString.t list val member : OrderedString.t -> OrderedString.t list ->
bool end

# StringSet.member "bar" (StringSet.add "foo" StringSet.empty);;

\- : bool = false

## ﻿2.4 Functors and type abstraction

As in the Fifo example, it would be good style to hide the actual
implementation of the type set, so that users of the structure will not rely
on sets being lists, and we can switch later to another, more efficient
representation of sets without breaking their code. This can be achieved by
restricting Set by a suitable functor signature:

# module type SETFUNCTOR = (Elt: ORDERED_TYPE) -> sig type element = Elt.t (*
concrete *) type set (* abstract *) val empty : set val add : element -> set
-> set val member : element -> set -> bool end;;

module type SETFUNCTOR = (Elt : ORDERED_TYPE) -> sig type element = Elt.t type
set val empty : set val add : element -> set -> set val member : element ->
set -> bool end

# module AbstractSet = (Set : SETFUNCTOR);;

module AbstractSet : SETFUNCTOR

# module AbstractStringSet = AbstractSet(OrderedString);;

module AbstractStringSet : sig type element = OrderedString.t type set =
AbstractSet(OrderedString).set val empty : set val add : element -> set -> set
val member : element -> set -> bool end

# AbstractStringSet.add "gee" AbstractStringSet.empty;;

\- : AbstractStringSet.set = <abstr>

In an attempt to write the type constraint above more elegantly, one may wish
to name the signature of the structure returned by the functor, then use that
signature in the constraint:

# module type SET = sig type element type set val empty : set val add :
element -> set -> set val member : element -> set -> bool end;;

module type SET = sig type element type set val empty : set val add : element
-> set -> set val member : element -> set -> bool end

# module WrongSet = (Set : (Elt: ORDERED_TYPE) -> SET);;

module WrongSet : (Elt : ORDERED_TYPE) -> SET

# module WrongStringSet = WrongSet(OrderedString);;

module WrongStringSet : sig type element = WrongSet(OrderedString).element
type set = WrongSet(OrderedString).set val empty : set val add : element ->
set -> set val member : element -> set -> bool end

# WrongStringSet.add "gee" WrongStringSet.empty ;;

Error: This constant has type string but an expression was expected of type
WrongStringSet.element = WrongSet(OrderedString).element

The problem here is that SET specifies the type element abstractly, so that
the type equality between element in the result of the functor and t in its
argument is forgotten. Consequently, WrongStringSet.element is not the same
type as string, and the operations of WrongStringSet cannot be applied to
strings. As demonstrated above, it is important that the type element in the
signature SET be declared equal to Elt.t; unfortunately, this is impossible
above since SET is defined in a context where Elt does not exist. To overcome
this difficulty, OCaml provides a with type construct over signatures that
allows enriching a signature with extra type equalities:

# module AbstractSet2 = (Set : (Elt: ORDERED_TYPE) -> (SET with type element =
Elt.t));;

module AbstractSet2 : (Elt : ORDERED_TYPE) -> sig type element = Elt.t type
set val empty : set val add : element -> set -> set val member : element ->
set -> bool end

As in the case of simple structures, an alternate syntax is provided for
defining functors and restricting their result:

    
    
    module AbstractSet2(Elt: ORDERED_TYPE) : (SET with type element = Elt.t) =
      struct ... end;;
    

Abstracting a type component in a functor result is a powerful technique that
provides a high degree of type safety, as we now illustrate. Consider an
ordering over character strings that is different from the standard ordering
implemented in the OrderedString structure. For instance, we compare strings
without distinguishing upper and lower case.

# module NoCaseString = struct type t = string let compare s1 s2 =
OrderedString.compare (String.lowercase_ascii s1) (String.lowercase_ascii s2)
end;;

module NoCaseString : sig type t = string val compare : string -> string ->
comparison end

# module NoCaseStringSet = AbstractSet(NoCaseString);;

module NoCaseStringSet : sig type element = NoCaseString.t type set =
AbstractSet(NoCaseString).set val empty : set val add : element -> set -> set
val member : element -> set -> bool end

# NoCaseStringSet.add "FOO" AbstractStringSet.empty ;;

Error: The value AbstractStringSet.empty has type AbstractStringSet.set =
AbstractSet(OrderedString).set but an expression was expected of type
NoCaseStringSet.set = AbstractSet(NoCaseString).set

Note that the two types AbstractStringSet.set and NoCaseStringSet.set are not
compatible, and values of these two types do not match. This is the correct
behavior: even though both set types contain elements of the same type
(strings), they are built upon different orderings of that type, and different
invariants need to be maintained by the operations (being strictly increasing
for the standard ordering and for the case-insensitive ordering). Applying
operations from AbstractStringSet to values of type NoCaseStringSet.set could
give incorrect results, or build lists that violate the invariants of
NoCaseStringSet.

## ﻿2.5 Modules and separate compilation

All examples of modules so far have been given in the context of the
interactive system. However, modules are most useful for large, batch-compiled
programs. For these programs, it is a practical necessity to split the source
into several files, called compilation units, that can be compiled separately,
thus minimizing recompilation after changes.

In OCaml, compilation units are special cases of structures and signatures,
and the relationship between the units can be explained easily in terms of the
module system. A compilation unit A comprises two files:

  * the implementation file A.ml, which contains a sequence of definitions, analogous to the inside of a struct…end construct; 
  * the interface file A.mli, which contains a sequence of specifications, analogous to the inside of a sig…end construct. 

These two files together define a structure named A as if the following
definition was entered at top-level:

    
    
    module A: sig (* contents of file A.mli *) end
            = struct (* contents of file A.ml *) end;;
    

The files that define the compilation units can be compiled separately using
the ocamlc -c command (the -c option means “compile only, do not try to
link”); this produces compiled interface files (with extension .cmi) and
compiled object code files (with extension .cmo). When all units have been
compiled, their .cmo files are linked together using the ocamlc command. For
instance, the following commands compile and link a program composed of two
compilation units Aux and Main:

    
    
    $ ocamlc -c Aux.mli                     # produces aux.cmi
    $ ocamlc -c Aux.ml                      # produces aux.cmo
    $ ocamlc -c Main.mli                    # produces main.cmi
    $ ocamlc -c Main.ml                     # produces main.cmo
    $ ocamlc -o theprogram Aux.cmo Main.cmo
    

The program behaves exactly as if the following phrases were entered at top-
level:

    
    
    module Aux: sig (* contents of Aux.mli *) end
              = struct (* contents of Aux.ml *) end;;
    module Main: sig (* contents of Main.mli *) end
               = struct (* contents of Main.ml *) end;;
    

In particular, Main can refer to Aux: the definitions and declarations
contained in Main.ml and Main.mli can refer to definition in Aux.ml, using the
Aux.ident notation, provided these definitions are exported in Aux.mli.

The order in which the .cmo files are given to ocamlc during the linking phase
determines the order in which the module definitions occur. Hence, in the
example above, Aux appears first and Main can refer to it, but Aux cannot
refer to Main.

Note that only top-level structures can be mapped to separately-compiled
files, but neither functors nor module types. However, all module-class
objects can appear as components of a structure, so the solution is to put the
functor or module type inside a structure, which can then be mapped to a file.

* * *

[![Previous](previous_motif.svg)](coreexamples.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](objectexamples.html)

