[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](values.html)

* * *

## ﻿11.1 Lexical conventions

#### ﻿Source file encoding

OCaml source files are expected to be valid UTF-8 encoded Unicode text. The
interpretation of source files which are not UTF-8 encoded is unspecified.
Such source files may be rejected in the future.

#### ﻿Blanks

The following characters are considered as blanks: space, horizontal
tabulation, carriage return, line feed and form feed. Blanks are ignored, but
they separate adjacent identifiers, literals and keywords that would otherwise
be confused as one single identifier, literal or keyword.

#### ﻿Comments

Comments are introduced by the two characters (*, with no intervening blanks,
and terminated by the characters *), with no intervening blanks. Comments are
treated as blank characters. Comments do not occur inside string or character
literals. Nested comments are handled correctly.

(* single line comment *) (* multiple line comment, commenting out part of a program, and containing a nested comment: let f = function | 'A'..'Z' -> "Uppercase" (* Add other cases later... *) *)

#### ﻿Identifiers

| ident| ::=|  (letter ∣ _) { letter ∣ 0…9 ∣ _ ∣ ' }  
---|---|---  
  
capitalized-ident| ::=|  uppercase-letter { letter ∣ 0…9 ∣ _ ∣ ' }  
  
lowercase-ident| ::=|  (\\#)? (lowercase-letter ∣ _) { letter ∣ 0…9 ∣ _ ∣ ' }  
  
letter| ::=|  uppercase-letter ∣ lowercase-letter  
  
lowercase-letter| ::=|  a…z ∣ U+00DF … U+00F6 ∣ U+00F8 … U+00FF ∣ U+0153 ∣
U+0161 ∣ U+017E  
  
uppercase-letter| ::=|  A…Z ∣ U+00C0 … U+00D6 ∣ U+00D8 … U+00DE ∣ U+0152 ∣
U+0160 ∣ U+017D ∣ U+0178 ∣ U+1E9E  
  
  
Identifiers are sequences of letters, digits, _ (the underscore character),
and ' (the single quote), starting with a letter or an underscore. Letters
contain the 52 lowercase and uppercase letters from the ASCII set, letters
ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ from the
Latin-1 Supplement block, letters ŠšŽžŒœŸ from the Latin Extended-A block and
upper case ẞ (U+189E). Any byte sequence which is equivalent to one of these
Unicode characters under NFC1 is supported too.

All characters in an identifier are meaningful. The current implementation
accepts identifiers up to 16000000 characters in length.

In many places, OCaml makes a distinction between capitalized identifiers and
identifiers that begin with a lowercase letter. The underscore character is
considered a lowercase letter for this purpose.

An identifier starting with \\# is called a _raw identifier_ and is equivalent
to the identifier obtained by dropping the \\# prefix, except that the result
is never interpreted as a keyword (see section 11.1).

#### ﻿Integer literals

| integer-literal| ::=|  [-] (0…9) { 0…9 ∣ _ }  
---|---|---  
 | ∣|  [-] (0x ∣ 0X) (0…9 ∣ A…F ∣ a…f) { 0…9 ∣ A…F ∣ a…f ∣ _ }   
 | ∣|  [-] (0o ∣ 0O) (0…7) { 0…7 ∣ _ }   
 | ∣|  [-] (0b ∣ 0B) (0…1) { 0…1 ∣ _ }   
  
int32-literal| ::=|  integer-literal l  
  
int64-literal| ::=|  integer-literal L  
  
nativeint-literal| ::=|  integer-literal n  
  
An integer literal is a sequence of one or more digits, optionally preceded by
a minus sign. By default, integer literals are in decimal (radix 10). The
following prefixes select a different radix:

Prefix| Radix  
---|---  
0x, 0X| hexadecimal (radix 16)  
0o, 0O| octal (radix 8)  
0b, 0B| binary (radix 2)  
  
(The initial 0 is the digit zero; the O for octal is the letter O.) An integer
literal can be followed by one of the letters l, L or n to indicate that this
integer has type int32, int64 or nativeint respectively, instead of the
default type int for integer literals. The interpretation of integer literals
that fall outside the range of representable integer values is undefined.

For convenience and readability, underscore characters (_) are accepted (and
ignored) within integer literals.

# let house_number = 37 let million = 1_000_000 let copyright = 0x00A9 let
counter64bit = ref 0L;;

val house_number : int = 37 val million : int = 1000000 val copyright : int =
169 val counter64bit : int64 ref = {contents = 0L}

#### ﻿Floating-point literals

| float-literal| ::=|  [-] (0…9) { 0…9 ∣ _ } [. { 0…9 ∣ _ }] [(e ∣ E) [+ ∣ -]
(0…9) { 0…9 ∣ _ }]  
---|---|---  
 | ∣|  [-] (0x ∣ 0X) (0…9 ∣ A…F ∣ a…f) { 0…9 ∣ A…F ∣ a…f ∣ _ } [. { 0…9 ∣ A…F ∣ a…f ∣ _ }] [(p ∣ P) [+ ∣ -] (0…9) { 0…9 ∣ _ }]   
  
Floating-point decimal literals consist in an integer part, a fractional part
and an exponent part. The integer part is a sequence of one or more digits,
optionally preceded by a minus sign. The fractional part is a decimal point
followed by zero, one or more digits. The exponent part is the character e or
E followed by an optional + or - sign, followed by one or more digits. It is
interpreted as a power of 10. The fractional part or the exponent part can be
omitted but not both, to avoid ambiguity with integer literals. The
interpretation of floating-point literals that fall outside the range of
representable floating-point values is undefined.

Floating-point hexadecimal literals are denoted with the 0x or 0X prefix. The
syntax is similar to that of floating-point decimal literals, with the
following differences. The integer part and the fractional part use
hexadecimal digits. The exponent part starts with the character p or P. It is
written in decimal and interpreted as a power of 2.

For convenience and readability, underscore characters (_) are accepted (and
ignored) within floating-point literals.

# let pi = 3.141_592_653_589_793_12 let small_negative = -1e-5 let
machine_epsilon = 0x1p-52;;

val pi : float = 3.14159265358979312 val small_negative : float = -1e-05 val
machine_epsilon : float = 2.22044604925031308e-16

#### ﻿Character literals

| char-literal| ::=|  ' regular-char '  
---|---|---  
 | ∣|  ' escape-sequence '  
  
escape-sequence| ::=|  \ (\ ∣ " ∣ ' ∣ n ∣ t ∣ b ∣ r ∣ space)  
 | ∣|  \ (0…9) (0…9) (0…9)   
 | ∣|  \x (0…9 ∣ A…F ∣ a…f) (0…9 ∣ A…F ∣ a…f)   
 | ∣|  \o (0…3) (0…7) (0…7)   
  
Character literals are delimited by ' (single quote) characters. The two
single quotes enclose either one US-ASCII character different from ' and \, or
one of the escape sequences below:

Sequence| Character denoted  
---|---  
\\\| backslash (\)  
\"| double quote (")  
\'| single quote (')  
\n| linefeed (LF)  
\r| carriage return (CR)  
\t| horizontal tabulation (TAB)  
\b| backspace (BS)  
\space| space (SPC)  
\ddd| the character with code ddd in decimal  
\xhh| the character with code hh in hexadecimal  
\oooo| the character with code ooo in octal  
  
A non-ASCII Unicode character is not a valid character literal. The numerical
escape sequences denote a character by its code, and can be used both for
characters in the ASCII range and for byte values outside it.

# let a = 'a' let single_quote = '\'' let char_max = '\xFF';;

val a : char = 'a' val single_quote : char = '\'' val char_max : char = '\255'

#### ﻿String literals

| string-literal| ::=|  " { string-character } "  
---|---|---  
 | ∣|  { quoted-string-id | { newline  
 | ∣|  any-char } | quoted-string-id }  
  
quoted-string-id| ::=|  { lowercase-letter ∣ _ }  
  
string-character| ::=|  regular-string-char  
 | ∣|  escape-sequence  
 | ∣|  \u{ { 0…9 ∣ A…F ∣ a…f }+ }  
 | ∣|  newline  
 | ∣|  \ newline { space ∣ tab }   
  
String literals are delimited by " (double quote) characters. The two double
quotes enclose a sequence of either characters different from " and \, or
escape sequences from the table given above for character literals, or a
Unicode character escape sequence.

A Unicode character escape sequence is substituted by the UTF-8 encoding of
the specified Unicode scalar value. The Unicode scalar value, an integer in
the ranges 0x0000...0xD7FF or 0xE000...0x10FFFF, is defined using 1 to 6
hexadecimal digits; leading zeros are allowed.

# let greeting = "Hello, World!\n" let superscript_plus = "\u{207A}";;

val greeting : string = "Hello, World!\n" val superscript_plus : string = "⁺"

A newline sequence is a line feed optionally preceded by a carriage return.
Since OCaml 5.2, a newline sequence occurring in a string literal is
normalized into a single line feed character.

To allow splitting long string literals across lines, the sequence \newline
spaces-or-tabs (a backslash at the end of a line followed by any number of
spaces and horizontal tabulations at the beginning of the next line) is
ignored inside string literals.

# let longstr = "Call me Ishmael. Some years ago — never mind how long \
precisely — having little or no money in my purse, and \ nothing particular to
interest me on shore, I thought I\ \ would sail about a little and see the
watery part of t\ he world.";;

val longstr : string = "Call me Ishmael. Some years ago — never mind how long
precisely — having little or no money in my purse, and nothing particular to
interest me on shore, I thought I would sail about a little and see the watery
part of the world."

Escaped newlines provide more convenient behavior than non-escaped newlines,
as the indentation is not considered part of the string literal.

# let contains_unexpected_spaces = "This multiline literal contains three
consecutive spaces." let no_unexpected_spaces = "This multiline literal \n\
uses a single space between all words.";;

val contains_unexpected_spaces : string = "This multiline literal\n contains
three consecutive spaces." val no_unexpected_spaces : string = "This multiline
literal \nuses a single space between all words."

Quoted string literals provide an alternative lexical syntax for string literals. They are useful to represent strings of arbitrary content without escaping. Quoted strings are delimited by a matching pair of { quoted-string-id | and | quoted-string-id } with the same quoted-string-id on both sides. Quoted strings do not interpret any character in a special way2 but requires that the sequence | quoted-string-id } does not occur in the string itself. The identifier quoted-string-id is a (possibly empty) sequence of lowercase letters and underscores that can be freely chosen to avoid such issue.

# let quoted_greeting = {|"Hello, World!"|} let nested = {ext|hello
{|world|}|ext};;

