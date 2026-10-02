[![Previous](previous_motif.svg)](indexops.html)
[![Up](contents_motif.svg)](extn.html) [![Next](next_motif.svg)](alerts.html)

* * *

## ﻿12.20 Empty variant types

(Introduced in 4.07.0)

| [type-representation](typedecl.html#type-representation)| ::=|  ...  
---|---|---  
 | ∣|  = |  
  
This extension allows user to define empty variants. Empty variant type can be
eliminated by refutation case of pattern matching.

type t = | let f (x: t) = match x with _ -> .

* * *

[![Previous](previous_motif.svg)](indexops.html)
[![Up](contents_motif.svg)](extn.html) [![Next](next_motif.svg)](alerts.html)

