[![Previous](previous_motif.svg)](runtime.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](lexyacc.html)

* * *

# Chapter 16 Native-code compilation (ocamlopt)

  * [16.1 Overview of the compiler](native.html#s%3Anative-overview)
  * [16.2 Options](native.html#s%3Anative-options)
  * [16.3 Common errors](native.html#s%3Anative-common-errors)
  * [16.4 Running executables produced by ocamlopt](native.html#s%3Anative%3Arunning-executable)
  * [16.5 Compatibility with the bytecode compiler](native.html#s%3Acompat-native-bytecode)

This chapter describes the OCaml high-performance native-code compiler
ocamlopt, which compiles OCaml source files to native code object files and
links these object files to produce standalone executables.

The native-code compiler is only available on certain platforms. It produces
code that runs faster than the bytecode produced by ocamlc, at the cost of
increased compilation time and executable code size. Compatibility with the
bytecode compiler is extremely high: the same source code should run
identically when compiled with ocamlc and ocamlopt.

It is not possible to mix native-code object files produced by ocamlopt with
bytecode object files produced by ocamlc: a program must be compiled entirely
with ocamlopt or entirely with ocamlc. Native-code object files produced by
ocamlopt cannot be loaded in the toplevel system ocaml.

## ﻿16.1 Overview of the compiler

The ocamlopt command has a command-line interface very close to that of
ocamlc. It accepts the same types of arguments, and processes them
sequentially, after all options have been processed:

  * Arguments ending in .mli are taken to be source files for compilation unit interfaces. Interfaces specify the names exported by compilation units: they declare value names with their types, define public data types, declare abstract data types, and so on. From the file x.mli, the ocamlopt compiler produces a compiled interface in the file x.cmi. The interface produced is identical to that produced by the bytecode compiler ocamlc.
  * Arguments ending in .ml are taken to be source files for compilation unit implementations. Implementations provide definitions for the names exported by the unit, and also contain expressions to be evaluated for their side-effects. From the file x.ml, the ocamlopt compiler produces two files: x.o, containing native object code, and x.cmx, containing extra information for linking and optimization of the clients of the unit. The compiled implementation should always be referred to under the name x.cmx (when given a .o or .obj file, ocamlopt assumes that it contains code compiled from C, not from OCaml).

The implementation is checked against the interface file x.mli (if it exists)
as described in the manual for ocamlc (chapter [13](comp.html#c%3Acamlc)).

  * Arguments ending in .cmx are taken to be compiled object code. These files are linked together, along with the object files obtained by compiling .ml arguments (if any), and the OCaml standard library, to produce a native-code executable program. The order in which .cmx and .ml arguments are presented on the command line is relevant: compilation units are initialized in that order at run-time, and it is a link-time error to use a component of a unit before having initialized it. Hence, a given x.cmx file must come before all .cmx files that refer to the unit x.
  * Arguments ending in .cmxa are taken to be libraries of object code. Such a library packs in two files (lib.cmxa and lib.a/.lib) a set of object files (.cmx and .o/.obj files). Libraries are build with ocamlopt -a (see the description of the -a option below). The object files contained in the library are linked as regular .cmx files (see above), in the order specified when the library was built. The only difference is that if an object file contained in a library is not referenced anywhere in the program, then it is not linked in.
  * Arguments ending in .c are passed to the C compiler, which generates a .o/.obj object file. This object file is linked with the program.
  * Arguments ending in .o, .a or .so (.obj, .lib and .dll under Windows) are assumed to be C object files and libraries. They are linked with the program.

The output of the linking phase is a regular Unix or Windows executable file.
It does not need ocamlrun to run.

The compiler is able to emit some information on its internal stages:

  * .cmt files for the implementation of the compilation unit and .cmti for signatures if the option -bin-annot is passed to it (see the description of -bin-annot below). Each such file contains a typed abstract syntax tree (AST), that is produced during the type checking procedure. This tree contains all available information about the location and the specific type of each term in the source file. The AST is partial if type checking was unsuccessful.

These .cmt and .cmti files are typically useful for code inspection tools.

  * .cmir-linear files for the implementation of the compilation unit if the option -save-ir-after scheduling is passed to it. Each such file contains a low-level intermediate representation, produced by the instruction scheduling pass.

An external tool can perform low-level optimisations, such as code layout, by
transforming a .cmir-linear file. To continue compilation, the compiler can be
invoked with (a possibly modified) .cmir-linear file as an argument, instead
of the corresponding source file.

## ﻿16.2 Options

The following command-line options are recognized by ocamlopt. The options
-pack, -a, -shared, -c, -output-obj and -output-complete-obj are mutually
exclusive.

-a
     Build a library(.cmxa and .a/.lib files) with the object files (.cmx and .o/.obj files) given on the command line, instead of linking them into an executable file. The name of the library must be set with the -o option.

If -cclib or -ccopt options are passed on the command line, these options are
stored in the resulting .cmxa library. Then, linking with this library
automatically adds back the -cclib and -ccopt options as if they had been
provided on the command line, unless the -noautolink option is given.

-absname
     Force error messages to show absolute paths for file names.
-no-absname
     Do not try to show absolute filenames in error messages.
-annot
     Deprecated since OCaml 4.11. Please use -bin-annot instead. 
-args filename
     Read additional newline-terminated command line arguments from filename. 
-args0 filename
     Read additional null character terminated command line arguments from filename. 
-bin-annot
     Dump detailed information about the compilation (types, bindings, tail-calls, etc) in binary format. The information for file src.ml (resp. src.mli) is put into file src.cmt (resp. src.cmti). In case of a type error, dump all the information inferred by the type-checker before the error. The *.cmt and *.cmti files produced by -bin-annot contain more information and are much more compact than the files produced by -annot. 
-c
     Compile only. Suppress the linking phase of the compilation. Source code files are turned into compiled files, but no executable file is produced. This option is useful to compile modules separately. 
-cc ccomp
     Use ccomp as the C linker called to build the final executable and as the C compiler for compiling .c source files. When linking object files produced by a C++ compiler (such as g++ or clang++), it is recommended to use -cc c++. 
-cclib -llibname
     Pass the -llibname option to the linker . This causes the given C library to be linked with the program. 
-ccopt option
     Pass the given option to the C compiler and linker. For instance, -ccopt -Ldir causes the C linker to search for C libraries in directory dir. 
-cmi-file filename
     Use the given interface file to type-check the ML source file to compile. When this option is not specified, the compiler looks for a .mli file with the same base name than the implementation it is compiling and in the same directory. If such a file is found, the compiler looks for a corresponding .cmi file in the included directories and reports an error if it fails to find one. 
-color mode
     Enable or disable colors in compiler messages (especially warnings and errors). The following modes are supported: 

auto

     use heuristics to enable colors only if the output supports them (an ANSI-compatible tty terminal); 
always

     enable colors unconditionally; 
never

     disable color output. 

The environment variable OCAML_COLOR is considered if -color is not provided.
Its values are auto/always/never as above.

If -color is not provided, OCAML_COLOR is not set and the environment variable
NO_COLOR is set, then color output is disabled. Otherwise, the default setting
is ’auto’, and the current heuristic checks that the TERM environment variable
exists and is not empty or dumb, and that ’isatty(stderr)’ holds.

-error-style mode
     Control the way error messages and warnings are printed. The following modes are supported: 

short

     only print the error and its location; 
contextual

     like short, but also display the source code snippet corresponding to the location of the error. 
The default setting is contextual.

The environment variable OCAML_ERROR_STYLE is considered if -error-style is
not provided. Its values are short/contextual as above.

-compact
     Optimize the produced code for space rather than for time. This results in slightly smaller but slightly slower programs. The default is to optimize for speed. 
-config
     Print the version number of ocamlopt and a detailed summary of its configuration, then exit. 
-config-var var
     Print the value of a specific configuration variable from the -config output, then exit. If the variable does not exist, the exit code is non-zero. This option is only available since OCaml 4.08, so script authors should have a fallback for older versions. 
-depend ocamldep-args
     Compute dependencies, as the ocamldep command would do. The remaining arguments are interpreted as if they were given to the ocamldep command. 
-for-pack module-path
     Generate an object file (.cmx and .o/.obj files) that can later be included as a sub-module (with the given access path) of a compilation unit constructed with -pack. For instance, ocamlopt -for-pack P -c A.ml will generate a.cmx and a.o files that can later be used with ocamlopt -pack -o P.cmx a.cmx. Note: you can still pack a module that was compiled without -for-pack but in this case exceptions will be printed with the wrong names. 
-g
     Add debugging information while compiling and linking. This option is required in order to produce stack backtraces when the program terminates on an uncaught exception (see section [15.2](runtime.html#s%3Aocamlrun-options)). 
-no-g
     Do not record debugging information (default). 
-i
     Cause the compiler to print all defined names (with their inferred types or their definitions) when compiling an implementation (.ml file). No compiled files (.cmo and .cmi files) are produced. This can be useful to check the types inferred by the compiler. Also, since the output follows the syntax of interfaces, it can help in writing an explicit interface (.mli file) for a file: just redirect the standard output of the compiler to a .mli file, and edit that file to remove all declarations of unexported names. 
-i-variance
     Cause the compiler to print the computed variance of type parameters for every type declaration. Without this option, variance is printed only for private types or types without a manifest (e.g., abstract types).
-I directory
     Add the given directory to the list of directories searched for compiled interface files (.cmi), compiled object code files (.cmx), and libraries (.cmxa). By default, the current directory is searched first, then the standard library directory. Directories added with -I are searched after the current directory, in the order in which they were given on the command line, but before the standard library directory. See also option -nostdlib.

If the given directory starts with +, it is taken relative to the standard
library directory. For instance, -I +unix adds the subdirectory unix of the
standard library to the search path.

-H directory
     Behaves identically to -I, except that (a) programs may not directly refer to modules added to the search path this way, and (b) these directories are searched after any -I directories. This makes it possible to provide the compiler with compiled interface and object code files for the current program’s transitive dependencies (the dependencies of its dependencies) without allowing them to silently become direct dependencies. 
-impl filename
     Compile the file filename as an implementation file, even if its extension is not .ml. 
-inline n
     Set aggressiveness of inlining to n, where n is a positive integer. Specifying -inline 0 prevents all functions from being inlined, except those whose body is smaller than the call site. Thus, inlining causes no expansion in code size. The default aggressiveness, -inline 1, allows slightly larger functions to be inlined, resulting in a slight expansion in code size. Higher values for the -inline option cause larger and larger functions to become candidate for inlining, but can result in a serious increase in code size. 
-intf filename
     Compile the file filename as an interface file, even if its extension is not .mli. 
-intf-suffix string
     Recognize file names ending with string as interface files (instead of the default .mli). 
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
-linkall
     Force all modules contained in libraries to be linked in. If this flag is not given, unreferenced modules are not linked in. When building a library (option -a), setting the -linkall option forces all subsequent links of programs involving that library to link all the modules contained in the library. When compiling a module (option -c), setting the -linkall option ensures that this module will always be linked if it is put in a library and this library is linked. 
-linscan
     Use linear scan register allocation. Compiling with this allocator is faster than with the usual graph coloring allocator, sometimes quite drastically so for long functions and modules. On the other hand, the generated code can be a bit slower. 
-match-context-rows number
     Set the number of rows of context used for optimization during pattern matching compilation. The default value is 32. Lower values cause faster compilation, but less optimized code. This advanced option is meant for use in the event that a pattern-match-heavy program leads to significant increases in compilation time. 
-no-alias-deps
     Do not record dependencies for module aliases. See section [12.8](modulealias.html#s%3Amodule-alias) for more information. 
-no-app-funct
     Deactivates the applicative behaviour of functors. With this option, each functor application generates new types in its result and applying the same functor twice to the same argument yields two incompatible structures.
-no-float-const-prop
     Deactivates the constant propagation for floating-point operations. This option should be given if the program changes the float rounding mode during its execution. 
-noassert
     Do not compile assertion checks. Note that the special form assert false is always compiled because it is typed specially. This flag has no effect when linking already-compiled files.
-noautolink
     When linking .cmxa libraries, ignore -cclib and -ccopt options potentially contained in the libraries (if these options were given when building the libraries). This can be useful if a library contains incorrect specifications of C libraries or C options; in this case, during linking, set -noautolink and pass the correct C libraries and options on the command line. 
-nodynlink
     Allow the compiler to use some optimizations that are valid only for code that is statically linked to produce a non-relocatable executable. The generated code cannot be linked to produce a shared library nor a position-independent executable (PIE). Many operating systems produce PIEs by default, causing errors when linking code compiled with -nodynlink. Either do not use -nodynlink or pass the option -ccopt -no-pie at link-time. 
-nolabels
     Ignore non-optional labels in types. Labels cannot be used in applications, and parameter order becomes strict.
-nostdlib
     Do not automatically add the standard library directory to the list of directories searched for compiled interface files (.cmi), compiled object code files (.cmx), and libraries (.cmxa). See also option -I. 
-o filename
     Specify the name of the final output file, whether it is an executable, a compiled object (-c option), a library (-a option), a packed object (-pack option), a dynlinkable plugin (-shared option), or a C source or object file (-output-obj and -output-complete-obj options).

The default output name for an executable depends on the platform, it is a.out
on Unix, camlprog.exe on Windows.

This can also be used when compiling but not linking an interface or
implementation file (-c option), in which case it sets both the name of the
cmi or .cmx file, and of the compilation unit to the filename up to the first
dot.

-opaque
     When the native compiler compiles an implementation, by default it produces a .cmx file containing information for cross-module optimization. It also expects .cmx files to be present for the dependencies of the currently compiled source, and uses them for optimization. Since OCaml 4.03, the compiler will emit a warning if it is unable to locate the .cmx file of one of those dependencies.

The -opaque option, available since 4.04, disables cross-module optimization
information for the currently compiled unit. When compiling .mli interface,
using -opaque marks the compiled .cmi interface so that subsequent
compilations of modules that depend on it will not rely on the corresponding
.cmx file, nor warn if it is absent. When the native compiler compiles a .ml
implementation, using -opaque generates a .cmx that does not contain any
cross-module optimization information.

Using this option may degrade the quality of generated code, but it reduces
compilation time, both on clean and incremental builds. Indeed, with the
native compiler, when the implementation of a compilation unit changes, all
the units that depend on it may need to be recompiled – because the cross-
module information may have changed. If the compilation unit whose
implementation changed was compiled with -opaque, no such recompilation needs
to occur. This option can thus be used, for example, to get faster edit-
compile-test feedback loops.

-open Module
     Opens the given module before processing the interface or implementation files. If several -open options are given, they are processed in order, just as if the statements open! Module1;; ... open! ModuleN;; were added at the top of each file. 
-output-obj
     Cause the linker to produce a C object file instead of an executable file. This is useful to wrap OCaml code as a C library, callable from any C program. See chapter [23](intfc.html#c%3Aintf-c), section [23.7.6](intfc.html#ss%3Ac-embedded-code). The name of the output object file must be set with the -o option. This option can also be used to produce a compiled shared/dynamic library (.so extension, .dll under Windows). 
-output-complete-obj
     Same as -output-obj options except the object file produced includes the runtime and autolink libraries. 
-pack
     Build an object file (.cmx and .o/.obj files) and its associated compiled interface (.cmi) that combines the .cmx object files given on the command line, making them appear as sub-modules of the output .cmx file. The name of the output .cmx file must be given with the -o option. For instance, 
    
    
            ocamlopt -pack -o P.cmx A.cmx B.cmx C.cmx
    

generates compiled files P.cmx, P.o and P.cmi describing a compilation unit
having three sub-modules A, B and C, corresponding to the contents of the
object files A.cmx, B.cmx and C.cmx. These contents can be referenced as P.A,
P.B and P.C in the remainder of the program.

The .cmx object files being combined must have been compiled with the
appropriate -for-pack option. In the example above, A.cmx, B.cmx and C.cmx
must have been compiled with ocamlopt -for-pack P.

Multiple levels of packing can be achieved by combining -pack with -for-pack.
Consider the following example:

    
    
            ocamlopt -for-pack P.Q -c A.ml
            ocamlopt -pack -o Q.cmx -for-pack P A.cmx
            ocamlopt -for-pack P -c B.ml
            ocamlopt -pack -o P.cmx Q.cmx B.cmx
    

The resulting P.cmx object file has sub-modules P.Q, P.Q.A and P.B.

-pp command
     Cause the compiler to call the given command as a preprocessor for each source file. The output of command is redirected to an intermediate file, which is compiled. If there are no compilation errors, the intermediate file is deleted afterwards. 
-ppx command
     After parsing, pipe the abstract syntax tree through the preprocessor command. The module Ast_mapper, described in chapter [31](parsing.html#c%3Aparsinglib): [ Ast_mapper ](compilerlibref/Ast_mapper.html) , implements the external interface of a preprocessor.
-principal
     Check information path during type-checking, to make sure that all types are derived in a principal way. When using labelled arguments and/or polymorphic methods, this flag is required to ensure future versions of the compiler will be able to infer types correctly, even if internal algorithms change. All programs accepted in -principal mode are also accepted in the default mode with equivalent types, but different binary signatures, and this may slow down type checking; yet it is a good idea to use it once before publishing source code.
-rectypes
     Allow arbitrary recursive types during type-checking. By default, only recursive types where the recursion goes through an object type are supported. Note that once you have created an interface using this flag, you must use it again for all dependencies.
-runtime-variant suffix
     Add the suffix string to the name of the runtime library used by the program. Currently, only one such suffix is supported: d, and only if the OCaml compiler was configured with option -with-debug-runtime. This suffix gives the debug version of the runtime, which is useful for debugging pointer problems in low-level code such as C stubs. 
-S
     Keep the assembly code produced during the compilation. The assembly code for the source file x.ml is saved in the file x.s. 
-safe-string
     Enforce the separation between types string and bytes, thereby making strings read-only. This is the default, and enforced since OCaml 5.0.
-safer-matching
     Do not use type information to optimize pattern-matching. This allows to detect match failures even if a pattern-matching was wrongly assumed to be exhaustive. This only impacts GADT and polymorphic variant compilation.
-save-ir-after pass
     Save intermediate representation after the given compilation pass to a file. The currently supported passes and the corresponding file extensions are: scheduling (.cmir-linear).

This experimental feature enables external tools to inspect and manipulate
compiler’s intermediate representation of the program using compiler-libs
library (see chapter [31](parsing.html#c%3Aparsinglib) and [ Compiler_libs
](compilerlibref/Compiler_libs.html) ).

-set-runtime-default name=value
     When linking an executable, override the default value for a runtime setting. The currently supported settings are: 

standard_library_default

     Specifies the default location used by the executable to locate the Standard Library. By default, this is the absolute path to the Standard Library the compiler itself was configured with. 
-shared
     Build a plugin (usually .cmxs) that can be dynamically loaded with the Dynlink module. The name of the plugin must be set with the -o option. A plugin can include a number of OCaml modules and libraries, and extra native objects (.o, .obj, .a, .lib files). Building native plugins is only supported for some operating system. Under some systems (currently, only Linux AMD 64), all the OCaml code linked in a plugin must have been compiled without the -nodynlink flag. Some constraints might also apply to the way the extra native objects have been compiled (under Linux AMD 64, they must contain only position-independent code). 
-short-paths
     When a type is visible under several module-paths, use the shortest one when printing the type’s name in inferred interfaces and error and warning messages. Identifier names starting with an underscore _ or containing double underscores __ incur a penalty of +10 when computing their length.
-stop-after pass
     Stop compilation after the given compilation pass. The currently supported passes are: parsing, typing, scheduling, emit. 
-strict-sequence
     Force the left-hand part of each sequence to have type unit.
-strict-formats
     Reject invalid formats that were accepted in legacy format implementations. You should use this flag to detect and fix such invalid formats, as they will be rejected by future OCaml versions.
-typing-recovery
     Try to collect all typing errors. 
-unboxed-types
     When a type is unboxable (i.e. a record with a single argument or a concrete datatype with a single constructor of one argument) it will be unboxed unless annotated with [@@ocaml.boxed]. 
-no-unboxed-types
     When a type is unboxable it will be boxed unless annotated with [@@ocaml.unboxed]. This is the default. 
-unsafe
     Turn bound checking off for array and string accesses (the v.(i) and s.[i] constructs). Programs compiled with -unsafe are therefore faster, but unsafe: anything can happen if the program accesses an array or string outside of its bounds. Additionally, turn off the check for zero divisor in integer division and modulus operations. With -unsafe, an integer division (or modulus) by zero can halt the program or continue with an unspecified result instead of raising a Division_by_zero exception. 
-unsafe-string
     Identify the types string and bytes, thereby making strings writable. This is intended for compatibility with old source code and should not be used with new software. This option raises an error unconditionally since OCaml 5.0.
-v
     Print the version number of the compiler and the location of the standard library directory, then exit.
-verbose
     Print all external commands before they are executed, in particular invocations of the assembler, C compiler, and linker. Useful to debug C library problems.
-version or -vnum
     Print the version number of the compiler in short form (e.g. 3.11.0), then exit. 
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
It is displayed by ocamlopt -help. Note that warnings 5 and 10 are not always
triggered, depending on the internals of the type checker.

-warn-error warning-list
     Mark as fatal the warnings specified in the argument warning-list. The compiler will stop with an error when one of these warnings is emitted. The warning-list has the same meaning as for the -w option: a + sign (or an uppercase letter) marks the corresponding warnings as fatal, a - sign (or a lowercase letter) turns them back into non-fatal warnings, and a @ sign both enables and marks as fatal the corresponding warnings.

Note: it is not recommended to use warning sets (i.e. letters) as arguments to
-warn-error in production code, because this can break your build when future
versions of OCaml add some new warnings.

The default setting is -warn-error -a (no warning is fatal).

-warn-help
     Show the description of all available warning numbers.
-where
     Print the location of the standard library, then exit. 
-with-runtime
     The pair of options -with-runtime and -without-runtime give precise control over the way the runtime is linked. -with-runtime is the default. In summary, it instructs to include the runtime system, or a reference to the default path of the runtime system, in the generated program/executable/object file. The detailed behaviour depends on the compiler and options used:

For ocamlc, in its default linking mode (no use of -custom or -output-*),
-with-runtime creates a file which can be executed, whereas -without-runtime
creates a pure bytecode image which must be explicitly passed to a runtime
(i.e. ./foo vs ocamlrun ./foo).

For all other uses of ocamlc and ocamlopt, -with-runtime and -without-runtime
control whether the compiler passes flags for linking with the installed
runtime (-with-runtime) or whether the user is required to pass them
(-without-runtime).

For more information about the options -custom and -output-*, see their
documentation and section [23.7.6](intfc.html#ss%3Ac-embedded-code) of the
manual.

-without-runtime
     The compiler does not include the runtime system (nor a reference to it) in the generated program, executable or object file; it must be supplied separately. See option -with-runtime for details. 
- file
     Process file as a file name, even if it starts with a dash (-) character. 
-help or \--help
     Display a short usage summary and exit.

##### ﻿Options for the 64-bit x86 architecture

The 64-bit code generator for Intel/AMD x86 processors (amd64 architecture)
supports the following additional options:

-fPIC
     Generate position-independent machine code. This is the default. 
-fno-PIC
     Generate position-dependent machine code. 

##### ﻿Contextual control of command-line options

The compiler command line can be modified “from the outside” with the
following mechanisms. These are experimental and subject to change. They
should be used only for experimental and development work, not in released
packages.

OCAMLPARAM (environment variable)

     A set of arguments that will be inserted before or after the arguments from the command line. Arguments are specified in a comma-separated list of name=value pairs. A _ is used to specify the position of the command line arguments, i.e. a=x,_,b=y means that a=x should be executed before parsing the arguments, and b=y after. Finally, an alternative separator can be specified as the first character of the string, within the set :|; ,. 
ocaml_compiler_internal_params (file in the stdlib directory)

     A mapping of file names to lists of arguments that will be added to the command line (and OCAMLPARAM) arguments. 

## ﻿16.3 Common errors

The error messages are almost identical to those of ocamlc. See section
[13.4](comp.html#s%3Acomp-errors).

## ﻿16.4 Running executables produced by ocamlopt

Executables generated by ocamlopt are native, stand-alone executable files
that can be invoked directly. They do not depend on the ocamlrun bytecode
runtime system nor on dynamically-loaded C/OCaml stub libraries.

During execution of an ocamlopt-generated executable, the following
environment variables are also consulted:

OCAMLRUNPARAM

     Same usage as in ocamlrun (see section [15.2](runtime.html#s%3Aocamlrun-options)), except that option l is ignored (the operating system’s stack size limit is used instead). 
CAMLRUNPARAM

     If OCAMLRUNPARAM is not found in the environment, then CAMLRUNPARAM will be used instead. If CAMLRUNPARAM is not found, then the default values will be used. 

> Windows: On Windows, an ocamlopt-generated executable will expand the * and
> ? wildcards in arguments before anything else. The string array Sys.argv is
> constructed using the expanded arguments. To avoid this behaviour, a custom
> entry point can be written in C, as outlined in section
> [23.7.5](intfc.html#ss%3Amain-c).

## ﻿16.5 Compatibility with the bytecode compiler

This section lists the known incompatibilities between the bytecode compiler
and the native-code compiler. Except on those points, the two compilers should
generate code that behave identically.

  * Signals are detected only when the program performs an allocation in the heap. That is, if a signal is delivered while in a piece of code that does not allocate, its handler will not be called until the next heap allocation.
  * On ARM and PowerPC processors (32 and 64 bits), fused multiply-add (FMA) instructions can be generated for a floating-point multiplication followed by a floating-point addition or subtraction, as in x *. y +. z. The FMA instruction avoids rounding the intermediate result x *. y, which is generally beneficial, but produces floating-point results that differ slightly from those produced by the bytecode interpreter.
  * The native-code compiler performs a number of optimizations that the bytecode compiler does not perform, especially when the Flambda optimizer is active. In particular, the native-code compiler identifies and eliminates “dead code”, i.e. computations that do not contribute to the results of the program. For example, 
        
        let _ = ignore M.f
        

contains a reference to compilation unit M when compiled to bytecode. This
reference forces M to be linked and its initialization code to be executed.
The native-code compiler eliminates the reference to M, hence the compilation
unit M may not be linked and executed. A workaround is to compile M with the
-linkall flag so that it will always be linked and executed, even if not
referenced. See also the Sys.opaque_identity function from the Sys standard
library module.

  * Before 4.10, stack overflows, typically caused by excessively deep recursion, are not always turned into a Stack_overflow exception like with the bytecode compiler. The runtime system makes a best effort to trap stack overflows and raise the Stack_overflow exception, but sometimes it fails and a “segmentation fault” or another system fault occurs instead.

* * *

[![Previous](previous_motif.svg)](runtime.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](lexyacc.html)