val quoted_greeting : string = "\"Hello, World!\"" val nested : string =
"hello {|world|}"

The current implementation places practically no restrictions on the length of
string literals.

#### ﻿Naming labels

To avoid ambiguities, naming labels in expressions cannot just be defined
syntactically as the sequence of the three tokens ~, ident and :, and have to
be defined at the lexical level.

| label-name| ::=|  lowercase-ident  
---|---|---  
  
label| ::=|  ~ label-name :  
  
optlabel| ::=|  ? label-name :  
  
Naming labels come in two flavours: label for normal arguments and optlabel
for optional ones. They are simply distinguished by their first character,
either ~ or ?.

Despite label and optlabel being lexical entities in expressions, their
expansions ~ label-name : and ? label-name : will be used in grammars, for the
sake of readability. Note also that inside type expressions, this expansion
can be taken literally, _i.e._ there are really 3 tokens, with optional blanks
between them.

#### ﻿Prefix and infix symbols

| infix-symbol| ::=|  (core-operator-char ∣ % ∣ <) { operator-char }  
---|---|---  
 | ∣|  # { operator-char }+  
  
prefix-symbol| ::=|  ! { operator-char }  
 | ∣|  (? ∣ ~) { operator-char }+  
  
operator-char| ::=|  ~ ∣ ! ∣ ? ∣ core-operator-char ∣ % ∣ < ∣ : ∣ .  
  
