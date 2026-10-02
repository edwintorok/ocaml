[![Previous](previous_motif.svg)](inlinerecords.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](indexops.html)

* * *

## ﻿12.18 Documentation comments

  * [12.18.1 Floating comments](doccomments.html#ss%3Afloating-comments)
  * [12.18.2 Item comments](doccomments.html#ss%3Aitem-comments)
  * [12.18.3 Label comments](doccomments.html#ss%3Alabel-comments)

(Introduced in OCaml 4.03)

Comments which start with ** are treated specially by the compiler. They are
automatically converted during parsing into attributes (see
[12.12](attributes.html#s%3Aattributes)) to allow tools to process them as
documentation.

Such comments can take three forms: _floating comments_ , _item comments_ and
_label comments_. Any comment starting with ** which does not match one of
these forms will cause the compiler to emit warning 50.

Comments which start with ** are also used by the ocamldoc documentation
generator (see [19](ocamldoc.html#c%3Aocamldoc)). The three comment forms
recognised by the compiler are a subset of the forms accepted by ocamldoc (see
[19.2](ocamldoc.html#s%3Aocamldoc-comments)).

### ﻿12.18.1 Floating comments

Comments surrounded by blank lines that appear within structures, signatures,
classes or class types are converted into [floating-
attribute](attributes.html#floating-attribute)s. For example:

type t = T (** Now some definitions for [t] *) let mkT = T

will be converted to:

type t = T [@@@ocaml.text " Now some definitions for [t] "] let mkT = T

### ﻿12.18.2 Item comments

Comments which appear _immediately before_ or _immediately after_ a structure
item, signature item, class item or class type item are converted into [item-
attribute](attributes.html#item-attribute)s. Immediately before or immediately
after means that there must be no blank lines, ;;, or other documentation
comments between them. For example:

type t = T (** A description of [t] *)

or

(** A description of [t] *) type t = T

will be converted to:

type t = T [@@ocaml.doc " A description of [t] "]

Note that, if a comment appears immediately next to multiple items, as in:

type t = T (** An ambiguous comment *) type s = S

then it will be attached to both items:

type t = T [@@ocaml.doc " An ambiguous comment "] type s = S [@@ocaml.doc " An
ambiguous comment "]

and the compiler will emit warning 50.

### ﻿12.18.3 Label comments

Comments which appear _immediately after_ a labelled argument, record field,
variant constructor, object method or polymorphic variant constructor are
converted into [attribute](attributes.html#attribute)s. Immediately after
means that there must be no blank lines or other documentation comments
between them. For example:

type t1 = lbl:int (** Labelled argument *) -> unit type t2 = { fld: int; (** Record field *) fld2: float; } type t3 = | Cstr of string (** Variant constructor *) | Cstr2 of string type t4 = < meth: int * int; (** Object method *) > type t5 = [ `PCstr (** Polymorphic variant constructor *) ]

will be converted to:

type t1 = lbl:(int [@ocaml.doc " Labelled argument "]) -> unit type t2 = { fld: int [@ocaml.doc " Record field "]; fld2: float; } type t3 = | Cstr of string [@ocaml.doc " Variant constructor "] | Cstr2 of string type t4 = < meth : int * int [@ocaml.doc " Object method "] > type t5 = [ `PCstr [@ocaml.doc " Polymorphic variant constructor "] ]

Note that label comments take precedence over item comments, so:

type t = T of string (** Attaches to T not t *)

will be converted to:

type t = T of string [@ocaml.doc " Attaches to T not t "]

whilst:

type t = T of string (** Attaches to T not t *) (** Attaches to t *)

will be converted to:

type t = T of string [@ocaml.doc " Attaches to T not t "] [@@ocaml.doc "
Attaches to t "]

In the absence of meaningful comment on the last constructor of a type, an
empty comment (**) can be used instead:

type t = T of string (**) (** Attaches to t *)

will be converted directly to

type t = T of string [@@ocaml.doc " Attaches to t "]

* * *

[![Previous](previous_motif.svg)](inlinerecords.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](indexops.html)

