[![Previous](previous_motif.svg)](firstclassmodules.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](signaturesubstitution.html)

* * *

## ﻿12.6 Recovering the type of a module

(Introduced in OCaml 3.12)

| [module-type](modtypes.html#module-type)| ::=|  ...  
---|---|---  
 | ∣|  module type of [module-expr](modules.html#module-expr)  
  
The construction module type of [module-expr](modules.html#module-expr)
expands to the module type (signature or functor type) inferred for the module
expression [module-expr](modules.html#module-expr). To make this module type
reusable in many situations, it is intentionally not strengthened: abstract
types and datatypes are not explicitly related with the types of the original
module. For the same reason, module aliases in the inferred type are expanded.

A typical use, in conjunction with the signature-level include construct, is
to extend the signature of an existing structure. In that case, one wants to
keep the types equal to types in the original module. This can done using the
following idiom.

module type MYHASH = sig include module type of struct include Hashtbl end val
replace: ('a, 'b) t -> 'a -> 'b -> unit end

The signature MYHASH then contains all the fields of the signature of the
module Hashtbl (with strengthened type definitions), plus the new field
replace. An implementation of this signature can be obtained easily by using
the include construct again, but this time at the structure level:

module MyHash : MYHASH = struct include Hashtbl let replace t k v = remove t
k; add t k v end

Another application where the absence of strengthening comes handy, is to
provide an alternative implementation for an existing module.

module MySet : module type of Set = struct … end

This idiom guarantees that Myset is compatible with Set, but allows it to
represent sets internally in a different way.

* * *

[![Previous](previous_motif.svg)](firstclassmodules.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](signaturesubstitution.html)

