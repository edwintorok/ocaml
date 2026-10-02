[![Previous](previous_motif.svg)](types.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](patterns.html)

* * *

## ﻿11.5 Constants

| constant| ::=|  [integer-literal](lex.html#integer-literal)  
---|---|---  
 | ∣|  [int32-literal](lex.html#int32-literal)  
 | ∣|  [int64-literal](lex.html#int64-literal)  
 | ∣|  [nativeint-literal](lex.html#nativeint-literal)  
 | ∣|  [float-literal](lex.html#float-literal)  
 | ∣|  [char-literal](lex.html#char-literal)  
 | ∣|  [string-literal](lex.html#string-literal)  
 | ∣|  [constr](names.html#constr)  
 | ∣|  false  
 | ∣|  true  
 | ∣|  ()  
 | ∣|  begin end  
 | ∣|  []  
 | ∣|  [||]  
 | ∣|  `[tag-name](names.html#tag-name)  
  
See also the following language extension: [extension
literals](extensionsyntax.html#ss%3Aextension-literals).

The syntactic class of constants comprises literals from the four base types
(integers, floating-point numbers, characters, character strings), the integer
variants, and constant constructors from both normal and polymorphic variants,
as well as the special constants false, true, (), [], and [||], which behave
like constant constructors, and begin end, which is equivalent to ().

* * *

[![Previous](previous_motif.svg)](types.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](patterns.html)

