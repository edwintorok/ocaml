[![Previous](previous_motif.svg)](modules.html)
[![Up](contents_motif.svg)](language.html)

* * *

## ﻿11.12 Compilation units

| unit-interface| ::=|  { [specification](modtypes.html#specification) [;;] }  
---|---|---  
  
unit-implementation| ::=|  [ [module-items](modules.html#module-items) ]  
  
Compilation units bridge the module system and the separate compilation
system. A compilation unit is composed of two parts: an interface and an
implementation. The interface contains a sequence of specifications, just as
the inside of a sig … end signature expression. The implementation contains a
sequence of definitions and expressions, just as the inside of a struct … end
module expression. A compilation unit also has a name unit-name, derived from
the names of the files containing the interface and the implementation (see
chapter [13](comp.html#c%3Acamlc) for more details). A compilation unit
behaves roughly as the module definition

module unit-name : sig unit-interface end = struct unit-implementation end

A compilation unit can refer to other compilation units by their names, as if
they were regular modules. For instance, if U is a compilation unit that
defines a type t, other compilation units can refer to that type under the
name U.t; they can also refer to U as a whole structure. Except for names of
other compilation units, a unit interface or unit implementation must not have
any other free variables. In other terms, the type-checking and compilation of
an interface or implementation proceeds in the initial environment

name1 : sig [specification](modtypes.html#specification)1 end … namen : sig
[specification](modtypes.html#specification)n end

where name1 … namen are the names of the other compilation units available in
the search path (see chapter [13](comp.html#c%3Acamlc) for more details) and
[specification](modtypes.html#specification)1 …
[specification](modtypes.html#specification)n are their respective interfaces.

* * *

[![Previous](previous_motif.svg)](modules.html)
[![Up](contents_motif.svg)](language.html)

