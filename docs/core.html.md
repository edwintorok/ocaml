[![Previous](previous_motif.svg)](tsan.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](stdlib.html)

* * *

# Chapter 29 The core library

  * [29.1 Built-in types and predefined exceptions](core.html#s%3Acore-builtins)
  * [29.2 Module Stdlib: the initially opened module](core.html#s%3Astdlib-module)

This chapter describes the OCaml core library, which is composed of
declarations for built-in types and exceptions, plus the module Stdlib that
provides basic operations on these built-in types. The Stdlib module is
special in two ways:

  * It is automatically linked with the user’s object code files by the ocamlc command (chapter [13](comp.html#c%3Acamlc)).
  * It is automatically “opened” when a compilation starts, or when the toplevel system is launched. Hence, it is possible to use unqualified identifiers to refer to the functions provided by the Stdlib module, without adding a open Stdlib directive. 

## ﻿29.1 Built-in types and predefined exceptions

The following built-in types and predefined exceptions are always defined in
the compilation environment, but are not part of any module. As a consequence,
they can only be referred by their short names.

### ﻿Built-in types

    
    
    type int
    

> The type of integer numbers.
    
    
    type char
    

> The type of characters.
    
    
    type bytes
    

> The type of (writable) byte sequences.
    
    
    type string
    

> The type of (read-only) character strings.
    
    
    type float
    

> The type of floating-point numbers.
    
    
    type bool = false | true
    

> The type of booleans (truth values).
    
    
    type unit = ()
    

> The type of the unit value.
    
    
    type exn
    

> The type of exception values.
    
    
    type 'a array
    

> The type of arrays whose elements have type 'a.
    
    
    type 'a iarray
    

> The type of immutable arrays whose elements have type 'a.
    
    
    type floatarray
    

> The type of mutable arrays of floats with packed representation.
    
    
    type 'a list = [] | :: of 'a * 'a list
    

> The type of lists whose elements have type 'a.
    
    
    type 'a option = None | Some of 'a
    

> The type of optional values of type 'a.
    
    
    type int32
    

> The type of signed 32-bit integers. Literals for 32-bit integers are
> suffixed by l. See the [Int32](libref/Int32.html) module.
    
    
    type int64
    

> The type of signed 64-bit integers. Literals for 64-bit integers are
> suffixed by L. See the [Int64](libref/Int64.html) module.
    
    
    type nativeint
    

> The type of signed, platform-native integers (32 bits on 32-bit processors,
> 64 bits on 64-bit processors). Literals for native integers are suffixed by
> n. See the [Nativeint](libref/Nativeint.html) module.
    
    
    type ('a, 'b, 'c, 'd, 'e, 'f) format6
    

> The type of format strings. 'a is the type of the parameters of the format,
> 'f is the result type for the printf-style functions, 'b is the type of the
> first argument given to %a and %t printing functions (see module
> [Printf](libref/Printf.html)), 'c is the result type of these functions, and
> also the type of the argument transmitted to the first argument of kprintf-
> style functions, 'd is the result type for the scanf-style functions (see
> module [Scanf](libref/Scanf.html)), and 'e is the type of the receiver
> function for the scanf-style functions.
    
    
    type 'a lazy_t
    

> This type is used to implement the [Lazy](libref/Lazy.html) module. It
> should not be used directly.

### ﻿Predefined exceptions

    
    
    exception Match_failure of (string * int * int)
    

> Exception raised when none of the cases of a pattern-matching apply. The
> arguments are the location of the match keyword in the source code (file
> name, line number, column number).
    
    
    exception Assert_failure of (string * int * int)
    

> Exception raised when an assertion fails. The arguments are the location of
> the assert keyword in the source code (file name, line number, column
> number).
    
    
    exception Invalid_argument of string
    

> Exception raised by library functions to signal that the given arguments do
> not make sense. The string gives some information to the programmer. As a
> general rule, this exception should not be caught, it denotes a programming
> error and the code should be modified not to trigger it.
    
    
    exception Failure of string
    

> Exception raised by library functions to signal that they are undefined on
> the given arguments. The string is meant to give some information to the
> programmer; you must _not_ pattern match on the string literal because it
> may change in future versions (use `Failure _` instead).
    
    
    exception Not_found
    

> Exception raised by search functions when the desired object could not be
> found.
    
    
    exception Out_of_memory
    

> Exception raised by the garbage collector when there is insufficient memory
> to complete the computation. (Not reliable for allocations on the minor
> heap.)
    
    
    exception Stack_overflow
    

> Exception raised by the bytecode interpreter when the evaluation stack
> reaches its maximal size. This often indicates infinite or excessively deep
> recursion in the user’s program. Before 4.10, it was not fully implemented
> by the native-code compiler.
    
    
    exception Sys_error of string
    

> Exception raised by the input/output functions to report an operating system
> error. The string is meant to give some information to the programmer; you
> must _not_ pattern match on the string literal because it may change in
> future versions (use `Sys_error _` instead).
    
    
    exception End_of_file
    

> Exception raised by input functions to signal that the end of file has been
> reached.
    
    
    exception Division_by_zero
    

> Exception raised by integer division and remainder operations when their
> second argument is zero.
    
    
    exception Sys_blocked_io
    

> A special case of Sys_error raised when no I/O is possible on a non-blocking
> I/O channel.
    
    
    exception Undefined_recursive_module of (string * int * int)
    

> Exception raised when an ill-founded recursive module definition is
> evaluated. (See section [12.2](recursivemodules.html#s%3Arecursive-
> modules).) The arguments are the location of the definition in the source
> code (file name, line number, column number).

## ﻿29.2 Module Stdlib: the initially opened module

  * [Module Stdlib](libref/Stdlib.html): the initially opened module 

* * *

[![Previous](previous_motif.svg)](tsan.html)
[![Up](contents_motif.svg)](index.html) [![Next](next_motif.svg)](stdlib.html)

