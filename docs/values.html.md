[![Previous](previous_motif.svg)](lex.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](names.html)

* * *

## ﻿11.2 Values

  * [11.2.1 Base values](values.html#ss%3Avalues%3Abase)
  * [11.2.2 Tuples](values.html#ss%3Avalues%3Atuple)
  * [11.2.3 Records](values.html#ss%3Avalues%3Arecords)
  * [11.2.4 Arrays](values.html#ss%3Avalues%3Aarray)
  * [11.2.5 Variant values](values.html#ss%3Avalues%3Avariant)
  * [11.2.6 Polymorphic variants](values.html#ss%3Avalues%3Apolyvars)
  * [11.2.7 Functions](values.html#ss%3Avalues%3Afun)
  * [11.2.8 Objects](values.html#ss%3Avalues%3Aobj)

This section describes the kinds of values that are manipulated by OCaml
programs.

### ﻿11.2.1 Base values

#### ﻿Integer numbers

Integer values are integer numbers from −230 to 230−1, that is −1073741824 to
1073741823. The implementation may support a wider range of integer values: on
64-bit platforms, the current implementation supports integers ranging from
−262 to 262−1.

#### ﻿Floating-point numbers

Floating-point values are numbers in floating-point representation. The
current implementation uses double-precision floating-point numbers conforming
to the IEEE 754 standard, with 53 bits of mantissa and an exponent ranging
from −1022 to 1023.

#### ﻿Characters

Character values are represented as 8-bit integers between 0 and 255.
Character codes between 0 and 127 are interpreted following the ASCII
standard. The current implementation interprets character codes between 128
and 255 following the ISO 8859-1 standard.

#### ﻿Character strings

String values are finite sequences of characters. The current implementation
supports strings containing up to 224 − 5 characters (16777211 characters); on
64-bit platforms, the limit is 257 − 9.

### ﻿11.2.2 Tuples

Tuples of values are written (v1, …, vn), standing for the n-tuple of values
v1 to vn. The current implementation supports tuple of up to 222 − 1 elements
(4194303 elements).

### ﻿11.2.3 Records

Record values are labeled tuples of values. The record value written {
[field](names.html#field)1 = v1; …; [field](names.html#field)n = vn }
associates the value vi to the record field [field](names.html#field)i, for i
= 1 … n. The current implementation supports records with up to 222 − 1 fields
(4194303 fields).

### ﻿11.2.4 Arrays

Arrays are finite, variable-sized sequences of values of the same type. The
current implementation supports arrays containing up to 222 − 1 elements
(4194303 elements) unless the elements are floating-point numbers (2097151
elements in this case); on 64-bit platforms, the limit is 254 − 1 for all
arrays.

### ﻿11.2.5 Variant values

Variant values are either a constant constructor, or a non-constant
constructor applied to a number of values. The former case is written
[constr](names.html#constr); the latter case is written
[constr](names.html#constr) (v1, ... , vn ), where the vi are said to be the
arguments of the non-constant constructor [constr](names.html#constr). The
parentheses may be omitted if there is only one argument.

The following constants are treated like built-in constant constructors:

Constant| Constructor  
---|---  
false| the boolean false  
true| the boolean true  
()| the “unit” value  
[]| the empty list  
  
The current implementation limits each variant type to have at most 246 non-
constant constructors and 230−1 constant constructors.

### ﻿11.2.6 Polymorphic variants

Polymorphic variants are an alternate form of variant values, not belonging
explicitly to a predefined variant type, and following specific typing rules.
They can be either constant, written `[tag-name](names.html#tag-name), or non-
constant, written `[tag-name](names.html#tag-name)(v).

### ﻿11.2.7 Functions

Functional values are mappings from values to values.

### ﻿11.2.8 Objects

Objects are composed of a hidden internal state which is a record of instance
variables, and a set of methods for accessing and modifying these variables.
The structure of an object is described by the toplevel class that created it.

* * *

[![Previous](previous_motif.svg)](lex.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](names.html)