core-operator-char| ::=|  $ ∣ & ∣ * ∣ + ∣ - ∣ / ∣ = ∣ > ∣ @ ∣ ^ ∣ |  
  
See also the following language extensions: [extension
operators](extensionsyntax.html#s%3Aext-ops), [extended indexing
operators](indexops.html#s%3Aindex-operators), and [binding
operators](bindingops.html#s%3Abinding-operators).

Sequences of “operator characters”, such as <=> or !!, are read as a single
token from the infix-symbol or prefix-symbol class. These symbols are parsed
as prefix and infix operators inside expressions, but otherwise behave like
normal identifiers.

#### ﻿Keywords

The identifiers below are reserved as keywords, and must be prefixed with \\#
to be used otherwise (see section 11.1):

    
    
          and         as          assert      asr         begin       class
          constraint  do          done        downto      effect      else
          end         exception   external    false       for         fun
          function    functor     if          in          include     inherit
          initializer land        lazy        let         lor         lsl
          lsr         lxor        match       method      mod         module
          mutable     new         nonrec      object      of          open
          or          private     rec         sig         struct      then
          to          true        try         type        val         virtual
          when        while       with
    

  
The following character sequences are also keywords (and unlike the above
identifiers, they are always reserved):

    
    
        !=    #     &     &&    '     (     )     *     +     ,     -
        -.    ->    .     ..    .~    :     ::    :=    :>    ;     ;;
        <     <-    =     >     >]    >}    ?     [     [<    [>    [|
        ]     _     `     {     {<    |     |]    ||    }     ~
    

Note that the exact set of keywords can be modified by using the -keywords
command-line compiler flag (see section [13.2](comp.html#s%3Acomp-options)).
Finally, note that the following identifiers are keywords of the now
unmaintained Camlp4 system and should be avoided for backwards compatibility
reasons.

    
    
        parser    value    $     $$    $:    <:    <<    >>    ??
    

#### ﻿Ambiguities

Lexical ambiguities are resolved according to the “longest match” rule: when a
character sequence can be decomposed into two tokens in several different
ways, the decomposition retained is the one with the longest first token.

#### ﻿Line number directives

| linenum-directive| ::=|  # { 0…9 }+ " { string-character } "  
---|---|---  
  
Preprocessors that generate OCaml source code can insert line number
directives in their output so that error messages produced by the compiler
contain line numbers and file names referring to the source file before
preprocessing, instead of after preprocessing. A line number directive starts
at the beginning of a line, is composed of a # (sharp sign), followed by a
positive integer (the source line number), followed by a character string (the
source file name). Line number directives are treated as blanks during lexical
analysis.

* * *

1

    

Normalization Form C

2

    

Except for the normalization of newline sequences into a single line feed
mentioned earlier.

* * *

[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](values.html)

