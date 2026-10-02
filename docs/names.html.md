[![Previous](previous_motif.svg)](values.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](types.html)

* * *

## ﻿11.3 Names

Identifiers are used to give names to several classes of language objects and
refer to these objects by name later:

  * value names (syntactic class value-name), 
  * value constructors and exception constructors (class constr-name), 
  * labels ([label-name](lex.html#label-name), defined in section [11.1](lex.html#sss%3Alabelname)), 
  * polymorphic variant tags (tag-name), 
  * type constructors (typeconstr-name), 
  * record fields (field-name), 
  * class names (class-name), 
  * method names (method-name), 
  * instance variable names (inst-var-name), 
  * module names (module-name), 
  * module type names (modtype-name). 

These eleven name spaces are distinguished both by the context and by the
capitalization of the identifier: whether the first letter of the identifier
is in lowercase (written [lowercase-ident](lex.html#lowercase-ident) below) or
in uppercase (written [capitalized-ident](lex.html#capitalized-ident)).
Underscore is considered a lowercase letter for this purpose.

#### ﻿Naming objects

| value-name| ::=|  [lowercase-ident](lex.html#lowercase-ident)  
---|---|---  
 | ∣|  ( operator-name )  
  
operator-name| ::=|  [prefix-symbol](lex.html#prefix-symbol) ∣ infix-op  
  
infix-op| ::=|  [infix-symbol](lex.html#infix-symbol)  
 | ∣|  * ∣ + ∣ - ∣ -. ∣ = ∣ != ∣ < ∣ > ∣ or ∣ || ∣ & ∣ && ∣ :=  
 | ∣|  mod ∣ land ∣ lor ∣ lxor ∣ lsl ∣ lsr ∣ asr  
  
constr-name| ::=|  [capitalized-ident](lex.html#capitalized-ident)  
  
tag-name| ::=|  [capitalized-ident](lex.html#capitalized-ident)  
  
typeconstr-name| ::=|  [lowercase-ident](lex.html#lowercase-ident)  
  
field-name| ::=|  [lowercase-ident](lex.html#lowercase-ident)  
  
module-name| ::=|  [capitalized-ident](lex.html#capitalized-ident)  
  
modtype-name| ::=|  [ident](lex.html#ident)  
  
class-name| ::=|  [lowercase-ident](lex.html#lowercase-ident)  
  
inst-var-name| ::=|  [lowercase-ident](lex.html#lowercase-ident)  
  
method-name| ::=|  [lowercase-ident](lex.html#lowercase-ident)  
  
See also the following language extension: [extended indexing
operators](indexops.html#s%3Aindex-operators).

As shown above, prefix and infix symbols as well as some keywords can be used
as value names, provided they are written between parentheses. The
capitalization rules are summarized in the table below.

Name space| Case of first letter  
---|---  
Values| lowercase  
Constructors| uppercase  
Labels| lowercase  
Polymorphic variant tags| uppercase  
Exceptions| uppercase  
Type constructors| lowercase  
Record fields| lowercase  
Classes| lowercase  
Instance variables| lowercase  
Methods| lowercase  
Modules| uppercase  
Module types| any  
  
Note on polymorphic variant tags: the current implementation accepts lowercase
variant tags in addition to capitalized variant tags, but we suggest you avoid
lowercase variant tags for portability and compatibility with future OCaml
versions.

#### ﻿Referring to named objects

| value-path| ::=|  [ module-path . ] value-name  
---|---|---  
  
constr| ::=|  [ module-path . ] constr-name  
  
typeconstr| ::=|  [ extended-module-path . ] typeconstr-name  
  
field| ::=|  [ module-path . ] field-name  
  
modtype-path| ::=|  [ extended-module-path . ] modtype-name  
  
class-path| ::=|  [ module-path . ] class-name  
  
classtype-path| ::=|  [ extended-module-path . ] class-name  
  
module-path| ::=|  module-name { . module-name }  
  
extended-module-path| ::=|  extended-module-name { . extended-module-name }  
  
extended-module-name| ::=|  module-name { ( extended-module-path ) }  
  
A named object can be referred to either by its name (following the usual
static scoping rules for names) or by an access path prefix . name, where
prefix designates a module and name is the name of an object defined in that
module. The first component of the path, prefix, is either a simple module
name or an access path name1 . name2 …, in case the defining module is itself
nested inside other modules. For referring to type constructors, module types,
or class types, the prefix can also contain simple functor applications (as in
the syntactic class extended-module-path above) in case the defining module is
the result of a functor application.

Label names, tag names, method names and instance variable names need not be
qualified: the former three are global labels, while the latter are local to a
class.

* * *

[![Previous](previous_motif.svg)](values.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](types.html)

