[![Previous](previous_motif.svg)](profil.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](flambda.html)

* * *

# Chapter 23 Interfacing C with OCaml

  * [23.1 Overview and compilation information](intfc.html#s%3Ac-overview)
  * [23.2 The value type](intfc.html#s%3Ac-value)
  * [23.3 Representation of OCaml data types](intfc.html#s%3Ac-ocaml-datatype-repr)
  * [23.4 Operations on values](intfc.html#s%3Ac-ops-on-values)
  * [23.5 Living in harmony with the garbage collector](intfc.html#s%3Ac-gc-harmony)
  * [23.6 A complete example](intfc.html#s%3Ac-intf-example)
  * [23.7 Advanced topic: callbacks from C to OCaml](intfc.html#s%3Ac-callback)
  * [23.8 Advanced example with callbacks](intfc.html#s%3Ac-advexample)
  * [23.9 Advanced topic: custom blocks](intfc.html#s%3Ac-custom)
  * [23.10 Advanced topic: Bigarrays and the OCaml-C interface](intfc.html#s%3AC-Bigarrays)
  * [23.11 Advanced topic: cheaper C call](intfc.html#s%3AC-cheaper-call)
  * [23.12 Advanced topic: multithreading](intfc.html#s%3AC-multithreading)
  * [23.13 Advanced topic: interfacing with Windows Unicode APIs](intfc.html#s%3Ainterfacing-windows-unicode-apis)
  * [23.14 Building mixed C/OCaml libraries: ocamlmklib](intfc.html#s%3Aocamlmklib)
  * [23.15 Cautionary words: the internal runtime API](intfc.html#s%3Ac-internal-guidelines)

This chapter describes how user-defined primitives, written in C, can be
linked with OCaml code and called from OCaml functions, and how these C
functions can call back to OCaml code.

## ﻿23.1 Overview and compilation information

### ﻿23.1.1 Declaring primitives

| [definition](modules.html#definition)| ::=|  ...  
---|---|---  
 | ∣|  external [value-name](names.html#value-name) : [typexpr](types.html#typexpr) = external-declaration  
 | ∣|  external [value-name](names.html#value-name) [: [typexpr](types.html#typexpr)] = [value-path](names.html#value-path)  
  
external-declaration| ::=|  [string-literal](lex.html#string-literal) [
[string-literal](lex.html#string-literal) [ [string-literal](lex.html#string-
literal) ] ]  
  
User primitives are declared in an implementation file or struct…end module
expression using the external keyword:

    
    
            external name : type = C-function-name
    

This defines the value name name as a function with type type that executes by
calling the given C function. For instance, here is how the seek_in primitive
is declared in the standard library module Stdlib:

    
    
            external seek_in : in_channel -> int -> unit = "caml_ml_seek_in"
    

Primitives with several arguments are always curried. The C function does not
necessarily have the same name as the ML function.

External functions thus defined can be specified in interface files or sig…end
signatures either as regular values

    
    
            val name : type
    

thus hiding their implementation as C functions, or explicitly as “manifest”
external functions

    
    
            external name : type = C-function-name
    

The latter is slightly more efficient, as it allows clients of the module to
call directly the C function instead of going through the corresponding OCaml
function. On the other hand, it should not be used in library modules if they
have side-effects at toplevel, as this direct call interferes with the
linker’s algorithm for removing unused modules from libraries at link-time.

The second form of declaration seen above enables one to re-bind a previously-
declared primitive under a new name. This will copy the type, C function
name(s), and any additional information as discussed in section 23.11. One may
optionally ascribe a type to the new binding as well. This feature is only
available in OCaml 5.6 or later.

The arity (number of arguments) of a primitive is automatically determined
from its OCaml type in the external declaration, by counting the number of
function arrows in the type. For instance, seek_in above has arity 2, and the
caml_ml_seek_in C function is called with two arguments. Similarly,

    
    
        external seek_in_pair: in_channel * int -> unit = "caml_ml_seek_in_pair"
    

has arity 1, and the caml_ml_seek_in_pair C function receives one argument
(which is a pair of OCaml values).

Type abbreviations are not expanded when determining the arity of a primitive.
For instance,

    
    
            type int_endo = int -> int
            external f : int_endo -> int_endo = "f"
            external g : (int -> int) -> (int -> int) = "f"
    

f has arity 1, but g has arity 2. This allows a primitive to return a
functional value (as in the f example above): just remember to name the
functional return type in a type abbreviation.

The language accepts external declarations with one or two flag strings in
addition to the C function’s name. These flags are reserved for the
implementation of the standard library.

### ﻿23.1.2 Implementing primitives

User primitives with arity n ≤ 5 are implemented by C functions that take n
arguments of type value, and return a result of type value. The type value is
the type of the representations for OCaml values. It encodes objects of
several base types (integers, floating-point numbers, strings, …) as well as
OCaml data structures. The type value and the associated conversion functions
and macros are described in detail below. For instance, here is the
declaration for the C function implementing the In_channel.input primitive,
which takes 4 arguments:

    
    
    CAMLprim value input(value channel, value buffer, value offset, value length)
    {
      ...
    }
    

When the primitive function is applied in an OCaml program, the C function is
called with the values of the expressions to which the primitive is applied as
arguments. The value returned by the function is passed back to the OCaml
program as the result of the function application.

User primitives with arity greater than 5 should be implemented by two C
functions. The first function, to be used in conjunction with the bytecode
compiler ocamlc, receives two arguments: a pointer to an array of OCaml values
(the values for the arguments), and an integer which is the number of
arguments provided. The other function, to be used in conjunction with the
native-code compiler ocamlopt, takes its arguments directly. For instance,
here are the two C functions for the 7-argument primitive Nat.add_nat:

    
    
    CAMLprim value add_nat_native(value nat1, value ofs1, value len1,
                                  value nat2, value ofs2, value len2,
                                  value carry_in)
    {
      ...
    }
    CAMLprim value add_nat_bytecode(value * argv, int argn)
    {
      return add_nat_native(argv[0], argv[1], argv[2], argv[3],
                            argv[4], argv[5], argv[6]);
    }
    

The names of the two C functions must be given in the primitive declaration,
as follows:

    
    
            external name : type =
                     bytecode-C-function-name native-code-C-function-name
    

For instance, in the case of add_nat, the declaration is:

    
    
            external add_nat: nat -> int -> int -> nat -> int -> int -> int -> int
                            = "add_nat_bytecode" "add_nat_native"
    

Implementing a user primitive is actually two separate tasks: on the one hand,
decoding the arguments to extract C values from the given OCaml values, and
encoding the return value as an OCaml value; on the other hand, actually
computing the result from the arguments. Except for very simple primitives, it
is often preferable to have two distinct C functions to implement these two
tasks. The first function actually implements the primitive, taking native C
values as arguments and returning a native C value. The second function, often
called the “stub code”, is a simple wrapper around the first function that
converts its arguments from OCaml values to C values, calls the first
function, and converts the returned C value to an OCaml value. For instance,
here is the stub code for the Int64.float_of_bits primitive:

    
    
    CAMLprim value caml_int64_float_of_bits(value vi)
    {
      return caml_copy_double(caml_int64_float_of_bits_unboxed(Int64_val(vi)));
    }
    

(Here, caml_copy_double and Int64_val are conversion functions and macros for
the type value, that will be described later. The CAMLprim macro expands to
the required compiler directives to ensure that the function is exported and
accessible from OCaml.) The hard work is performed by the function
caml_int64_float_of_bits_unboxed, which is declared as:

    
    
    double caml_int64_float_of_bits_unboxed(int64_t i)
    {
      ...
    }
    

To write C code that operates on OCaml values, the following include files are
provided:

Include file| Provides  
---|---  
<caml/mlvalues.h>| definition of the value type, and conversion macros  
<caml/alloc.h>| allocation functions (to create structured OCaml objects)  
<caml/memory.h>| miscellaneous memory-related functions and macros (for GC
interface, in-place modification of structures, etc).  
<caml/fail.h>| functions for raising exceptions (see section 23.4.5)  
<caml/callback.h>| callback from C to OCaml (see section 23.7).  
<caml/custom.h>| operations on custom blocks (see section 23.9).  
<caml/intext.h>| operations for writing user-defined serialization and
deserialization functions for custom blocks (see section 23.9).  
<caml/threads.h>| operations for interfacing in the presence of multiple
threads (see section 23.12).  
  
These files reside in the caml/ subdirectory of the OCaml standard library
directory, which is returned by the command ocamlc -where (usually
/usr/local/lib/ocaml or /usr/lib/ocaml).

### ﻿23.1.3 Statically linking C code with OCaml code

The OCaml runtime system comprises three main parts: the bytecode interpreter,
the memory manager, and a set of C functions that implement the primitive
operations. Some bytecode instructions are provided to call these C functions,
designated by their offset in a table of functions (the table of primitives).

In the default mode, the OCaml linker produces bytecode for the standard
runtime system, with a standard set of primitives. References to primitives
that are not in this standard set result in the “unavailable C primitive”
error. (Unless dynamic loading of C libraries is supported – see section
23.1.4 below.)

In the “custom runtime” mode, the OCaml linker scans the object files and
determines the set of required primitives. Then, it builds a suitable runtime
system, by calling the native code linker with:

  * the table of the required primitives; 
  * a library that provides the bytecode interpreter, the memory manager, and the standard primitives; 
  * libraries and object code files (.o files) mentioned on the command line for the OCaml linker, that provide implementations for the user’s primitives. 

This builds a runtime system with the required primitives. The OCaml linker
generates bytecode for this custom runtime system. The bytecode is appended to
the end of the custom runtime system, so that it will be automatically
executed when the output file (custom runtime + bytecode) is launched.

To link in “custom runtime” mode, execute the ocamlc command with:

  * the -custom option; 
  * the names of the desired OCaml object files (.cmo and .cma files) ; 
  * the names of the C object files and libraries (.o and .a files) that implement the required primitives. Under Unix and Windows, a library named libname.a (respectively, .lib) residing in one of the standard library directories can also be specified as -cclib -lname. 

If you are using the native-code compiler ocamlopt, the -custom flag is not
needed, as the final linking phase of ocamlopt always builds a standalone
executable. To build a mixed OCaml/C executable, execute the ocamlopt command
with:

  * the names of the desired OCaml native object files (.cmx and .cmxa files); 
  * the names of the C object files and libraries (.o, .a, .so or .dll files) that implement the required primitives. 

Starting with Objective Caml 3.00, it is possible to record the -custom option
as well as the names of C libraries in an OCaml library file .cma or .cmxa.
For instance, consider an OCaml library mylib.cma, built from the OCaml object
files a.cmo and b.cmo, which reference C code in libmylib.a. If the library is
built as follows:

    
    
            ocamlc -a -o mylib.cma -custom a.cmo b.cmo -cclib -lmylib
    

users of the library can simply link with mylib.cma:

    
    
            ocamlc -o myprog mylib.cma ...
    

and the system will automatically add the -custom and -cclib -lmylib options,
achieving the same effect as

    
    
            ocamlc -o myprog -custom a.cmo b.cmo ... -cclib -lmylib
    

The alternative is of course to build the library without extra options:

    
    
            ocamlc -a -o mylib.cma a.cmo b.cmo
    

and then ask users to provide the -custom and -cclib -lmylib options
themselves at link-time:

    
    
            ocamlc -o myprog -custom mylib.cma ... -cclib -lmylib
    

The former alternative is more convenient for the final users of the library,
however.

### ﻿23.1.4 Dynamically linking C code with OCaml code

Starting with Objective Caml 3.03, an alternative to static linking of C code
using the -custom code is provided. In this mode, the OCaml linker generates a
pure bytecode executable (no embedded custom runtime system) that simply
records the names of dynamically-loaded libraries containing the C code. The
standard OCaml runtime system ocamlrun then loads dynamically these libraries,
and resolves references to the required primitives, before executing the
bytecode.

This facility is currently available on all platforms supported by OCaml
except Cygwin 64 bits.

To dynamically link C code with OCaml code, the C code must first be compiled
into a shared library (under Unix) or DLL (under Windows). This involves 1-
compiling the C files with appropriate C compiler flags for producing
position-independent code (when required by the operating system), and 2-
building a shared library from the resulting object files. The resulting
shared library or DLL file must be installed in a place where ocamlrun can
find it later at program start-up time (see section
[15.3](runtime.html#s%3Aocamlrun-dllpath)). Finally (step 3), execute the
ocamlc command with

  * the names of the desired OCaml object files (.cmo and .cma files) ; 
  * the names of the C shared libraries (.so or .dll files) that implement the required primitives. Under Unix and Windows, a library named dllname.so (respectively, .dll) residing in one of the standard library directories can also be specified as -dllib -lname. 

Do _not_ set the -custom flag, otherwise you’re back to static linking as
described in section 23.1.3. The ocamlmklib tool (see section 23.14) automates
steps 2 and 3.

As in the case of static linking, it is possible (and recommended) to record
the names of C libraries in an OCaml .cma library archive. Consider again an
OCaml library mylib.cma, built from the OCaml object files a.cmo and b.cmo,
which reference C code in dllmylib.so. If the library is built as follows:

    
    
            ocamlc -a -o mylib.cma a.cmo b.cmo -dllib -lmylib
    

users of the library can simply link with mylib.cma:

    
    
            ocamlc -o myprog mylib.cma ...
    

and the system will automatically add the -dllib -lmylib option, achieving the
same effect as

    
    
            ocamlc -o myprog a.cmo b.cmo ... -dllib -lmylib
    

Using this mechanism, users of the library mylib.cma do not need to know that
it references C code, nor whether this C code must be statically linked (using
-custom) or dynamically linked.

### ﻿23.1.5 Choosing between static linking and dynamic linking

After having described two different ways of linking C code with OCaml code,
we now review the pros and cons of each, to help developers of mixed OCaml/C
libraries decide.

The main advantage of dynamic linking is that it preserves the platform-
independence of bytecode executables. That is, the bytecode executable
contains no machine code, and can therefore be compiled on platform A and
executed on other platforms B, C, …, as long as the required shared libraries
are available on all these platforms. In contrast, executables generated by
ocamlc -custom run only on the platform on which they were created, because
they embark a custom-tailored runtime system specific to that platform. In
addition, dynamic linking results in smaller executables.

Another advantage of dynamic linking is that the final users of the library do
not need to have a C compiler, C linker, and C runtime libraries installed on
their machines. This is no big deal under Unix and Cygwin, but many Windows
users are reluctant to install Microsoft Visual C just to be able to do ocamlc
-custom.

There are two drawbacks to dynamic linking. The first is that the resulting
executable is not stand-alone: it requires the shared libraries, as well as
ocamlrun, to be installed on the machine executing the code. If you wish to
distribute a stand-alone executable, it is better to link it statically, using
ocamlc -custom -ccopt -static or ocamlopt -ccopt -static. Dynamic linking also
raises the “DLL hell” problem: some care must be taken to ensure that the
right versions of the shared libraries are found at start-up time.

The second drawback of dynamic linking is that it complicates the construction
of the library. The C compiler and linker flags to compile to position-
independent code and build a shared library vary wildly between different Unix
systems. Also, dynamic linking is not supported on all Unix systems, requiring
a fall-back case to static linking in the Makefile for the library. The
ocamlmklib command (see section 23.14) tries to hide some of these system
dependencies.

In conclusion: dynamic linking is highly recommended under the native Windows
port, because there are no portability problems and it is much more convenient
for the end users. Under Unix, dynamic linking should be considered for
mature, frequently used libraries because it enhances platform-independence of
bytecode executables. For new or rarely-used libraries, static linking is much
simpler to set up in a portable way.

### ﻿23.1.6 Building standalone custom runtime systems

It is sometimes inconvenient to build a custom runtime system each time OCaml
code is linked with C libraries, like ocamlc -custom does. For one thing, the
building of the runtime system is slow on some systems (that have bad linkers
or slow remote file systems); for another thing, the platform-independence of
bytecode files is lost, forcing to perform one ocamlc -custom link per
platform of interest.

An alternative to ocamlc -custom is to build separately a custom runtime
system integrating the desired C libraries, then generate “pure” bytecode
executables (not containing their own runtime system) that can run on this
custom runtime. This is achieved by the -make-runtime and -use-runtime flags
to ocamlc. For example, to build a custom runtime system integrating the C
parts of the “Unix” and “Threads” libraries, do:

    
    
            ocamlc -make-runtime -o /home/me/ocamlunixrun unix.cma threads.cma
    

To generate a bytecode executable that runs on this runtime system, do:

    
    
            ocamlc -use-runtime /home/me/ocamlunixrun -o myprog \
                    unix.cma threads.cma your .cmo and .cma files
    

The bytecode executable myprog can then be launched as usual: myprog args or
/home/me/ocamlunixrun myprog args.

Notice that the bytecode libraries unix.cma and threads.cma must be given
twice: when building the runtime system (so that ocamlc knows which C
primitives are required) and also when building the bytecode executable (so
that the bytecode from unix.cma and threads.cma is actually linked in).

## ﻿23.2 The value type

All OCaml objects are represented by the C type value, defined in the include
file <caml/mlvalues.h>, along with macros to manipulate values of that type.
An object of type value is either:

  * an unboxed integer; 
  * or a pointer to a block inside the heap, allocated through one of the `caml_alloc_*` functions described in section 23.4.4. 

### ﻿23.2.1 Integer values

Integer values encode 63-bit signed integers (31-bit on 32-bit architectures).
They are unboxed (unallocated).

### ﻿23.2.2 Blocks

Blocks in the heap are garbage-collected, and therefore have strict structure
constraints. Each block includes a header containing the size of the block (in
words), and the tag of the block. The tag governs how the contents of the
blocks are structured. A tag lower than No_scan_tag indicates a structured
block, containing well-formed values, which is recursively traversed by the
garbage collector. A tag greater than or equal to No_scan_tag indicates a raw
block, whose contents are not scanned by the garbage collector. For the
benefit of ad-hoc polymorphic primitives such as equality and structured
input-output, structured and raw blocks are further classified according to
their tags as follows:

Tag| Contents of the block  
---|---  
0 to No_scan_tag−1| A structured block (an array of OCaml objects). Each field
is a value.  
Closure_tag| A closure representing a functional value. The first word is a
pointer to a piece of code, the remaining words are value containing the
environment.  
String_tag| A character string or a byte sequence.  
Double_tag| A double-precision floating-point number.  
Double_array_tag| An array or record of double-precision floating-point
numbers.  
Abstract_tag| A block representing an abstract datatype.  
Custom_tag| A block representing an abstract datatype with user-defined
finalization, comparison, hashing, serialization and deserialization functions
attached.  
  
### ﻿23.2.3 Pointers outside the heap

In earlier versions of OCaml, it was possible to use word-aligned pointers to
addresses outside the heap as OCaml values, just by casting the pointer to
type value. This usage is no longer supported since OCaml 5.0.

A correct way to manipulate pointers to out-of-heap blocks from OCaml is to
store those pointers in OCaml blocks with tag Abstract_tag or Custom_tag, then
use the blocks as the OCaml values.

Here is an example of encapsulation of out-of-heap pointers of C type ty *
inside Abstract_tag blocks. Section 23.6 gives a more complete example using
Custom_tag blocks.

    
    
    /* Create an OCaml value encapsulating the pointer p */
    static value val_of_typtr(ty * p)
    {
      value v = caml_alloc(1, Abstract_tag);
      *((ty **) Data_abstract_val(v)) = p;
      return v;
    }
    
    /* Extract the pointer encapsulated in the given OCaml value */
    static ty * typtr_of_val(value v)
    {
      return *((ty **) Data_abstract_val(v));
    }
    

Alternatively, out-of-heap pointers can be treated as “native” integers, that
is, boxed 32-bit integers on a 32-bit platform and boxed 64-bit integers on a
64-bit platform.

    
    
    /* Create an OCaml value encapsulating the pointer p */
    static value val_of_typtr(ty * p)
    {
      return caml_copy_nativeint((intnat) p);
    }
    
    /* Extract the pointer encapsulated in the given OCaml value */
    static ty * typtr_of_val(value v)
    {
      return (ty *) Nativeint_val(v);
    }
    

For pointers that are at least 2-aligned (the low bit is guaranteed to be
zero), we have yet another valid representation as an OCaml tagged integer.

    
    
    /* Create an OCaml value encapsulating the pointer p */
    static value val_of_typtr(ty * p)
    {
      assert (((uintptr_t) p & 1) == 0);  /* check correct alignment */
      return (value) p | 1;
    }
    
    /* Extract the pointer encapsulated in the given OCaml value */
    static ty * typtr_of_val(value v)
    {
      return (ty *) (v & ~1);
    }
    

## ﻿23.3 Representation of OCaml data types

This section describes how OCaml data types are encoded in the value type.

### ﻿23.3.1 Atomic types

OCaml type| Encoding  
---|---  
int| Unboxed integer values.  
char| Unboxed integer values (ASCII code).  
float| Blocks with tag Double_tag.  
bytes| Blocks with tag String_tag.  
string| Blocks with tag String_tag.  
int32| Blocks with tag Custom_tag.  
int64| Blocks with tag Custom_tag.  
nativeint| Blocks with tag Custom_tag.  
  
### ﻿23.3.2 Tuples and records

Tuples are represented by pointers to blocks, with tag 0.

Records are also represented by zero-tagged blocks. The ordering of labels in
the record type declaration determines the layout of the record fields: the
value associated to the label declared first is stored in field 0 of the
block, the value associated to the second label goes in field 1, and so on.

As an optimization, records whose fields all have static type float are
represented as arrays of floating-point numbers, with tag Double_array_tag.
(See the section below on arrays.)

As another optimization, unboxable record types are represented specially;
unboxable record types are the immutable record types that have only one
field. An unboxable type will be represented in one of two ways: boxed or
unboxed. Boxed record types are represented as described above (by a block
with tag 0 or Double_array_tag). An unboxed record type is represented
directly by the value of its field (i.e. there is no block to represent the
record itself).

The representation is chosen according to the following, in decreasing order
of priority:

  * An attribute ([@@boxed] or [@@unboxed]) on the type declaration. 
  * A compiler option (-unboxed-types or -no-unboxed-types). 
  * The default representation. In the present version of OCaml, the default is the boxed representation. 

### ﻿23.3.3 Arrays

Arrays of integers and pointers are represented like tuples and records, that
is, as pointers to blocks tagged 0. They are accessed with the Field macro for
reading and the caml_modify function for writing.

Values of type floatarray (as manipulated by the Float.Array module), as well
as records whose declaration contains only float fields, use an efficient
unboxed representation: blocks with tag Double_array_tag whose content consist
of raw double values, which are not themselves valid OCaml values. They should
be accessed using the Double_flat_field and Store_double_flat_field macros.

Finally, arrays of type float array may use either the boxed or the unboxed
representation depending on the how the compiler is configured. They currently
use the unboxed representation by default, but can be made to use the boxed
representation by passing the \--disable-flat-float-array flag to the
‘configure‘ script. They should be accessed using the Double_array_field and
Store_double_array_field macros, which will work correctly under both modes.

### ﻿23.3.4 Concrete data types

Constructed terms are represented either by unboxed integers (for constant
constructors) or by blocks whose tag encode the constructor (for non-constant
constructors). The constant constructors and the non-constant constructors for
a given concrete type are numbered separately, starting from 0, in the order
in which they appear in the concrete type declaration. A constant constructor
is represented by the unboxed integer equal to its constructor number. A non-
constant constructor declared with n arguments is represented by a block of
size n, tagged with the constructor number; the n fields contain its
arguments. Example:

Constructed term| Representation  
---|---  
()| Val_int(0)  
false| Val_int(0)  
true| Val_int(1)  
[]| Val_int(0)  
h::t| Block with size = 2 and tag = 0; first field contains h, second field t.  
  
As a convenience, <caml/mlvalues.h> defines the macros Val_unit, Val_false,
Val_true and Val_emptylist to refer to (), false, true and [].

The following example illustrates the assignment of integers and block tags to
constructors:

    
    
    type t =
      | A             (* First constant constructor -> integer "Val_int(0)" *)
      | B of string   (* First non-constant constructor -> block with tag 0 *)
      | C             (* Second constant constructor -> integer "Val_int(1)" *)
      | D of bool     (* Second non-constant constructor -> block with tag 1 *)
      | E of t * t    (* Third non-constant constructor -> block with tag 2 *)
    

As an optimization, unboxable concrete data types are represented specially; a
concrete data type is unboxable if it has exactly one constructor and this
constructor has exactly one argument. Unboxable concrete data types are
represented in the same ways as unboxable record types: see the description in
section 23.3.2.

### ﻿23.3.5 Objects

Objects are represented as blocks with tag Object_tag. The first field of the
block refers to the object’s class and associated method suite, in a format
that cannot easily be exploited from C. The second field contains a unique
object ID, used for comparisons. The remaining fields of the object contain
the values of the instance variables of the object. It is unsafe to access
directly instance variables, as the type system provides no guarantee about
the instance variables contained by an object.

One may extract a public method from an object using the C function
caml_get_public_method (declared in <caml/mlvalues.h>.) Since public method
tags are hashed in the same way as variant tags, and methods are functions
taking self as first argument, if you want to do the method call foo#bar from
the C side, you should call:

    
    
      callback(caml_get_public_method(foo, caml_hash_variant("bar")), foo);
    

### ﻿23.3.6 Polymorphic variants

Like constructed terms, polymorphic variant values are represented either as
integers (for polymorphic variants without argument), or as blocks (for
polymorphic variants with an argument). Unlike constructed terms, variant
constructors are not numbered starting from 0, but identified by a hash value
(an OCaml integer), as computed by the C function caml_hash_variant (declared
in <caml/mlvalues.h>): the hash value for a variant constructor named, say,
VConstr is caml_hash_variant("VConstr").

The variant value `VConstr is represented by caml_hash_variant("VConstr"). The
variant value `VConstr(v) is represented by a block of size 2 and tag 0, with
field number 0 containing caml_hash_variant("VConstr") and field number 1
containing v.

Unlike constructed values, polymorphic variant values taking several arguments
are not flattened. That is, `VConstr(v, w) is represented by a block of size
2, whose field number 1 contains the representation of the pair (v, w), rather
than a block of size 3 containing v and w in fields 1 and 2.

## ﻿23.4 Operations on values

### ﻿23.4.1 Kind tests

  * Is_long(v) is true if value v is an immediate integer, false otherwise 
  * Is_block(v) is true if value v is a pointer to a block, and false if it is an immediate integer. 
  * Is_none(v) is true if value v is None. 
  * Is_some(v) is true if value v (assumed to be of option type) corresponds to the Some constructor. 

### ﻿23.4.2 Operations on integers

The header <caml/config.h> defines a C integer type intnat of signed 64-bit
integers (32-bit integers on 32-bit architectures). This type is used to
represent the integer encoded by a value corresponding to an unboxed integer
without truncation.

  * Val_long(n) returns the value encoding the intnat n. 
  * Long_val(v) returns the intnat encoded in value v. 
  * Val_int(i) returns the value encoding the int i. 
  * Int_val(v) returns the int encoded in value v. Note that this operation may result in a truncated value since int is 32-bit wide on 64-bit architectures. 
  * Val_bool(x) returns the OCaml boolean representing the truth value of the C integer x. 
  * Bool_val(v) returns 0 if v is the OCaml boolean false, 1 if v is true. 
  * Val_true, Val_false represent the OCaml booleans true and false. 
  * Val_emptylist represents the empty list. 
  * Val_none represents the OCaml value None. 

### ﻿23.4.3 Accessing blocks

  * Wosize_val(v) returns the size of the block v, in words, excluding the header. 
  * Tag_val(v) returns the tag of the block v. 
  * Field(v, n) returns the value contained in the nth field of the structured block v. Fields are numbered from 0 to Wosize_val(v)−1. 
  * Store_field(b, n, v) stores the value v in the field number n of value b, which must be a structured block. 
  * Code_val(v) returns the code part of the closure v. 
  * caml_string_length(v) returns the length (number of bytes) of the string or byte sequence v. 
  * Byte(v, n) returns the nth byte of the string or byte sequence v, with type char. Bytes are numbered from 0 to string_length(v)−1. 
  * Byte_u(v, n) returns the nth byte of the string or byte sequence v, with type unsigned char. Bytes are numbered from 0 to string_length(v)−1. 
  * String_val(v) returns a pointer to the first byte of the string v, with type const char *. This pointer is a valid C string: there is a null byte after the last byte in the string. However, OCaml strings can contain embedded null bytes, which will confuse the usual C functions over strings. The function caml_string_is_c_safe(v) returns true if the OCaml string v does not contain any embedded null bytes. 
  * Bytes_val(v) returns a pointer to the first byte of the byte sequence v, with type unsigned char *. 
  * Double_val(v) returns the floating-point number contained in value v, with type double. 
  * Double_array_field(v, n) returns the nth element of a float array v. 
  * Store_double_array_field(v, n, d) stores the double precision floating-point number d in the nth element of a float array v. 
  * Double_flat_field(v, n) returns the nth element of a floatarray or a record of floats v (an unboxed block tagged Double_array_tag). 
  * Store_double_flat_field(v, n, d) stores the double precision floating-point number d in the nth element of a floatarray or a record of floats v. 
  * Data_custom_val(v) returns a pointer to the data part of the custom block v. This pointer has type void * and must be cast to the type of the data contained in the custom block. 
  * Int32_val(v) returns the 32-bit integer contained in the int32 v. 
  * Int64_val(v) returns the 64-bit integer contained in the int64 v. 
  * Nativeint_val(v) returns the long integer contained in the nativeint v. 
  * caml_field_unboxed(v) returns the value of the field of a value v of any unboxed type (record or concrete data type). 
  * caml_field_boxed(v) returns the value of the field of a value v of any boxed type (record or concrete data type). 
  * caml_field_unboxable(v) calls either caml_field_unboxed or caml_field_boxed according to the default representation of unboxable types in the current version of OCaml. 
  * Some_val(v) returns the argument x of a value v of the form Some(x). 

The expressions Field(v, n), Byte(v, n) and Byte_u(v, n) are valid l-values.
Hence, they can be assigned to, resulting in an in-place modification of value
v. Assigning directly to Field(v, n) must be done with care to avoid confusing
the garbage collector (see below).

### ﻿23.4.4 Allocating blocks

#### ﻿Simple interface

  * Atom(t) returns an “atom” (zero-sized block) with tag t. Zero-sized blocks are preallocated outside of the heap. It is incorrect to try and allocate a zero-sized block using the functions below. For instance, Atom(0) represents the empty array. 
  * caml_alloc(n, t) returns a fresh block of size n with tag t. If t is less than No_scan_tag, then the fields of the block are initialized with a valid value in order to satisfy the GC constraints. 
  * caml_alloc_tuple(n) returns a fresh block of size n words, with tag 0. 
  * caml_alloc_string(n) returns a byte sequence (or string) value of length n bytes. The sequence initially contains uninitialized bytes. 
  * caml_alloc_initialized_string(n, p) returns a byte sequence (or string) value of length n bytes. The value is initialized from the n bytes starting at address p. 
  * caml_copy_string(s) returns a string or byte sequence value containing a copy of the null-terminated C string s (a char *). 
  * caml_copy_double(d) returns a floating-point value initialized with the double d. 
  * caml_copy_int32(i), caml_copy_int64(i) and caml_copy_nativeint(i) return a value of OCaml type int32, int64 and nativeint, respectively, initialized with the integer i. 
  * caml_alloc_array(f, a) allocates an array of values, calling function f over each element of the input array a to transform it into a value. The array a is an array of pointers terminated by the null pointer. The function f receives each pointer as argument, and returns a value. The zero-tagged block returned by alloc_array(f, a) is filled with the values returned by the successive calls to f. (This function must not be used to build an array of floating-point numbers.) 
  * caml_copy_string_array(p) allocates an array of strings or byte sequences, copied from the pointer to a string array p (a char **). p must be NULL-terminated. 
  * caml_alloc_float_array(n) allocates an array of floating point numbers of size n. The array initially contains uninitialized values. 
  * caml_alloc_unboxed(v) returns the value (of any unboxed type) whose field is the value v. 
  * caml_alloc_boxed(v) allocates and returns a value (of any boxed type) whose field is the value v. 
  * caml_alloc_unboxable(v) calls either caml_alloc_unboxed or caml_alloc_boxed according to the default representation of unboxable types in the current version of OCaml. 
  * caml_alloc_some(v) allocates a block representing Some(v). 

#### ﻿Low-level interface

The following functions are slightly more efficient than caml_alloc, but also
much more difficult to use.

From the standpoint of the allocation functions, blocks are divided according
to their size as zero-sized blocks, small blocks (with size less than or equal
to `Max_young_wosize`), and large blocks (with size greater than
`Max_young_wosize`). The constant `Max_young_wosize` is declared in the
include file <caml/mlvalues.h>. It is guaranteed to be at least 64 (words), so
that any block with constant size less than or equal to 64 can be assumed to
be small. For blocks whose size is computed at run-time, the size must be
compared against `Max_young_wosize` to determine the correct allocation
procedure.

  * caml_alloc_small(n, t) returns a fresh small block of size n ≤ Max_young_wosize words, with tag t. If this block is a structured block (i.e. if t < No_scan_tag), then the fields of the block (initially containing garbage) must be initialized with legal values (using direct assignment to the fields of the block) before the next allocation. 
  * caml_alloc_shr(n, t) returns a fresh block of size n, with tag t. The size of the block can be greater than `Max_young_wosize`. (It can also be smaller, but in this case it is more efficient to call caml_alloc_small instead of caml_alloc_shr.) If this block is a structured block (i.e. if t < No_scan_tag), then the fields of the block (initially containing garbage) must be initialized with legal values (using the caml_initialize function described below) before the next allocation. 

### ﻿23.4.5 Raising exceptions

Two functions are provided to raise two standard exceptions:

  * caml_failwith(s), where s is a null-terminated C string (with type `char *`), raises exception Failure with argument s. 
  * caml_invalid_argument(s), where s is a null-terminated C string (with type `char *`), raises exception Invalid_argument with argument s. 

Raising arbitrary exceptions from C is more delicate: the exception
constructor is dynamically allocated by the OCaml program, and therefore must
be communicated to the C function using the registration facility described
below in section 23.7.4. Once the exception constructor is recovered in C, the
following functions actually raise the exception:

  * caml_raise_constant(id) raises the exception id with no argument; 
  * caml_raise_with_arg(id, v) raises the exception id with the OCaml value v as argument; 
  * caml_raise_with_args(id, n, v) raises the exception id with the OCaml values v[0], …, v[n-1] as arguments; 
  * caml_raise_with_string(id, s), where s is a null-terminated C string, raises the exception id with a copy of the C string s as argument. 

Sometimes, it is necessary to clean-up state and release resources before
actually raising the exception back into OCaml. To this end, alternative
functions that return the exception instead of raising it directly
(caml_exception_failure, caml_exception_invalid_argument, etc.) are provided.
The type caml_result represents either an OCaml value or an exception; see
section 23.7.2.

## ﻿23.5 Living in harmony with the garbage collector

Unused blocks in the heap are automatically reclaimed by the garbage
collector. This requires some cooperation from C code that manipulates heap-
allocated blocks.

### ﻿23.5.1 Simple interface

In general, any variable in C code that references a heap-allocated OCaml
value must be known to the runtime when the GC runs, as references to any
objects moved by the GC need to be updated. Modifications of mutable fields
must also be tracked by the GC for correctness. Listed below are simple rules
to achieve this. In some cases, the rules dictate registration of variables
that may not be technically needed (eg because the referenced OCaml value is
an immediate, or because the GC is guaranteed not to be invoked during the
lifetime of the variable). However, trying to optimize root registration is a
common source of safety bugs, so it is strongly recommended to follow the
rules below in most cases. The implementation of the root registration
mechanism is efficient and will not typically result in any performance
penalty.

All the macros described in this section are declared in the <caml/memory.h>
header file.

Rule 1  _A function that has parameters or local variables of type value must
begin with a call to one of the CAMLparam macros and return with CAMLreturn,
CAMLreturn0, or CAMLreturnT. _

There are six CAMLparam macros: CAMLparam0 to CAMLparam5, which take zero to
five arguments respectively. If your function has no more than 5 parameters of
type value, use the corresponding macros with these parameters as arguments.
If your function has more than 5 parameters of type value, use CAMLparam5 with
five of these parameters, and use one or more calls to the CAMLxparam macros
for the remaining parameters (CAMLxparam1 to CAMLxparam5). If the function has
an argument x which is an array of values of length n, use CAMLparamN (x, n)
to declare it (or CAMLxparamN (x, n) if you already have a call to CAMLparam
for some other arguments).

The macros CAMLreturn, CAMLreturn0, and CAMLreturnT are used to replace the C
keyword return; any function using a CAMLparam macro on entry should use
CAMLreturn on all exit points. C functions exported as OCaml externals must
return a value, and they should use CAMLreturn (x) instead of return x. Some
helper functions may manipulate OCaml values yet return void or another
datatype. void-returning procedures should explicitly use CAMLreturn0, and not
have any implicit return. Helper functions returning C data of some type t
should use CAMLreturnT (t, x) instead of return x.

##### ﻿Note:

Some C compilers give bogus warnings about unused variables caml__dummy_xxx at
each use of CAMLparam and CAMLlocal. You should ignore them.

  

Examples:

    
    
    CAMLprim value my_external (value v1, value v2, value v3)
    {
      CAMLparam3 (v1, v2, v3);
      ...
      CAMLreturn (Val_unit);
    }
    
    
    static void helper_procedure (value v1, value v2)
    {
      CAMLparam2 (v1, v2);
      ...
      CAMLreturn0;
    }
    
    static int helper_function (value v1, value v2)
    {
      CAMLparam2 (v1, v2);
      ...
      CAMLreturnT (int, 0);
    }
    

##### ﻿Note:

If your function is a primitive with more than 5 arguments for use with the
byte-code runtime, its arguments are not values and must not be declared (they
have types value * and int).

##### ﻿Warning:

CAMLreturn0 should only be used for internal procedures that return void.
CAMLreturn(Val_unit) should be used for functions that return an OCaml unit
value. Primitives (C functions that can be called from OCaml) should never
return void.

Rule 2  _Local variables of type value must be declared with one of the
CAMLlocal macros. Arrays of values are declared with CAMLlocalN. These macros
must be used at the beginning of the function, not in a nested block.
Temporaries are equivalent to local variables, but they cannot be registered
with the garbage collector, so a temporary of type value must not be live when
a garbage collection may occur. _

The macros CAMLlocal1 to CAMLlocal5 declare and initialize one to five local
variables of type value. The variable names are given as arguments to the
macros. CAMLlocalN(x, n) declares and initializes a local variable of type
value [n]. You can use several calls to these macros if you have more than 5
local variables.

Example:

    
    
    CAMLprim value bar (value v1, value v2, value v3)
    {
      CAMLparam3 (v1, v2, v3);
      CAMLlocal1 (result);
      result = caml_alloc (3, 0);
      ...
      CAMLreturn (result);
    }
    

##### ﻿Warning:

CAMLlocal (and CAMLxparam) can only be called _after_ CAMLparam. If a function
declares local values but takes no value argument, it should start with
CAMLparam0 ().

    
    
    static value foo (int n)
    {
      CAMLparam0 ();;
      CAMLlocal (result);
      ...
      CAMLreturn (result);
    }
    

Rule 3  _Assignments to the fields of structured blocks must be done with the
Store_field macro (for normal blocks), Store_double_array_field macro (for
float array values) or Store_double_flat_field (for floatarray values and
records of floating-point numbers). Other assignments must not use
Store_field, Store_double_array_field nor Store_double_flat_field. _

Store_field (b, n, v) stores the value v in the field number n of value b,
which must be a block (i.e. Is_block(b) must be true).

Example:

    
    
    CAMLprim value bar (value v1, value v2, value v3)
    {
      CAMLparam3 (v1, v2, v3);
      CAMLlocal1 (result);
      result = caml_alloc (3, 0);
      Store_field (result, 0, v1);
      Store_field (result, 1, v2);
      Store_field (result, 2, v3);
      CAMLreturn (result);
    }
    

##### ﻿Warning:

The first argument of Store_field and Store_double_field must be a variable
declared by CAMLparam* or a parameter declared by CAMLlocal* to ensure that a
garbage collection triggered by the evaluation of the other arguments will not
invalidate the first argument after it is computed.

##### ﻿Use with CAMLlocalN:

Arrays of values declared using CAMLlocalN must not be written to using
Store_field. Use the normal C array syntax instead.

Rule 4  _Global variables containing values must be registered with the
garbage collector using the caml_register_global_root function, save that
global variables and locations that will only ever contain OCaml integers (and
never pointers) do not have to be registered._

_The same is true for any memory location outside the OCaml heap that contains
a value and is not guaranteed to be reachable—for as long as it contains such
value—from either another registered global variable or location, local
variable declared with CAMLlocal or function parameter declared with
CAMLparam. _

Registration of a global variable v is achieved by calling
caml_register_global_root(&v) just before or just after a valid value is
stored in v for the first time; likewise, registration of an arbitrary
location p is achieved by calling caml_register_global_root(p).

You must not call any of the OCaml runtime functions or macros between
registering and storing the value. Neither must you store anything in the
variable v (likewise, the location p) that is not a valid value.

The registration causes the contents of the variable or memory location to be
updated by the garbage collector whenever the value in such variable or
location is moved within the OCaml heap. In the presence of threads care must
be taken to ensure appropriate synchronisation with the OCaml runtime to avoid
a race condition against the garbage collector when reading or writing the
value. (See section 23.12.2.)

A registered global variable v can be un-registered by calling
caml_remove_global_root(&v).

If the contents of the global variable v are seldom modified after
registration, better performance can be achieved by calling
caml_register_generational_global_root(&v) to register v (after its
initialization with a valid value, but before any allocation or call to the GC
functions), and caml_remove_generational_global_root(&v) to un-register it. In
this case, you must not modify the value of v directly, but you must use
caml_modify_generational_global_root(&v,x) to set it to x. The garbage
collector takes advantage of the guarantee that v is not modified between
calls to caml_modify_generational_global_root to scan it less often. This
improves performance if the modifications of v happen less often than minor
collections.

##### ﻿Note:

The CAML macros use identifiers (local variables, type identifiers, structure
tags) that start with caml__. Do not use any identifier starting with caml__
in your programs.

### ﻿23.5.2 Low-level interface

We now give the GC rules corresponding to the low-level allocation functions
caml_alloc_small and caml_alloc_shr. You can ignore those rules if you stick
to the simplified allocation function caml_alloc.

Rule 5  _After a structured block (a block with tag less than No_scan_tag) is
allocated with the low-level functions, all fields of this block must be
filled with well-formed values before the next allocation operation. If the
block has been allocated with caml_alloc_small, filling is performed by direct
assignment to the fields of the block: _

    
    
    _Field( v, n) = _vn _;_

_If the block has been allocated with caml_alloc_shr, filling is performed
through the caml_initialize function: _

    
    
    _caml_initialize( &Field(v, n), _vn _);_

The next allocation can trigger a garbage collection. The garbage collector
assumes that all structured blocks contain well-formed values. Newly created
blocks contain random data, which generally do not represent well-formed
values.

If you really need to allocate before the fields can receive their final
value, first initialize with a constant value (e.g. Val_unit), then allocate,
then modify the fields with the correct value (see rule 6).

Rule 6  _Direct assignment to a field of a block, as in_

    
    
     _Field( v, n) = w;
    _

_is safe only if v is a block newly allocated by caml_alloc_small; that is, if
no allocation took place between the allocation of v and the assignment to the
field. In all other cases, never assign directly. If the block has just been
allocated by caml_alloc_shr, use caml_initialize to assign a value to a field
for the first time: _

    
    
    _caml_initialize( &Field(v, n), w);
    _

_Otherwise, you are updating a field that previously contained a well-formed
value; then, call the caml_modify function: _

    
    
    _caml_modify( &Field(v, n), w);
    _

To illustrate the rules above, here is a C function that builds and returns a
list containing the two integers given as parameters. First, we write it using
the simplified allocation functions:

    
    
    value alloc_list_int(int i1, int i2)
    {
      CAMLparam0 ();
      CAMLlocal2 (result, r);
    
      r = caml_alloc(2, 0);                   /* Allocate a cons cell */
      Store_field(r, 0, Val_int(i2));         /* car = the integer i2 */
      Store_field(r, 1, Val_emptylist);       /* cdr = the empty list [] */
      result = caml_alloc(2, 0);              /* Allocate the other cons cell */
      Store_field(result, 0, Val_int(i1));    /* car = the integer i1 */
      Store_field(result, 1, r);              /* cdr = the first cons cell */
      CAMLreturn (result);
    }
    

Here, the registering of result is not strictly needed, because no allocation
takes place after it gets its value, but it’s easier and safer to simply
register all the local variables that have type value.

Here is the same function written using the low-level allocation functions. We
notice that the cons cells are small blocks and can be allocated with
caml_alloc_small, and filled by direct assignments on their fields.

    
    
    value alloc_list_int(int i1, int i2)
    {
      CAMLparam0 ();
      CAMLlocal2 (result, r);
    
      r = caml_alloc_small(2, 0);             /* Allocate a cons cell */
      Field(r, 0) = Val_int(i2);              /* car = the integer i2 */
      Field(r, 1) = Val_emptylist;            /* cdr = the empty list [] */
      result = caml_alloc_small(2, 0);        /* Allocate the other cons cell */
      Field(result, 0) = Val_int(i1);         /* car = the integer i1 */
      Field(result, 1) = r;                   /* cdr = the first cons cell */
      CAMLreturn (result);
    }
    

In the two examples above, the list is built bottom-up. Here is an alternate
way, that proceeds top-down. It is less efficient, but illustrates the use of
caml_modify.

    
    
    value alloc_list_int(int i1, int i2)
    {
      CAMLparam0 ();
      CAMLlocal2 (tail, r);
    
      r = caml_alloc_small(2, 0);             /* Allocate a cons cell */
      Field(r, 0) = Val_int(i1);              /* car = the integer i1 */
      Field(r, 1) = Val_int(0);               /* A dummy value
      tail = caml_alloc_small(2, 0);          /* Allocate the other cons cell */
      Field(tail, 0) = Val_int(i2);           /* car = the integer i2 */
      Field(tail, 1) = Val_emptylist;         /* cdr = the empty list [] */
      caml_modify(&Field(r, 1), tail);        /* cdr of the result = tail */
      CAMLreturn (r);
    }
    

It would be incorrect to perform Field(r, 1) = tail directly, because the
allocation of tail has taken place since r was allocated.

### ﻿23.5.3 Pending actions and asynchronous exceptions

Since 4.10, allocation functions are guaranteed not to run any OCaml code,
including finalisers, signal handlers and other threads running on the same
domain. Instead, their execution is delayed to a later safe point.

The function `caml_process_pending_actions` from <caml/signals.h> executes any
pending signal handlers and finalisers, Memprof callbacks, preemptive
systhread switching, and requested minor and major garbage collections. In
particular, it can raise asynchronous exceptions and cause mutations on the
OCaml heap from the same domain. It is recommended to call it regularly at
safe points inside long-running non-blocking C code.

The function `caml_process_pending_actions_res` returns the exception instead
of raising it directly into OCaml code. This is represented by a different C
type, caml_result rather than value. The result can be tested using
caml_result_is_exception, followed by some cleanup logic, and finally
caml_get_value_or_raise which returns the value (here just a unit value,
ignored) or raises the exception.

    
    
        CAMLlocalresult(res);
        ...
        res = caml_process_pending_actions_res();
        if(caml_result_is_exception(res)) {
          ...cleanup...
          (void)caml_get_value_or_raise(res);
        }
    

For more details on caml_result, see section 23.7.2.

## ﻿23.6 A complete example

This section outlines how the functions from the Unix curses library can be
made available to OCaml programs. First of all, here is the interface
curses.ml that declares the curses primitives and data types:

    
    
    (* File curses.ml -- declaration of primitives and data types *)
    type window                   (* The type "window" remains abstract *)
    external initscr: unit -> window = "caml_curses_initscr"
    external endwin: unit -> unit = "caml_curses_endwin"
    external refresh: unit -> unit = "caml_curses_refresh"
    external wrefresh : window -> unit = "caml_curses_wrefresh"
    external newwin: int -> int -> int -> int -> window = "caml_curses_newwin"
    external addch: char -> unit = "caml_curses_addch"
    external mvwaddch: window -> int -> int -> char -> unit = "caml_curses_mvwaddch"
    external addstr: string -> unit = "caml_curses_addstr"
    external mvwaddstr: window -> int -> int -> string -> unit
             = "caml_curses_mvwaddstr"
    (* lots more omitted *)
    

To compile this interface:

    
    
            ocamlc -c curses.ml
    

To implement these functions, we just have to provide the stub code; the core
functions are already implemented in the curses library. The stub code file,
curses_stubs.c, looks like this:

    
    
    /* File curses_stubs.c -- stub code for curses */
    #include <curses.h>
    #include <caml/mlvalues.h>
    #include <caml/memory.h>
    #include <caml/alloc.h>
    #include <caml/custom.h>
    
    /* Encapsulation of opaque window handles (of type WINDOW *)
       as OCaml custom blocks. */
    
    static struct custom_operations curses_window_ops = {
      "fr.inria.caml.curses_windows",
      custom_finalize_default,
      custom_compare_default,
      custom_hash_default,
      custom_serialize_default,
      custom_deserialize_default,
      custom_compare_ext_default,
      custom_fixed_length_default
    };
    
    /* Accessing the WINDOW * part of an OCaml custom block */
    #define Window_val(v) (*((WINDOW **) Data_custom_val(v)))
    
    /* Allocating an OCaml custom block to hold the given WINDOW * */
    static value alloc_window(WINDOW * w)
    {
      value v = caml_alloc_custom(&curses_window_ops, sizeof(WINDOW *), 0, 1);
      Window_val(v) = w;
      return v;
    }
    
    CAMLprim value caml_curses_initscr(value unit)
    {
      CAMLparam1 (unit);
      CAMLreturn (alloc_window(initscr()));
    }
    
    CAMLprim value caml_curses_endwin(value unit)
    {
      CAMLparam1 (unit);
      endwin();
      CAMLreturn (Val_unit);
    }
    
    CAMLprim value caml_curses_refresh(value unit)
    {
      CAMLparam1 (unit);
      refresh();
      CAMLreturn (Val_unit);
    }
    
    CAMLprim value caml_curses_wrefresh(value win)
    {
      CAMLparam1 (win);
      wrefresh(Window_val(win));
      CAMLreturn (Val_unit);
    }
    
    CAMLprim value caml_curses_newwin(value nlines, value ncols, value x0, value y0)
    {
      CAMLparam4 (nlines, ncols, x0, y0);
      CAMLreturn (alloc_window(newwin(Int_val(nlines), Int_val(ncols),
                                      Int_val(x0), Int_val(y0))));
    }
    
    CAMLprim value caml_curses_addch(value c)
    {
      CAMLparam1 (c);
      addch(Int_val(c));            /* Characters are encoded like integers */
      CAMLreturn (Val_unit);
    }
    
    CAMLprim value caml_curses_mvwaddch(value win, value x, value y, value c)
    {
      CAMLparam4 (win, x, y, c);
      mvwaddch(Window_val(win), Int_val(x), Int_val(y), Int_val(c));
      CAMLreturn (Val_unit);
    }
    
    CAMLprim value caml_curses_addstr(value s)
    {
      CAMLparam1 (s);
      addstr(String_val(s));
      CAMLreturn (Val_unit);
    }
    
    CAMLprim value caml_curses_mvwaddstr(value win, value x, value y, value s)
    {
      CAMLparam4 (win, x, y, s);
      mvwaddstr(Window_val(win), Int_val(x), Int_val(y), String_val(s));
      CAMLreturn (Val_unit);
    }
    
    /* This goes on for pages. */
    

The file curses_stubs.c can be compiled with:

    
    
            cc -c -I`ocamlc -where` curses_stubs.c
    

or, even simpler,

    
    
            ocamlc -c curses_stubs.c
    

(When passed a .c file, the ocamlc command simply calls the C compiler on that
file, with the right -I option.)

Now, here is a sample OCaml program prog.ml that uses the curses module:

    
    
    (* File prog.ml -- main program using curses *)
    open Curses;;
    let main_window = initscr () in
    let small_window = newwin 10 5 20 10 in
      mvwaddstr main_window 10 2 "Hello";
      mvwaddstr small_window 4 3 "world";
      refresh();
      Unix.sleep 5;
      endwin()
    

To compile and link this program, run:

    
    
           ocamlc -custom -o prog unix.cma curses.cmo prog.ml curses_stubs.o -cclib -lcurses
    

(On some machines, you may need to put -cclib -lcurses -cclib -ltermcap or
-cclib -ltermcap instead of -cclib -lcurses.)

## ﻿23.7 Advanced topic: callbacks from C to OCaml

So far, we have described how to call C functions from OCaml. In this section,
we show how C functions can call OCaml functions, either as callbacks (OCaml
calls C which calls OCaml), or with the main program written in C.

### ﻿23.7.1 Applying OCaml closures from C

C functions can apply OCaml function values (closures) to OCaml values. The
following functions are provided to perform the applications:

  * caml_callback(f, a) applies the functional value f to the value a and returns the value returned by f. 
  * caml_callback2(f, a, b) applies the functional value f (which is assumed to be a curried OCaml function with two arguments) to a and b. 
  * caml_callback3(f, a, b, c) applies the functional value f (a curried OCaml function with three arguments) to a, b and c. 
  * caml_callbackN(f, n, args) applies the functional value f to the n arguments contained in the C array of values args. 

If the function f does not return, but raises an exception that escapes the
scope of the application, then this exception is propagated to the next
enclosing OCaml code, skipping over the C code. That is, if an OCaml function
f calls a C function g that calls back an OCaml function h that raises a stray
exception, then the execution of g is interrupted and the exception is
propagated back into f.

### ﻿23.7.2 caml_result: resource cleanup on OCaml exceptions

If the OCaml function called with caml_callback (or
caml_process_pending_actions as mentioned in Section 23.5.3) raises an
exception, the C caller will be interrupted immediately to return to the
closest OCaml exception handler. This is often the wrong behavior if the C
caller needs to run some resource cleanup logic to terminate safely.

The OCaml FFI provides an alternative API to call OCaml code from C that
returns a value of type caml_result instead of value. A C value of type
caml_result is either an OCaml value returned correctly by the OCaml function,
or an OCaml exception raised by the OCaml function. The C caller can run any
cleanup logic before re-raising the exception (if any) or continuing the
computation.

caml_result values can be manipulated using the following functions and
macros:

  * value caml_get_value_or_raise(caml_result res) (in <caml/fail.h>) returns the value contained in res or reraises the exception it contains. In particular, (void)caml_get_value_or_raise(res) can be used to ignore an OCaml result of type unit, yet propagate exceptions to the caller.
  * Result_value(value v) (in <caml/mlvalues.h>) is the result that represents returning the value v.
  * Result_exception(value exn) (in <caml/mlvalues.h>) is the result that represents raising the exception exn.
  * int caml_result_is_exception(caml_result res) (in <caml/mlvalues.h>) is true if res represents an exception.
  * The macro CAMLlocalresult(foo) (in <caml/memory.h>) is the caml_result counterpart of CAMLlocal1: it declares a local variable of type caml_result, whose content is tracked by the OCaml GC. Just like CAMLlocal1, it can only be used between a CAMLparam macro and CAMLreturn or CAMLreturnT macros. There is no equivalent of CAMLlocal2, CAMLlocal3, etc., but the macro can be used several times. 

For convenience, Result_unit is defined as Result_value(Val_unit).

By convention, result-returning C functions have their name suffixed with
_res, for example caml_callback2_res and caml_process_pending_actions_res.

Some examples:

    
    
    #include <caml/mlvalues.h> // for the caml_result type, caml_result_is_exception
    #include <caml/memory.h>   // CAMLlocalresult
    #include <caml/callback.h> // caml_callback_res
    #include <caml/fail.h>     // caml_get_value_or_raise
    #include <caml/alloc.h>    // caml_alloc_2
    
    /* This function calls an OCaml callback,
       and returns the value or reraises the exception. */
    value logging_callback(value f, value arg) {
      CAMLparam2(f, arg);
      CAMLlocalresult(res);
      printf("Start callback.\n");
      res = caml_callback_res(f, arg);
      printf("End callback.\n");
      CAMLreturn (caml_get_value_or_raise(res));
    }
    
    /* This function assumes that the callback returns
       a 'unit' value and ignores it -- or reraises
       its exception. It must be called by C, as it
       does not return a value, but the caller cannot
       handle exceptions as they are raised directly. */
    void logging_unit_callback(value f, value arg) {
      CAMLparam2(f, arg);
      CAMLlocalresult(res);
      printf("Start unit callback.\n");
      res = caml_callback_res(f, arg);
      printf("End callback.\n");
      (void)caml_get_value_or_raise(res);
      CAMLreturn0;
    }
    
    /* This function calls a callback on two arguments in turn,
       and returns the pair of values;
       it does not reraise exceptions, but returns a caml_result instead, letting
       its own C caller perform its own cleanup. */
    caml_result two_callbacks_res(value f, value arg1, value arg2) {
      CAMLparam3(f, arg1, arg2);
      CAMLlocalresult(res);
      CAMLlocal3(v1, v2, pair);
    
      res = caml_callback_res(f, arg1);
      // early exit on exception
      if (caml_result_is_exception(res))
        CAMLreturnT(caml_result, res);
      v1 = caml_get_value_or_raise(res);
    
      res = caml_callback_res(f, arg2);
      if (caml_result_is_exception(res))
        CAMLreturnT(caml_result, res);
      v2 = caml_get_value_or_raise(res);
    
      // build the pair of values, and
      // wrap it in a caml_result
      pair = caml_alloc_2(0, v1, v2);
      res = Result_value(pair);
      CAMLreturnT(caml_result, res);
    }
    

##### ﻿Compatibility:

The caml_result type is available since OCaml 5.3. Older versions of OCaml use
an unsafe concept of encoded exceptions (suffix _exn, operations
Is_exception_result and Extract_exception) which are of type value but are not
valid OCaml values and can crash the GC if they are not extracted immediately
by the caller. We strongly recommend using caml_result instead, to have a
clear separation between valid values and reified exceptions at distinct C
types, but the older approach remains available for backwards-compatibility.

### ﻿23.7.3 Obtaining or registering OCaml closures for use in C functions

There are two ways to obtain OCaml function values (closures) to be passed to
the callback functions described above. One way is to pass the OCaml function
as an argument to a primitive function. For example, if the OCaml code
contains the declaration

    
    
        external apply : ('a -> 'b) -> 'a -> 'b = "caml_apply"
    

the corresponding C stub can be written as follows:

    
    
        CAMLprim value caml_apply(value vf, value vx)
        {
          CAMLparam2(vf, vx);
          CAMLlocal1(vy);
          vy = caml_callback(vf, vx);
          CAMLreturn(vy);
        }
    

Another possibility is to use the registration mechanism provided by OCaml.
This registration mechanism enables OCaml code to register OCaml functions
under some global name, and C code to retrieve the corresponding closure by
this global name.

On the OCaml side, registration is performed by evaluating Callback.register n
v. Here, n is the global name (an arbitrary string) and v the OCaml value. For
instance:

    
    
        let f x = print_string "f is applied to "; print_int x; print_newline()
        let _ = Callback.register "test function" f
    

On the C side, a pointer to the value registered under name n is obtained by
calling caml_named_value(n). The returned pointer must then be dereferenced to
recover the actual OCaml value. If no value is registered under the name n,
the null pointer is returned. For example, here is a C wrapper that calls the
OCaml function f above:

    
    
        void call_caml_f(int arg)
        {
            caml_callback(*caml_named_value("test function"), Val_int(arg));
        }
    

The pointer returned by caml_named_value is constant and can safely be cached
in a C variable to avoid repeated name lookups. The value pointed to cannot be
changed from C. However, it might change during garbage collection, so must
always be recomputed at the point of use. Here is a more efficient variant of
call_caml_f above that calls caml_named_value only once:

    
    
        void call_caml_f(int arg)
        {
            static const value * closure_f = NULL;
            if (closure_f == NULL) {
                /* First time around, look up by name */
                closure_f = caml_named_value("test function");
            }
            caml_callback(*closure_f, Val_int(arg));
        }
    

### ﻿23.7.4 Registering OCaml exceptions for use in C functions

The registration mechanism described above can also be used to communicate
exception constructors from OCaml to C. The OCaml code registers the exception
constructor by evaluating Callback.register_exception n exn, where n is an
arbitrary name and exn is an exception value with the exception constructor to
register. For example:

    
    
        exception Error of string
        let _ = Callback.register_exception "test exception" (Error "any string")
    

The C code can then recover the exception constructor using caml_named_value
and pass it as first argument to the functions raise_constant, raise_with_arg,
and raise_with_string (described in section 23.4.5) to actually raise the
exception. For example, here is a C function that raises the Error exception
with the given argument:

    
    
        void raise_error(char * msg)
        {
            caml_raise_with_string(*caml_named_value("test exception"), msg);
        }
    

### ﻿23.7.5 Main program in C

In normal operation, a mixed OCaml/C program starts by executing the OCaml
initialization code, which then may proceed to call C functions. We say that
the main program is the OCaml code. In some applications, it is desirable that
the C code plays the role of the main program, calling OCaml functions when
needed. This can be achieved as follows:

  * The C part of the program must provide a main function, which will override the default main function provided by the OCaml runtime system. Execution will start in the user-defined main function just like for a regular C program.
  * At some point, the C code must call caml_main(argv) to initialize the OCaml code. The argv argument is a C array of strings (type char **), terminated with a NULL pointer, which represents the command-line arguments, as passed as second argument to main. The OCaml array Sys.argv will be initialized from this parameter. For the bytecode compiler, argv[0] and argv[1] are also consulted to find the file containing the bytecode.
  * The call to caml_main initializes the OCaml runtime system, loads the bytecode (in the case of the bytecode compiler), and executes the initialization code of the OCaml program. Typically, this initialization code registers callback functions using Callback.register. Once the OCaml initialization code is complete, control returns to the C code that called caml_main.
  * The C code can then invoke OCaml functions using the callback mechanism (see section 23.7.1). 

### ﻿23.7.6 Embedding the OCaml code in the C code

The bytecode compiler in custom runtime mode (ocamlc -custom) normally appends
the bytecode to the executable file containing the custom runtime. This has
two consequences. First, the final linking step must be performed by ocamlc.
Second, the OCaml runtime library must be able to find the name of the
executable file from the command-line arguments. When using caml_main(argv) as
in section 23.7.5, this means that argv[0] or argv[1] must contain the
executable file name.

An alternative is to embed the bytecode in the C code. The -output-obj and
-output-complete-obj options to ocamlc are provided for this purpose. They
cause the ocamlc compiler to output a C object file (.o file, .obj under
Windows) containing the bytecode for the OCaml part of the program, as well as
a caml_startup function. The C object file produced by ocamlc -output-
complete-obj also contains the runtime and autolink libraries. The C object
file produced by ocamlc -output-obj or ocamlc -output-complete-obj can then be
linked with C code using the standard C compiler, or stored in a C library.

The caml_startup function must be called from the main C program in order to
initialize the OCaml runtime and execute the OCaml initialization code. Just
like caml_main, it takes one argv parameter containing the command-line
parameters. Unlike caml_main, this argv parameter is used only to initialize
Sys.argv, but not for finding the name of the executable file.

The caml_startup function calls the uncaught exception handler (or enters the
debugger, if running under ocamldebug) if an exception escapes from a top-
level module initialiser. Such exceptions may be caught in the C code by
instead using the caml_startup_exn function and testing the result using
Is_exception_result (followed by Extract_exception if appropriate).

The -output-obj and -output-complete-obj options can also be used to obtain
the C source file. More interestingly, these options can also produce directly
a shared library (.so file, .dll under Windows) that contains the OCaml code,
the OCaml runtime system and any other static C code given to ocamlc (.o, .a,
respectively, .obj, .lib). This use of -output-obj and -output-complete-obj is
very similar to a normal linking step, but instead of producing a main program
that automatically runs the OCaml code, it produces a shared library that can
run the OCaml code on demand. The three possible behaviors of -output-obj and
-output-complete-obj (to produce a C source code .c, a C object file .o, a
shared library .so), are selected according to the extension of the resulting
file (given with -o).

The native-code compiler ocamlopt also supports the -output-obj and -output-
complete-obj options, causing it to output a C object file or a shared library
containing the native code for all OCaml modules on the command-line, as well
as the OCaml startup code. Initialization is performed by calling caml_startup
(or caml_startup_exn) as in the case of the bytecode compiler. The file
produced by ocamlopt -output-complete-obj also contains the runtime and
autolink libraries.

For the final linking phase, in addition to the object file produced by
-output-obj, you will have to provide the OCaml runtime library (libcamlrun.a
for bytecode, libasmrun.a for native-code), as well as all C libraries that
are required by the OCaml libraries used. For instance, assume the OCaml part
of your program uses the Unix library. With ocamlc, you should do:

    
    
            ocamlc -output-obj -o camlcode.o unix.cma other .cmo and .cma files
            cc -o myprog C objects and libraries \
               camlcode.o -L‘ocamlc -where‘ -lunix -lcamlrun
    

With ocamlopt, you should do:

    
    
            ocamlopt -output-obj -o camlcode.o unix.cmxa other .cmx and .cmxa files
            cc -o myprog C objects and libraries \
               camlcode.o -L‘ocamlc -where‘ -lunix -lasmrun
    

For the final linking phase, in addition to the object file produced by
-output-complete-obj, you will have only to provide the C libraries required
by the OCaml runtime.

For instance, assume the OCaml part of your program uses the Unix library.
With ocamlc, you should do:

    
    
            ocamlc -output-complete-obj -o camlcode.o unix.cma other .cmo and .cma files
            cc -o myprog C objects and libraries \
               camlcode.o C libraries required by the runtime, eg -lm  -ldl -lcurses -lpthread
    

With ocamlopt, you should do:

    
    
            ocamlopt -output-complete-obj -o camlcode.o unix.cmxa other .cmx and .cmxa files
            cc -o myprog C objects and libraries \
               camlcode.o C libraries required by the runtime, eg -lm -ldl
    

##### ﻿Warning:

On some ports, special options are required on the final linking phase that
links together the object file produced by the -output-obj and -output-
complete-obj options and the remainder of the program. Those options are shown
in the configuration file Makefile.config generated during compilation of
OCaml, as the variable OC_LDFLAGS.

  * Windows with the MSVC compiler: the object file produced by OCaml have been compiled with the /MD flag, and therefore all other object files linked with it should also be compiled with /MD. 
  * other systems: you may have to add one or both of -lm and -ldl, depending on your OS and C compiler. 

##### ﻿Stack backtraces.

When OCaml bytecode produced by ocamlc -g is embedded in a C program, no
debugging information is included, and therefore it is impossible to print
stack backtraces on uncaught exceptions. This is not the case when native code
produced by ocamlopt -g is embedded in a C program: stack backtrace
information is available, but the backtrace mechanism needs to be turned on
programmatically. This can be achieved from the OCaml side by calling
Printexc.record_backtrace true in the initialization of one of the OCaml
modules. This can also be achieved from the C side by calling
caml_record_backtraces(1); in the OCaml-C glue code. (caml_record_backtraces
is declared in <caml/backtrace.h>)

##### ﻿Unloading the runtime.

In case the shared library produced with -output-obj is to be loaded and
unloaded repeatedly by a single process, care must be taken to unload the
OCaml runtime explicitly, in order to avoid various system resource leaks.

Since 4.05, caml_shutdown function can be used to shut the runtime down
gracefully, which equals the following:

  * Running the functions that were registered with Stdlib.at_exit. 
  * Triggering finalization of allocated custom blocks (see section 23.9). For example, Stdlib.in_channel and Stdlib.out_channel are represented by custom blocks that enclose file descriptors, which are to be released. 
  * Unloading the dependent shared libraries that were loaded by the runtime, including dynlink plugins. 
  * Freeing the memory blocks that were allocated by the runtime with malloc. Inside C primitives, it is advised to use caml_stat_* functions from <caml/memory.h> for managing static (that is, non-moving) blocks of heap memory, as all the blocks allocated with these functions are automatically freed by caml_shutdown. For ensuring compatibility with legacy C stubs that have used caml_stat_* incorrectly, this behaviour is only enabled if the runtime is started with a specialized caml_startup_pooled function. 

One should make sure to join all domains into the main domain before calling
caml_shutdown. If there are more than one domain alive when calling
caml_shutdown, a warning will be issued and no attempt will be made to
terminate other domains.

As a shared library may have several clients simultaneously, it is made for
convenience that caml_startup (and caml_startup_pooled) may be called multiple
times, given that each such call is paired with a corresponding call to
caml_shutdown (in a nested fashion). The runtime will be unloaded once there
are no outstanding calls to caml_startup.

Once a runtime is unloaded, it cannot be started up again without reloading
the shared library and reinitializing its static data. Therefore, at the
moment, the facility is only useful for building reloadable shared libraries.

##### ﻿Unix signal handling.

Depending on the target platform and operating system, the native-code runtime
system may install signal handlers for one or several of the SIGSEGV, SIGTRAP
and SIGFPE signals when caml_startup is called, and reset these signals to
their default behaviors when caml_shutdown is called. The main program written
in C should not try to handle these signals itself.

## ﻿23.8 Advanced example with callbacks

This section illustrates the callback facilities described in section 23.7. We
are going to package some OCaml functions in such a way that they can be
linked with C code and called from C just like any C functions. The OCaml
functions are defined in the following mod.ml OCaml source:

    
    
    (* File mod.ml -- some "useful" OCaml functions *)
    
    let rec fib n = if n < 2 then n else fib(n-1) + fib(n-2)
    
    let format_result n = Printf.sprintf "Result is: %d\n" n
    
    (* Export those two functions to C *)
    
    let _ = Callback.register "fib" fib
    let _ = Callback.register "format_result" format_result
    

Here is the C stub code for calling these functions from C:

    
    
    /* File modwrap.c -- wrappers around the OCaml functions */
    
    #include <stdio.h>
    #include <string.h>
    #include <caml/mlvalues.h>
    #include <caml/callback.h>
    
    int fib(int n)
    {
      static const value * fib_closure = NULL;
      if (fib_closure == NULL) fib_closure = caml_named_value("fib");
      return Int_val(caml_callback(*fib_closure, Val_int(n)));
    }
    
    char * format_result(int n)
    {
      static const value * format_result_closure = NULL;
      if (format_result_closure == NULL)
        format_result_closure = caml_named_value("format_result");
      return strdup(String_val(caml_callback(*format_result_closure, Val_int(n))));
      /* We copy the C string returned by String_val to the C heap
         so that it remains valid after garbage collection. */
    }
    

We now compile the OCaml code to a C object file and put it in a C library
along with the stub code in modwrap.c and the OCaml runtime system:

    
    
            ocamlc -custom -output-obj -o modcaml.o mod.ml
            ocamlc -c modwrap.c
            cp `ocamlc -where`/libcamlrun.a mod.a && chmod +w mod.a
            ar r mod.a modcaml.o modwrap.o
    

(One can also use ocamlopt -output-obj instead of ocamlc -custom -output-obj.
In this case, replace libcamlrun.a (the bytecode runtime library) by
libasmrun.a (the native-code runtime library).)

Now, we can use the two functions fib and format_result in any C program, just
like regular C functions. Just remember to call caml_startup (or
caml_startup_exn) once before.

    
    
    /* File main.c -- a sample client for the OCaml functions */
    
    #include <stdio.h>
    #include <caml/callback.h>
    
    extern int fib(int n);
    extern char * format_result(int n);
    
    int main(int argc, char ** argv)
    {
      int result;
    
      /* Initialize OCaml code */
      caml_startup(argv);
      /* Do some computation */
      result = fib(10);
      printf("fib(10) = %s\n", format_result(result));
      return 0;
    }
    

To build the whole program, just invoke the C compiler as follows:

    
    
            cc -o prog -I `ocamlc -where` main.c mod.a -lcurses
    

(On some machines, you may need to put -ltermcap or -lcurses -ltermcap instead
of -lcurses.)

## ﻿23.9 Advanced topic: custom blocks

Blocks with tag Custom_tag start with a pointer to a C struct with type struct
custom_operations that associates user-provided finalization, comparison,
hashing, serialization and deserialization functions for this block.

After this pointer to custom operations, there can be arbitrary data of zero,
one or more words whose semantics is defined by the user (for example this can
be just a pointer to a C struct or a C struct itself). Use Data_custom_val on
the block value to get a pointer on the start of this arbitrary data.

### ﻿23.9.1 The struct custom_operations

The struct custom_operations is defined in <caml/custom.h> and contains the
following fields:

  * char *identifier   
A zero-terminated character string serving as an identifier for serialization
and deserialization operations.

  * void (*finalize)(value v)   
The finalize field contains a pointer to a C function that is called when the
block becomes unreachable and is about to be reclaimed. The block is passed as
first argument to the function. The finalize field can also be
custom_finalize_default to indicate that no finalization function is
associated with the block. Note the caution below: there are many restrictions
on the behaviour of these custom block finalizers. For more powerful and
flexible finalization, use Gc.finalise (see [Gc](libref/Gc.html)).

  * int (*compare)(value v1, value v2)   
The compare field contains a pointer to a C function that is called whenever
two custom blocks are compared using OCaml’s generic comparison operators (=,
<>, <=, >=, <, > and compare). The C function should return 0 if the data
contained in the two blocks are structurally equal, a negative integer if the
data from the first block is less than the data from the second block, and a
positive integer if the data from the first block is greater than the data
from the second block.

The compare field can be set to custom_compare_default; this default
comparison function simply raises Failure.

  * int (*compare_ext)(value v1, value v2)   
(Since 3.12.1) The compare_ext field contains a pointer to a C function that
is called whenever one custom block and one unboxed integer are compared using
OCaml’s generic comparison operators (=, <>, <=, >=, <, > and compare). As in
the case of the compare field, the C function should return 0 if the two
arguments are structurally equal, a negative integer if the first argument
compares less than the second argument, and a positive integer if the first
argument compares greater than the second argument.

The compare_ext field can be set to custom_compare_ext_default; this default
comparison function simply raises Failure.

  * intnat (*hash)(value v)   
The hash field contains a pointer to a C function that is called whenever
OCaml’s generic hash operator (see module [Hashtbl](libref/Hashtbl.html)) is
applied to a custom block. The C function can return an arbitrary integer
representing the hash value of the data contained in the given custom block.
The hash value must be compatible with the compare function, in the sense that
two structurally equal data (that is, two custom blocks for which compare
returns 0) must have the same hash value.

The hash field can be set to custom_hash_default, in which case the custom
block is ignored during hash computation.

  * void (*serialize)(value v, uintnat * bsize_32, uintnat * bsize_64)   
The serialize field contains a pointer to a C function that is called whenever
the custom block needs to be serialized (marshaled) using the OCaml functions
output_value or Marshal.to_.... For a custom block, those functions first
write the identifier of the block (as given by the identifier field) to the
output stream, then call the user-provided serialize function. That function
is responsible for writing the data contained in the custom block, using the
serialize_... functions defined in <caml/intext.h> and listed in section
23.9.4. The user-provided serialize function must then store in its bsize_32
and bsize_64 parameters the sizes in bytes of the data part of the custom
block on a 32-bit architecture and on a 64-bit architecture, respectively.

The serialize field can be set to custom_serialize_default, in which case the
Failure exception is raised when attempting to serialize the custom block.

  * uintnat (*deserialize)(void * dst)   
The deserialize field contains a pointer to a C function that is called
whenever a custom block with identifier identifier needs to be deserialized
(un-marshaled) using the OCaml functions input_value or Marshal.from_.... This
user-provided function is responsible for reading back the data written by the
serialize operation, using the deserialize_... functions defined in
<caml/intext.h> and listed in section 23.9.4. It must then rebuild the data
part of the custom block and store it at the pointer given as the dst
argument. Finally, it returns the size in bytes of the data part of the custom
block. This size must be identical to the bsize_32 result of the serialize
operation if the architecture is 32 bits, or bsize_64 if the architecture is
64 bits.

The deserialize field can be set to custom_deserialize_default to indicate
that deserialization is not supported. In this case, do not register the
struct custom_operations with the deserializer using
register_custom_operations (see below).

  * const struct custom_fixed_length* fixed_length   
(Since 4.08.0) Normally, space in the serialized output is reserved to write
the bsize_32 and bsize_64 fields returned by serialize. However, for very
short custom blocks, this space can be larger than the data itself! As a space
optimisation, if serialize always returns the same values for bsize_32 and
bsize_64, then these values may be specified in the fixed_length structure,
and do not consume space in the serialized output.

_Caution_ : the finalize, compare, hash, serialize, and deserialize functions
attached to custom block descriptors are allowed only limited interactions
with the OCaml runtime. Within these functions, do not call any of the OCaml
allocation functions, and do not perform any callback into OCaml code or allow
it to be called (for example, do not call caml_release_runtime_system()). Do
not use CAMLparam to register the parameters to these functions, do not use
CAMLlocal to register their local variables, and do not use CAMLreturn to
return the result. Do not raise exceptions. To signal an error during
deserialization, use caml_deserialize_error, and serialize and deserialize
functions may freely use the functions from section 23.9.4. There are
especially stringent restrictions on the behavior of custom block finalizers.
In addition to the restrictions above, finalizers must not access the OCaml
heap, or mutate the OCaml heap or any memory reachable from OCaml GC roots.
However, note that finalize functions may freely use caml_remove_global_root
and caml_remove_generational_global_root. In short, if a custom block
finalizer does anything with the value it receives other than call
Data_custom_val on it, then it is probably unsafe. When in doubt, err on the
side of caution.

### ﻿23.9.2 Allocating custom blocks

Custom blocks must be allocated via caml_alloc_custom or
caml_alloc_custom_mem:

caml_alloc_custom(ops, size, used, max)

returns a fresh custom block, with room for size bytes of user data, and whose
associated operations are given by ops (a pointer to a struct
custom_operations, usually statically allocated as a C global variable).

The two parameters used and max are used to control the speed of garbage
collection when the finalized object contains pointers to out-of-heap
resources. Generally speaking, the OCaml incremental major collector adjusts
its speed relative to the allocation rate of the program. The faster the
program allocates, the harder the GC works in order to reclaim quickly
unreachable blocks and avoid having large amount of “floating garbage”
(unreferenced objects that the GC has not yet collected).

Normally, the allocation rate is measured by counting the in-heap size of
allocated blocks. However, it often happens that finalized objects contain
pointers to out-of-heap memory blocks and other resources (such as file
descriptors, X Windows bitmaps, etc.). For those blocks, the in-heap size of
blocks is not a good measure of the quantity of resources allocated by the
program.

The two arguments used and max give the GC an idea of how much out-of-heap
resources are consumed by the finalized block being allocated: you give the
amount of resources allocated to this object as parameter used, and the
maximum amount that you want to see in floating garbage as parameter max. The
units are arbitrary: the GC cares only about the ratio used / max.

For instance, if you are allocating a finalized block holding an X Windows
bitmap of w by h pixels, and you’d rather not have more than 1 mega-pixels of
unreclaimed bitmaps, specify used = w * h and max = 1000000.

Another way to describe the effect of the used and max parameters is in terms
of full GC cycles. If you allocate many custom blocks with used / max = 1 / N,
the GC will then do one full cycle (examining every object in the heap and
calling finalization functions on those that are unreachable) every N
allocations. For instance, if used = 1 and max = 1000, the GC will do one full
cycle at least every 1000 allocations of custom blocks.

If your finalized blocks contain no pointers to out-of-heap resources, or if
the previous discussion made little sense to you, just take used = 0 and max =
1. But if you later find that the finalization functions are not called “often
enough”, consider increasing the used / max ratio.

caml_alloc_custom_mem(ops, size, used)

Use this function when your custom block holds only out-of-heap memory (memory
allocated with malloc or caml_stat_alloc) and no other resources. used should
be the number of bytes of out-of-heap memory that are held by your custom
block. This function works like caml_alloc_custom except that the max
parameter is under the control of the user (via the custom_major_ratio,
custom_minor_ratio, and custom_minor_max_size parameters) and proportional to
the heap sizes. It has been available since OCaml 4.08.0.

### ﻿23.9.3 Accessing custom blocks

The data part of a custom block v can be accessed via the pointer
Data_custom_val(v). This pointer has type void * and should be cast to the
actual type of the data stored in the custom block.

The contents of custom blocks are not scanned by the garbage collector, and
must therefore not contain any pointer inside the OCaml heap. In other terms,
never store an OCaml value in a custom block, and do not use Field,
Store_field nor caml_modify to access the data part of a custom block.
Conversely, any C data structure (not containing heap pointers) can be stored
in a custom block.

### ﻿23.9.4 Writing custom serialization and deserialization functions

The following functions, defined in <caml/intext.h>, are provided to write and
read back the contents of custom blocks in a portable way. Those functions
handle endianness conversions when e.g. data is written on a little-endian
machine and read back on a big-endian machine.

Function| Action  
---|---  
caml_serialize_int_1| Write a 1-byte integer  
caml_serialize_int_2| Write a 2-byte integer  
caml_serialize_int_4| Write a 4-byte integer  
caml_serialize_int_8| Write a 8-byte integer  
caml_serialize_float_4| Write a 4-byte float  
caml_serialize_float_8| Write a 8-byte float  
caml_serialize_block_1| Write an array of 1-byte quantities  
caml_serialize_block_2| Write an array of 2-byte quantities  
caml_serialize_block_4| Write an array of 4-byte quantities  
caml_serialize_block_8| Write an array of 8-byte quantities  
caml_deserialize_uint_1| Read an unsigned 1-byte integer  
caml_deserialize_sint_1| Read a signed 1-byte integer  
caml_deserialize_uint_2| Read an unsigned 2-byte integer  
caml_deserialize_sint_2| Read a signed 2-byte integer  
caml_deserialize_uint_4| Read an unsigned 4-byte integer  
caml_deserialize_sint_4| Read a signed 4-byte integer  
caml_deserialize_uint_8| Read an unsigned 8-byte integer  
caml_deserialize_sint_8| Read a signed 8-byte integer  
caml_deserialize_float_4| Read a 4-byte float  
caml_deserialize_float_8| Read an 8-byte float  
caml_deserialize_block_1| Read an array of 1-byte quantities  
caml_deserialize_block_2| Read an array of 2-byte quantities  
caml_deserialize_block_4| Read an array of 4-byte quantities  
caml_deserialize_block_8| Read an array of 8-byte quantities  
caml_deserialize_error| Signal an error during deserialization; input_value or
Marshal.from_... raise a Failure exception after cleaning up their internal
data structures  
  
Serialization functions are attached to the custom blocks to which they apply.
Obviously, deserialization functions cannot be attached this way, since the
custom block does not exist yet when deserialization begins! Thus, the struct
custom_operations that contain deserialization functions must be registered
with the deserializer in advance, using the register_custom_operations
function declared in <caml/custom.h>. Deserialization proceeds by reading the
identifier off the input stream, allocating a custom block of the size
specified in the input stream, searching the registered struct
custom_operation blocks for one with the same identifier, and calling its
deserialize function to fill the data part of the custom block.

### ﻿23.9.5 Choosing identifiers

Identifiers in struct custom_operations must be chosen carefully, since they
must identify uniquely the data structure for serialization and
deserialization operations. In particular, consider including a version number
in the identifier; this way, the format of the data can be changed later, yet
backward-compatible deserialisation functions can be provided.

Identifiers starting with _ (an underscore character) are reserved for the
OCaml runtime system; do not use them for your custom data. We recommend to
use a URL (http://mymachine.mydomain.com/mylibrary/version-number) or a Java-
style package name (com.mydomain.mymachine.mylibrary.version-number) as
identifiers, to minimize the risk of identifier collision.

### ﻿23.9.6 Finalized blocks

Custom blocks generalize the finalized blocks that were present in OCaml prior
to version 3.00. For backwards compatibility, the format of custom blocks is
compatible with that of finalized blocks, and the caml_alloc_final function is
still available to allocate a custom block with a given finalization function,
but default comparison, hashing and serialization functions. (In particular,
the finalization function must not access the OCaml runtime.)

caml_alloc_final(n, f, used, max) returns a fresh custom block of size n+1
words, with finalization function f. The first word is reserved for storing
the custom operations; the other n words are available for your data. The two
parameters used and max are used to control the speed of garbage collection,
as described for caml_alloc_custom.

## ﻿23.10 Advanced topic: Bigarrays and the OCaml-C interface

This section explains how C stub code that interfaces C or Fortran code with
OCaml code can use Bigarrays.

### ﻿23.10.1 Include file

The include file <caml/bigarray.h> must be included in the C stub file. It
declares the functions, constants and macros discussed below.

### ﻿23.10.2 Accessing an OCaml bigarray from C or Fortran

If v is a OCaml value representing a Bigarray, the expression
Caml_ba_data_val(v) returns a pointer to the data part of the array. This
pointer is of type void * and can be cast to the appropriate C type for the
array (e.g. double [], char [][10], etc).

Various characteristics of the OCaml Bigarray can be consulted from C as
follows:

C expression| Returns  
---|---  
Caml_ba_array_val(v)->num_dims| number of dimensions  
Caml_ba_array_val(v)->dim[i]| i-th dimension  
Caml_ba_array_val(v)->flags & CAML_BA_KIND_MASK| kind of array elements  
  
The kind of array elements is one of the following constants:

Constant| Element kind  
---|---  
CAML_BA_FLOAT16| 16-bit half-precision floats  
CAML_BA_FLOAT32| 32-bit single-precision floats  
CAML_BA_FLOAT64| 64-bit double-precision floats  
CAML_BA_SINT8| 8-bit signed integers  
CAML_BA_UINT8| 8-bit unsigned integers  
CAML_BA_SINT16| 16-bit signed integers  
CAML_BA_UINT16| 16-bit unsigned integers  
CAML_BA_INT32| 32-bit signed integers  
CAML_BA_INT64| 64-bit signed integers  
CAML_BA_CAML_INT| 31- or 63-bit signed integers  
CAML_BA_NATIVE_INT| 32- or 64-bit (platform-native) integers  
CAML_BA_COMPLEX32| 32-bit single-precision complex numbers  
CAML_BA_COMPLEX64| 64-bit double-precision complex numbers  
CAML_BA_CHAR| 8-bit characters  
  
##### ﻿Warning:

Caml_ba_array_val(v) must always be dereferenced immediately and not stored
anywhere, including local variables. It resolves to a derived pointer: it is
not a valid OCaml value but points to a memory region managed by the GC. For
this reason this value must not be stored in any memory location that could be
live cross a GC.

The following example shows the passing of a two-dimensional Bigarray to a C
function and a Fortran function.

    
    
        extern void my_c_function(double * data, int dimx, int dimy);
        extern void my_fortran_function_(double * data, int * dimx, int * dimy);
    
        CAMLprim value caml_stub(value bigarray)
        {
          int dimx = Caml_ba_array_val(bigarray)->dim[0];
          int dimy = Caml_ba_array_val(bigarray)->dim[1];
          /* C passes scalar parameters by value */
          my_c_function(Caml_ba_data_val(bigarray), dimx, dimy);
          /* Fortran passes all parameters by reference */
          my_fortran_function_(Caml_ba_data_val(bigarray), &dimx, &dimy);
          return Val_unit;
        }
    

### ﻿23.10.3 Wrapping a C or Fortran array as an OCaml Bigarray

A pointer p to an already-allocated C or Fortran array can be wrapped and
returned to OCaml as a Bigarray using the caml_ba_alloc or caml_ba_alloc_dims
functions.

  * caml_ba_alloc(kind | layout, numdims, p, dims)

Return an OCaml Bigarray wrapping the data pointed to by p. kind is the kind
of array elements (one of the CAML_BA_ kind constants above). layout is
CAML_BA_C_LAYOUT for an array with C layout and CAML_BA_FORTRAN_LAYOUT for an
array with Fortran layout. numdims is the number of dimensions in the array.
dims is an array of numdims long integers, giving the sizes of the array in
each dimension.

  * caml_ba_alloc_dims(kind | layout, numdims, p, (long) dim1, (long) dim2, …, (long) dimnumdims)

Same as caml_ba_alloc, but the sizes of the array in each dimension are listed
as extra arguments in the function call, rather than being passed as an array.

The following example illustrates how statically-allocated C and Fortran
arrays can be made available to OCaml.

    
    
        extern long my_c_array[100][200];
        extern float my_fortran_array_[300][400];
    
        CAMLprim value caml_get_c_array(value unit)
        {
          long dims[2];
          dims[0] = 100; dims[1] = 200;
          return caml_ba_alloc(CAML_BA_NATIVE_INT | CAML_BA_C_LAYOUT,
                               2, my_c_array, dims);
        }
    
        CAMLprim value caml_get_fortran_array(value unit)
        {
          return caml_ba_alloc_dims(CAML_BA_FLOAT32 | CAML_BA_FORTRAN_LAYOUT,
                                    2, my_fortran_array_, 300L, 400L);
        }
    

## ﻿23.11 Advanced topic: cheaper C call

This section describe how to make calling C functions cheaper.

Note: This only applies to the native compiler. So whenever you use any of
these methods, you have to provide an alternative byte-code stub that ignores
all the special annotations.

### ﻿23.11.1 Passing unboxed values

We said earlier that all OCaml objects are represented by the C type value,
and one has to use macros such as Int_val to decode data from the value type.
It is however possible to tell the OCaml native-code compiler to do this for
us and pass arguments unboxed to the C function. Similarly it is possible to
tell OCaml to expect the result unboxed and box it for us.

The motivation is that, by letting ‘ocamlopt‘ deal with boxing, it can often
decide to suppress it entirely.

For instance let’s consider this example:

    
    
    external foo : float -> float -> float = "foo"
    
    let f a b =
      let len = Array.length a in
      assert (Array.length b = len);
      let res = Array.make len 0. in
      for i = 0 to len - 1 do
        res.(i) <- foo a.(i) b.(i)
      done
    

Float arrays are unboxed in OCaml, however the C function foo expect its
arguments as boxed floats and returns a boxed float. Hence the OCaml compiler
has no choice but to box a.(i) and b.(i) and unbox the result of foo. This
results in the allocation of 3 * len temporary float values.

Now if we annotate the arguments and result with [@unboxed], the native-code
compiler will be able to avoid all these allocations:

    
    
    external foo
      :  (float [@unboxed])
      -> (float [@unboxed])
      -> (float [@unboxed])
      = "foo_byte" "foo"
    

In this case the C functions must look like:

    
    
    CAMLprim double foo(double a, double b)
    {
      ...
    }
    
    CAMLprim value foo_byte(value a, value b)
    {
      return caml_copy_double(foo(Double_val(a), Double_val(b)))
    }
    

For convenience, when all arguments and the result are annotated with
[@unboxed], it is possible to put the attribute only once on the declaration
itself. So we can also write instead:

    
    
    external foo : float -> float -> float = "foo_byte" "foo" [@@unboxed]
    

The following table summarize what OCaml types can be unboxed, and what C
types should be used in correspondence:

OCaml type| C type  
---|---  
float| double  
int32| int32_t  
int64| int64_t  
nativeint| intnat  
  
Similarly, it is possible to pass untagged OCaml integers between OCaml and C.
This is done by annotating the arguments and/or result with [@untagged]:

    
    
    external f : string -> (int [@untagged]) = "f_byte" "f"
    

The corresponding C type must be intnat.

Note: Do not use the C int type in correspondence with (int [@untagged]). This
is because they often differ in size.

It is possible to annotate with [@untagged] any immediate type, i.e. types
that are represented like int. This includes bool, char, any variant type with
only constant constructors. Note: this does not include Unix.file_descr which
is not represented as an integer on all platforms.

### ﻿23.11.2 Direct C call

In order to be able to run the garbage collector in the middle of a C
function, the OCaml native-code compiler generates some bookkeeping code
around C calls. Technically it wraps every C call with the C function
caml_c_call which is part of the OCaml runtime.

For small functions that are called repeatedly, this indirection can have a
big impact on performances. However this is not needed if we know that the C
function doesn’t allocate, doesn’t raise exceptions, and doesn’t release the
domain lock (see section 23.12.2). We can instruct the OCaml native-code
compiler of this fact by annotating the external declaration with the
attribute [@@noalloc]:

    
    
    external bar : int -> int -> int = "foo" [@@noalloc]
    

In this case calling bar from OCaml is as cheap as calling any other OCaml
function, except for the fact that the OCaml compiler can’t inline C
functions...

### ﻿23.11.3 Example: calling C library functions without indirection

Using these attributes, it is possible to call C library functions with no
indirection. For instance many math functions are defined this way in the
OCaml standard library:

    
    
    external sqrt : float -> float = "caml_sqrt_float" "sqrt"
      [@@unboxed] [@@noalloc]
    (** Square root. *)
    
    external exp : float -> float = "caml_exp_float" "exp" [@@unboxed] [@@noalloc]
    (** Exponential. *)
    
    external log : float -> float = "caml_log_float" "log" [@@unboxed] [@@noalloc]
    (** Natural logarithm. *)
    

## ﻿23.12 Advanced topic: multithreading

Using multiple threads (shared-memory concurrency) in a mixed OCaml/C
application requires special precautions, which are described in this section.

### ﻿23.12.1 Registering threads created from C

Callbacks from C to OCaml are possible only if the calling thread is known to
the OCaml run-time system. Threads created from OCaml (through the
Thread.create function of the system threads library) are automatically known
to the run-time system. If the application creates additional threads from C
and wishes to callback into OCaml code from these threads, it must first
register them with the run-time system. The following functions are declared
in the include file <caml/threads.h>.

  * caml_c_thread_register() registers the calling thread with the OCaml run-time system. Returns 1 on success, 0 on error. Registering an already-registered thread does nothing and returns 0. 
  * caml_c_thread_register_in_domain(uintnat dom_unique_id) registers the calling thread with the OCaml run-time system in the domain with identifier dom_unique_id as provided by Domain.self and Domain.get_id. The domain must be running when this function is called. Registering an already-registered thread does nothing and returns 0, even if it was previously registered in another domain. Registering a thread in one domain, unregistering it, and then registering it later in a different domain is not supported. 
  * caml_c_thread_unregister() must be called before the thread terminates, to unregister it from the OCaml run-time system. Returns 1 on success, 0 on error. If the calling thread was not previously registered, does nothing and returns 0. 

### ﻿23.12.2 Parallel execution of long-running C code with systhreads

Domains are the unit of parallelism for OCaml programs. When using the
systhreads library, multiple threads might be attached to the same domain.
However, at any time, at most one of those thread can be executing OCaml code
or C code that uses the OCaml run-time system by domain. Technically, this is
enforced by a “domain lock” that any thread must hold while executing such
code within a domain.

When OCaml calls the C code implementing a primitive, the domain lock is held,
therefore the C code has full access to the facilities of the run-time system.
However, no other thread in the same domain can execute OCaml code
concurrently with the C code of the primitive. See also chapter
[9.6](parallelism.html#s%3Apar_c_bindings) for the behaviour with multiple
domains.

If a C primitive runs for a long time or performs potentially blocking input-
output operations, it can explicitly release the domain lock, enabling other
OCaml threads in the same domain to run concurrently with its operations. The
C code must re-acquire the domain lock before returning to OCaml. This is
achieved with the following functions, declared in the include file
<caml/threads.h>.

  * caml_release_runtime_system() The calling thread releases the domain lock and other OCaml resources, enabling other threads to run OCaml code in parallel with the execution of the calling thread. 
  * caml_acquire_runtime_system() The calling thread re-acquires the domain lock and other OCaml resources. It may block until no other thread in the same domain uses the OCaml run-time system. 

These functions poll for pending signals by calling asynchronous callbacks
(section 23.5.3) before releasing and after acquiring the lock. They can
therefore execute arbitrary OCaml code including raising an asynchronous
exception.

After caml_release_runtime_system() was called and until
caml_acquire_runtime_system() is called, the C code must not access any OCaml
data, nor call any function of the run-time system, nor call back into OCaml
code. Consequently, arguments provided by OCaml to the C primitive must be
copied into C data structures before calling caml_release_runtime_system(),
and results to be returned to OCaml must be encoded as OCaml values after
caml_acquire_runtime_system() returns.

Example: the following C primitive invokes rmdir to delete a directory. The
rmdir function can block for some time, so we choose to release the OCaml run-
time system while it is running.

    
    
    #include <caml/memory.h>
    #include <caml/threads.h>
    #include <caml/unixsupport.h>
    
    CAMLprim value stub_rmdir(value vpath)
    {
      CAMLparam1(vpath);
    
      /* Raise Unix.Unix_error(Unix.ENOENT, ...) if the OCaml string
         contains embedded null bytes */
      caml_unix_check_path(vpath, "rmdir");
    
      /* Copy the string argument to a C string, allocated outside the
         OCaml heap. */
      char_os *path = caml_stat_strdup_to_os(String_val(vpath));
      /* Release the OCaml run-time system */
      caml_release_runtime_system();
    
      /* Delete the directory */
    #ifdef _WIN32
      int ret = _wrmdir(path);
    #else
      int ret = rmdir(path);
    #endif
    
      /* Free the copy of the string, which we might as well do before
         acquiring the runtime system to benefit from parallelism. */
      caml_stat_free(path);
      /* Re-acquire the OCaml run-time system */
      caml_acquire_runtime_system();
    
      /* Raise Unix.Unix_error(...) if rmdir failed */
      if (ret == -1) caml_uerror("rmdir", vpath);
    
      /* Return to OCaml */
      CAMLreturn(Val_unit);
    }
    

The macro Caml_state evaluates to the domain state variable, and checks in
debug mode that the domain lock is held. Such a check is also placed in normal
mode at key entry points of the C API; this is why calling some of the runtime
functions and macros without correctly owning the domain lock can result in a
fatal error: no domain lock held. The variant Caml_state_opt does not perform
any check but evaluates to NULL when the domain lock is not held. This lets
you determine whether a thread belonging to a domain currently holds its
domain lock, for various purposes.

Callbacks from C to OCaml must be performed while holding the domain lock to
the OCaml run-time system. This is naturally the case if the callback is
performed by a C primitive that did not release the run-time system. If the C
primitive released the run-time system previously, or the callback is
performed from other C code that was not invoked from OCaml (e.g. an event
loop in a GUI application), the run-time system must be acquired before the
callback and released after:

    
    
      caml_acquire_runtime_system();
      /* Resolve OCaml function vfun to be invoked */
      /* Build OCaml argument varg to the callback */
      vres = callback(vfun, varg);
      /* Copy relevant parts of result vres to C data structures */
      caml_release_runtime_system();
    

Note: the acquire and release functions described above were introduced in
OCaml 3.12. Older code uses the following historical names, declared in
<caml/signals.h>:

  * caml_enter_blocking_section as an alias for caml_release_runtime_system
  * caml_leave_blocking_section as an alias for caml_acquire_runtime_system

Intuition: a “blocking section” is a piece of C code that does not use the
OCaml run-time system, typically a blocking input/output operation.

## ﻿23.13 Advanced topic: interfacing with Windows Unicode APIs

This section contains some general guidelines for writing C stubs that use
Windows Unicode APIs.

The OCaml system under Windows can be configured at build time in one of two
modes:

  * legacy mode: All path names, environment variables, command line arguments, etc. on the OCaml side are assumed to be encoded using the current 8-bit code page of the system.
  * Unicode mode: All path names, environment variables, command line arguments, etc. on the OCaml side are assumed to be encoded using UTF-8.

In what follows, we say that a string has the _OCaml encoding_ if it is
encoded in UTF-8 when in Unicode mode, in the current code page in legacy
mode, or is an arbitrary string under Unix. A string has the _platform
encoding_ if it is encoded in UTF-16 under Windows or is an arbitrary string
under Unix.

From the point of view of the writer of C stubs, the challenges of interacting
with Windows Unicode APIs are twofold:

  * The Windows API uses the UTF-16 encoding to support Unicode. The runtime system performs the necessary conversions so that the OCaml programmer only needs to deal with the OCaml encoding. C stubs that call Windows Unicode APIs need to use specific runtime functions to perform the necessary conversions in a compatible way.
  * When writing stubs that need to be compiled under both Windows and Unix, the stubs need to be written in a way that allow the necessary conversions under Windows but that also work under Unix, where typically nothing particular needs to be done to support Unicode.

The native C character type under Windows is WCHAR, two bytes wide, while
under Unix it is char, one byte wide. A type char_os is defined in
<caml/misc.h> that stands for the concrete C character type of each platform.
Strings in the platform encoding are of type char_os *.

The following functions are exposed to help write compatible C stubs. To use
them, you need to include both <caml/misc.h> and <caml/osdeps.h>.

  * char_os* caml_stat_strdup_to_os(const char *) copies the argument while translating from OCaml encoding to the platform encoding. This function is typically used to convert the char * underlying an OCaml string before passing it to an operating system API that takes a Unicode argument. Under Unix, it is equivalent to caml_stat_strdup.

Note: For maximum backwards compatibility in Unicode mode, if the argument is
not a valid UTF-8 string, this function will fall back to assuming that it is
encoded in the current code page.

  * char* caml_stat_strdup_of_os(const char_os *) copies the argument while translating from the platform encoding to the OCaml encoding. It is the inverse of caml_stat_strdup_to_os. This function is typically used to convert a string obtained from the operating system before passing it on to OCaml code. Under Unix, it is equivalent to caml_stat_strdup.
  * value caml_copy_string_of_os(char_os *) allocates an OCaml string with contents equal to the argument string converted to the OCaml encoding. This function is essentially equivalent to caml_stat_strdup_of_os followed by caml_copy_string, except that it avoids the allocation of the intermediate string returned by caml_stat_strdup_of_os. Under Unix, it is equivalent to caml_copy_string.

Note: The strings returned by caml_stat_strdup_to_os and
caml_stat_strdup_of_os are allocated using caml_stat_alloc, so they need to be
deallocated using caml_stat_free when they are no longer needed.

##### ﻿Example

We want to bind the function getenv in a way that works both under Unix and
Windows. Under Unix this function has the prototype:

    
    
        char *getenv(const char *);
    

While the Unicode version under Windows has the prototype:

    
    
        WCHAR *_wgetenv(const WCHAR *);
    

In terms of char_os, both functions take an argument of type char_os * and
return a result of the same type. We begin by choosing the right
implementation of the function to bind:

    
    
    #ifdef _WIN32
    #define getenv_os _wgetenv
    #else
    #define getenv_os getenv
    #endif
    

The rest of the binding is the same for both platforms:

    
    
    #include <caml/mlvalues.h>
    #include <caml/misc.h>
    #include <caml/alloc.h>
    #include <caml/fail.h>
    #include <caml/osdeps.h>
    #include <stdlib.h>
    
    CAMLprim value stub_getenv(value var_name)
    {
      CAMLparam1(var_name);
      CAMLlocal1(var_value);
      char_os *var_name_os, *var_value_os;
    
      var_name_os = caml_stat_strdup_to_os(String_val(var_name));
      var_value_os = getenv_os(var_name_os);
      caml_stat_free(var_name_os);
    
      if (var_value_os == NULL)
        caml_raise_not_found();
    
      var_value = caml_copy_string_of_os(var_value_os);
    
      CAMLreturn(var_value);
    }
    

## ﻿23.14 Building mixed C/OCaml libraries: ocamlmklib

The ocamlmklib command facilitates the construction of libraries containing
both OCaml code and C code, and usable both in static linking and dynamic
linking modes. This command is available under Windows since Objective Caml
3.11 and under other operating systems since Objective Caml 3.03.

The ocamlmklib command takes three kinds of arguments:

  * OCaml source files and object files (.cmo, .cmx, .ml) comprising the OCaml part of the library; 
  * C object files (.o, .a, respectively, .obj, .lib) comprising the C part of the library; 
  * Support libraries for the C part (-llib). 

It generates the following outputs:

  * An OCaml bytecode library .cma incorporating the .cmo and .ml OCaml files given as arguments, and automatically referencing the C library generated with the C object files. 
  * An OCaml native-code library .cmxa incorporating the .cmx and .ml OCaml files given as arguments, and automatically referencing the C library generated with the C object files. 
  * If dynamic linking is supported on the target platform, a .so (respectively, .dll) shared library built from the C object files given as arguments, and automatically referencing the support libraries. 
  * A C static library .a(respectively, .lib) built from the C object files. 

In addition, the following options are recognized:

-cclib, -ccopt, -I, -linkall
     These options are passed as is to ocamlc or ocamlopt. See the documentation of these commands. 
-rpath, -R, -Wl,-rpath, -Wl,-R
     These options are passed as is to the C compiler. Refer to the documentation of the C compiler. 
-custom
     Force the construction of a statically linked library only, even if dynamic linking is supported. 
-failsafe
     Fall back to building a statically linked library if a problem occurs while building the shared library (e.g. some of the support libraries are not available as shared libraries). 
-Ldir
     Add dir to the search path for support libraries (-llib). 
-ocamlc cmd
     Use cmd instead of ocamlc to call the bytecode compiler. 
-ocamlopt cmd
     Use cmd instead of ocamlopt to call the native-code compiler. 
-o output
     Set the name of the generated OCaml library. ocamlmklib will generate output.cma and/or output.cmxa. If not specified, defaults to a. 
-oc outputc
     Set the name of the generated C library. ocamlmklib will generate liboutputc.so (if shared libraries are supported) and liboutputc.a. If not specified, defaults to the output name given with -o. 

##### ﻿Example

Consider an OCaml interface to the standard libz C library for reading and
writing compressed files. Assume this library resides in /usr/local/zlib. This
interface is composed of an OCaml part zip.cmo/zip.cmx and a C part zipstubs.o
containing the stub code around the libz entry points. The following command
builds the OCaml libraries zip.cma and zip.cmxa, as well as the companion C
libraries dllzip.so and libzip.a:

    
    
    ocamlmklib -o zip zip.cmo zip.cmx zipstubs.o -lz -L/usr/local/zlib
    

If shared libraries are supported, this performs the following commands:

    
    
    ocamlc -a -o zip.cma zip.cmo -dllib -lzip \
            -cclib -lzip -cclib -lz -ccopt -L/usr/local/zlib
    ocamlopt -a -o zip.cmxa zip.cmx -cclib -lzip \
            -cclib -lzip -cclib -lz -ccopt -L/usr/local/zlib
    gcc -shared -o dllzip.so zipstubs.o -lz -L/usr/local/zlib
    ar rc libzip.a zipstubs.o
    

Note: This example is on a Unix system. The exact command lines may be
different on other systems.

If shared libraries are not supported, the following commands are performed
instead:

    
    
    ocamlc -a -custom -o zip.cma zip.cmo -cclib -lzip \
            -cclib -lz -ccopt -L/usr/local/zlib
    ocamlopt -a -o zip.cmxa zip.cmx -lzip \
            -cclib -lz -ccopt -L/usr/local/zlib
    ar rc libzip.a zipstubs.o
    

Instead of building simultaneously the bytecode library, the native-code
library and the C libraries, ocamlmklib can be called three times to build
each separately. Thus,

    
    
    ocamlmklib -o zip zip.cmo -lz -L/usr/local/zlib
    

builds the bytecode library zip.cma, and

    
    
    ocamlmklib -o zip zip.cmx -lz -L/usr/local/zlib
    

builds the native-code library zip.cmxa, and

    
    
    ocamlmklib -o zip zipstubs.o -lz -L/usr/local/zlib
    

builds the C libraries dllzip.so and libzip.a. Notice that the support
libraries (-lz) and the corresponding options (-L/usr/local/zlib) must be
given on all three invocations of ocamlmklib, because they are needed at
different times depending on whether shared libraries are supported.

## ﻿23.15 Cautionary words: the internal runtime API

Not all header available in the caml/ directory were described in previous
sections. All those unmentioned headers are part of the internal runtime API,
for which there is _no_ stability guarantee. If you really need access to this
internal runtime API, this section provides some guidelines that may help you
to write code that might not break on every new version of OCaml.

##### ﻿Note

Programmers which come to rely on the internal API for a use-case which they
find realistic and useful are encouraged to open a request for improvement on
the bug tracker.

### ﻿23.15.1 Internal variables and CAML_INTERNALS

Since OCaml 4.04, it is possible to get access to every part of the internal
runtime API by defining the CAML_INTERNALS macro before loading caml header
files. If this macro is not defined, parts of the internal runtime API are
hidden.

If you are using internal C variables, do not redeclare them by hand. You
should import those variables by including the corresponding header files. The
representation of those variables has already changed once in OCaml 4.10, and
is still under evolution. If your code relies on such internal and brittle
properties, it will be broken at some point in time.

For instance, rather than redeclaring caml_young_limit:

    
    
    extern int caml_young_limit;
    

which breaks in OCaml ≥ 4.10, you should include the minor_gc header:

    
    
    #include <caml/minor_gc.h>
    

### ﻿23.15.2 OCaml version macros

Finally, if including the right headers is not enough, or if you need to
support version older than OCaml 4.04, the header file <caml/version.h> should
help you to define your own compatibility layer. This file provides few macros
defining the current OCaml version. In particular, the OCAML_VERSION macro
describes the current version, its format is MmmPP. For example, if you need
some specific handling for versions older than 4.10.0, you could write

    
    
    #include <caml/version.h>
    #if OCAML_VERSION >= 41000
    ...
    #else
    ...
    #endif
    

* * *

[![Previous](previous_motif.svg)](profil.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](flambda.html)

