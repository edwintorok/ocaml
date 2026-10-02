[![Previous](previous_motif.svg)](depend.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](debugger.html)

* * *

# Chapter 19 The documentation generator (ocamldoc)

  * [19.1 Usage](ocamldoc.html#s%3Aocamldoc-usage)
  * [19.2 Syntax of documentation comments](ocamldoc.html#s%3Aocamldoc-comments)
  * [19.3 Custom generators](ocamldoc.html#s%3Aocamldoc-custom-generators)
  * [19.4 Adding command line options](ocamldoc.html#s%3Aocamldoc-adding-flags)

This chapter describes OCamldoc, a tool that generates documentation from
special comments embedded in source files. The comments used by OCamldoc are
of the form (**…*) and follow the format described in section 19.2.

OCamldoc can produce documentation in various formats: HTML, LATEX, TeXinfo,
Unix man pages, and dot dependency graphs. Moreover, users can add their own
custom generators, as explained in section 19.3.

In this chapter, we use the word _element_ to refer to any of the following
parts of an OCaml source file: a type declaration, a value, a module, an
exception, a module type, a type constructor, a record field, a class, a class
type, a class method, a class value or a class inheritance clause.

## ﻿19.1 Usage

### ﻿19.1.1 Invocation

OCamldoc is invoked via the command ocamldoc, as follows:

    
    
            ocamldoc options sourcefiles
    

#### ﻿Options for choosing the output format

The following options determine the format for the generated documentation.

-html
     Generate documentation in HTML default format. The generated HTML pages are stored in the current directory, or in the directory specified with the -d option. You can customize the style of the generated pages by editing the generated style.css file, or by providing your own style sheet using option -css-style. The file style.css is not generated if it already exists or if -css-style is used.
-latex
     Generate documentation in LATEX default format. The generated LATEX document is saved in file ocamldoc.out, or in the file specified with the -o option. The document uses the style file ocamldoc.sty. This file is generated when using the -latex option, if it does not already exist. You can change this file to customize the style of your LATEX documentation.
-texi
     Generate documentation in TeXinfo default format. The generated LATEX document is saved in file ocamldoc.out, or in the file specified with the -o option.
-man
     Generate documentation as a set of Unix man pages. The generated pages are stored in the current directory, or in the directory specified with the -d option.
-dot
     Generate a dependency graph for the toplevel modules, in a format suitable for displaying and processing by dot. The dot tool is available from [https://graphviz.org/](https://graphviz.org/). The textual representation of the graph is written to the file ocamldoc.out, or to the file specified with the -o option. Use dot ocamldoc.out to display it.
-g file.cm[o,a,xs]
     Dynamically load the given file, which defines a custom documentation generator. See section 19.4.1. This option is supported by the ocamldoc command (to load .cmo and .cma files) and by its native-code version ocamldoc.opt (to load .cmxs files). If the given file is a simple one and does not exist in the current directory, then ocamldoc looks for it in the custom generators default directory, and in the directories specified with optional -i options.
-customdir
     Display the custom generators default directory.
-i directory
     Add the given directory to the path where to look for custom generators.

#### ﻿General options

-d dir
     Generate files in directory dir, rather than the current directory.
-dump file
     Dump collected information into file. This information can be read with the -load option in a subsequent invocation of ocamldoc.
-hide modules
     Hide the given complete module names in the generated documentation. modules is a list of complete module names separated by ’,’, without blanks. For instance: Stdlib,M2.M3.
-inv-merge-ml-mli
     Reverse the precedence of implementations and interfaces when merging. All elements in implementation files are kept, and the -m option indicates which parts of the comments in interface files are merged with the comments in implementation files.
-keep-code
     Always keep the source code for values, methods and instance variables, when available.
-load file
     Load information from file, which has been produced by ocamldoc -dump. Several -load options can be given.
-m flags
     Specify merge options between interfaces and implementations. (see section 19.1.2 for details). flags can be one or several of the following characters: 

d

     merge description 
a

     merge @author
v

     merge @version
l

     merge @see
s

     merge @since
b

     merge @before
o

     merge @deprecated
p

     merge @param
e

     merge @raise
r

     merge @return
A

     merge everything 
-no-custom-tags
     Do not allow custom @-tags (see section 19.2.5).
-no-stop
     Keep elements placed after/between the (**/**) special comment(s) (see section 19.2).
-o file
     Output the generated documentation to file instead of ocamldoc.out. This option is meaningful only in conjunction with the -latex, -texi, or -dot options.
-pp command
     Pipe sources through preprocessor command.
-impl filename
     Process the file filename as an implementation file, even if its extension is not .ml.
-intf filename
     Process the file filename as an interface file, even if its extension is not .mli.
-text filename
     Process the file filename as a text file, even if its extension is not .txt.
-sort
     Sort the list of top-level modules before generating the documentation.
-stars
     Remove blank characters until the first asterisk (’*’) in each line of comments.
-t title
     Use title as the title for the generated documentation.
-intro file
     Use content of file as ocamldoc text to use as introduction (HTML, LATEX and TeXinfo only). For HTML, the file is used to create the whole index.html file.
-v
     Verbose mode. Display progress information.
-version
     Print version string and exit.
-vnum
     Print short version number and exit.
-warn-error
     Treat Ocamldoc warnings as errors.
-hide-warnings
     Do not print OCamldoc warnings.
-help or \--help
     Display a short usage summary and exit. 

#### ﻿Type-checking options

OCamldoc calls the OCaml type-checker to obtain type information. The
following options impact the type-checking phase. They have the same meaning
as for the ocamlc and ocamlopt commands.

-I directory
     Add directory to the list of directories search for compiled interface files (.cmi files).
-H directory
     Like -I, but the -H directories are searched last and the program may not directly refer to the modules added to the search path this way.
-nolabels
     Ignore non-optional labels in types.
-rectypes
     Allow arbitrary recursive types. (See the -rectypes option to ocamlc.)

#### ﻿Options for generating HTML pages

The following options apply in conjunction with the -html option:

-all-params
     Display the complete list of parameters for functions and methods.
-charset charset
     Add information about character encoding being charset (default is iso-8859-1).
-colorize-code
     Colorize the OCaml code enclosed in [ ] and {[ ]}, using colors to emphasize keywords, etc. If the code fragments are not syntactically correct, no color is added.
-css-style filename
     Use filename as the Cascading Style Sheet file.
-index-only
     Generate only index files.
-short-functors
     Use a short form to display functors: 
    
    
    module M : functor (A:Module) -> functor (B:Module2) -> sig .. end
    

is displayed as:

    
    
    module M (A:Module) (B:Module2) : sig .. end
    

#### ﻿Options for generating LATEX files

The following options apply in conjunction with the -latex option:

-latex-value-prefix prefix
     Give a prefix to use for the labels of the values in the generated LATEX document. The default prefix is the empty string. You can also use the options -latex-type-prefix, -latex-exception-prefix, -latex-module-prefix, -latex-module-type-prefix, -latex-class-prefix, -latex-class-type-prefix, -latex-attribute-prefix and -latex-method-prefix.

These options are useful when you have, for example, a type and a value with
the same name. If you do not specify prefixes, LATEX will complain about
multiply defined labels.

-latextitle n,style
     Associate style number n to the given LATEX sectioning command style, e.g. section or subsection. (LATEX only.) This is useful when including the generated document in another LATEX document, at a given sectioning level. The default association is 1 for section, 2 for subsection, 3 for subsubsection, 4 for paragraph and 5 for subparagraph.
-noheader
     Suppress header in generated documentation.
-notoc
     Do not generate a table of contents.
-notrailer
     Suppress trailer in generated documentation.
-sepfiles
     Generate one .tex file per toplevel module, instead of the global ocamldoc.out file. 

#### ﻿Options for generating TeXinfo files

The following options apply in conjunction with the -texi option:

-esc8
     Escape accented characters in Info files.
-info-entry
     Specify Info directory entry.
-info-section
     Specify section of Info directory.
-noheader
     Suppress header in generated documentation.
-noindex
     Do not build index for Info files.
-notrailer
     Suppress trailer in generated documentation. 

#### ﻿Options for generating dot graphs

The following options apply in conjunction with the -dot option:

-dot-colors colors
     Specify the colors to use in the generated dot code. When generating module dependencies, ocamldoc uses different colors for modules, depending on the directories in which they reside. When generating types dependencies, ocamldoc uses different colors for types, depending on the modules in which they are defined. colors is a list of color names separated by ’,’, as in Red,Blue,Green. The available colors are the ones supported by the dot tool.
-dot-include-all
     Include all modules in the dot output, not only modules given on the command line or loaded with the -load option.
-dot-reduce
     Perform a transitive reduction of the dependency graph before outputting the dot code. This can be useful if there are a lot of transitive dependencies that clutter the graph.
-dot-types
     Output dot code describing the type dependency graph instead of the module dependency graph. 

#### ﻿Options for generating man files

The following options apply in conjunction with the -man option:

-man-mini
     Generate man pages only for modules, module types, classes and class types, instead of pages for all elements.
-man-suffix suffix
     Set the suffix used for generated man filenames. Default is ’3o’, as in List.3o.
-man-section section
     Set the section number used for generated man filenames. Default is ’3’.

### ﻿19.1.2 Merging of module information

Information on a module can be extracted either from the .mli or .ml file, or
both, depending on the files given on the command line. When both .mli and .ml
files are given for the same module, information extracted from these files is
merged according to the following rules:

  * Only elements (values, types, classes, ...) declared in the .mli file are kept. In other terms, definitions from the .ml file that are not exported in the .mli file are not documented. 
  * Descriptions of elements and descriptions in @-tags are handled as follows. If a description for the same element or in the same @-tag of the same element is present in both files, then the description of the .ml file is concatenated to the one in the .mli file, if the corresponding -m flag is given on the command line. If a description is present in the .ml file and not in the .mli file, the .ml description is kept. In either case, all the information given in the .mli file is kept. 

### ﻿19.1.3 Coding rules

The following rules must be respected in order to avoid name clashes resulting
in cross-reference errors:

  * In a module, there must not be two modules, two module types or a module and a module type with the same name. In the default HTML generator, modules ab and AB will be printed to the same file on case insensitive file systems. 
  * In a module, there must not be two classes, two class types or a class and a class type with the same name. 
  * In a module, there must not be two values, two types, or two exceptions with the same name. 
  * Values defined in tuple, as in let (x,y,z) = (1,2,3) are not kept by OCamldoc. 
  * Avoid the following construction: 

open Foo (* which has a module Bar with a value x *) module Foo = struct
module Bar = struct let x = 1 end end let dummy = Bar.x

In this case, OCamldoc will associate Bar.x to the x of module Foo defined
just above, instead of to the Bar.x defined in the opened module Foo.

## ﻿19.2 Syntax of documentation comments

Comments containing documentation material are called _special comments_ and
are written between (** and *). Special comments must start exactly with (**.
Comments beginning with ( and more than two * are ignored.

### ﻿19.2.1 Placement of documentation comments

OCamldoc can associate comments to some elements of the language encountered
in the source files. The association is made according to the locations of
comments with respect to the language elements. The locations of comments in
.mli and .ml files are different.

#### ﻿Comments in .mli files

A special comment is associated to an element if it is placed before or after
the element.  
A special comment before an element is associated to this element if :

  * There is no blank line or another special comment between the special comment and the element. However, a regular comment can occur between the special comment and the element. 
  * The special comment is not already associated to the previous element. 
  * The special comment is not the first one of a toplevel module. 

A special comment after an element is associated to this element if there is
no blank line or comment between the special comment and the element.

There are two exceptions: for constructors and record fields in type
definitions, the associated comment can only be placed after the constructor
or field definition, without blank lines or other comments between them. The
special comment for a constructor with another constructor following must be
placed before the ’|’ character separating the two constructors.

The following sample interface file foo.mli illustrates the placement rules
for comments in .mli files.

(** The first special comment of the file is the comment associated with the whole module.*) (** Special comments can be placed between elements and are kept by the OCamldoc tool, but are not associated to any element. @-tags in these comments are ignored.*) (*******************************************************************) (** Comments like the one above, with more than two asterisks, are ignored. *) (** The comment for function f. *) val f : int -> int -> int (** The continuation of the comment for function f. *) (** Comment for exception My_exception, even with a simple comment between the special comment and the exception.*) (* Hello, I'm a simple comment :-) *) exception My_exception of (int -> int) * int (** Comment for type weather *) type weather = | Rain of int (** The comment for constructor Rain *) | Sun (** The comment for constructor Sun *) (** Comment for type weather2 *) type weather2 = | Rain of int (** The comment for constructor Rain *) | Sun (** The comment for constructor Sun *) (** I can continue the comment for type weather2 here because there is already a comment associated to the last constructor.*) (** The comment for type my_record *) type my_record = { foo : int ; (** Comment for field foo *) bar : string ; (** Comment for field bar *) } (** Continuation of comment for type my_record *) (** Comment for foo *) val foo : string (** This comment is associated to foo and not to bar. *) val bar : string (** This comment is associated to bar. *) (** The comment for class my_class *) class my_class : object (** A comment to describe inheritance from cl *) inherit cl (** The comment for attribute tutu *) val mutable tutu : string (** The comment for attribute toto. *) val toto : int (** This comment is not attached to titi since there is a blank line before titi, but is kept as a comment in the class. *) val titi : string (** Comment for method toto *) method toto : string (** Comment for method m *) method m : float -> int end (** The comment for the class type my_class_type *) class type my_class_type = object (** The comment for variable x. *) val mutable x : int (** The comment for method m. *) method m : int -> int end (** The comment for module Foo *) module Foo : sig (** The comment for x *) val x : int (** A special comment that is kept but not associated to any element *) end (** The comment for module type my_module_type. *) module type my_module_type = sig (** The comment for value x. *) val x : int (** The comment for module M. *) module M : sig (** The comment for value y. *) val y : int (* ... *) end end

#### ﻿Comments in .ml files

A special comment is associated to an element if it is placed before the
element and there is no blank line between the comment and the element.
Meanwhile, there can be a simple comment between the special comment and the
element. There are two exceptions, for constructors and record fields in type
definitions, whose associated comment must be placed after the constructor or
field definition, without blank line between them. The special comment for a
constructor with another constructor following must be placed before the ’|’
character separating the two constructors.

The following example of file toto.ml shows where to place comments in a .ml
file.

(** The first special comment of the file is the comment associated to the whole module. *) (** The comment for function f *) let f x y = x + y (** This comment is not attached to any element since there is another special comment just before the next element. *) (** Comment for exception My_exception, even with a simple comment between the special comment and the exception.*) (* A simple comment. *) exception My_exception of (int -> int) * int (** Comment for type weather *) type weather = | Rain of int (** The comment for constructor Rain *) | Sun (** The comment for constructor Sun *) (** The comment for type my_record *) type my_record = { foo : int ; (** Comment for field foo *) bar : string ; (** Comment for field bar *) } (** The comment for class my_class *) class my_class = object (** A comment to describe inheritance from cl *) inherit cl (** The comment for the instance variable tutu *) val mutable tutu = "tutu" (** The comment for toto *) val toto = 1 val titi = "titi" (** Comment for method toto *) method toto = tutu ^ "!" (** Comment for method m *) method m (f : float) = 1 end (** The comment for class type my_class_type *) class type my_class_type = object (** The comment for the instance variable x. *) val mutable x : int (** The comment for method m. *) method m : int -> int end (** The comment for module Foo *) module Foo = struct (** The comment for x *) let x = 0 (** A special comment in the class, but not associated to any element. *) end (** The comment for module type my_module_type. *) module type my_module_type = sig (* Comment for value x. *) val x : int (* ... *) end

### ﻿19.2.2 The Stop special comment

The special comment (**/**) tells OCamldoc to discard elements placed after
this comment, up to the end of the current class, class type, module or module
type, or up to the next stop comment. For instance:

class type foo = object (** comment for method m *) method m : string (**/**)
(** This method won't appear in the documentation *) method bar : int end (**
This value appears in the documentation, since the Stop special comment in the
class does not affect the parent module of the class.*) val foo : string
(**/**) (** The value bar does not appear in the documentation.*) val bar :
string (**/**) (** The type t appears since in the documentation since the
previous stop comment toggled off the "no documentation mode". *) type t =
string

The -no-stop option to ocamldoc causes the Stop special comments to be
ignored.

### ﻿19.2.3 Syntax of documentation comments

The inside of documentation comments (**…*) consists of free-form text with
optional formatting annotations, followed by optional _tags_ giving more
specific information about parameters, version, authors, … The tags are
distinguished by a leading @ character. Thus, a documentation comment has the
following shape:

    
    
    (** The comment begins with a description, which is text formatted
       according to the rules described in the next section.
       The description continues until the first non-escaped '@' character.
       @author Mr Smith
       @param x description for parameter x
    *)
    

Some elements support only a subset of all @-tags. Tags that are not relevant
to the documented element are simply ignored. For instance, all tags are
ignored when documenting type constructors, record fields, and class
inheritance clauses. Similarly, a @param tag on a class instance variable is
ignored.

At last, (**) is the empty documentation comment.

### ﻿19.2.4 Text formatting

Here is the BNF grammar for the simple markup language used to format text
descriptions.

| text| ::=|  {text-element}+  
---|---|---  
  
  
| inline-text| ::=|  {inline-text-element}+  
---|---|---  
  
  
text-element| ::=  
---|---  
  
∣| inline-text-element|  
---|---|---  
∣| blank-line| force a new line.  
  
  

inline-text-element| ::=  
---|---  
  
∣|  { { 0 … 9 }+ inline-text } | format text as a section header; the integer following { indicates the sectioning level.   
---|---|---  
∣|  { { 0 … 9 }+ : label inline-text } |  same, but also associate the name label to the current point. This point can be referenced by its fully-qualified label in a {! command, just like any other element.   
∣|  {b inline-text } | set text in bold.   
∣|  {i inline-text } | set text in italic.   
∣|  {e inline-text } | emphasize text.   
∣|  {C inline-text } | center text.   
∣|  {L inline-text } | left align text.   
∣|  {R inline-text } | right align text.   
∣|  {ul list } | build a list.   
∣|  {ol list } | build an enumerated list.   
∣|  {{: string } inline-text } | put a link to the given address (given as string) on the given text.   
∣|  [ string ] | set the given string in source code style.   
∣|  {[ string ]} | set the given string in preformatted source code style.  
∣|  {v string v} | set the given string in verbatim style.   
∣|  {% string %} | target-specific content (LATEX code by default, see details in 19.2.4.4)   
∣|  {! string } | insert a cross-reference to an element (see section 19.2.4.2 for the syntax of cross-references).  
∣|  {{! string } inline-text } | insert a cross-reference with the given text.   
∣|  {!modules: string string ... } | insert an index table for the given module names. Used in HTML only.  
∣|  {!indexlist} | insert a table of links to the various indexes (types, values, modules, ...). Used in HTML only.  
∣|  {^ inline-text } | set text in superscript.  
∣|  {_ inline-text } | set text in subscript.  
∣| escaped-string| typeset the given string as is; special characters (’{’,
’}’, ’[’, ’]’ and ’@’) must be escaped by a ’\’  
  
  

#### ﻿19.2.4.1 List formatting

| list| ::=|  
---|---|---  
 | ∣|  { {- inline-text } }+  
 | ∣|  { {li inline-text } }+  
  
A shortcut syntax exists for lists and enumerated lists:

    
    
    (** Here is a {b list}
    - item 1
    - item 2
    - item 3
    
    The list is ended by the blank line.*)
    

is equivalent to:

    
    
    (** Here is a {b list}
    {ul {- item 1}
    {- item 2}
    {- item 3}}
    The list is ended by the blank line.*)
    

The same shortcut is available for enumerated lists, using ’+’ instead of ’-’.
Note that only one list can be defined by this shortcut in nested lists.

#### ﻿19.2.4.2 Cross-reference formatting

Cross-references are fully qualified element names, as in the example
{!Foo.Bar.t}. This is an ambiguous reference as it may designate a type name,
a value name, a class name, etc. It is possible to make explicit the intended
syntactic class, using {!type:Foo.Bar.t} to designate a type, and
{!val:Foo.Bar.t} a value of the same name.

The list of possible syntactic class is as follows:

tag| syntactic class  
---|---  
module:| module  
modtype:| module type  
class:| class  
classtype:| class type  
val:| value  
type:| type  
exception:| exception  
attribute:| attribute  
method:| class method  
section:| ocamldoc section  
const:| variant constructor  
recfield:| record field  
  
In the case of variant constructors or record fields, the constructor or field
name should be preceded by the name of the corresponding type to avoid the
ambiguity of several types having the same constructor names. For example, the
constructor Node of the type tree will be referenced as {!tree.Node} or
{!const:tree.Node}, or possibly {!Mod1.Mod2.tree.Node} from outside the
module.

#### ﻿19.2.4.3 First sentence

In the description of a value, type, exception, module, module type, class or
class type, the _first sentence_ is sometimes used in indexes, or when just a
part of the description is needed. The first sentence is composed of the first
characters of the description, until

  * the first dot followed by a blank, or 
  * the first blank line 

outside of the following text formatting : {ul list } , {ol list } , [ string
] , {[ string ]} , {v string v} , {% string %} , {! string } , {^ text } , {_
text } .

#### ﻿19.2.4.4 Target-specific formatting

The content inside {%foo: ... %} is target-specific and will be interpreted
only by the backend foo, and ignored by other backends. The backends of the
distribution are latex, html, texi and man. If no target is specified (syntax
{% ... %}), latex is chosen by default. Custom generators may support their
own target prefix.

#### ﻿19.2.4.5 Recognized HTML tags

The HTML tags <b>..</b>, <code>..</code>, <i>..</i>, <ul>..</ul>, <ol>..</ol>,
<li>..</li>, <center>..</center> and <h[0-9]>..</h[0-9]> can be used instead
of, respectively, {b ..} , [..] , {i ..} , {ul ..} , {ol ..} , {li ..} , {C
..} and {[0-9] ..}.

### ﻿19.2.5 Documentation tags (@-tags)

#### ﻿Predefined tags

The following table gives the list of predefined @-tags, with their syntax and
meaning.  

@author string | The author of the element. One author per @author tag. There may be several @author tags for the same element.   
---|---  
@deprecated text | The text should describe when the element was deprecated, what to use as a replacement, and possibly the reason for deprecation.   
@param id text | Associate the given description (text) to the given parameter name id. This tag is used for functions, methods, classes and functors.   
@raise Exc text | Explain that the element may raise the exception Exc.   
@return text | Describe the return value and its possible values. This tag is used for functions and methods.   
@see < URL > text | Add a reference to the URL with the given text as comment.   
@see 'filename' text | Add a reference to the given file name (written between single quotes), with the given text as comment.   
@see "document-name" text | Add a reference to the given document name (written between double quotes), with the given text as comment.   
@since string | Indicate when the element was introduced.   
@before version text | Associate the given description (text) to the given version in order to document compatibility issues.   
@version string | The version number for the element.   
  
#### ﻿Custom tags

You can use custom tags in the documentation comments, but they will have no
effect if the generator used does not handle them. To use a custom tag, for
example foo, just put @foo with some text in your comment, as in:

    
    
    (** My comment to show you a custom tag.
    @foo this is the text argument to the [foo] custom tag.
    *)
    

To handle custom tags, you need to define a custom generator, as explained in
section 19.3.2.

## ﻿19.3 Custom generators

OCamldoc operates in two steps:

  1. analysis of the source files; 
  2. generation of documentation, through a documentation generator, which is an object of class Odoc_args.class_generator. 

Users can provide their own documentation generator to be used during step 2
instead of the default generators. All the information retrieved during the
analysis step is available through the Odoc_info module, which gives access to
all the types and functions representing the elements found in the given
modules, with their associated description.

The files you can use to define custom generators are installed in the
ocamldoc sub-directory of the OCaml standard library.

### ﻿19.3.1 The generator modules

The type of a generator module depends on the kind of generated documentation.
Here is the list of generator module types, with the name of the generator
class in the module :

  * for HTML : Odoc_html.Html_generator (class html), 
  * for LATEX : Odoc_latex.Latex_generator (class latex), 
  * for TeXinfo : Odoc_texi.Texi_generator (class texi), 
  * for man pages : Odoc_man.Man_generator (class man), 
  * for graphviz (dot) : Odoc_dot.Dot_generator (class dot), 
  * for other kinds : Odoc_gen.Base (class generator). 

That is, to define a new generator, one must implement a module with the
expected signature, and with the given generator class, providing the generate
method as entry point to make the generator generates documentation for a
given list of modules :

    
    
            method generate : Odoc_info.Module.t_module list -> unit
    

This method will be called with the list of analysed and possibly merged
Odoc_info.t_module structures.

It is recommended to inherit from the current generator of the same kind as
the one you want to define. Doing so, it is possible to load various custom
generators to combine improvements brought by each one.

This is done using first class modules (see chapter
[12.5](firstclassmodules.html#s%3Afirst-class-modules)).

The easiest way to define a custom generator is the following this example,
here extending the current HTML generator. We don’t have to know if this is
the original HTML generator defined in ocamldoc or if it has been extended
already by a previously loaded custom generator :

    
    
    module Generator (G : Odoc_html.Html_generator) =
    struct
      class html =
        object(self)
          inherit G.html as html
          (* ... *)
    
          method generate module_list =
            (* ... *)
            ()
    
          (* ... *)
      end
    end;;
    
    let _ = Odoc_args.extend_html_generator (module Generator : Odoc_gen.Html_functor);;
    

To know which methods to override and/or which methods are available, have a
look at the different base implementations, depending on the kind of generator
you are extending :

  * for HTML : [odoc_html.ml](https://github.com/ocaml/ocaml/blob/5.6/ocamldoc/odoc_html.ml), 
  * for LATEX : [odoc_latex.ml](https://github.com/ocaml/ocaml/blob/5.6/ocamldoc/odoc_latex.ml), 
  * for TeXinfo : [odoc_texi.ml](https://github.com/ocaml/ocaml/blob/5.6/ocamldoc/odoc_texi.ml), 
  * for man pages : [odoc_man.ml](https://github.com/ocaml/ocaml/blob/5.6/ocamldoc/odoc_man.ml), 
  * for graphviz (dot) : [odoc_dot.ml](https://github.com/ocaml/ocaml/blob/5.6/ocamldoc/odoc_dot.ml). 

### ﻿19.3.2 Handling custom tags

Making a custom generator handle custom tags (see 19.2.5) is very simple.

#### ﻿For HTML

Here is how to develop a HTML generator handling your custom tags.

The class Odoc_html.Generator.html inherits from the class Odoc_html.info,
containing a field tag_functions which is a list pairs composed of a custom
tag (e.g. "foo") and a function taking a text and returning HTML code (of type
string). To handle a new tag bar, extend the current HTML generator and
complete the tag_functions field:

    
    
    module Generator (G : Odoc_html.Html_generator) =
    struct
      class html =
        object(self)
          inherit G.html
    
          (** Return HTML code for the given text of a bar tag. *)
          method html_of_bar t = (* your code here *)
    
          initializer
            tag_functions <- ("bar", self#html_of_bar) :: tag_functions
      end
    end
    let _ = Odoc_args.extend_html_generator (module Generator : Odoc_gen.Html_functor);;
    

Another method of the class Odoc_html.info will look for the function
associated to a custom tag and apply it to the text given to the tag. If no
function is associated to a custom tag, then the method prints a warning
message on stderr.

#### ﻿For other generators

You can act the same way for other kinds of generators.

## ﻿19.4 Adding command line options

The command line analysis is performed after loading the module containing the
documentation generator, thus allowing command line options to be added to the
list of existing ones. Adding an option can be done with the function

    
    
            Odoc_args.add_option : string * Arg.spec * string -> unit
    

Note: Existing command line options can be redefined using this function.

### ﻿19.4.1 Compilation and usage

#### ﻿Defining a custom generator class in one file

Let custom.ml be the file defining a new generator class. Compilation of
custom.ml can be performed by the following command :

    
    
            ocamlc -I +ocamldoc -c custom.ml
    

The file custom.cmo is created and can be used this way :

    
    
            ocamldoc -g custom.cmo other-options source-files
    

Options selecting a built-in generator to ocamldoc, such as -html, have no
effect if a custom generator of the same kind is provided using -g. If the
kinds do not match, the selected built-in generator is used and the custom one
is ignored.

#### ﻿Defining a custom generator class in several files

It is possible to define a generator class in several modules, which are
defined in several files file1.ml[i], file2.ml[i], ..., filen.ml[i]. A .cma
library file must be created, including all these files.

The following commands create the custom.cma file from files file1.ml[i], ...,
filen.ml[i] :

    
    
    ocamlc -I +ocamldoc -c file1.ml[i]
    ocamlc -I +ocamldoc -c file2.ml[i]
    ...
    ocamlc -I +ocamldoc -c filen.ml[i]
    ocamlc -o custom.cma -a file1.cmo file2.cmo ... filen.cmo
    

Then, the following command uses custom.cma as custom generator:

    
    
            ocamldoc -g custom.cma other-options source-files
    

* * *

[![Previous](previous_motif.svg)](depend.html)
[![Up](contents_motif.svg)](index.html)
[![Next](next_motif.svg)](debugger.html)

