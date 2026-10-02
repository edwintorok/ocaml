[![Previous](previous_motif.svg)](generativefunctors.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](inlinerecords.html)

* * *

## ﻿12.16 Extension-only syntax

  * [12.16.1 Extension operators](extensionsyntax.html#ss%3Aextension-operators)
  * [12.16.2 Extension literals](extensionsyntax.html#ss%3Aextension-literals)

(Introduced in OCaml 4.02.2, extended in 4.03)

Some syntactic constructions are accepted during parsing and rejected during
type checking. These syntactic constructions can therefore not be used
directly in vanilla OCaml. However, -ppx rewriters and other external tools
can exploit this parser leniency to extend the language with these new
syntactic constructions by rewriting them to vanilla constructions.

### ﻿12.16.1 Extension operators

(Introduced in OCaml 4.02.2, extended to unary operators in OCaml 4.12.0)

| infix-symbol| ::=|  ...  
---|---|---  
 | ∣|  # { [operator-char](lex.html#operator-char) } # { [operator-char](lex.html#operator-char) ∣ # }   
  
prefix-symbol| ::=|  ...  
 | ∣|  (? ∣ ~ ∣ !) { [operator-char](lex.html#operator-char) } # { [operator-char](lex.html#operator-char) ∣ # }   
  
  
There are two classes of operators available for extensions: infix operators
with a name starting with a # character and containing more than one #
character, and unary operators with a name (starting with a ?, ~, or !
character) containing at least one # character.

For instance:

# let infix x y = x##y;;

Error: ## is not a valid value identifier.

# let prefix x = !#x;;

Error: !# is not a valid value identifier.

Note that both ## and !# must be eliminated by a ppx rewriter to make this
example valid.

### ﻿12.16.2 Extension literals

(Introduced in OCaml 4.03)

| float-literal| ::=|  ...  
---|---|---  
 | ∣|  [-] (0…9) { 0…9 ∣ _ } [. { 0…9 ∣ _ }] [(e ∣ E) [+ ∣ -] (0…9) { 0…9 ∣ _ }] [g…z ∣ G…Z]   
 | ∣|  [-] (0x ∣ 0X) (0…9 ∣ A…F ∣ a…f) { 0…9 ∣ A…F ∣ a…f ∣ _ } [. { 0…9 ∣ A…F ∣ a…f ∣ _ }] [(p ∣ P) [+ ∣ -] (0…9) { 0…9 ∣ _ }] [g…z ∣ G…Z]   
  
int-literal| ::=|  ...  
 | ∣|  [-] (0…9) { 0…9 ∣ _ }[g…z ∣ G…Z]   
 | ∣|  [-] (0x ∣ 0X) (0…9 ∣ A…F ∣ a…f) { 0…9 ∣ A…F ∣ a…f ∣ _ } [g…z ∣ G…Z]   
 | ∣|  [-] (0o ∣ 0O) (0…7) { 0…7 ∣ _ } [g…z ∣ G…Z]   
 | ∣|  [-] (0b ∣ 0B) (0…1) { 0…1 ∣ _ } [g…z ∣ G…Z]   
  
  
Int and float literals followed by an one-letter identifier in the range
[g..z∣G..Z] are extension-only literals.

* * *

[![Previous](previous_motif.svg)](generativefunctors.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](inlinerecords.html)

