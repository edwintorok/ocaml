[![Previous](previous_motif.svg)](comp.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](runtime.html)

* * *

# Chapter 14 The toplevel system or REPL (ocaml)

  * [14.1 Options](toplevel.html#s%3Atoplevel-options)
  * [14.2 Toplevel directives](toplevel.html#s%3Atoplevel-directives)
  * [14.3 The toplevel and the module system](toplevel.html#s%3Atoplevel-modules)
  * [14.4 Common errors](toplevel.html#s%3Atoplevel-common-errors)
  * [14.5 Building custom toplevel systems: ocamlmktop](toplevel.html#s%3Acustom-toplevel)
  * [14.6 The native toplevel: ocamlnat (experimental)](toplevel.html#s%3Aocamlnat)

This chapter describes ocaml, the toplevel system for OCaml, that permits
interactive use of the OCaml system through a read-eval-print loop (REPL). In
this mode, the system repeatedly reads OCaml phrases from the input, then
typechecks, compile and evaluate them, then prints the inferred type and
result value, if any. End-of-file on standard input terminates ocaml.

Input to the toplevel can span several lines. It begins after the # (sharp)
prompt printed by the system and is terminated by ;; (a double-semicolon)
followed by optional white space and comments and an end of line. The toplevel
input consists in one or several toplevel phrases, with the following syntax:

| toplevel-input| ::=|  { [definition](modules.html#definition) } ;;  
---|---|---  
 | ∣|  [expr](expr.html#expr) ;;  
 | ∣|  # [ident](lex.html#ident) [ directive-argument ] ;;  
  
directive-argument| ::=|  [string-literal](lex.html#string-literal)  
 | ∣|  [integer-literal](lex.html#integer-literal)  
 | ∣|  [value-path](names.html#value-path)  
 | ∣|  true ∣ false  
  
A phrase can consist of a sequence of definitions, like those found in
implementations of compilation units or in struct … end module expressions.
The definitions can bind value names, type names, exceptions, module names, or
module type names. The toplevel system performs the bindings, then prints the
types and values (if any) for the names thus defined.

A phrase may also consist in a value expression (section
[11.7](expr.html#s%3Avalue-expr)). It is simply evaluated without performing
any bindings, and its value is printed.

Finally, a phrase can also consist in a toplevel directive, starting with #
(the sharp sign). These directives control the behavior of the toplevel; they
are listed below in section 14.2.

> Unix: The toplevel system is started by the command ocaml, as follows:
>  
>  
>             ocaml options objects                # interactive mode
>             ocaml options objects scriptfile        # script mode
>  
>
> options are described below. objects are filenames ending in .cmo or .cma;
> they are loaded into the interpreter immediately after options are set.
> scriptfile is any file name not ending in .cmo or .cma.
>
> If no scriptfile is given on the command line, the toplevel system enters
> interactive mode: phrases are read on standard input, results are printed on
> standard output, errors on standard error. End-of-file on standard input
> terminates ocaml (see also the #quit directive in section 14.2).
>
> On start-up (before the first phrase is read), the contents of
> initialization file are read as a sequence of OCaml phrases and executed as
> per the #use directive described in section 14.2. The evaluation outcode for
> each phrase are not displayed.
>
> The initialization file is the first found of:
>
>   1. .ocamlinit in the current directory;
>   2. XDG_CONFIG_HOME/ocaml/init.ml, if XDG_CONFIG_HOME is an absolute path;
>   3. otherwise, on Unix, HOME/ocaml/init.ml or, on Windows, ocaml\init.ml
> under LocalAppData (e.g. C:\Users\Bactrian\AppData\Local\ocaml\init.ml);
>   4. ocaml/init.ml under any of the absolute paths in XDG_CONFIG_DIRS. Paths
> in XDG_CONFIG_DIRS are colon-delimited on Unix, and semicolon-delimited on
> Windows;
>   5. if XDG_CONFIG_DIRS contained no absolute paths, /usr/xdg/ocaml/init.ml
> on Unix or, ocaml\init.ml under any of LocalAppData (e.g.
> C:\Users\Bactrian\AppData\Local), RoamingAppData (e.g.
> C:\Users\Bactrian\AppData\Roaming), or ProgramData (e.g. C:\ProgramData) on
> Windows;
>   6. HOME/.ocamlinit, if HOME is non-empty;
>

>
> The toplevel system does not perform line editing, but it can easily be used
> in conjunction with an external line editor such as ledit, or rlwrap. An
> improved toplevel, utop, is also available. Another option is to use ocaml
> under Gnu Emacs, which gives the full editing power of Emacs (command run-
> caml from library inf-caml).
>
> At any point, the parsing, compilation or evaluation of the current phrase
> can be interrupted by pressing ctrl-C (or, more precisely, by sending the
> INTR signal to the ocaml process). The toplevel then immediately returns to
> the # prompt.
>
> If scriptfile is given on the command-line to ocaml, the toplevel system
> enters script mode: the contents of the file are read as a sequence of OCaml
> phrases and executed, as per the #use directive (section 14.2). The outcome
> of the evaluation is not printed. On reaching the end of file, the ocaml
> command exits immediately. No commands are read from standard input.
> Sys.argv is transformed, ignoring all OCaml parameters, and starting with
> the script file name in Sys.argv.(0).
>
> In script mode, the first line of the script is ignored if it starts with
> #!. Thus, it should be possible to make the script itself executable and put
> as first line #!/usr/local/bin/ocaml, thus calling the toplevel system
> automatically when the script is run. However, ocaml itself is a #! script
> on most installations of OCaml, and Unix kernels usually do not handle
> nested #! scripts. A better solution is to put the following as the first
> line of the script:
>  
>  
>             #!/usr/local/bin/ocamlrun /usr/local/bin/ocaml
>  

## ﻿14.1 Options

The following command-line options are recognized by the ocaml command.

-absname
     Force error messages to show absolute paths for file names.
-no-absname
     Do not try to show absolute filenames in error messages.
-args filename
     Read additional newline-terminated command line arguments from filename. It is not possible to pass a scriptfile via file to the toplevel. 
-args0 filename
     Read additional null character terminated command line arguments from filename. It is not possible to pass a scriptfile via file to the toplevel. 
-i-variance
     Cause the compiler to print the computed variance of type parameters for every type declaration. Without this option, variance is printed only for private types or types without a manifest (e.g., abstract types).
-I directory
     Add the given directory to the list of directories searched for source and compiled files. By default, the current directory is searched first, then the standard library directory. Directories added with -I are searched after the current directory, in the order in which they were given on the command line, but before the standard library directory. See also option -nostdlib.

If the given directory starts with +, it is taken relative to the standard
library directory. For instance, -I +unix adds the subdirectory unix of the
standard library to the search path.

Directories can also be added to the list once the toplevel is running with
the #directory directive (section 14.2).

-init file
     Load the given file instead of the default initialization file. The default initialization file is the first found of: 

  1. .ocamlinit in the current directory; 
  2. XDG_CONFIG_HOME/ocaml/init.ml, if XDG_CONFIG_HOME is an absolute path; 
  3. otherwise, on Unix, HOME/ocaml/init.ml or, on Windows, ocaml\init.ml under LocalAppData (e.g. C:\Users\Bactrian\AppData\Local\ocaml\init.ml); 
  4. ocaml/init.ml under any of the absolute paths in XDG_CONFIG_DIRS. Paths in XDG_CONFIG_DIRS are colon-delimited on Unix, and semicolon-delimited on Windows; 
  5. if XDG_CONFIG_DIRS contained no absolute paths, /usr/xdg/ocaml/init.ml on Unix or, ocaml\init.ml under any of LocalAppData (e.g. C:\Users\Bactrian\AppData\Local), RoamingAppData (e.g. C:\Users\Bactrian\AppData\Roaming), or ProgramData (e.g. C:\ProgramData) on Windows; 
  6. HOME/.ocamlinit, if HOME is non-empty; 

-keywords version+list
     Set keywords according to the version+list specification.

This specification starts with an optional version number, defining the base
set of keywords, followed by a +-separated list of additional keywords to add
to this base set.

Without an explicit version number, the base set of keywords is the set of
keywords in the current version of OCaml. Additional keywords that do not
match any known keyword in the current version of the language trigger an
error whenever they are present in the source code.

-labels
     Labels are not ignored in types, labels may be used in applications, and labelled parameters can be given in any order. This is the default.
-no-app-funct
     Deactivates the applicative behaviour of functors. With this option, each functor application generates new types in its result and applying the same functor twice to the same argument yields two incompatible structures.
-noassert
     Do not compile assertion checks. Note that the special form assert false is always compiled because it is typed specially. 
-nolabels
     Ignore non-optional labels in types. Labels cannot be used in applications, and parameter order becomes strict.
-noprompt
     Do not display any prompt when waiting for input. 
-nopromptcont
     Do not display the secondary prompt when waiting for continuation lines in multi-line inputs. This should be used e.g. when running ocaml in an emacs window. 
-nostdlib
     Do not include the standard library directory in the list of directories searched for source and compiled files. 
-ppx command
     After parsing, pipe the abstract syntax tree through the preprocessor command. The module Ast_mapper, described in chapter [31](parsing.html#c%3Aparsinglib): [ Ast_mapper ](compilerlibref/Ast_mapper.html) , implements the external interface of a preprocessor.
-principal
     Check information path during type-checking, to make sure that all types are derived in a principal way. When using labelled arguments and/or polymorphic methods, this flag is required to ensure future versions of the compiler will be able to infer types correctly, even if internal algorithms change. All programs accepted in -principal mode are also accepted in the default mode with equivalent types, but different binary signatures, and this may slow down type checking; yet it is a good idea to use it once before publishing source code.
-rectypes
     Allow arbitrary recursive types during type-checking. By default, only recursive types where the recursion goes through an object type are supported. 
-safe-string
     Enforce the separation between types string and bytes, thereby making strings read-only. This is the default, and enforced since OCaml 5.0.
-safer-matching
     Do not use type information to optimize pattern-matching. This allows to detect match failures even if a pattern-matching was wrongly assumed to be exhaustive. This only impacts GADT and polymorphic variant compilation.
-short-paths
     When a type is visible under several module-paths, use the shortest one when printing the type’s name in inferred interfaces and error and warning messages. Identifier names starting with an underscore _ or containing double underscores __ incur a penalty of +10 when computing their length.
-stdin
     Read the standard input as a script file rather than starting an interactive session. 
-strict-sequence
     Force the left-hand part of each sequence to have type unit.
-strict-formats
     Reject invalid formats that were accepted in legacy format implementations. You should use this flag to detect and fix such invalid formats, as they will be rejected by future OCaml versions.
-unsafe
     Turn bound checking off for array and string accesses (the v.(i) and s.[i] constructs). Programs compiled with -unsafe are therefore faster, but unsafe: anything can happen if the program accesses an array or string outside of its bounds. 
-unsafe-string
     Identify the types string and bytes, thereby making strings writable. This is intended for compatibility with old source code and should not be used with new software. This option raises an error unconditionally since OCaml 5.0.
-v
     Print the version number of the compiler and the location of the standard library directory, then exit.
-verbose
     Print all external commands before they are executed, Useful to debug C library problems.
-version
     Print version string and exit.
-vnum
     Print short version number and exit.
-no-version
     Do not print the version banner at startup. 
-w warning-list
     Enable, disable, or mark as fatal the warnings specified by the argument warning-list. Each warning can be _enabled_ or _disabled_ , and each warning can be _fatal_ or _non-fatal_. If a warning is disabled, it isn’t displayed and doesn’t affect compilation in any way (even if it is fatal). If a warning is enabled, it is displayed normally by the compiler whenever the source code triggers it. If it is enabled and fatal, the compiler will also stop with an error after displaying it.

The warning-list argument is a sequence of warning specifiers, with no
separators between them. A warning specifier is one of the following:

+num

     Enable warning number num. 
-num
     Disable warning number num. 
@num

     Enable and mark as fatal warning number num. 
+num1..num2

     Enable warnings in the given range. 
-num1..num2
     Disable warnings in the given range. 
@num1..num2

     Enable and mark as fatal warnings in the given range. 
+letter

     Enable the set of warnings corresponding to letter. The letter may be uppercase or lowercase. 
-letter
     Disable the set of warnings corresponding to letter. The letter may be uppercase or lowercase. 
@letter

     Enable and mark as fatal the set of warnings corresponding to letter. The letter may be uppercase or lowercase. 
uppercase-letter

     Enable the set of warnings corresponding to uppercase-letter. 
lowercase-letter

     Disable the set of warnings corresponding to lowercase-letter. 

Alternatively, warning-list can specify a single warning using its mnemonic
name (see below), as follows:

+name

     Enable warning name. 
-name
     Disable warning name. 
@name

     Enable and mark as fatal warning name. 

Warning numbers, letters and names which are not currently defined are
ignored. The warnings are as follows (the name following each number specifies
the mnemonic for that warning).

1 comment-start

     Suspicious-looking start-of-comment mark. 
2 comment-not-end

     Suspicious-looking end-of-comment mark. 
3

     Deprecated synonym for the ’deprecated’ alert. 
4 fragile-match

     Fragile pattern matching: matching that will remain complete even if additional constructors are added to one of the variant types matched. 
5 ignored-partial-application

     Partially applied function: expression whose result has function type and is ignored. 
6 labels-omitted

     Label omitted in function application. 
7 method-override

     Method overridden. 
8 partial-match

     Partial match: missing cases in pattern-matching. 
9 missing-record-field-pattern

     Missing fields in a record pattern. 
10 non-unit-statement

     Expression on the left-hand side of a sequence that doesn’t have type unit (and that is not a function, see warning number 5). 
11 redundant-case

     Redundant case in a pattern matching (unused match case). 
12 redundant-subpat

     Redundant sub-pattern in a pattern-matching. 
13 instance-variable-override

     Instance variable overridden. 
14 illegal-backslash

     Illegal backslash escape in a string constant. 
15 implicit-public-methods

     Private method made public implicitly. 
16 unerasable-optional-argument

     Unerasable optional argument. 
17 undeclared-virtual-method

     Undeclared virtual method. 
18 not-principal

     Non-principal type. 
19 non-principal-labels

     Type without principality. 
20 ignored-extra-argument

     Unused function argument. 
21 nonreturning-statement

     Non-returning statement. 
22 preprocessor

     Preprocessor warning. 
23 useless-record-with

     Useless record with clause. 
24 bad-module-name

     Bad module name: the source file name is not a valid OCaml module name. 
25

     Ignored: now part of warning 8. 
26 unused-var

     Suspicious unused variable: unused variable that is bound with let or as, and doesn’t start with an underscore (_) character. 
27 unused-var-strict

     Innocuous unused variable: unused variable that is not bound with let nor as, and doesn’t start with an underscore (_) character. 
28 wildcard-arg-to-constant-constr

     Wildcard pattern given as argument to a constant constructor. 
29 eol-in-string

     Unescaped end-of-line in a string constant (non-portable code). 
30 duplicate-definitions

     Two labels or constructors of the same name are defined in two mutually recursive types. 
31 module-linked-twice

     A module is linked twice in the same executable. Ignored: now a hard error (since 5.1). 
32 unused-value-declaration

     Unused value declaration. (since 4.00) 
33 unused-open

     Unused open statement. (since 4.00) 
34 unused-type-declaration

     Unused type declaration. (since 4.00) 
35 unused-for-index

     Unused for-loop index. (since 4.00) 
36 unused-ancestor

     Unused ancestor variable. (since 4.00) 
37 unused-constructor

     Unused constructor. (since 4.00) 
38 unused-extension

     Unused extension constructor. (since 4.00) 
39 unused-rec-flag

     Unused rec flag. (since 4.00) 
40 name-out-of-scope

     Constructor or label name used out of scope. (since 4.01) 
41 ambiguous-name

     Ambiguous constructor or label name. (since 4.01) 
42 disambiguated-name

     Disambiguated constructor or label name (compatibility warning). (since 4.01) 
43 nonoptional-label

     Nonoptional label applied as optional. (since 4.01) 
44 open-shadow-identifier

     Open statement shadows an already defined identifier. (since 4.01) 
45 open-shadow-label-constructor

     Open statement shadows an already defined label or constructor. (since 4.01) 
46 bad-env-variable

     Error in environment variable. (since 4.01) 
47 attribute-payload

     Illegal attribute payload. (since 4.02) 
48 eliminated-optional-arguments

     Implicit elimination of optional arguments. (since 4.02) 
49 no-cmi-file

     Absent cmi file when looking up module alias. (since 4.02) 
50 unexpected-docstring

     Unexpected documentation comment. (since 4.03) 
51 wrong-tailcall-expectation

     Function call annotated with an incorrect @tailcall attribute. (since 4.03) 
52 fragile-literal-pattern (see [13.5.3](comp.html#ss%3Awarn52))

     Fragile constant pattern. (since 4.03) 
53 misplaced-attribute

     Attribute cannot appear in this context. (since 4.03) 
54 duplicated-attribute

     Attribute used more than once on an expression. (since 4.03) 
55 inlining-impossible

     Inlining impossible. (since 4.03) 
56 unreachable-case

     Unreachable case in a pattern-matching (based on type information). (since 4.03) 
57 ambiguous-var-in-pattern-guard (see [13.5.4](comp.html#ss%3Awarn57))

     Ambiguous or-pattern variables under guard. (since 4.03) 
58 no-cmx-file

     Missing cmx file. (since 4.03) 
59 flambda-assignment-to-non-mutable-value

     Assignment to non-mutable value. (since 4.03) 
60 unused-module

     Unused module declaration. (since 4.04) 
61 unboxable-type-in-prim-decl

     Unboxable type in primitive declaration. (since 4.04) 
62 constraint-on-gadt

     Type constraint on GADT type declaration. (since 4.06) 
63 erroneous-printed-signature

     Erroneous printed signature. (since 4.08) 
64 unsafe-array-syntax-without-parsing

     -unsafe used with a preprocessor returning a syntax tree. (since 4.08) 
65 redefining-unit

     Type declaration defining a new ’()’ constructor. (since 4.08) 
66 unused-open-bang

     Unused open! statement. (since 4.08) 
67 unused-functor-parameter

     Unused functor parameter. (since 4.10) 
68 match-on-mutable-state-prevent-uncurry

     Pattern-matching depending on mutable state prevents the remaining arguments from being uncurried. (since 4.12) 
69 unused-field

     Unused record field. (since 4.13) 
70 missing-mli

     Missing interface file. (since 4.13) 
71 unused-tmc-attribute

     Unused @tail_mod_cons attribute. (since 4.14) 
72 tmc-breaks-tailcall

     A tail call is turned into a non-tail call by the @tail_mod_cons transformation. (since 4.14) 
73 generative-application-expects-unit

     A generative functor is applied to an empty structure (struct end) rather than to (). (since 5.1) 
74 degraded-to-partial-match

     A pattern-matching is compiled as partial even if it appears to be total. (since 5.3) 
75 unnecessarily-partial-tuple-pattern

     A tuple pattern ends in .. but fully matches its expected type. (since 5.4) 
A

     all warnings 
C

     warnings 1, 2. 
D

     Alias for warning 3. 
E

     Alias for warning 4. 
F

     Alias for warning 5. 
K

     warnings 32, 33, 34, 35, 36, 37, 38, 39. 
L

     Alias for warning 6. 
M

     Alias for warning 7. 
P

     Alias for warning 8. 
R

     Alias for warning 9. 
S

     Alias for warning 10. 
U

     warnings 11, 12. 
V

     Alias for warning 13. 
X

     warnings 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 30. 
Y

     Alias for warning 26. 
Z

     Alias for warning 27. 

The default setting is -w +a-4-7-9-27-29-30-32..42-44-45-48-50-60-66..70-74.
It is displayed by  -help. Note that warnings 5 and 10 are not always
triggered, depending on the internals of the type checker.

-warn-error warning-list
     Mark as fatal the warnings specified in the argument warning-list. The compiler will stop with an error when one of these warnings is emitted. The warning-list has the same meaning as for the -w option: a + sign (or an uppercase letter) marks the corresponding warnings as fatal, a - sign (or a lowercase letter) turns them back into non-fatal warnings, and a @ sign both enables and marks as fatal the corresponding warnings.

Note: it is not recommended to use warning sets (i.e. letters) as arguments to
-warn-error in production code, because this can break your build when future
versions of OCaml add some new warnings.

The default setting is -warn-error -a (no warning is fatal).

-warn-help
     Show the description of all available warning numbers.
- file
     Use file as a script file name, even when it starts with a hyphen (-).
-help or \--help
     Display a short usage summary and exit.

> Unix: The following environment variables are also consulted:
>
> OCAMLTOP_INCLUDE_PATH
>      Additional directories to search for compiled object code files (.cmi,
> .cmo and .cma). The specified directories are considered from left to right,
> after the include directories specified on the command line via -I have been
> searched. Available since OCaml 4.08.
> OCAMLTOP_UTF_8
>      When printing string values, non-ascii bytes ( > \0x7E ) are printed as
> decimal escape sequence if OCAMLTOP_UTF_8 is set to false. Otherwise, they
> are printed unescaped.
> TERM
>      When printing error messages, the toplevel system attempts to underline
> visually the location of the error. It consults the TERM variable to
> determines the type of output terminal and look up its capabilities in the
> terminal database.
> XDG_CONFIG_HOME, HOME, XDG_CONFIG_DIRS
>      Initialization file lookup procedure (see above).

## ﻿14.2 Toplevel directives

The following directives control the toplevel behavior, load files in memory,
and trace program execution.

Note: all directives start with a # (sharp) symbol. This # must be typed
before the directive, and must not be confused with the # prompt displayed by
the interactive loop. For instance, typing #quit;; will exit the toplevel
loop, but typing quit;; will result in an “unbound value quit” error.

General

    

#help;;

     Prints a list of all available directives, with corresponding argument type if appropriate. 
#quit;;

     Exit the toplevel loop and terminate the ocaml command. 
Loading codes

    

#cd "dir-name";;

     Change the current working directory.
#directory "dir-name";;

     Add the given directory to the list of directories searched for source and compiled files.
#remove_directory "dir-name";;

     Remove the given directory from the list of directories searched for source and compiled files. Do nothing if the list does not contain the given directory.
#load "file-name";;

     Load in memory a bytecode object file (.cmo file) or library file (.cma file) produced by the batch compiler ocamlc.
#load_rec "file-name";;

     Load in memory a bytecode object file (.cmo file) or library file (.cma file) produced by the batch compiler ocamlc. When loading an object file that depends on other modules which have not been loaded yet, the .cmo files for these modules are searched and loaded as well, recursively. The loading order is not specified.
#use "file-name";;

     Read, compile and execute source phrases from the given file. This is textual inclusion: phrases are processed just as if they were typed on standard input. The reading of the file stops at the first error encountered.
#use_output "command";;

     Execute a command and evaluate its output as if it had been captured to a file and passed to #use.
#mod_use "file-name";;

     Similar to #use but also wrap the code into a top-level module of the same name as capitalized file name without extensions, following semantics of the compiler. 

For directives that take file names as arguments, if the given file name
specifies no directory, the file is searched in the following directories:

  1. In script mode, the directory containing the script currently executing; in interactive mode, the current working directory. 
  2. Directories added with the #directory directive. 
  3. Directories given on the command line with -I options. 
  4. The standard library directory. 

Environment queries

    

#show_class class-path;;

    
#show_class_type class-path;;

    
#show_exception ident;;

    
#show_module module-path;;

    
#show_module_type modtype-path;;

    
#show_type typeconstr;;

    
#show_val value-path;;

     Print the signature of the corresponding component.
#show ident;;

     Print the signatures of components with name ident in all the above categories. 
Pretty-printing

    

#install_printer printer-name;;

     This directive registers the function named printer-name (a value path) as a printer for values whose types match the argument type of the function. That is, the toplevel loop will call printer-name when it has such a value to print.

The printing function printer-name should have type Format.formatter -> t ->
unit, where t is the type for the values to be printed, and should output its
textual representation for the value of type t on the given formatter, using
the functions provided by the Format library. For backward compatibility,
printer-name can also have type t -> unit and should then output on the
standard formatter, but this usage is deprecated.

#print_depth n;;

     Limit the printing of values to a maximal depth of n. The parts of values whose depth exceeds n are printed as ... (ellipsis).
#print_length n;;

     Limit the number of value nodes printed to at most n. Remaining parts of values are printed as ... (ellipsis).
#remove_printer printer-name;;

     Remove the named function from the table of toplevel printers. 
Tracing

    

#trace function-name;;

     After executing this directive, all calls to the function named function-name will be “traced”. That is, the argument and the result are displayed for each call, as well as the exceptions escaping out of the function, raised either by the function itself or by another function it calls. If the function is curried, each argument is printed as it is passed to the function.
#untrace function-name;;

     Stop tracing the given function.
#untrace_all;;

     Stop tracing all functions traced so far. 
Compiler options

    

#debug bool;;

     Turn on/off the insertion of debugging events. Default is true.
#labels bool;;

     Ignore labels in function types if argument is false, or switch back to default behaviour (commuting style) if argument is true.
#ppx "file-name";;

     After parsing, pipe the abstract syntax tree through the preprocessor command.
#principal bool;;

     If the argument is true, check information paths during type-checking, to make sure that all types are derived in a principal way. If the argument is false, do not check information paths.
#rectypes;;

     Allow arbitrary recursive types during type-checking. Note: once enabled, this option cannot be disabled because that would lead to unsoundness of the type system.
#warn_error "warning-list";;

     Treat as errors the warnings enabled by the argument and as normal warnings the warnings disabled by the argument.
#warnings "warning-list";;

     Enable or disable warnings according to the argument.

## ﻿14.3 The toplevel and the module system

Toplevel phrases can refer to identifiers defined in compilation units with
the same mechanisms as for separately compiled units: either by using
qualified names (Modulename.localname), or by using the open construct and
unqualified names (see section [11.3](names.html#s%3Anames)).

However, before referencing another compilation unit, an implementation of
that unit must be present in memory. At start-up, the toplevel system contains
implementations for all the modules in the standard library. Implementations
for user modules can be entered with the #load directive described above.
Referencing a unit for which no implementation has been provided results in
the error Reference to undefined global `...'.

Note that entering open Mod merely accesses the compiled interface (.cmi file)
for Mod, but does not load the implementation of Mod, and does not cause any
error if no implementation of Mod has been loaded. The error “reference to
undefined global Mod” will occur only when executing a value or module
definition that refers to Mod.

## ﻿14.4 Common errors

This section describes and explains the most frequently encountered error
messages.

Cannot find file filename

     The named file could not be found in the current directory, nor in the directories of the search path.

If filename has the format mod.cmi, this means you have referenced the
compilation unit mod, but its compiled interface could not be found. Fix:
compile mod.mli or mod.ml first, to create the compiled interface mod.cmi.

If filename has the format mod.cmo, this means you are trying to load with
#load a bytecode object file that does not exist yet. Fix: compile mod.ml
first.

If your program spans several directories, this error can also appear because
you haven’t specified the directories to look into. Fix: use the #directory
directive to add the correct directories to the search path.

This expression has type t1, but is used with type t2

     See section [13.4](comp.html#s%3Acomp-errors).
Reference to undefined global mod

     You have neglected to load in memory an implementation for a module with #load. See section 14.3 above.

## ﻿14.5 Building custom toplevel systems: ocamlmktop

The ocamlmktop command builds OCaml toplevels that contain user code preloaded
at start-up.

The ocamlmktop command takes as argument a set of .cmo and .cma files, and
links them with the object files that implement the OCaml toplevel. The
typical use is:

    
    
            ocamlmktop -o mytoplevel foo.cmo bar.cmo gee.cmo
    

This creates the bytecode file mytoplevel, containing the OCaml toplevel
system, plus the code from the three .cmo files. This toplevel is directly
executable and is started by:

    
    
            ./mytoplevel
    

This enters a regular toplevel loop, except that the code from foo.cmo,
bar.cmo and gee.cmo is already loaded in memory, just as if you had typed:

    
    
            #load "foo.cmo";;
            #load "bar.cmo";;
            #load "gee.cmo";;
    

on entrance to the toplevel. The modules Foo, Bar and Gee are not opened,
though; you still have to do

    
    
            open Foo;;
    

yourself, if this is what you wish.

### ﻿14.5.1 Options

The following command-line options are recognized by ocamlmktop.

-cclib libname
     Pass the -llibname option to the C linker when linking in “custom runtime” mode. See the corresponding option for ocamlc, in chapter [13](comp.html#c%3Acamlc).
-ccopt option
     Pass the given option to the C compiler and linker, when linking in “custom runtime” mode. See the corresponding option for ocamlc, in chapter [13](comp.html#c%3Acamlc).
-custom
     Link in “custom runtime” mode. See the corresponding option for ocamlc, in chapter [13](comp.html#c%3Acamlc).
-I directory
     Add the given directory to the list of directories searched for compiled object code files (.cmo and .cma).
-o exec-file
     Specify the name of the toplevel file produced by the linker. The default is a.out.

## ﻿14.6 The native toplevel: ocamlnat (experimental)

This section describes a tool that is not yet officially supported but may be
found useful.

OCaml code executing in the traditional toplevel system uses the bytecode
interpreter. When increased performance is required, or for testing programs
that will only execute correctly when compiled to native code, the _native
toplevel_ may be used instead.

For the majority of installations the native toplevel will not have been
installed along with the rest of the OCaml toolchain. In such circumstances it
will be necessary to build the OCaml distribution from source. From the built
source tree of the distribution you may use make natruntop to build and
execute a native toplevel. (Alternatively make ocamlnat can be used, which
just performs the build step.)

If the make install command is run after having built the native toplevel then
the ocamlnat program (either from the source or the installation directory)
may be invoked directly rather than using make natruntop.

* * *

[![Previous](previous_motif.svg)](comp.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](runtime.html)

